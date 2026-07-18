import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';

// ═══════════════════════════════════════════════════════
//  CONNEXION / INSCRIPTION — Porte d'entrée de Shinra IA
// ═══════════════════════════════════════════════════════

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const crimson = Color(0xFFE1233D);
  static const gold = Color(0xFFD4AF37);
  static const bg = Color(0xFF07090F);
  static const surface = Color(0xFF0B0E18);

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  bool _isSignUp = false;
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  Future<void> _submit() async {
    if (_emailCtrl.text.trim().isEmpty || _passwordCtrl.text.isEmpty) {
      setState(() => _error = 'Email et mot de passe requis.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = _isSignUp
        ? await AuthService.signUp(
            email: _emailCtrl.text,
            password: _passwordCtrl.text,
            displayName: _nameCtrl.text,
          )
        : await AuthService.signIn(email: _emailCtrl.text, password: _passwordCtrl.text);

    if (!mounted) return;
    setState(() {
      _loading = false;
      if (!result.ok) _error = result.message;
    });
    // Si succès, le AuthGate (main.dart) redirige automatiquement vers le chat.
  }

  Future<void> _submitGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await AuthService.signInWithGoogle();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (!result.ok) _error = result.message;
    });
  }

  Future<void> _forgotPassword() async {
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Entre ton email d\'abord pour recevoir le lien.');
      return;
    }
    final result = await AuthService.resetPassword(_emailCtrl.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message ?? result.message ?? '')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(colors: [crimson, gold]).createShader(b),
                  child: Text('SHINRA IA',
                      style: GoogleFonts.cinzel(
                          fontSize: 34, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 6)),
                ),
                const SizedBox(height: 6),
                Text(
                  _isSignUp ? 'Crée ton compte pour commencer' : 'Content de te revoir',
                  style: GoogleFonts.rajdhani(color: Colors.white54, fontSize: 15),
                ),
                const SizedBox(height: 32),

                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                  ),
                  child: Column(
                    children: [
                      if (_isSignUp) ...[
                        _field(_nameCtrl, 'Nom (optionnel)', Icons.person_outline),
                        const SizedBox(height: 12),
                      ],
                      _field(_emailCtrl, 'Email', Icons.mail_outline),
                      const SizedBox(height: 12),
                      _field(_passwordCtrl, 'Mot de passe', Icons.lock_outline, obscure: true),

                      if (!_isSignUp)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _forgotPassword,
                            child: Text('Mot de passe oublié ?',
                                style: GoogleFonts.shareTechMono(color: crimson.withOpacity(0.7), fontSize: 11)),
                          ),
                        ),

                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(_error!, style: GoogleFonts.rajdhani(color: const Color(0xFFFF4D6D), fontSize: 13)),
                      ],

                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: gold,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: _loading
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(_isSignUp ? 'CRÉER MON COMPTE' : 'SE CONNECTER',
                                  style: GoogleFonts.shareTechMono(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),

                      const SizedBox(height: 14),
                      Row(children: [
                        Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text('OU', style: GoogleFonts.shareTechMono(color: Colors.white24, fontSize: 10)),
                        ),
                        Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
                      ]),
                      const SizedBox(height: 14),

                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: OutlinedButton.icon(
                          onPressed: _loading ? null : _submitGoogle,
                          icon: const Icon(Icons.g_mobiledata, color: Colors.white, size: 24),
                          label: Text('Continuer avec Google',
                              style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 14)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.white.withOpacity(0.15)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => setState(() {
                    _isSignUp = !_isSignUp;
                    _error = null;
                  }),
                  child: Text(
                    _isSignUp ? 'Déjà un compte ? Se connecter' : 'Pas encore de compte ? S\'inscrire',
                    style: GoogleFonts.rajdhani(color: crimson, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon, {bool obscure = false}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure && _obscure,
      style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
        prefixIcon: Icon(icon, color: crimson.withOpacity(0.5), size: 20),
        suffixIcon: obscure
            ? IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: Colors.white38, size: 18),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
        filled: true,
        fillColor: bg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      ),
    );
  }
}
