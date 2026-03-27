import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../database/database_helper.dart';

// ── Palette partilhada (igual ao GerirMembrosScreen) ─────
const Color _bgDark      = Color(0xFF0D1117);
const Color _cardColor   = Color(0xFF161B22);
const Color _accent      = Color(0xFF2F81F7);
const Color _textPrimary = Color(0xFFE6EDF3);
const Color _textMuted   = Color(0xFF8B949E);
const Color _borderColor = Color(0xFF30363D);
const Color _danger      = Color(0xFFD64045);
const Color _success     = Color(0xFF238636);
const Color _orange      = Color(0xFFE3800D);
const Color _purple      = Color(0xFF8957E5);
// ─────────────────────────────────────────────────────────

class GerirAcessoNoScreen extends StatefulWidget {
  final No no;
  const GerirAcessoNoScreen({Key? key, required this.no}) : super(key: key);

  @override
  _GerirAcessoNoScreenState createState() => _GerirAcessoNoScreenState();
}

class _GerirAcessoNoScreenState extends State<GerirAcessoNoScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> membros = [];
  bool _loading = true;
  final emailC = TextEditingController();
  List<Map<String, dynamic>> _sugestoes = [];
  bool _carregandoSugestoes = false;
  Map<String, dynamic>? _utilizadorSelecionado;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    _loadMembros();
  }

  @override
  void dispose() {
    _animController.dispose();
    emailC.dispose();
    super.dispose();
  }

  void _onEmailChanged(String texto) async {
    texto = texto.trim();
    setState(() => _utilizadorSelecionado = null);

    if (texto.length < 2) {
      setState(() => _sugestoes = []);
      return;
    }

    setState(() => _carregandoSugestoes = true);
    final resultados = await DatabaseHelper.instance.procurarUtilizadoresPorTexto(texto);
    final membroIds = membros.map((m) => m['id']).toSet();
    final filtrados = resultados.where((u) => !membroIds.contains(u['id'])).toList();

    if (!mounted) return;
    setState(() {
      _sugestoes = filtrados;
      _carregandoSugestoes = false;
    });
  }

  void _selecionarSugestao(Map<String, dynamic> u) {
    setState(() {
      _utilizadorSelecionado = u;
      _sugestoes = [];
    });
    emailC.text = u['email'];
  }

  void _loadMembros() async {
    setState(() => _loading = true);
    _animController.reset();
    final data = await DatabaseHelper.instance.getMembrosNo(widget.no.id!);
    setState(() {
      membros = data;
      _loading = false;
    });
    _animController.forward();
  }

  void _showSnackBar(String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
        ]),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        elevation: 0,
      ),
    );
  }

  void _darAcesso() async {
    final email = emailC.text.trim();
    if (email.isEmpty) {
      _showSnackBar('O campo de pesquisa está vazio.', _orange, Icons.warning_amber_rounded);
      return;
    }

    try {
      final utilizador = _utilizadorSelecionado ??
          await DatabaseHelper.instance.procurarUtilizadorPorEmail(email);

      if (utilizador == null) {
        _showSnackBar('Utilizador não encontrado!', _danger, Icons.error_outline_rounded);
        return;
      }

      final jaExiste = membros.any((m) => m['id'] == utilizador['id']);
      if (jaExiste) {
        _showSnackBar('Este utilizador já tem acesso a esta pasta!', _orange, Icons.warning_amber_rounded);
        return;
      }

      final sucesso = await DatabaseHelper.instance.darAcessoNo(utilizador['id'], widget.no.id!);

      if (sucesso) {
        emailC.clear();
        FocusScope.of(context).unfocus();
        setState(() {
          _utilizadorSelecionado = null;
          _sugestoes = [];
        });
        _loadMembros();
        _showSnackBar('${utilizador['nome']} tem agora acesso a esta pasta!', _success, Icons.check_circle_outline_rounded);
      } else {
        _showSnackBar('Erro ao dar acesso.', _danger, Icons.error_outline_rounded);
      }
    } catch (e) {
      _showSnackBar('Erro de sistema: $e', _danger, Icons.error_outline_rounded);
    }
  }

  void _removerAcesso(Map<String, dynamic> membro) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _borderColor),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: _danger.withOpacity(0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.lock_outline, color: _danger, size: 22),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Remover Acesso', style: TextStyle(color: _textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                      SizedBox(height: 2),
                      Text('O utilizador perderá acesso à pasta', style: TextStyle(color: _textMuted, fontSize: 12)),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 24),
              RichText(
                text: TextSpan(
                  style: const TextStyle(color: _textMuted, fontSize: 14, height: 1.5),
                  children: [
                    const TextSpan(text: 'Remover acesso de '),
                    TextSpan(text: '"${membro['nome']}"', style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.w600)),
                    const TextSpan(text: ' à pasta '),
                    TextSpan(text: '"${widget.no.nome}"', style: const TextStyle(color: _accent, fontWeight: FontWeight.w600)),
                    const TextSpan(text: '?\n\nEle perderá acesso a esta pasta e a todas as subpastas.'),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Row(children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: TextButton.styleFrom(
                      foregroundColor: _textMuted,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: _borderColor)),
                    ),
                    child: const Text('Cancelar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _danger,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Remover', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.removerAcessoNo(membro['id'], widget.no.id!);
      _loadMembros();
      _showSnackBar('Acesso removido.', _textMuted, Icons.info_outline_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      body: Stack(
        children: [
          // ── Background ──────────────────────────────────
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),
          Positioned(
            top: -100, right: -50,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_purple.withOpacity(0.12), Colors.transparent],
                  stops: const [0.2, 1.0],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 70),

                // ── Banner informativo ───────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _purple.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _purple.withOpacity(0.25)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.folder_shared_outlined, color: _purple, size: 18),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Acesso a esta pasta inclui automaticamente todas as subpastas dentro dela.',
                          style: TextStyle(color: _purple, fontSize: 12, height: 1.4),
                        ),
                      ),
                    ]),
                  ),
                ),

                // ── Campo de pesquisa ────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: _cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _borderColor),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Row(children: [
                            const SizedBox(width: 12),
                            const Icon(Icons.search_rounded, color: _textMuted, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: emailC,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(color: _textPrimary, fontSize: 14),
                                onChanged: _onEmailChanged,
                                onSubmitted: (_) => _darAcesso(),
                                decoration: InputDecoration(
                                  hintText: 'Pesquisar por nome ou email...',
                                  hintStyle: TextStyle(color: _textMuted.withOpacity(0.7), fontSize: 14),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                            if (_carregandoSugestoes)
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _accent)),
                              )
                            else if (emailC.text.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.clear, color: _textMuted, size: 18),
                                onPressed: () {
                                  emailC.clear();
                                  setState(() { _sugestoes = []; _utilizadorSelecionado = null; });
                                },
                                splashRadius: 20,
                              ),
                            ElevatedButton(
                              onPressed: _darAcesso,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _purple,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Dar Acesso', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ),
                          ]),
                        ),
                      ),

                      // ── Sugestões ──────────────────────
                      if (_utilizadorSelecionado != null)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: _success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _success.withOpacity(0.3)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.check_circle_rounded, color: _success, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${_utilizadorSelecionado!['nome']} (${_utilizadorSelecionado!['email']})',
                                style: const TextStyle(color: _success, fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ),
                          ]),
                        )
                      else if (_sugestoes.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          decoration: BoxDecoration(
                            color: _cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _borderColor),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: Column(
                            children: _sugestoes.take(5).map((u) {
                              final cor = u['perfil'] == 'admin' ? _accent : _orange;
                              return InkWell(
                                onTap: () => _selecionarSugestao(u),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(children: [
                                    Container(
                                      width: 36, height: 36,
                                      decoration: BoxDecoration(
                                        color: cor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: cor.withOpacity(0.3)),
                                      ),
                                      child: Center(child: Text((u['nome'] as String)[0].toUpperCase(), style: TextStyle(color: cor, fontSize: 14, fontWeight: FontWeight.w800))),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(u['nome'], style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                                        Text(u['email'], style: const TextStyle(color: _textMuted, fontSize: 12)),
                                      ],
                                    )),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: cor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                      child: Text(u['perfil'].toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: cor)),
                                    ),
                                  ]),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),

                // ── Separador ───────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Row(children: [
                    Container(width: 4, height: 16, decoration: BoxDecoration(color: _purple, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 10),
                    const Text('UTILIZADORES COM ACESSO', style: TextStyle(color: _textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                  ]),
                ),

                // ── Lista ───────────────────────────────
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator(color: _purple, strokeWidth: 2))
                      : membros.isEmpty
                          ? Center(
                              child: FadeTransition(
                                opacity: _fadeAnim,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 80, height: 80,
                                      decoration: BoxDecoration(color: _cardColor, shape: BoxShape.circle, border: Border.all(color: _borderColor, width: 2)),
                                      child: const Icon(Icons.lock_open_outlined, color: _textMuted, size: 36),
                                    ),
                                    const SizedBox(height: 20),
                                    const Text('Nenhum acesso atribuído', style: TextStyle(color: _textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 8),
                                    const Text('Usa a pesquisa acima para dar\nacesso a utilizadores específicos.', textAlign: TextAlign.center, style: TextStyle(color: _textMuted, fontSize: 14, height: 1.4)),
                                  ],
                                ),
                              ),
                            )
                          : FadeTransition(
                              opacity: _fadeAnim,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                                itemCount: membros.length,
                                itemBuilder: (context, index) {
                                  final membro = membros[index];
                                  final cor = membro['perfil'] == 'admin' ? _accent : _orange;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: _cardColor,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: _borderColor),
                                      ),
                                      child: Row(children: [
                                        Container(
                                          width: 48, height: 48,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [cor.withOpacity(0.3), cor.withOpacity(0.05)],
                                            ),
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(color: cor.withOpacity(0.3)),
                                          ),
                                          child: Center(child: Text((membro['nome'] as String)[0].toUpperCase(), style: TextStyle(color: cor, fontSize: 18, fontWeight: FontWeight.w800))),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(membro['nome'], style: const TextStyle(color: _textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                                            const SizedBox(height: 4),
                                            Text(membro['email'], style: const TextStyle(color: _textMuted, fontSize: 13), overflow: TextOverflow.ellipsis),
                                          ],
                                        )),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: _purple.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: _purple.withOpacity(0.2)),
                                          ),
                                          child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                            Icon(Icons.folder_open_rounded, size: 12, color: _purple),
                                            SizedBox(width: 5),
                                            Text('ACESSO', style: TextStyle(color: _purple, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                                          ]),
                                        ),
                                        const SizedBox(width: 12),
                                        IconButton(
                                          onPressed: () => _removerAcesso(membro),
                                          icon: const Icon(Icons.close_rounded),
                                          color: _textMuted,
                                          iconSize: 20,
                                          splashRadius: 24,
                                          hoverColor: _danger.withOpacity(0.1),
                                          highlightColor: _danger.withOpacity(0.1),
                                          tooltip: 'Remover acesso',
                                        ),
                                      ]),
                                    ),
                                  );
                                },
                              ),
                            ),
                ),
              ],
            ),
          ),

          // ── AppBar fixa (Glassmorphism) ──────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: _bgDark.withOpacity(0.8),
                  child: SafeArea(
                    bottom: false,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _borderColor.withOpacity(0.5)))),
                      child: Row(children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: _cardColor.withOpacity(0.8), borderRadius: BorderRadius.circular(10), border: Border.all(color: _borderColor)),
                            child: const Icon(Icons.arrow_back_rounded, color: _textPrimary, size: 20),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Gerir Acesso', style: TextStyle(color: _textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(widget.no.nome, style: const TextStyle(color: _textMuted, fontSize: 12), overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        if (!_loading)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: _purple.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.lock_open_rounded, color: _purple, size: 14),
                              const SizedBox(width: 6),
                              Text('${membros.length}', style: const TextStyle(color: _purple, fontSize: 13, fontWeight: FontWeight.w700)),
                            ]),
                          ),
                      ]),
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

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF30363D).withOpacity(0.3);
    const spacing = 32.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}