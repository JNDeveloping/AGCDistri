import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../dashboard/presentation/pages/dashboard_page.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/auth_header.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  static const String path = '/login';
  static const String name = 'login';

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: BlocConsumer<AuthCubit, AuthState>(
                listener: (context, state) {
                  if (state.isAuthenticated) {
                    context.goNamed(DashboardPage.name);
                  }

                  if (state.status == AuthStatus.failure && state.errorMessage != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.errorMessage!)),
                    );
                  }
                },
                builder: (context, state) {
                  final isLoading = state.status == AuthStatus.loading;

                  return Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const AuthHeader(),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: 'Correo corporativo'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Ingresá tu correo.';
                            }
                            if (!value.contains('@')) {
                              return 'Correo inválido.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: 'Contraseña'),
                          validator: (value) =>
                              value == null || value.isEmpty ? 'Ingresá tu contraseña.' : null,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  if (_formKey.currentState?.validate() ?? false) {
                                    context.read<AuthCubit>().login(
                                          email: _emailController.text.trim(),
                                          password: _passwordController.text,
                                        );
                                  }
                                },
                          child: Text(isLoading ? 'Validando...' : 'Iniciar sesión'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
