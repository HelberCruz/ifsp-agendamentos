import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> init() async {}

  static Stream<User?> authStateChanges() => _auth.authStateChanges();

  static Future<User?> registerWithEmail({required String email, required String password}) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    
    // CRIA O DOCUMENTO DO USUÁRIO NO FIRESTORE
    if (cred.user != null) {
      await _firestore.collection('users').doc(cred.user!.uid).set({
        'email': email,
        'nivel': 'user', // nível padrão
        'criadoEm': FieldValue.serverTimestamp(),
      });
    }
    
    return cred.user;
  }

  static Future<User?> loginWithEmail({required String email, required String password}) async {
    final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    return cred.user;
  }

  static Future<void> signOut() => _auth.signOut();

  static User? currentUser() => _auth.currentUser;

  // NOVO: OBTER NÍVEL DO USUÁRIO
  static Future<String> getUserLevel(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data()?['nivel'] ?? 'user';
  }

  // NOVO: STREAM DO PERFIL DO USUÁRIO
  static Stream<Map<String, dynamic>?> userProfileStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snap) {
      if (snap.exists) {
        return snap.data();
      }
      return null;
    });
  }
}