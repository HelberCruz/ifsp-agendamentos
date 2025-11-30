import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Serviço centralizado para gerenciar autenticação e perfil de usuários
// Integra Firebase Authentication com Firestore para dados extendidos
class AuthService {
  // Instâncias singleton dos serviços do Firebase
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Método de inicialização - pode ser usado para configurações futuras
  static Future<void> init() async {
    // Reservado para inicializações assíncronas se necessárias no futuro
    // Ex: Verificar configurações, carregar settings, etc.
  }

  // STREAM DO ESTADO DE AUTENTICAÇÃO
  // Fornece um stream que emite eventos quando o estado de autenticação muda
  // Útil para redirecionamento automático baseado no login
  static Stream<User?> authStateChanges() => _auth.authStateChanges();

  // REGISTRO DE NOVO USUÁRIO COM EMAIL E SENHA
  static Future<User?> registerWithEmail({
    required String email, 
    required String password
  }) async {
    // Cria usuário no Firebase Authentication
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email, 
      password: password
    );
    
    // CRIA O DOCUMENTO DO USUÁRIO NO FIRESTORE (dados extendidos)
    if (cred.user != null) {
      await _firestore.collection('users').doc(cred.user!.uid).set({
        'email': email,                    // Email do usuário
        'nivel': 'user',                   // nível padrão - sistema de permissões
        'criadoEm': FieldValue.serverTimestamp(), // Timestamp do servidor
      });
      // Estrutura do documento user no Firestore:
      // {
      //   email: "usuario@exemplo.com",
      //   nivel: "user", // ou "admin" para administradores
      //   criadoEm: January 1, 2024 at 12:00:00 PM UTC-3
      // }
    }
    
    return cred.user; // Retorna o objeto User criado
  }

  // LOGIN DE USUÁRIO EXISTENTE
  static Future<User?> loginWithEmail({
    required String email, 
    required String password
  }) async {
    // Autentica usuário com Firebase Authentication
    final cred = await _auth.signInWithEmailAndPassword(
      email: email, 
      password: password
    );
    return cred.user; // Retorna o objeto User autenticado
  }

  // LOGOUT DO USUÁRIO
  static Future<void> signOut() => _auth.signOut();

  // OBTER USUÁRIO ATUALMENTE AUTENTICADO
  static User? currentUser() => _auth.currentUser;

  // OBTER NÍVEL DE PERMISSÃO DO USUÁRIO
  // Busca no Firestore o campo 'nivel' que define as permissões
  static Future<String> getUserLevel(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    // Retorna 'user' como padrão se o campo não existir
    return doc.data()?['nivel'] ?? 'user';
    
    // Possíveis valores:
    // - 'user': Usuário normal (permissões básicas)
    // - 'admin': Administrador (acesso completo)
  }

  // STREAM DO PERFIL DO USUÁRIO EM TEMPO REAL
  // Útil para atualizar a UI automaticamente quando o perfil muda
  static Stream<Map<String, dynamic>?> userProfileStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snap) {
      if (snap.exists) {
        return snap.data(); // Retorna todos os dados do perfil
      }
      return null; // Retorna null se o documento não existir
    });
  }
}