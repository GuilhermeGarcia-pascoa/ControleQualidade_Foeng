import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../utils/session.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final emailC = TextEditingController(text: 'admin@foeng.pt');
  final passC = TextEditingController(text: 'admin');
  bool _obscurePass = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    emailC.dispose();
    passC.dispose();
    super.dispose();
  }

  void _login() async {
    final user = await DatabaseHelper.instance.login(emailC.text, passC.text);
    if (user != null) {
      await Session.saveUser(user.id!, user.perfil);
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => DashboardScreen(perfil: user.perfil)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Credenciais inválidas!'),
          backgroundColor: const Color(0xFFD64045),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color bgDark = Color(0xFF0D1117);
    const Color cardColor = Color(0xFF161B22);
    const Color accent = Color(0xFF2F81F7);
    const Color accentSoft = Color(0xFF1F6FEB);
    const Color textPrimary = Color(0xFFE6EDF3);
    const Color textMuted = Color(0xFF8B949E);
    const Color borderColor = Color(0xFF30363D);

    return Scaffold(
      backgroundColor: bgDark,
      body: Stack(
        children: [
          // Subtle grid background
          Positioned.fill(
            child: CustomPaint(painter: _GridPainter()),
          ),
          // Glow accent top-left
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [accent.withOpacity(0.15), Colors.transparent],
                ),
              ),
            ),
          ),
          // Glow accent bottom-right
          Positioned(
            bottom: -100,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [accentSoft.withOpacity(0.10), Colors.transparent],
                ),
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo da empresa
                        Image.asset(
                          'assets/images/logo.png',
                          height: 90,
                          fit: BoxFit.contain,
                        ),
                      
                        const SizedBox(height: 6),
                        const Text(
                          'Acesso à plataforma',
                          style: TextStyle(
                            color: textMuted,
                            fontSize: 13.5,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Card
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 32,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Email field
                              const Text(
                                'Email',
                                style: TextStyle(
                                  color: textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: emailC,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(color: textPrimary, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'email@exemplo.pt',
                                  hintStyle: TextStyle(color: textMuted.withOpacity(0.5), fontSize: 14),
                                  prefixIcon: const Icon(Icons.alternate_email_rounded, color: Color(0xFF8B949E), size: 18),
                                  filled: true,
                                  fillColor: bgDark,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: borderColor, width: 1),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: borderColor, width: 1),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: accent, width: 1.5),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Password field
                              const Text(
                                'Password',
                                style: TextStyle(
                                  color: textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: passC,
                                obscureText: _obscurePass,
                                style: const TextStyle(color: textPrimary, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: '••••••••',
                                  hintStyle: TextStyle(color: textMuted.withOpacity(0.5), fontSize: 14),
                                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF8B949E), size: 18),
                                  suffixIcon: GestureDetector(
                                    onTap: () => setState(() => _obscurePass = !_obscurePass),
                                    child: Icon(
                                      _obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      color: textMuted,
                                      size: 18,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: bgDark,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: borderColor, width: 1),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: borderColor, width: 1),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: accent, width: 1.5),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),
                              // Login button
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: accent,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text(
                                    'Entrar',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          '© ${DateTime.now().year} FOENG · Todos os direitos reservados',
                          style: const TextStyle(color: textMuted, fontSize: 11),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Subtle dot-grid background painter
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF30363D).withOpacity(0.4)
      ..strokeWidth = 1;

    const spacing = 28.0;
    const dotRadius = 1.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}