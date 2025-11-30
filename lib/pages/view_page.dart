import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/agendamento_service.dart';
import '../models/agendamento.dart';
import '../app_colors.dart';

// Tela para visualização dos agendamentos do usuário atual
// Utiliza StatelessWidget pois todo o estado é gerenciado pelo StreamBuilder
class ViewPage extends StatelessWidget {
  const ViewPage({super.key});
  
  @override 
  Widget build(BuildContext context) {
    // Obtém o usuário atual autenticado no Firebase
    final user = FirebaseAuth.instance.currentUser;
    // Extrai o UID do usuário ou usa string vazia como fallback
    final userUid = user?.uid ?? '';
    
    return Scaffold(
      // AppBar com título específico para esta tela
      appBar: AppBar(
        title: const Text('Meus Agendamentos'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      // Define a cor de fundo usando a paleta de cores do app
      backgroundColor: AppColors.background,
      // Corpo principal da tela
      body: StreamBuilder<List<Agendamento>>(
        // Stream que fornece os agendamentos do usuário em tempo real
        stream: AgendamentoService.streamUserAgendamentos(userUid),
        builder: (context, snap) {
          // Estado de carregamento - mostra indicador de progresso
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          // Tratamento de erro - mostra mensagem de erro amigável
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Ícone de erro com cor temática
                  Icon(Icons.error, color: AppColors.error, size: 64),
                  const SizedBox(height: 16), // Espaçamento consistente
                  Text(
                    'Erro ao carregar agendamentos',
                    style: TextStyle(fontSize: 16, color: AppColors.error),
                  ),
                ],
              ),
            );
          }
          
          // Obtém os dados do snapshot ou lista vazia se null
          final items = snap.data ?? [];
          // Filtra apenas os agendamentos ativos (não cancelados)
          final agendamentosAtivos = items.where((a) => a.isAtivo).toList();
          
          // Estado vazio - mostra mensagem quando não há agendamentos
          if (agendamentosAtivos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Ícone ilustrativo de calendário vazio
                  Icon(Icons.calendar_today, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  // Título da mensagem de estado vazio
                  const Text(
                    'Nenhum agendamento ativo',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  // Instrução para o usuário
                  const Text(
                    'Crie um novo agendamento para começar',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          
          // Lista de agendamentos ativos - constrói a interface principal
          return ListView.builder(
            padding: const EdgeInsets.all(16), // Padding ao redor da lista
            itemCount: agendamentosAtivos.length,
            itemBuilder: (context, index) {
              final a = agendamentosAtivos[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12), // Espaço entre cards
                child: Card(
                  elevation: 2, // Sombra sutil para profundidade
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16), // Cantos arredondados
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16), // Espaçamento interno
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cabeçalho do card com título e status
                        Row(
                          children: [
                            // Container do ícone com fundo colorido
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1), // Fundo sutil
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.event_available,
                                color: AppColors.primary, // Ícone na cor primária
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12), // Espaço entre ícone e texto
                            // Título do agendamento - ocupa espaço disponível
                            Expanded(
                              child: Text(
                                a.titulo,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // Badge de status "Ativo"
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.1), // Fundo verde claro
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Ativo',
                                style: TextStyle(
                                  color: AppColors.success, // Texto verde
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16), // Espaço entre seções
                        // Informações detalhadas do agendamento
                        _buildInfoRow('🏢 Sala', a.sala),
                        _buildInfoRow('📅 Data', _formatDate(a.inicio)),
                        _buildInfoRow(
                          '🕒 Horário',
                          '${_formatTime(a.inicio)} - ${_formatTime(a.fim)}',
                        ),
                        // Descrição - mostrada apenas se não estiver vazia
                        if (a.descricao.isNotEmpty)
                          _buildInfoRow('📝 Descrição', a.descricao),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
  
  // Widget auxiliar para construir linhas de informação consistentes
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4), // Espaçamento vertical entre linhas
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Alinha ao topo para multi-linha
        children: [
          // Container do label com largura fixa para alinhamento
          SizedBox(
            width: 100, // Largura fixa para alinhar todos os labels
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500, // Peso médio para destaque
                color: Colors.grey[700],     // Cor cinza escuro para labels
              ),
            ),
          ),
          const SizedBox(width: 8), // Espaço entre label e valor
          // Valor - ocupa o espaço restante
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w400, // Peso normal para valores
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // FUNÇÕES AUXILIARES PARA FORMATAR DATA E HORA
  
  // Formata data no padrão DD/MM/AAAA
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
  
  // Formata hora no padrão HH:MM
  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}