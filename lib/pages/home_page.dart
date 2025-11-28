import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/agendamento_service.dart';
import '../models/agendamento.dart';
import '../app_colors.dart'; // ✅ Import correto

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _userLevel = 'user';
  String _userUid = '';

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _userUid = user?.uid ?? '';
    _loadUserLevel();
  }

  void _loadUserLevel() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final level = await AuthService.getUserLevel(user.uid);
      setState(() => _userLevel = level);
    }
  }

  void _logout() async {
    await AuthService.signOut();
    Navigator.pushReplacementNamed(context, '/');
  }

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
              if (motivoController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Informe o motivo do cancelamento')),
                );
                return;
              }

              try {
                final adminUid = FirebaseAuth.instance.currentUser!.uid;
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
  Widget _buildAgendamentoCard(Agendamento a) {
    final isAdmin = _userLevel == 'admin';
    final isCanceled = !a.isAtivo;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Card(
        elevation: 2,
        color: isCanceled ? Colors.grey[100] : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isCanceled ? Colors.grey : AppColors.primary,
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
              decoration: isCanceled ? TextDecoration.lineThrough : null,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text('🏢 ${a.sala}'),
              Text('📅 ${_formatDate(a.inicio)}'),
              Text('🕒 ${_formatTime(a.inicio)} - ${_formatTime(a.fim)}'),
              if (a.descricao.isNotEmpty) 
                Text('📝 ${a.descricao}'),
              if (!a.isAtivo) ...[
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
                  Text('❌ ${a.canceladoMotivo}'),
              ],
              if (isAdmin)
                Text(
                  '👤 ${a.usuarioEmail}',
                  style: TextStyle(fontSize: 12, color: AppColors.primary),
                ),
            ],
          ),
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
                      ? _cancelarAgendamentoAdmin(a)
                      : _cancelarAgendamento(a),
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
    final stream = _userLevel == 'admin'
        ? AgendamentoService.streamAllAgendamentos()
        : AgendamentoService.streamUserAgendamentos(_userUid);

    return Scaffold(
      appBar: AppBar(
        title: const Text('IFSP Agendamentos'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
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
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/create'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Agendamento>>(
        stream: stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

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

          final items = snap.data ?? [];
          final agendamentosAtivos = items.where((a) => a.isAtivo).toList();
          final agendamentosCancelados = items.where((a) => !a.isAtivo).toList();

          return CustomScrollView(
            slivers: [
              // Cabeçalho
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
                        'Olá, ${user?.email?.split('@').first ?? 'usuário'}!',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _userLevel == 'admin'
                            ? '${agendamentosAtivos.length} agendamentos ativos no sistema'
                            : 'Você tem ${agendamentosAtivos.length} agendamentos ativos',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Agendamentos Ativos
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
              
              if (agendamentosAtivos.isNotEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildAgendamentoCard(agendamentosAtivos[index]),
                    childCount: agendamentosAtivos.length,
                  ),
                ),

              // Agendamentos Cancelados
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
              
              if (agendamentosCancelados.isNotEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildAgendamentoCard(agendamentosCancelados[index]),
                    childCount: agendamentosCancelados.length,
                  ),
                ),

              // Lista vazia
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
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}