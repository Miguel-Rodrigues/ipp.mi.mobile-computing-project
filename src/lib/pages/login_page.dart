import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final pass = TextEditingController();
  bool isLogin = true;
  String error = "";

  @override
  void dispose() {
    email.dispose();
    pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset(
            'assets/login_bg.png',
            fit: BoxFit.cover,
          ),

          // Dark overlay for readability
          Container(
            color: Colors.black.withAlpha(140),
          ),

          // Content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Center(
                      // Se quiseres ligeiramente mais abaixo:
                      // child: Align(alignment: const Alignment(0, 0.15), child: ...)
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 480),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(242),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isLogin ? "Login" : "Registo",
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 20),

                            TextField(
                              controller: email,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: Colors.black87),
                              decoration: const InputDecoration(
                                labelText: "Email",
                                labelStyle: TextStyle(color: Colors.black54),
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),

                            TextField(
                              controller: pass,
                              obscureText: true,
                              style: const TextStyle(color: Colors.black87),
                              decoration: const InputDecoration(
                                labelText: "Password",
                                labelStyle: TextStyle(color: Colors.black54),
                                border: OutlineInputBorder(),
                              ),
                            ),

                            if (error.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Text(
                                  error,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),

                            const SizedBox(height: 16),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () async {
                                  try {
                                    if (isLogin) {
                                      await AuthService().login(
                                        email.text,
                                        pass.text,
                                      );
                                    } else {
                                      await AuthService().register(
                                        email.text,
                                        pass.text,
                                      );
                                    }
                                  } catch (_) {
                                    setState(() => error = "Erro no login");
                                  }
                                },
                                child: Text(isLogin ? "Entrar" : "Criar conta"),
                              ),
                            ),

                            TextButton(
                              onPressed: () {
                                setState(() {
                                  isLogin = !isLogin;
                                  error = "";
                                });
                              },
                              child: Text(
                                isLogin
                                    ? "Não tens conta? Criar"
                                    : "Já tens conta? Entrar",
                                style: const TextStyle(color: Colors.black87),
                              ),
                            ),

                            const SizedBox(height: 8),

                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.login),
                                label: const Text("Entrar com Google"),
                                onPressed: () async {
                                  try {
                                    await AuthService().loginWithGoogle();
                                  } catch (_) {
                                    setState(() => error = "Erro Google");
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
