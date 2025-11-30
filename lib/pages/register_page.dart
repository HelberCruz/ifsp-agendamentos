import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../app_colors.dart';

// Tela de registro/criação de nova conta de usuário
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Controladores para os campos de texto
  final _email = TextEditingController();        // Controla o campo de email
  final _pw = TextEditingController();           // Controla o campo de senha
  final _pw2 = TextEditingController();          // Controla o campo de confirmação de senha
  
  // Estados da interface
  bool _loading = false;                         // Indica se está processando o registro
  String? _error;                               // Mensagem de erro (null quando não há erro)
  bool _obscureText1 = true;                    // Controla visibilidade da senha principal
  bool _obscureText2 = true;                    // Controla visibilidade da confirmação de senha

  // Método principal para processar o registro do usuário
  void _register() async {
    // Validação inicial: verifica se as senhas coincidem
    if (_pw.text != _pw2.text) { 
      setState(() => _error = 'Senhas não coincidem'); 
      return; // Interrompe o processo se senhas não coincidirem
    }
    
    // Prepara a interface para o processo de registro
    setState(() { 
      _loading = true;  // Ativa o indicador de carregamento
      _error = null;    // Limpa qualquer erro anterior
    });
    
    try {
      // Tenta registrar o usuário usando o serviço de autenticação
      await AuthService.registerWithEmail(
        email: _email.text.trim(),  // Remove espaços em branco do email
        password: _pw.text          // Senha fornecida pelo usuário
      );
      
      // Se o registro for bem-sucedido e a tela ainda estiver montada,
      // navega para a página inicial substituindo a rota atual
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
      
    } catch (e) {
      // Captura qualquer exceção durante o registro e exibe como mensagem de erro
      setState(() => _error = e.toString());
    } finally {
      // Garante que o loading seja desativado independente do resultado,
      // verificando se o widget ainda está montado para evitar erros
      if (mounted) setState(() => _loading = false);
    }
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      // AppBar com título e cores temáticas
      appBar: AppBar(
        title: const Text('Criar conta'),
        backgroundColor: AppColors.primary,     // Cor primária do tema
        foregroundColor: Colors.white,          // Cor do texto/icons branco
      ),
      // Cor de fundo da página usando a cor de background do tema
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),    // Padding consistente em todas as bordas
          child: Column(
            children: [
              // Espaçamento no topo do conteúdo
              const SizedBox(height: 20),
              
              // Ícone ilustrativo para criação de conta
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,  // Cor de fundo mais clara que a primária
                  borderRadius: BorderRadius.circular(20), // Cantos arredondados
                ),
                child: Icon(Icons.person_add, size: 40, color: AppColors.primary),
              ),
              
              const SizedBox(height: 24), // Espaço entre ícone e título
              
              // Título principal da página
              Text(
                'Criar Nova Conta',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark, // Cor escura da paleta primária
                ),
              ),
              
              const SizedBox(height: 8), // Espaço entre título e subtítulo
              
              // Instrução para o usuário
              Text(
                'Preencha os dados abaixo',
                style: TextStyle(
                  color: Colors.grey[600], // Cor cinza para texto secundário
                ),
              ),
              
              const SizedBox(height: 32), // Espaço antes dos campos de formulário
              
              // Container principal que envolve todos os campos do formulário
              Container(
                decoration: BoxDecoration(
                  color: Colors.white, // Fundo branco para contrastar com o background
                  borderRadius: BorderRadius.circular(12), // Cantos arredondados
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1), // Sombra sutil
                      blurRadius: 8,                        // Desfoque da sombra
                      offset: const Offset(0, 2),          // Posição da sombra (baixo)
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Campo de email
                    TextField(
                      controller: _email, // Vincula ao controlador de email
                      decoration: const InputDecoration(
                        labelText: 'E-mail',               // Texto do label
                        border: InputBorder.none,          // Remove borda padrão
                        contentPadding: EdgeInsets.all(16), // Espaçamento interno
                        prefixIcon: Icon(Icons.email),     // Ícone à esquerda
                      ),
                      keyboardType: TextInputType.emailAddress, // Teclado otimizado para email
                    ),
                    
                    // Divisor visual entre campos
                    Divider(height: 1, color: Colors.grey[300]),
                    
                    // Campo de senha principal
                    TextField(
                      controller: _pw, // Vincula ao controlador de senha
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                        prefixIcon: const Icon(Icons.lock), // Ícone de cadeado
                        suffixIcon: IconButton(
                          // Ícone que alterna entre mostrar/ocultar senha
                          icon: Icon(_obscureText1 ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscureText1 = !_obscureText1),
                        ),
                      ),
                      obscureText: _obscureText1, // Controla se o texto está oculto
                    ),
                    
                    // Segundo divisor visual
                    Divider(height: 1, color: Colors.grey[300]),
                    
                    // Campo de confirmação de senha
                    TextField(
                      controller: _pw2, // Vincula ao controlador de confirmação
                      decoration: InputDecoration(
                        labelText: 'Confirmar senha',      // Label específico para confirmação
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                        prefixIcon: const Icon(Icons.lock_outline), // Ícone diferente para distinguir
                        suffixIcon: IconButton(
                          // Ícone independente para este campo
                          icon: Icon(_obscureText2 ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscureText2 = !_obscureText2),
                        ),
                      ),
                      obscureText: _obscureText2, // Controle independente de visibilidade
                    ),
                  ],
                ),
              ),
              
              // Seção condicional para exibir mensagens de erro
              if (_error != null) ...[
                const SizedBox(height: 16), // Espaço antes do erro
                Container(
                  width: double.infinity,    // Ocupa toda a largura disponível
                  padding: const EdgeInsets.all(12), // Espaçamento interno
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1), // Fundo vermelho claro
                    borderRadius: BorderRadius.circular(8),  // Cantos levemente arredondados
                  ),
                  child: Row(
                    children: [
                      // Ícone de erro
                      Icon(Icons.error, color: AppColors.error, size: 20),
                      const SizedBox(width: 8), // Espaço entre ícone e texto
                      Expanded(
                        // Texto de erro que quebra linha se necessário
                        child: Text(
                          _error!,
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 24), // Espaço antes do botão principal
              
              // Botão de ação principal - Criar Conta
              SizedBox(
                width: double.infinity,  // Botão ocupa toda a largura
                height: 50,              // Altura fixa para consistência
                child: ElevatedButton(
                  onPressed: _loading ? null : _register, // Desabilita durante loading
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, // Cor primária do tema
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // Cantos arredondados
                    ),
                    // Estado desabilitado é controlado automaticamente pelo onPressed null
                  ),
                  child: _loading 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,    // Espessura mais fina para melhor estética
                            color: Colors.white, // Cor branca para contraste
                          ),
                        )
                      : const Text(
                          'Criar Conta',
                          style: TextStyle(
                            fontSize: 16, 
                            fontWeight: FontWeight.bold, // Texto em negrito
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}