import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/agendamento.dart';

class AgendamentoService {
  static final _col = FirebaseFirestore.instance.collection('agendamentos');

  // STREAM PARA USUÁRIO NORMAL (SÓ OS DELE)
  static Stream<List<Agendamento>> streamUserAgendamentos(String userUid) {
    return _col
        .where('usuarioUid', isEqualTo: userUid)
        .orderBy('inicio')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Agendamento.fromMap(d.data(), d.id)).toList());
  }

  // STREAM PARA ADMIN (TODOS OS AGENDAMENTOS)
  static Stream<List<Agendamento>> streamAllAgendamentos() {
    return _col
        .orderBy('inicio')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Agendamento.fromMap(d.data(), d.id)).toList());
  }

  static Future<void> add(Agendamento a) async {
    try {
      print('🔄 Iniciando salvamento do agendamento...');

      final inicioTimestamp = Timestamp.fromDate(a.inicio);
      final fimTimestamp = Timestamp.fromDate(a.fim);

      // VERIFICA CONFLITOS - VERSÃO SIMPLIFICADA (SEM CAMPO FIM NA QUERY)
      final inicioDia = DateTime(a.inicio.year, a.inicio.month, a.inicio.day);
      final fimDia = DateTime(a.inicio.year, a.inicio.month, a.inicio.day, 23, 59);
      
      final q = await _col
          .where('sala', isEqualTo: a.sala)
          .where('status', isEqualTo: 'ativo')
          .where('inicio', isGreaterThanOrEqualTo: Timestamp.fromDate(inicioDia))
          .where('inicio', isLessThanOrEqualTo: Timestamp.fromDate(fimDia))
          .get();

      // VERIFICA CONFLITOS MANUALMENTE
      bool hasConflict = q.docs.any((doc) {
        final existing = Agendamento.fromMap(doc.data(), doc.id);
        return a.inicio.isBefore(existing.fim) && a.fim.isAfter(existing.inicio);
      });

      if (hasConflict) {
        throw Exception(
            'Conflito de horário: Já existe um agendamento para esta sala no horário selecionado.');
      }

      // SALVA NO FIRESTORE
      await _col.add({
        'sala': a.sala,
        'titulo': a.titulo,
        'descricao': a.descricao,
        'usuario': a.usuario,
        'usuarioEmail': a.usuarioEmail,
        'usuarioUid': a.usuarioUid,
        'inicio': inicioTimestamp,
        'fim': fimTimestamp, // ✅ CAMPO FIM AINDA É SALVO
        'status': 'ativo',
        'criadoPor': FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
        'criadoEm': FieldValue.serverTimestamp(),
      });

      print('✅ Agendamento salvo com sucesso!');
    } catch (e) {
      print('❌ Erro ao salvar agendamento: $e');
      rethrow;
    }
  }

  // CANCELAR AGENDAMENTO (USUÁRIO NORMAL)
  static Future<void> cancelarAgendamento(String id, String usuarioUid) async {
    final doc = _col.doc(id);
    final snap = await doc.get();

    if (!snap.exists) {
      throw Exception('Agendamento não encontrado');
    }

    final agendamento = Agendamento.fromMap(snap.data()!, snap.id);

    if (agendamento.usuarioUid != usuarioUid) {
      throw Exception('Você só pode cancelar seus próprios agendamentos');
    }

    await doc.update({
      'status': 'cancelado',
      'canceladoPor': usuarioUid,
      'canceladoEm': FieldValue.serverTimestamp(),
    });
  }

  // CANCELAR AGENDAMENTO PELO ADMIN
  static Future<void> cancelarAgendamentoAdmin(
      String id, String adminUid, String motivo) async {
    final doc = _col.doc(id);
    final snap = await doc.get();

    if (!snap.exists) {
      throw Exception('Agendamento não encontrado');
    }

    await doc.update({
      'status': 'cancelado_pelo_admin',
      'canceladoPor': adminUid,
      'canceladoMotivo': motivo,
      'canceladoEm': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> remove(String id) => _col.doc(id).delete();
}