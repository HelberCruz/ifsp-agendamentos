import 'package:cloud_firestore/cloud_firestore.dart';

class Agendamento {
  final String id;
  final String sala;
  final String titulo;
  final String descricao;
  final String usuario;
  final String usuarioEmail;
  final String usuarioUid; // NOVO: UID do usuário
  final DateTime inicio;
  final DateTime fim;
  final String status; // NOVO: 'ativo', 'cancelado', 'cancelado_pelo_admin'
  final String? canceladoPor; // NOVO: quem cancelou
  final String? canceladoMotivo; // NOVO: motivo do cancelamento

  Agendamento({
    required this.id,
    required this.sala,
    required this.titulo,
    required this.descricao,
    required this.usuario,
    required this.usuarioEmail,
    required this.usuarioUid,
    required this.inicio,
    required this.fim,
    this.status = 'ativo',
    this.canceladoPor,
    this.canceladoMotivo,
  });

  factory Agendamento.fromMap(Map<String, dynamic> m, String id) {
    DateTime parseDate(dynamic date) {
      if (date is Timestamp) {
        return date.toDate();
      } else if (date is String) {
        return DateTime.parse(date);
      } else {
        return DateTime.now();
      }
    }

    return Agendamento(
      id: id,
      sala: m['sala'] ?? '',
      titulo: m['titulo'] ?? '',
      descricao: m['descricao'] ?? '',
      usuario: m['usuario'] ?? '',
      usuarioEmail: m['usuarioEmail'] ?? '',
      usuarioUid: m['usuarioUid'] ?? '',
      inicio: parseDate(m['inicio']),
      fim: parseDate(m['fim']),
      status: m['status'] ?? 'ativo',
      canceladoPor: m['canceladoPor'],
      canceladoMotivo: m['canceladoMotivo'],
    );
  }

  Map<String, dynamic> toMap() => {
    'sala': sala,
    'titulo': titulo,
    'descricao': descricao,
    'usuario': usuario,
    'usuarioEmail': usuarioEmail,
    'usuarioUid': usuarioUid,
    'inicio': Timestamp.fromDate(inicio),
    'fim': Timestamp.fromDate(fim),
    'status': status,
    'canceladoPor': canceladoPor,
    'canceladoMotivo': canceladoMotivo,
    'criadoEm': FieldValue.serverTimestamp(),
  };

  // NOVO: VERIFICA SE ESTÁ ATIVO
  bool get isAtivo => status == 'ativo';
  
  // NOVO: VERIFICA SE FOI CANCELADO PELO ADMIN
  bool get isCanceladoPeloAdmin => status == 'cancelado_pelo_admin';
}