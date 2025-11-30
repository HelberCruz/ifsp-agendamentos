import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/agendamento_service.dart';
import '../models/agendamento.dart';
import '../app_colors.dart'; // ✅ Import correto

// Tela principal do aplicativo - lista de agendamentos
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _userLevel = 'user'; // Nível de acesso do usuário (user/admin)
  String _userUid = ''; // UID do usuário atual

  @override
  void initState() {
    super.initState();
    // Obtém UID do usuário logado
    final user = FirebaseAuth.instance.currentUser;
    _userUid = user?.uid ?? '';
    _loadUserLevel(); // Carrega nível de acesso
  }

  // Carrega o nível de acesso do usuário (admin ou user)
  void _loadUserLevel() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final level = await AuthService.getUserLevel(user.uid);
      setState(() => _userLevel = level);
    }
  }

  // Método para logout do usuário
  void _logout() async {
    await AuthService.signOut();
    Navigator.pushReplacementNamed(context, '/'); // Volta para tela de login
  }

  // Diálogo para cancelar agendamento (usuário comum)
  void _cancelarAgendamento(Agendamento a) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Agendamento'),
        content: Text('Deseja cancelar o agendamento "${a.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Não'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Chama serviço para cancelar agendamento
                await AgendamentoService.cancelarAgendamento(a.id, _userUid);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Agendamento cancelado'),
                        backgroundColor: Colors.orange),
                  );
                }
              } catch (e) {
                // Trata erros no cancelamento
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Erro: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sim, Cancelar'),
          ),
        ],
      ),
    );
  }

  // Diálogo para cancelar agendamento como administrador (com motivo)
  void _cancelarAgendamentoAdmin(Agendamento a) async {
    final motivoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Agendamento (Admin)'),
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Valida se motivo foi preenchido
              if (motivoController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Informe o motivo do cancelamento')),
                );
                return;
              }

              try {
                final adminUid = FirebaseAuth.instance.currentUser!.uid;
                // Cancela agendamento como admin
                await AgendamentoService.cancelarAgendamentoAdmin(
                    a.id, adminUid, motivoController.text.trim());

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Agendamento cancelado pelo admin'),
                        backgroundColor: Colors.orange),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Erro: $e'), backgroundColor: Colors.red),
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

  // ✅ ÚNICA versão do método _buildAgendamentoCard
  // Widget para construir card de agendamento
  Widget _buildAgendamentoCard(Agendamento a) {
    final isAdmin = _userLevel == 'admin'; // Verifica se usuário é admin
    final isCanceled = !a.isAtivo; // Verifica se agendamento está cancelado

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Card(
        elevation: 2,
        color: isCanceled ? Colors.grey[100] : Colors.white, // Cor diferente para cancelados
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isCanceled ? Colors.grey : AppColors.primary, // Ícone cinza se cancelado
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(
              isCanceled ? Icons.event_busy : Icons.event_available,
              color: Colors.white,
              size: 24,
            ),
          ),
          title: Text(
            a.titulo,
            style: TextStyle(
              decoration: isCanceled ? TextDecoration.lineThrough : null, // Risca texto se cancelado
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text('🏢 ${a.sala}'), // Nome da sala
              Text('📅 ${_formatDate(a.inicio)}'), // Data formatada
              Text('🕒 ${_formatTime(a.inicio)} - ${_formatTime(a.fim)}'), // Horário
              if (a.descricao.isNotEmpty) 
                Text('📝 ${a.descricao}'), // Descrição se existir
              if (!a.isAtivo) ...[ // Informações adicionais para cancelados
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${a.status == 'cancelado' ? 'Cancelado pelo usuário' : 'Cancelado pelo admin'}',
                    style: TextStyle(color: AppColors.error, fontSize: 12),
                  ),
                ),
                if (a.canceladoMotivo != null)
                  Text('❌ ${a.canceladoMotivo}'), // Motivo do cancelamento
              ],
              if (isAdmin) // Mostra email do usuário apenas para admin
                Text(
                  '👤 ${a.usuarioEmail}',
                  style: TextStyle(fontSize: 12, color: AppColors.primary),
                ),
            ],
          ),
          // Botão de cancelamento apenas para agendamentos ativos
          trailing: a.isAtivo
              ? IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Icons.close, color: AppColors.error, size: 20),
                  ),
                  onPressed: () => isAdmin
                      ? _cancelarAgendamentoAdmin(a) // Admin vê diálogo com motivo
                      : _cancelarAgendamento(a), // Usuário comum vê confirmação simples
                  tooltip: isAdmin ? 'Cancelar como admin' : 'Cancelar agendamento',
                )
              : null,
        ),
      ),
    );
  }

  // ✅ Método build CORRETAMENTE formatado
  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser();

    // DEFINE O STREAM CORRETO BASEADO NO NÍVEL DO USUÁRIO
    // Admin: vê todos os agendamentos | User: vê apenas seus agendamentos
    final stream = _userLevel == 'admin'
        ? AgendamentoService.streamAllAgendamentos()
        : AgendamentoService.streamUserAgendamentos(_userUid);

    return Scaffold(
      appBar: AppBar(
        title: const Text('IFSP Agendamentos'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          // Badge "ADMIN" se usuário for administrador
          if (_userLevel == 'admin')
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'ADMIN',
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          // Botão de logout
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
          )
        ],
      ),
      // Botão flutuante para criar novo agendamento
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/create'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      // Corpo principal com lista de agendamentos
      body: StreamBuilder<List<Agendamento>>(
        stream: stream, // Stream que atualiza automaticamente
        builder: (context, snap) {
          // Mostra loading enquanto carrega dados
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Trata erros no stream
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, color: AppColors.error, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'Erro: ${snap.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.error),
                    ),
                  ],
                ),
              ),
            );
          }

          // Processa dados recebidos
          final items = snap.data ?? [];
          // Separa agendamentos ativos e cancelados
          final agendamentosAtivos = items.where((a) => a.isAtivo).toList();
          final agendamentosCancelados = items.where((a) => !a.isAtivo).toList();

          // Usa CustomScrollView para layout mais flexível
          return CustomScrollView(
            slivers: [
              // Cabeçalho com saudação e estatísticas
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryLight, AppColors.primary.withOpacity(0.1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Olá, ${user?.email?.split('@').first ?? 'usuário'}!', // Extrai nome do email
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _userLevel == 'admin'
                            ? '${agendamentosAtivos.length} agendamentos ativos no sistema' // Mensagem para admin
                            : 'Você tem ${agendamentosAtivos.length} agendamentos ativos', // Mensagem para user
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Seção de Agendamentos Ativos
              if (agendamentosAtivos.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Icon(Icons.event_available, color: AppColors.success, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Agendamentos Ativos (${agendamentosAtivos.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Lista de agendamentos ativos
              if (agendamentosAtivos.isNotEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildAgendamentoCard(agendamentosAtivos[index]),
                    childCount: agendamentosAtivos.length,
                  ),
                ),

              // Seção de Agendamentos Cancelados
              if (agendamentosCancelados.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Icon(Icons.event_busy, color: Colors.grey, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Agendamentos Cancelados (${agendamentosCancelados.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Lista de agendamentos cancelados
              if (agendamentosCancelados.isNotEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildAgendamentoCard(agendamentosCancelados[index]),
                    childCount: agendamentosCancelados.length,
                  ),
                ),

              // Mensagem quando não há agendamentos
              if (items.isEmpty)
                SliverFillRemaining(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhum agendamento',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          'Toque no botão + para criar seu primeiro agendamento',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // ✅ FUNÇÕES AUXILIARES PARA FORMATAR DATA E HORA
  
  // Formata data para DD/MM/AAAA
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // Formata hora para HH:MM
  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}