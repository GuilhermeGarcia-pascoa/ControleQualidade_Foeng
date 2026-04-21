import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../utils/session.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Preencha todos os campos para continuar.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() { _loading = true; _error = null; });

    final user = await DatabaseHelper.instance.login(
      _emailCtrl.text.trim(), _passCtrl.text.trim());

    if (!mounted) return;

    if (user != null) {
      await Session.saveUser(user.id!, user.perfil);
      await AppTheme.loadTheme();
      if (!mounted) return;
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => DashboardScreen(perfil: user.perfil)));
    } else {
      setState(() { _loading = false; _error = 'Email ou password incorretos.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: AppTheme.primaryNavy,
      body: Stack(children: [
        // Background geometric pattern
        Positioned.fill(child: CustomPaint(painter: _GeoPainter())),
        // Accent glow
        Positioned(
          top: -120, right: -80,
          child: Container(
            width: 400, height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [AppTheme.accentBlue.withOpacity(0.12), Colors.transparent],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -100, left: -60,
          child: Container(
            width: 350, height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [AppTheme.accentTeal.withOpacity(0.08), Colors.transparent],
              ),
            ),
          ),
        ),
        SafeArea(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.opaque,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Logo & Brand
                          Row(children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: AppTheme.accentBlue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Text('F',
                                  style: TextStyle(
                                    color: Colors.white, fontSize: 22,
                                    fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('FOENG',
                                  style: TextStyle(
                                    color: Colors.white, fontSize: 17,
                                    fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                                Text('Quality Control',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.45),
                                    fontSize: 11, letterSpacing: 0.8)),
                              ],
                            ),
                          ]),
                          const SizedBox(height: 52),

                          // Heading
                          const Text('Bem-vindo de volta',
                            style: TextStyle(
                              color: Colors.white, fontSize: 30,
                              fontWeight: FontWeight.w700, letterSpacing: -0.8,
                              height: 1.1)),
                          const SizedBox(height: 8),
                          Text('Aceda à sua conta para continuar',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.45),
                              fontSize: 15, height: 1.5)),
                          const SizedBox(height: 40),

                          // Card
                          Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.10), width: 1),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Email field
                                const _FieldLabel(label: 'Endereço de email'),
                                const SizedBox(height: 8),
                                _DarkField(
                                  controller: _emailCtrl,
                                  hint: 'nome@empresa.pt',
                                  icon: Icons.alternate_email_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                  onSubmitted: (_) => _login(),
                                ),
                                const SizedBox(height: 20),

                                // Password field
                                const _FieldLabel(label: 'Password'),
                                const SizedBox(height: 8),
                                _DarkField(
                                  controller: _passCtrl,
                                  hint: '••••••••••',
                                  icon: Icons.lock_outline_rounded,
                                  obscureText: _obscure,
                                  onSubmitted: (_) => _login(),
                                  suffix: IconButton(
                                    icon: Icon(
                                      _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      color: Colors.white38, size: 18),
                                    onPressed: () => setState(() => _obscure = !_obscure),
                                  ),
                                ),

                                // Error
                                if (_error != null) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.error.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                                    ),
                                    child: Row(children: [
                                      const Icon(Icons.error_outline_rounded,
                                        color: Color(0xFFFC8181), size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(_error!,
                                        style: const TextStyle(
                                          color: Color(0xFFFC8181), fontSize: 13))),
                                    ]),
                                  ),
                                ],

                                const SizedBox(height: 24),

                                // Login button
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: _loading ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.accentBlue,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14)),
                                    ),
                                    child: _loading
                                        ? const SizedBox(width: 20, height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white, strokeWidth: 2))
                                        : const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text('Entrar na plataforma',
                                                style: TextStyle(fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.2)),
                                              SizedBox(width: 8),
                                              Icon(Icons.arrow_forward_rounded, size: 18),
                                            ]),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),
                          Center(
                            child: Text(
                              '© ${DateTime.now().year} FOENG · Todos os direitos reservados',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.25),
                                fontSize: 11, letterSpacing: 0.3)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});
  @override
  Widget build(BuildContext context) {
    return Text(label,
      style: TextStyle(
        color: Colors.white.withOpacity(0.55),
        fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5));
  }
}

class _DarkField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final void Function(String)? onSubmitted;
  final Widget? suffix;

  const _DarkField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.onSubmitted,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onSubmitted: onSubmitted,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        cursorColor: AppTheme.accentBlueLight,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 14),
          prefixIcon: Icon(icon, color: Colors.white38, size: 18),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 4),
          filled: false,
        ),
      ),
    );
  }
}

class _GeoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.025)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Diagonal grid
    const spacing = 60.0;
    for (double x = -spacing; x < size.width + size.height; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x - size.height, size.height), paint);
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}