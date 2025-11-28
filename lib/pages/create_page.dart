import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/agendamento_service.dart';
import '../models/agendamento.dart';
import '../app_colors.dart';

const SALAS = ['Estúdio', 'LAB Maker', 'Quadra'];

class CreatePage extends StatefulWidget {
  const CreatePage({super.key});
  @override
  State<CreatePage> createState() => _CreatePageState();
}

class _CreatePageState extends State<CreatePage> {
  String _sala = SALAS[0];
  DateTime? _date;
  TimeOfDay? _start;
  TimeOfDay? _end;
  final _title = TextEditingController();
  final _desc = TextEditingController();
  bool _loading = false;

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
        _start = null;
        _end = null;
      });
    }
  }

  Future<void> _pickStart() async {
    final t = await showTimePicker(
        context: context, initialTime: const TimeOfDay(hour: 8, minute: 0));
    if (t != null) {
      setState(() => _start = t);
      if (_end != null && _isStartAfterEnd(t, _end!)) {
        setState(() => _end = null);
      }
    }
  }

  Future<void> _pickEnd() async {
    final t = await showTimePicker(
        context: context, 
        initialTime: _start ?? const TimeOfDay(hour: 9, minute: 0));
    if (t != null && _start != null && !_isStartAfterEnd(_start!, t)) {
      setState(() => _end = t);
    } else if (_start == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione o horário de início primeiro')),
      );
    }
  }

  bool _isStartAfterEnd(TimeOfDay start, TimeOfDay end) {
    return start.hour > end.hour || (start.hour == end.hour && start.minute >= end.minute);
  }

  DateTime? _combine(DateTime d, TimeOfDay t) =>
      DateTime(d.year, d.month, d.day, t.hour, t.minute);

  void _save() async {
    if (_date == null ||
        _start == null ||
        _end == null ||
        _title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preencha todos os campos')));
      return;
    }

    final inicio = _combine(_date!, _start!)!;
    final fim = _combine(_date!, _end!)!;

    if (!fim.isAfter(inicio)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Horário final deve ser depois do inicial')));
      return;
    }

    setState(() => _loading = true);

    final user = FirebaseAuth.instance.currentUser;
    final a = Agendamento(
        id: '',
        sala: _sala,
        titulo: _title.text.trim(),
        descricao: _desc.text.trim(),
        usuario: user?.displayName ?? user?.email ?? 'Usuário',
        usuarioEmail: user?.email ?? 'anon',
        usuarioUid: user?.uid ?? 'unknown',
        inicio: inicio,
        fim: fim);

    try {
      await AgendamentoService.add(a);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Agendamento criado com sucesso!'),
            backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro: ${e.toString()}'),
            backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              // Card Principal
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
                    // Sala
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
                        isExpanded: true,
                        underline: const SizedBox(),
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

                    // Título
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

                    // Descrição
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
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Descreva o propósito do agendamento...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Data e Horário
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
                        Expanded(
                          child: _buildTimeButton(
                            icon: Icons.calendar_today,
                            text: dateStr,
                            onPressed: _pickDate,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTimeButton(
                            icon: Icons.access_time,
                            text: startStr,
                            onPressed: _pickStart,
                          ),
                        ),
                        const SizedBox(width: 12),
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

              // Botão Salvar
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
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
          side: BorderSide(color: Colors.grey[300]!),
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