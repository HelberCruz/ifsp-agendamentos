import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/agendamento_service.dart';
import '../models/agendamento.dart';
import '../app_colors.dart';

// Lista de salas disponíveis para agendamento
const SALAS = ['Estúdio', 'LAB Maker', 'Quadra'];

// Tela para criar novo agendamento
class CreatePage extends StatefulWidget {
  const CreatePage({super.key});
  @override
  State<CreatePage> createState() => _CreatePageState();
}

class _CreatePageState extends State<CreatePage> {
  // Variáveis de estado do formulário
  String _sala = SALAS[0]; // Sala selecionada (padrão: primeira da lista)
  DateTime? _date; // Data selecionada
  TimeOfDay? _start; // Horário de início
  TimeOfDay? _end; // Horário de fim
  final _title = TextEditingController(); // Controlador para campo título
  final _desc = TextEditingController(); // Controlador para campo descrição
  bool _loading = false; // Estado de carregamento durante o salvamento

  // Método para selecionar data
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
        context: context,
        initialDate: now,
        firstDate: now,
        lastDate: now.add(const Duration(days: 365)));
    if (d != null) {
      setState(() {
        _date = d;
        _start = null; // Reseta horários quando muda a data
        _end = null;
      });
    }
  }

  // Método para selecionar horário de início
  Future<void> _pickStart() async {
    final t = await showTimePicker(
        context: context, initialTime: const TimeOfDay(hour: 8, minute: 0));
    if (t != null) {
      setState(() => _start = t);
      // Se horário final for anterior ao novo início, reseta horário final
      if (_end != null && _isStartAfterEnd(t, _end!)) {
        setState(() => _end = null);
      }
    }
  }

  // Método para selecionar horário de fim
  Future<void> _pickEnd() async {
    final t = await showTimePicker(
        context: context, 
        initialTime: _start ?? const TimeOfDay(hour: 9, minute: 0));
    // Só permite selecionar se início já foi definido e horário é válido
    if (t != null && _start != null && !_isStartAfterEnd(_start!, t)) {
      setState(() => _end = t);
    } else if (_start == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione o horário de início primeiro')),
      );
    }
  }

  // Verifica se horário de início é depois do horário de fim
  bool _isStartAfterEnd(TimeOfDay start, TimeOfDay end) {
    return start.hour > end.hour || (start.hour == end.hour && start.minute >= end.minute);
  }

  // Combina DateTime (data) com TimeOfDay (horário) em um único DateTime
  DateTime? _combine(DateTime d, TimeOfDay t) =>
      DateTime(d.year, d.month, d.day, t.hour, t.minute);

  // Método para salvar o agendamento
  void _save() async {
    // Validação dos campos obrigatórios
    if (_date == null ||
        _start == null ||
        _end == null ||
        _title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preencha todos os campos')));
      return;
    }

    // Combina data com horários
    final inicio = _combine(_date!, _start!)!;
    final fim = _combine(_date!, _end!)!;

    // Valida se horário final é depois do inicial
    if (!fim.isAfter(inicio)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Horário final deve ser depois do inicial')));
      return;
    }

    setState(() => _loading = true);

    // Obtém dados do usuário logado
    final user = FirebaseAuth.instance.currentUser;
    
    // Cria objeto Agendamento
    final a = Agendamento(
        id: '', // ID vazio (será gerado pelo Firebase)
        sala: _sala,
        titulo: _title.text.trim(),
        descricao: _desc.text.trim(),
        usuario: user?.displayName ?? user?.email ?? 'Usuário', // Nome ou email
        usuarioEmail: user?.email ?? 'anon', // Email do usuário
        usuarioUid: user?.uid ?? 'unknown', // UID do usuário
        inicio: inicio,
        fim: fim);

    try {
      // Salva agendamento no Firebase
      await AgendamentoService.add(a);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Agendamento criado com sucesso!'),
            backgroundColor: Colors.green));
        Navigator.pop(context); // Volta para tela anterior
      }
    } catch (e) {
      // Trata erros no salvamento
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro: ${e.toString()}'),
            backgroundColor: Colors.red));
      }
    } finally {
      // Garante que loading seja desativado
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    // Limpa os controladores para evitar vazamento de memória
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Formata textos para exibição
    final dateStr = _date == null
        ? 'Selecionar data'
        : '${_date!.day}/${_date!.month}/${_date!.year}';
    final startStr = _start == null ? 'Início' : _start!.format(context);
    final endStr = _end == null ? 'Fim' : _end!.format(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo Agendamento'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Card Principal do formulário
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Seção de Seleção de Sala
                    Text(
                      'Sala',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: DropdownButton<String>(
                        value: _sala,
                        isExpanded: true, // Ocupa toda a largura
                        underline: const SizedBox(), // Remove linha padrão
                        items: SALAS
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _sala = v!),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Campo de Título
                    Text(
                      'Título do Agendamento',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: TextField(
                        controller: _title,
                        decoration: const InputDecoration(
                          hintText: 'Ex: Aula de Programação',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Campo de Descrição (Opcional)
                    Text(
                      'Descrição (Opcional)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: TextField(
                        controller: _desc,
                        maxLines: 3, // Campo maior para descrição
                        decoration: const InputDecoration(
                          hintText: 'Descreva o propósito do agendamento...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Seção de Data e Horário
                    Text(
                      'Data e Horário',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Botão para selecionar data
                        Expanded(
                          child: _buildTimeButton(
                            icon: Icons.calendar_today,
                            text: dateStr,
                            onPressed: _pickDate,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Botão para selecionar horário de início
                        Expanded(
                          child: _buildTimeButton(
                            icon: Icons.access_time,
                            text: startStr,
                            onPressed: _pickStart,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Botão para selecionar horário de fim
                        Expanded(
                          child: _buildTimeButton(
                            icon: Icons.access_time,
                            text: endStr,
                            onPressed: _pickEnd,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Botão de Salvar
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save, // Desabilita durante loading
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Salvar Agendamento',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget reutilizável para botões de data/horário
  Widget _buildTimeButton({
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[300]!), // Borda cinza
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}