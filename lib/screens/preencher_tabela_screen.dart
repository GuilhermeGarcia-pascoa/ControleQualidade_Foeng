import 'package:flutter/material.dart';
import '../models/models.dart';
import '../database/database_helper.dart';
import '../widgets/campo_widget.dart';
import '../utils/toast.dart';

// ─── PALETA ESCURA (consistente com DashboardScreen) ─────
class _C {
  static const bg         = Color(0xFF0D1117);
  static const surface    = Color(0xFF161B22);
  static const surfaceAlt = Color(0xFF1C2330);
  static const border     = Color(0xFF30363D);
  static const accent     = Color(0xFF00C2A8);
  static const accentDim  = Color(0x2200C2A8);
  static const primary    = Color(0xFF58A6FF);
  static const primaryDim = Color(0x1558A6FF);
  static const textPri    = Color(0xFFE6EDF3);
  static const textSec    = Color(0xFF8B949E);
  static const textMuted  = Color(0xFF484F58);
  static const danger     = Color(0xFFF85149);
  static const dangerDim  = Color(0x20F85149);
  static const warning    = Color(0xFFD29922);
  static const warningDim = Color(0x22D29922);
  static const success    = Color(0xFF3FB950);
}

class PreencherTabelaScreen extends StatefulWidget {
  final No no;
  const PreencherTabelaScreen({Key? key, required this.no}) : super(key: key);

  @override
  _PreencherTabelaScreenState createState() => _PreencherTabelaScreenState();
}

class _PreencherTabelaScreenState extends State<PreencherTabelaScreen>
    with SingleTickerProviderStateMixin {
  List<CampoDinamico> campos = [];
  Map<String, dynamic> dadosPreenchidos = {};
  bool _loading = true;
  bool _salvando = false;

  late AnimationController _btnCtrl;
  late Animation<double> _btnAnim;

  @override
  void initState() {
    super.initState();
    _btnCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _btnAnim =
        CurvedAnimation(parent: _btnCtrl, curve: Curves.elasticOut);
    _loadCampos();
  }

  @override
  void dispose() {
    _btnCtrl.dispose();
    super.dispose();
  }

  void _loadCampos() async {
    try {
      final data = await DatabaseHelper.instance.getCampos(widget.no.id!);
      setState(() {
        campos = data;
        _loading = false;
      });
      _btnCtrl.forward();
    } catch (e) {
      setState(() => _loading = false);
      Toast.mostrar(context, 'Erro ao carregar campos', tipo: ToastTipo.erro);
    }
  }

  // Progresso de preenchimento
  int get _camposPreenchidos =>
      campos.where((c) => dadosPreenchidos[c.nomeCampo] != null &&
          dadosPreenchidos[c.nomeCampo].toString().isNotEmpty).length;

  double get _progresso =>
      campos.isEmpty ? 0 : _camposPreenchidos / campos.length;

  int get _obrigatoriosPorPreencher => campos
      .where((c) =>
          c.obrigatorio == 1 &&
          (dadosPreenchidos[c.nomeCampo] == null ||
              dadosPreenchidos[c.nomeCampo].toString().isEmpty))
      .length;

  void _salvarRegisto() async {
    if (dadosPreenchidos.isEmpty) {
      Toast.mostrar(context, 'Preencha pelo menos um campo antes de submeter!',
          tipo: ToastTipo.aviso);
      return;
    }

    for (final campo in campos) {
      final valor = dadosPreenchidos[campo.nomeCampo];
      if (campo.obrigatorio == 1 &&
          (valor == null || valor.toString().isEmpty)) {
        Toast.mostrar(context, 'O campo "${campo.nomeCampo}" é obrigatório!',
            tipo: ToastTipo.erro);
        return;
      }
    }

    setState(() => _salvando = true);

    try {
      final sucesso = await DatabaseHelper.instance.inserirRegisto({
        'no_id': widget.no.id,
        'dados': dadosPreenchidos,
      });

      if (!mounted) return;

      if (sucesso) {
        Toast.mostrar(context, 'Registo guardado com sucesso!',
            tipo: ToastTipo.sucesso);
        Navigator.pop(context);
      } else {
        Toast.mostrar(context,
            'Erro ao guardar registo. Verifique a ligação ao servidor.',
            tipo: ToastTipo.erro);
      }
    } catch (e) {
      Toast.mostrar(context, 'Erro: ${e.toString()}', tipo: ToastTipo.erro);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── AppBar
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: _C.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  color: _C.textSec, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: _C.border),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.no.nome,
                    style: TextStyle(
                      color: _C.textPri,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Preenchimento de dados',
                    style: TextStyle(
                      color: _C.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              background: Container(
                color: _C.surface,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(painter: _GridPainter()),
                    ),
                    Positioned(
                      top: -20,
                      right: -20,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            _C.accent.withOpacity(0.10),
                            Colors.transparent,
                          ]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Loading
          if (_loading)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                          color: _C.accent, strokeWidth: 2.5),
                    ),
                    const SizedBox(height: 14),
                    Text('A carregar campos...',
                        style: TextStyle(color: _C.textSec, fontSize: 13)),
                  ],
                ),
              ),
            )

          // ── Empty
          else if (campos.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: _C.surfaceAlt,
                        shape: BoxShape.circle,
                        border: Border.all(color: _C.border),
                      ),
                      child:
                          Icon(Icons.edit_off_outlined, size: 32, color: _C.textMuted),
                    ),
                    const SizedBox(height: 20),
                    Text('Nenhum campo definido',
                        style: TextStyle(
                            color: _C.textPri,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(
                      'Pede ao administrador para adicionar campos.',
                      style: TextStyle(color: _C.textSec, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )

          // ── Conteúdo
          else ...[
            // Barra de progresso + stats
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: _ProgressCard(
                  total: campos.length,
                  preenchidos: _camposPreenchidos,
                  progresso: _progresso,
                  obrigatoriosPendentes: _obrigatoriosPorPreencher,
                ),
              ),
            ),

            // Campos
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final campo = campos[index];
                    return _CampoWrapper(
                      index: index,
                      campo: campo,
                      preenchido: dadosPreenchidos[campo.nomeCampo] != null &&
                          dadosPreenchidos[campo.nomeCampo].toString().isNotEmpty,
                      child: CampoWidget(
                        campo: campo,
                        onValueChanged: (nomeCampo, valor) {
                          setState(() => dadosPreenchidos[nomeCampo] = valor);
                        },
                      ),
                    );
                  },
                  childCount: campos.length,
                ),
              ),
            ),
          ],
        ],
      ),

      // ── Botão de submeter
      bottomNavigationBar: campos.isEmpty || _loading
          ? null
          : _SubmitBar(
              salvando: _salvando,
              progresso: _progresso,
              obrigatoriosPendentes: _obrigatoriosPorPreencher,
              btnAnim: _btnAnim,
              onSubmit: _salvarRegisto,
            ),
    );
  }
}

// ─── PROGRESS CARD ────────────────────────────────────────

class _ProgressCard extends StatelessWidget {
  final int total;
  final int preenchidos;
  final double progresso;
  final int obrigatoriosPendentes;

  const _ProgressCard({
    required this.total,
    required this.preenchidos,
    required this.progresso,
    required this.obrigatoriosPendentes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Stats
              _StatChip(
                icon: Icons.list_alt_rounded,
                label: '$total campos',
                color: _C.primary,
              ),
              const SizedBox(width: 8),
              _StatChip(
                icon: Icons.check_circle_outline_rounded,
                label: '$preenchidos preenchidos',
                color: _C.success,
              ),
              if (obrigatoriosPendentes > 0) ...[
                const SizedBox(width: 8),
                _StatChip(
                  icon: Icons.error_outline_rounded,
                  label: '$obrigatoriosPendentes obrigatórios',
                  color: _C.warning,
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          // Barra de progresso
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progresso,
                    minHeight: 6,
                    backgroundColor: _C.surfaceAlt,
                    valueColor: AlwaysStoppedAnimation(
                      progresso == 1.0 ? _C.success : _C.accent,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${(progresso * 100).toInt()}%',
                style: TextStyle(
                  color: progresso == 1.0 ? _C.success : _C.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── WRAPPER DE CAMPO ────────────────────────────────────

class _CampoWrapper extends StatefulWidget {
  final int index;
  final CampoDinamico campo;
  final bool preenchido;
  final Widget child;

  const _CampoWrapper({
    required this.index,
    required this.campo,
    required this.preenchido,
    required this.child,
  });

  @override
  State<_CampoWrapper> createState() => _CampoWrapperState();
}

class _CampoWrapperState extends State<_CampoWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: widget.index * 55), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isObrigatorio = widget.campo.obrigatorio == 1;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: widget.preenchido
                    ? _C.accent.withOpacity(0.4)
                    : isObrigatorio
                        ? _C.warning.withOpacity(0.3)
                        : _C.border,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header do campo
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(14, 12, 14, 0),
                  child: Row(
                    children: [
                      // Número do campo
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: _C.surfaceAlt,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _C.border),
                        ),
                        child: Center(
                          child: Text(
                            '${widget.index + 1}',
                            style: TextStyle(
                              color: _C.textSec,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.campo.nomeCampo,
                          style: TextStyle(
                            color: _C.textPri,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isObrigatorio)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: _C.warningDim,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: _C.warning.withOpacity(0.4)),
                          ),
                          child: Text(
                            'obrigatório',
                            style: TextStyle(
                              color: _C.warning,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (widget.preenchido) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.check_circle_rounded,
                            color: _C.accent, size: 16),
                      ],
                    ],
                  ),
                ),
                // Widget do campo
                Theme(
                  data: Theme.of(context).copyWith(
                    inputDecorationTheme: InputDecorationTheme(
                      filled: true,
                      fillColor: _C.surfaceAlt,
                      labelStyle:
                          TextStyle(color: _C.textSec, fontSize: 13),
                      hintStyle:
                          TextStyle(color: _C.textMuted, fontSize: 13),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: _C.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.transparent),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: _C.accent, width: 1.5),
                      ),
                    ),
                    textTheme: Theme.of(context).textTheme.apply(
                          bodyColor: _C.textPri,
                          displayColor: _C.textPri,
                        ),
                    colorScheme: Theme.of(context).colorScheme.copyWith(
                          primary: _C.accent,
                          surface: _C.surfaceAlt,
                          onSurface: _C.textPri,
                        ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                    child: widget.child,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── BARRA DE SUBMIT ─────────────────────────────────────

class _SubmitBar extends StatelessWidget {
  final bool salvando;
  final double progresso;
  final int obrigatoriosPendentes;
  final Animation<double> btnAnim;
  final VoidCallback onSubmit;

  const _SubmitBar({
    required this.salvando,
    required this.progresso,
    required this.obrigatoriosPendentes,
    required this.btnAnim,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: _C.surface,
        border: Border(top: BorderSide(color: _C.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Aviso se obrigatórios por preencher
          if (obrigatoriosPendentes > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _C.warningDim,
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: _C.warning.withOpacity(0.35)),
                ),
                child: Row(children: [
                  Icon(Icons.info_outline_rounded,
                      color: _C.warning, size: 15),
                  const SizedBox(width: 8),
                  Text(
                    '$obrigatoriosPendentes campo${obrigatoriosPendentes != 1 ? 's' : ''} obrigatório${obrigatoriosPendentes != 1 ? 's' : ''} por preencher',
                    style: TextStyle(
                        color: _C.warning,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                ]),
              ),
            ),

          // Botão
          ScaleTransition(
            scale: btnAnim,
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      salvando ? _C.surfaceAlt : _C.accent,
                  disabledBackgroundColor: _C.surfaceAlt,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                onPressed: salvando ? null : onSubmit,
                child: salvando
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _C.accent,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text('A guardar...',
                              style: TextStyle(
                                  color: _C.textSec,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.send_rounded,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'SUBMETER DADOS',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),

          const SizedBox(height: 8),
          Text(
            'Campos obrigatórios marcados com  obrigatório',
            style: TextStyle(fontSize: 10, color: _C.textMuted),
          ),
        ],
      ),
    );
  }
}

// ─── CUSTOM PAINTER: GRID ────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF30363D).withOpacity(0.4)
      ..strokeWidth = 0.5;

    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}