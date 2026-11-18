import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _signup = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _toggleMode() => setState(() {
    _signup = !_signup;
    _error = null;
    _confirm.clear();
  });

  /// Mêmes règles que le schéma UserCreate du backend, pour prévenir
  /// l'utilisateur sans aller-retour serveur. Le serveur reste l'autorité.
  String? _validate(String username) {
    if (username.length < 3 || username.length > 30) {
      return "L'identifiant doit faire entre 3 et 30 caractères";
    }
    if (_password.text.length < 8) {
      return 'Le mot de passe doit faire au moins 8 caractères';
    }
    if (utf8.encode(_password.text).length > 72) {
      return 'Le mot de passe est trop long';
    }
    if (_password.text != _confirm.text) {
      return 'Les deux mots de passe ne correspondent pas';
    }
    return null;
  }

  String _message(DioException e) {
    final code = e.response?.statusCode;
    final data = e.response?.data;
    final detail = data is Map ? data['detail'] : null;
    if (code == 401) return 'Identifiant ou mot de passe incorrect';
    if ((code == 403 || code == 409) && detail is String) return detail;
    return 'Erreur de connexion au serveur';
  }

  Future<void> _submit() async {
    if (_loading) return;
    final username = _username.text.trim();
    if (_signup) {
      final invalid = _validate(username);
      if (invalid != null) {
        setState(() => _error = invalid);
        return;
      }
    }
    setState(() { _loading = true; _error = null; });
    final auth = ref.read(authControllerProvider.notifier);
    try {
      if (_signup) {
        await auth.register(username, _password.text);
      } else {
        await auth.login(username, _password.text);
      }
    } on DioException catch (e) {
      if (mounted) setState(() => _error = _message(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_signup ? 'ActaBank — Créer un compte' : 'ActaBank — Connexion'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _username,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Identifiant',
                      helperText: _signup ? 'Entre 3 et 30 caractères' : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    textInputAction: _signup ? TextInputAction.next : TextInputAction.done,
                    onSubmitted: _signup ? null : (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      helperText: _signup ? 'Au moins 8 caractères' : null,
                    ),
                  ),
                  if (_signup) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _confirm,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(labelText: 'Confirmer le mot de passe'),
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (_error != null) ...[
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(_signup ? 'Créer mon compte' : 'Se connecter'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _loading ? null : _toggleMode,
                    child: Text(_signup ? 'Déjà un compte ? Se connecter' : 'Pas encore de compte ? Créer un compte'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}