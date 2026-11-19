
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import 'registro_page.dart';
import 'inicio_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _mostrarPassword = false;
  bool _cargando = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ==========================================
  // INICIAR SESION
  // ==========================================

  Future<void> _iniciarSesion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);

    try {
      await _authService.iniciarSesion(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const InicioPage(),
        ),
        (route) => false,
      );

    } on AuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
        ),
      );

    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al iniciar sesión: $e'),
          backgroundColor: Colors.red,
        ),
      );

    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  // ==========================================
  // RECUPERAR CONTRASEÑA
  // ==========================================

  Future<void> _recuperarPassword() async {
    final emailController = TextEditingController(
      text: _emailController.text.trim(),
    );

    final email = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Recuperar contraseña'),
          content: TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  emailController.text.trim(),
                );
              },
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );

    emailController.dispose();

    if (email == null || email.isEmpty) return;

    try {
      await _authService.recuperarPassword(email);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Si el correo está registrado, recibirás instrucciones '
            'para recuperar tu contraseña.',
          ),
          backgroundColor: Colors.green,
        ),
      );

    } on AuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ==========================================
  // INTERFAZ
  // ==========================================

  @override
  Widget build(BuildContext context) {
    const azul = Color(0xFF1765BD);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FD),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),

            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 420,
              ),

              child: Card(
                color: Colors.white,
                elevation: 3,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),

                child: Padding(
                  padding: const EdgeInsets.all(26),

                  child: Form(
                    key: _formKey,

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,

                      children: [

                        const SizedBox(height: 15),

                        const Icon(
                          Icons.inventory_2,
                          color: azul,
                          size: 75,
                        ),

                        const SizedBox(height: 18),

                        const Text(
                          'OptiInventario Lite',
                          textAlign: TextAlign.center,

                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: azul,
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          'Inicia sesión para continuar',
                          textAlign: TextAlign.center,

                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 15,
                          ),
                        ),

                        const SizedBox(height: 35),

                        // CORREO

                        TextFormField(
                          controller: _emailController,

                          keyboardType: TextInputType.emailAddress,

                          decoration: const InputDecoration(
                            labelText: 'Correo electrónico',
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(),
                          ),

                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Ingresa tu correo';
                            }

                            if (!RegExp(
                              r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                            ).hasMatch(value.trim())) {
                              return 'Correo no válido';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // CONTRASEÑA

                        TextFormField(
                          controller: _passwordController,

                          obscureText: !_mostrarPassword,

                          decoration: InputDecoration(
                            labelText: 'Contraseña',

                            prefixIcon: const Icon(
                              Icons.lock_outline,
                            ),

                            border: const OutlineInputBorder(),

                            suffixIcon: IconButton(
                              icon: Icon(
                                _mostrarPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),

                              onPressed: () {
                                setState(() {
                                  _mostrarPassword =
                                      !_mostrarPassword;
                                });
                              },
                            ),
                          ),

                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingresa tu contraseña';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 10),

                        // RECUPERAR CONTRASEÑA

                        Align(
                          alignment: Alignment.centerRight,

                          child: TextButton(
                            onPressed: _cargando
                                ? null
                                : _recuperarPassword,

                            child: const Text(
                              '¿Olvidaste tu contraseña?',
                              style: TextStyle(color: azul),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // BOTON INGRESAR

                        SizedBox(
                          height: 52,

                          child: ElevatedButton(
                            onPressed: _cargando
                                ? null
                                : _iniciarSesion,

                            style: ElevatedButton.styleFrom(
                              backgroundColor: azul,
                              foregroundColor: Colors.white,

                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),

                            child: _cargando
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    'INICIAR SESIÓN',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 25),

                        const Divider(),

                        const SizedBox(height: 10),

                        // REGISTRO

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,

                          children: [
                            const Text(
                              '¿No tienes una cuenta?',
                            ),

                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const RegistroPage(),
                                  ),
                                );
                              },

                              child: const Text(
                                'Crear cuenta',
                                style: TextStyle(
                                  color: azul,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
