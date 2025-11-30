import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../app_colors.dart';

// Tela de login do aplicativo
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController(); // Controlador para campo de email
  final _pw = TextEditingController(); // Controlador para campo de senha
  bool _loading = false; // Estado de carregamento durante o login
  String? _error; // Mensagem de erro (null quando não há erro)
  bool _obscureText = true; // Controla se a senha está visível ou oculta

  // Método para tentar fazer login
  void _try() async {
    setState(() { 
      _loading = true; // Ativa loading
      _error = null; // Limpa erros anteriores
    });
    try {
      // Tenta fazer login com email e senha
      await AuthService.loginWithEmail(email: _email.text.trim(), password: _pw.text);
      // Se login for bem-sucedido, navega para home
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      // Se houver erro, mostra mensagem genérica por segurança
      setState(() => _error = 'E-mail ou senha incorretos');
    } finally {
      // Desativa loading independente do resultado
      if (mounted) setState(() => _loading = false);
    }
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 60), // Espaço no topo
              
              // Logo do aplicativo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.calendar_today, size: 40, color: Colors.white),
              ),
              
              const SizedBox(height: 24),
              // Título do aplicativo
              Text(
                'IFSP Agendamentos',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 8),
              // Subtítulo
              Text(
                'Faça login para continuar',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 40), // Espaço antes dos campos
              
              // Container dos campos de login
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Campo de email
                    TextField(
                      controller: _email,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        border: InputBorder.none, // Remove borda padrão
                        contentPadding: EdgeInsets.all(16),
                        prefixIcon: Icon(Icons.email), // Ícone do email
                      ),
                      keyboardType: TextInputType.emailAddress, // Teclado otimizado para email
                    ),
                    // Divisor entre os campos
                    Divider(height: 1, color: Colors.grey[300]),
                    // Campo de senha
                    TextField(
                      controller: _pw,
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                        prefixIcon: const Icon(Icons.lock), // Ícone do cadeado
                        suffixIcon: IconButton(
                          // Ícone que alterna entre mostrar/ocultar senha
                          icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscureText = !_obscureText),
                        ),
                      ),
                      obscureText: _obscureText, // Controla se texto está oculto
                    ),
                  ],
                ),
              ),
              
              // Exibe mensagem de erro se existir
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1), // Fundo vermelho claro
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: AppColors.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              // Botão de login
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _try, // Desabilita durante loading
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white, // Loading branco
                          ),
                        )
                      : const Text(
                          'Entrar',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
              // Botão para navegar para tela de registro
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/register'),
                child: const Text('Criar conta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}