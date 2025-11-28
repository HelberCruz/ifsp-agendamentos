import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/agendamento_service.dart';
import '../services/auth_service.dart';
import '../models/agendamento.dart';
import '../app_colors.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});
  @override State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  late final Stream<List<Agendamento>> _stream;
  String _userLevel = 'user';

  @override
  void initState() {
    super.initState();
    _stream = AgendamentoService.streamAllAgendamentos();
    _loadUserLevel();
  }

  void _loadUserLevel() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final level = await AuthService.getUserLevel(user.uid);
      setState(() => _userLevel = level);
    }
  }

  void _cancelarAgendamentoAdmin(Agendamento a) async {
    final motivoController = TextEditingController();
    
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
                  const SnackBar(content: Text('Informe o motivo do cancelamento')),
                );
                return;
              }

              try {
                final adminUid = FirebaseAuth.instance.currentUser!.uid;
                await AgendamentoService.cancelarAgendamentoAdmin(
                  a.id, 
                  adminUid, 
                  motivoController.text.trim()
                );
                
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Agendamento cancelado pelo admin'), backgroundColor: Colors.orange),
                  );
                }
              } catch (e) {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel Administrativo'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppColors.background,
      body: StreamBuilder<List<Agendamento>>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

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

          final items = snap.data ?? [];
          final agendamentosAtivos = items.where((a) => a.isAtivo).toList();
          final agendamentosCancelados = items.where((a) => !a.isAtivo).toList();

          return Column(
            children: [
              // Header Stats
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

              // Tabs
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
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
                      Expanded(
                        child: TabBarView(
                          children: [
                            // ABA ATIVOS
                            _buildAgendamentosList(agendamentosAtivos, true),
                            // ABA CANCELADOS
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

  Widget _buildAgendamentosList(List<Agendamento> agendamentos, bool isAtivo) {
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

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: agendamentos.length,
      itemBuilder: (context, index) {
        final a = agendamentos[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Card(
            elevation: 2,
            color: isAtivo ? Colors.white : Colors.grey[100],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isAtivo ? AppColors.primary : Colors.grey,
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
                  decoration: isAtivo ? null : TextDecoration.lineThrough,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('🏢 ${a.sala}'),
                  Text('👤 ${a.usuarioEmail}'),
                  Text('📅 ${_formatDate(a.inicio)}'),
                  Text('🕒 ${_formatTime(a.inicio)} → ${_formatTime(a.fim)}'),
                  if (a.descricao.isNotEmpty) Text('📝 ${a.descricao}'),
                  if (!isAtivo) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Status: ${a.status}',
                      style: TextStyle(color: AppColors.error, fontSize: 12),
                    ),
                    if (a.canceladoMotivo != null) 
                      Text('Motivo: ${a.canceladoMotivo}'),
                  ],
                ],
              ),
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}