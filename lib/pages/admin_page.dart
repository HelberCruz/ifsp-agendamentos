import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/agendamento_service.dart';
import '../services/auth_service.dart';
import '../models/agendamento.dart';
import '../app_colors.dart';

// Tela administrativa para gerenciar agendamentos
class AdminPage extends StatefulWidget {
  const AdminPage({super.key});
  @override State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  late final Stream<List<Agendamento>> _stream; // Stream para receber agendamentos em tempo real
  String _userLevel = 'user'; // Nível de acesso do usuário

  @override
  void initState() {
    super.initState();
    // Inicializa o stream com todos os agendamentos do Firebase
    _stream = AgendamentoService.streamAllAgendamentos();
    // Carrega o nível de acesso do usuário atual
    _loadUserLevel();
  }

  // Método para verificar se usuário tem permissão de admin
  void _loadUserLevel() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final level = await AuthService.getUserLevel(user.uid);
      setState(() => _userLevel = level);
    }
  }

  // Método para cancelar agendamento como administrador
  void _cancelarAgendamentoAdmin(Agendamento a) async {
    final motivoController = TextEditingController(); // Controlador para campo de motivo
    
    // Diálogo de confirmação de cancelamento
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Agendamento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Agendamento: ${a.titulo}'),
            Text('Usuário: ${a.usuarioEmail}'),
            const SizedBox(height: 16),
            // Campo para inserir motivo do cancelamento
            TextField(
              controller: motivoController,
              decoration: const InputDecoration(
                labelText: 'Motivo do cancelamento',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          // Botão para cancelar a ação
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          // Botão para confirmar cancelamento
          ElevatedButton(
            onPressed: () async {
              // Valida se motivo foi preenchido
              if (motivoController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Informe o motivo do cancelamento')),
                );
                return;
              }

              try {
                // Obtém UID do admin logado
                final adminUid = FirebaseAuth.instance.currentUser!.uid;
                // Chama serviço para cancelar agendamento
                await AgendamentoService.cancelarAgendamentoAdmin(
                  a.id, 
                  adminUid, 
                  motivoController.text.trim()
                );
                
                // Fecha diálogo e mostra confirmação
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Agendamento cancelado pelo admin'), backgroundColor: Colors.orange),
                  );
                }
              } catch (e) {
                // Trata erros no cancelamento
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Confirmar Cancelamento'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Verifica se usuário não é admin - mostra tela de acesso restrito
    if (_userLevel != 'admin') {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Acesso Restrito'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.admin_panel_settings, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text(
                'Acesso Restrito',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Acesso permitido apenas para administradores',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Tela principal do admin
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel Administrativo'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppColors.background,
      // StreamBuilder para atualizar lista em tempo real
      body: StreamBuilder<List<Agendamento>>(
        stream: _stream,
        builder: (context, snap) {
          // Mostra loading enquanto carrega dados
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Trata erros no stream
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: AppColors.error, size: 64),
                  const SizedBox(height: 16),
                  Text('Erro: ${snap.error}'),
                ],
              ),
            );
          }

          // Processa dados recebidos
          final items = snap.data ?? [];
          // Separa agendamentos ativos e cancelados
          final agendamentosAtivos = items.where((a) => a.isAtivo).toList();
          final agendamentosCancelados = items.where((a) => !a.isAtivo).toList();

          return Column(
            children: [
              // Cabeçalho com estatísticas
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Ativos',
                      agendamentosAtivos.length.toString(),
                      Icons.event_available,
                    ),
                    _buildStatItem(
                      'Cancelados',
                      agendamentosCancelados.length.toString(),
                      Icons.event_busy,
                    ),
                    _buildStatItem(
                      'Total',
                      items.length.toString(),
                      Icons.calendar_today,
                    ),
                  ],
                ),
              ),

              // Abas para agendamentos ativos e cancelados
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      // Container das abas
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TabBar(
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.grey[700],
                          indicator: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          tabs: const [
                            Tab(
                              icon: Icon(Icons.event_available, size: 20),
                              text: 'Ativos',
                            ),
                            Tab(
                              icon: Icon(Icons.event_busy, size: 20),
                              text: 'Cancelados',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Conteúdo das abas
                      Expanded(
                        child: TabBarView(
                          children: [
                            // ABA ATIVOS - mostra lista de agendamentos ativos
                            _buildAgendamentosList(agendamentosAtivos, true),
                            // ABA CANCELADOS - mostra lista de agendamentos cancelados
                            _buildAgendamentosList(agendamentosCancelados, false),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Widget para construir item de estatística no cabeçalho
  Widget _buildStatItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // Widget para construir lista de agendamentos
  Widget _buildAgendamentosList(List<Agendamento> agendamentos, bool isAtivo) {
    // Mensagem quando não há agendamentos
    if (agendamentos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isAtivo ? Icons.event_available : Icons.event_busy,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isAtivo ? 'Nenhum agendamento ativo' : 'Nenhum agendamento cancelado',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    // Lista de agendamentos
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: agendamentos.length,
      itemBuilder: (context, index) {
        final a = agendamentos[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Card(
            elevation: 2,
            color: isAtivo ? Colors.white : Colors.grey[100], // Cor diferente para cancelados
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isAtivo ? AppColors.primary : Colors.grey, // Cor do ícone baseada no status
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  isAtivo ? Icons.event_available : Icons.event_busy,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              title: Text(
                a.titulo,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration: isAtivo ? null : TextDecoration.lineThrough, // Risca texto se cancelado
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('🏢 ${a.sala}'), // Ícone e nome da sala
                  Text('👤 ${a.usuarioEmail}'), // Ícone e email do usuário
                  Text('📅 ${_formatDate(a.inicio)}'), // Ícone e data
                  Text('🕒 ${_formatTime(a.inicio)} → ${_formatTime(a.fim)}'), // Ícone e horário
                  if (a.descricao.isNotEmpty) Text('📝 ${a.descricao}'), // Descrição se existir
                  if (!isAtivo) ...[ // Informações adicionais para cancelados
                    const SizedBox(height: 4),
                    Text(
                      'Status: ${a.status}',
                      style: TextStyle(color: AppColors.error, fontSize: 12),
                    ),
                    if (a.canceladoMotivo != null) 
                      Text('Motivo: ${a.canceladoMotivo}'), // Motivo do cancelamento
                  ],
                ],
              ),
              // Botão de cancelamento apenas para agendamentos ativos
              trailing: isAtivo
                  ? IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(Icons.close, color: AppColors.error, size: 20),
                      ),
                      onPressed: () => _cancelarAgendamentoAdmin(a),
                      tooltip: 'Cancelar agendamento',
                    )
                  : null,
            ),
          ),
        );
      },
    );
  }

  // Formata data para DD/MM/AAAA
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // Formata hora para HH:MM
  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}