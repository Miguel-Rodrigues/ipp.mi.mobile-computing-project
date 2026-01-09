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
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 80),
            Text(isLogin ? "Login" : "Registo",
                style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 20),

            TextField(
              controller: email,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: pass,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),

            if (error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8),
                child:
                Text(error, style: const TextStyle(color: Colors.red)),
              ),

            const SizedBox(height: 20),

            ElevatedButton(
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

            TextButton(
              onPressed: () {
                setState(() {
                  isLogin = !isLogin;
                  error = "";
                });
              },
              child: Text(isLogin
                  ? "Não tens conta? Criar"
                  : "Já tens conta? Entrar"),
            ),

            const SizedBox(height: 16),

            OutlinedButton.icon(
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
          ],
        ),
      ),
    );
  }
}
