import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/agendamento.dart';

// Serviço responsável por todas as operações de CRUD e streams de agendamentos no Firebase
class AgendamentoService {
  // Referência para a coleção 'agendamentos' no Firestore
  static final _col = FirebaseFirestore.instance.collection('agendamentos');

  // STREAM PARA USUÁRIO NORMAL (SÓ OS DELE)
  // Retorna um stream em tempo real apenas dos agendamentos do usuário específico
  static Stream<List<Agendamento>> streamUserAgendamentos(String userUid) {
    return _col
        .where('usuarioUid', isEqualTo: userUid) // Filtra pelo UID do usuário
        .orderBy('inicio') // Ordena por data/hora de início
        .snapshots() // Obtém snapshots em tempo real
        .map((snap) =>
            // Converte cada documento para objeto Agendamento
            snap.docs.map((d) => Agendamento.fromMap(d.data(), d.id)).toList());
  }

  // STREAM PARA ADMIN (TODOS OS AGENDAMENTOS)
  // Retorna um stream em tempo real de TODOS os agendamentos do sistema
  static Stream<List<Agendamento>> streamAllAgendamentos() {
    return _col
        .orderBy('inicio') // Ordena por data/hora de início
        .snapshots() // Obtém snapshots em tempo real
        .map((snap) =>
            // Converte cada documento para objeto Agendamento
            snap.docs.map((d) => Agendamento.fromMap(d.data(), d.id)).toList());
  }

  // ADICIONA NOVO AGENDAMENTO COM VERIFICAÇÃO DE CONFLITOS
  static Future<void> add(Agendamento a) async {
    try {
      print('🔄 Iniciando salvamento do agendamento...');

      // Converte DateTime para Timestamp do Firestore
      final inicioTimestamp = Timestamp.fromDate(a.inicio);
      final fimTimestamp = Timestamp.fromDate(a.fim);

      // VERIFICA CONFLITOS - VERSÃO SIMPLIFICADA (SEM CAMPO FIM NA QUERY)
      // Estratégia: busca todos os agendamentos ativos da mesma sala no mesmo dia
      // e faz a verificação de conflito manualmente na aplicação
      
      // Define o início do dia (00:00:00)
      final inicioDia = DateTime(a.inicio.year, a.inicio.month, a.inicio.day);
      // Define o final do dia (23:59:59)
      final fimDia = DateTime(a.inicio.year, a.inicio.month, a.inicio.day, 23, 59);
      
      // Consulta agendamentos que podem ter conflito:
      // - Mesma sala
      // - Status ativo
      // - No mesmo dia
      final q = await _col
          .where('sala', isEqualTo: a.sala)
          .where('status', isEqualTo: 'ativo')
          .where('inicio', isGreaterThanOrEqualTo: Timestamp.fromDate(inicioDia))
          .where('inicio', isLessThanOrEqualTo: Timestamp.fromDate(fimDia))
          .get();

      // VERIFICA CONFLITOS MANUALMENTE NA APLICAÇÃO
      // Lógica: dois intervalos [inicio1, fim1] e [inicio2, fim2] se sobrepõem se:
      // inicio1 < fim2 E fim1 > inicio2
      bool hasConflict = q.docs.any((doc) {
        final existing = Agendamento.fromMap(doc.data(), doc.id);
        return a.inicio.isBefore(existing.fim) && a.fim.isAfter(existing.inicio);
      });

      if (hasConflict) {
        throw Exception(
            'Conflito de horário: Já existe um agendamento para esta sala no horário selecionado.');
      }

      // SALVA NO FIRESTORE - todos os campos necessários
      await _col.add({
        'sala': a.sala,
        'titulo': a.titulo,
        'descricao': a.descricao,
        'usuario': a.usuario,
        'usuarioEmail': a.usuarioEmail,
        'usuarioUid': a.usuarioUid,
        'inicio': inicioTimestamp,
        'fim': fimTimestamp, // ✅ CAMPO FIM AINDA É SALVO (importante para verificações)
        'status': 'ativo', // Status inicial do agendamento
        'criadoPor': FirebaseAuth.instance.currentUser?.uid ?? 'unknown', // Quem criou
        'criadoEm': FieldValue.serverTimestamp(), // Timestamp do servidor
      });

      print('✅ Agendamento salvo com sucesso!');
    } catch (e) {
      print('❌ Erro ao salvar agendamento: $e');
      rethrow; // Repassa a exceção para o chamador tratar
    }
  }

  // CANCELAR AGENDAMENTO (USUÁRIO NORMAL)
  // Permite que um usuário cancele seus próprios agendamentos
  static Future<void> cancelarAgendamento(String id, String usuarioUid) async {
    final doc = _col.doc(id); // Referência ao documento específico
    final snap = await doc.get(); // Obtém o documento atual

    // Verifica se o agendamento existe
    if (!snap.exists) {
      throw Exception('Agendamento não encontrado');
    }

    // Converte os dados do Firestore para objeto Agendamento
    final agendamento = Agendamento.fromMap(snap.data()!, snap.id);

    // VERIFICAÇÃO DE AUTORIZAÇÃO - segurança importante
    // Usuário só pode cancelar seus próprios agendamentos
    if (agendamento.usuarioUid != usuarioUid) {
      throw Exception('Você só pode cancelar seus próprios agendamentos');
    }

    // Atualiza o documento com informações de cancelamento
    await doc.update({
      'status': 'cancelado', // Status específico para cancelamento pelo usuário
      'canceladoPor': usuarioUid, // Quem cancelou
      'canceladoEm': FieldValue.serverTimestamp(), // Quando foi cancelado
    });
  }

  // CANCELAR AGENDAMENTO PELO ADMIN
  // Permite que administradores cancelem qualquer agendamento com motivo
  static Future<void> cancelarAgendamentoAdmin(
      String id, String adminUid, String motivo) async {
    final doc = _col.doc(id); // Referência ao documento específico
    final snap = await doc.get(); // Obtém o documento atual

    // Verifica se o agendamento existe
    if (!snap.exists) {
      throw Exception('Agendamento não encontrado');
    }

    // Admin pode cancelar qualquer agendamento - sem verificação de propriedade
    await doc.update({
      'status': 'cancelado_pelo_admin', // Status específico para cancelamento admin
      'canceladoPor': adminUid, // UID do admin que cancelou
      'canceladoMotivo': motivo, // Motivo obrigatório do cancelamento
      'canceladoEm': FieldValue.serverTimestamp(), // Quando foi cancelado
    });
  }

  // REMOVER AGENDAMENTO COMPLETAMENTE DO SISTEMA
  // ⚠️ Uso cuidadoso - remove permanentemente o documento
  static Future<void> remove(String id) => _col.doc(id).delete();
}