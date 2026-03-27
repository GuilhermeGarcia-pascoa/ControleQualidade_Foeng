import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/models.dart';
import 'nos_screen.dart';
import '../utils/session.dart';
import 'login_screen.dart';
import '../utils/toast.dart';
import 'gerir_membros_screen.dart';

// ─── PALETA ESCURA ────────────────────────────────────────
class _C {
  static const bg         = Color(0xFF0D1117); // fundo principal
  static const surface    = Color(0xFF161B22); // cards
  static const surfaceAlt = Color(0xFF1C2330); // hover / alt
  static const border     = Color(0xFF30363D); // bordas subtis
  static const accent     = Color(0xFF00C2A8); // verde-azulado
  static const accentDim  = Color(0x2200C2A8); // accent translúcido
  static const primary    = Color(0xFF58A6FF); // azul links/icons
  static const primaryDim = Color(0x1558A6FF);
  static const textPri    = Color(0xFFE6EDF3);
  static const textSec    = Color(0xFF8B949E);
  static const textMuted  = Color(0xFF484F58);
  static const danger     = Color(0xFFF85149);
  static const dangerDim  = Color(0x20F85149);
  static const success    = Color(0xFF3FB950);
  static const warning    = Color(0xFFD29922);
}

class DashboardScreen extends StatefulWidget {
  final String perfil;
  const DashboardScreen({Key? key, required this.perfil}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  List<Projeto> projetos = [];
  bool _loading = true;
  late AnimationController _fabAnim;

  @override
  void initState() {
    super.initState();
    _fabAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadProjetos();
  }

  @override
  void dispose() {
    _fabAnim.dispose();
    super.dispose();
  }
  
  void _loadProjetos() async {
    setState(() => _loading = true);
    List<Projeto> data;
    if (widget.perfil == 'admin') {
      data = await DatabaseHelper.instance.getProjetos();
    } else {
      data = await DatabaseHelper.instance.getProjetosTrabalhador();
    }
    setState(() {
      projetos = data;
      _loading = false;
    });
    _fabAnim.forward(from: 0);
  }

  // ─── DIALOGS ────────────────────────────────────────────

  void _renomearProjeto(Projeto projeto) {
    final nomeC = TextEditingController(text: projeto.nome);
    final descC = TextEditingController(text: projeto.descricao);
    _showDarkDialog(
      icon: Icons.edit_outlined,
      iconColor: _C.primary,
      title: 'Renomear Projeto',
      content: _dialogFields(nomeC: nomeC, descC: descC),
      confirmLabel: 'Guardar',
      confirmColor: _C.primary,
      onConfirm: () async {
        if (nomeC.text.trim().isEmpty) return;
        Navigator.pop(context);
        await DatabaseHelper.instance
            .renomearProjeto(projeto.id!, nomeC.text.trim(), descC.text.trim());
        _loadProjetos();
        Toast.mostrar(context, 'Projeto renomeado!', tipo: ToastTipo.sucesso);
      },
    );
  }

  void _copiarProjeto(Projeto projeto) {
    final nomeC = TextEditingController(text: '${projeto.nome} (cópia)');
    _showDarkDialog(
      icon: Icons.copy_outlined,
      iconColor: _C.accent,
      title: 'Copiar Projeto',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nome do novo projeto:',
              style: TextStyle(fontSize: 13, color: _C.textSec)),
          const SizedBox(height: 8),
          _darkTextField(controller: nomeC, label: 'Nome', icon: Icons.work_outline),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _C.primaryDim,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _C.primary.withOpacity(0.3)),
            ),
            child: Row(children: [
              Icon(Icons.info_outline, color: _C.primary, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Serão copiadas todas as pastas e campos.\nOs registos não são copiados.',
                  style: TextStyle(fontSize: 12, color: _C.primary),
                ),
              ),
            ]),
          ),
        ],
      ),
      confirmLabel: 'Copiar',
      confirmColor: _C.accent,
      onConfirm: () async {
        if (nomeC.text.trim().isEmpty) return;
        Navigator.pop(context);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => Center(
            child: CircularProgressIndicator(color: _C.accent),
          ),
        );
        await DatabaseHelper.instance
            .copiarProjeto(projeto.id!, nomeC.text.trim());
        Navigator.pop(context);
        _loadProjetos();
        Toast.mostrar(context, 'Projeto copiado com sucesso!',
            tipo: ToastTipo.sucesso);
      },
    );
  }

  void _mostrarDialogCriarProjeto() {
    final nomeC = TextEditingController();
    final descC = TextEditingController();
    _showDarkDialog(
      icon: Icons.folder_special_outlined,
      iconColor: _C.accent,
      title: 'Novo Projeto',
      content: _dialogFields(nomeC: nomeC, descC: descC),
      confirmLabel: 'Criar',
      confirmColor: _C.accent,
      onConfirm: () async {
        if (nomeC.text.trim().isEmpty) {
          Toast.mostrar(context, 'O nome é obrigatório!',
              tipo: ToastTipo.aviso);
          return;
        }
        Navigator.pop(context);
        await DatabaseHelper.instance.criarProjeto({
          'nome': nomeC.text.trim(),
          'descricao': descC.text.trim(),
        });
        _loadProjetos();
        Toast.mostrar(context, 'Projeto criado com sucesso!',
            tipo: ToastTipo.sucesso);
      },
    );
  }

  void _confirmarApagarProjeto(Projeto projeto) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          Center(child: CircularProgressIndicator(color: _C.accent)),
    );
    final contagem =
        await DatabaseHelper.instance.getContagemProjeto(projeto.id!);
    Navigator.pop(context);

    final totalNos = contagem['total_nos'] ?? 0;
    final totalRegistos = contagem['total_registos'] ?? 0;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _C.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _C.dangerDim,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.warning_amber_rounded,
                      color: _C.danger, size: 22),
                ),
                const SizedBox(width: 12),
                Text('Apagar Projeto',
                    style: TextStyle(
                        color: _C.danger,
                        fontWeight: FontWeight.w700,
                        fontSize: 17)),
              ]),
              const SizedBox(height: 16),
              Text(
                'Tens a certeza que queres apagar "${projeto.nome}"?',
                style: TextStyle(
                    color: _C.textPri,
                    fontWeight: FontWeight.w600,
                    fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _C.dangerDim,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _C.danger.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Será permanentemente apagado:',
                        style: TextStyle(
                            color: _C.danger,
                            fontWeight: FontWeight.w600,
                            fontSize: 12)),
                    const SizedBox(height: 10),
                    _LinhaContagem(
                        icone: Icons.folder_rounded,
                        cor: _C.primary,
                        texto:
                            '$totalNos pasta${totalNos != 1 ? 's' : ''}'),
                    const SizedBox(height: 6),
                    _LinhaContagem(
                        icone: Icons.assignment_rounded,
                        cor: _C.warning,
                        texto:
                            '$totalRegistos registo${totalRegistos != 1 ? 's' : ''}'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text('Esta ação não pode ser desfeita.',
                  style: TextStyle(color: _C.textMuted, fontSize: 12)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: TextButton.styleFrom(
                      foregroundColor: _C.textSec,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.danger,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Apagar Tudo',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      final sucesso =
          await DatabaseHelper.instance.apagarProjeto(projeto.id!);
      if (sucesso) {
        _loadProjetos();
        Toast.mostrar(context, 'Projeto "${projeto.nome}" apagado.',
            tipo: ToastTipo.erro);
      }
    }
  }

  // ─── HELPERS ────────────────────────────────────────────

  Widget _dialogFields(
      {required TextEditingController nomeC,
      required TextEditingController descC}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _darkTextField(
            controller: nomeC,
            label: 'Nome do Projeto',
            icon: Icons.work_outline),
        const SizedBox(height: 12),
        _darkTextField(
            controller: descC,
            label: 'Descrição',
            icon: Icons.description_outlined,
            maxLines: 2),
      ],
    );
  }

  Widget _darkTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: _C.textPri, fontSize: 14),
      cursorColor: _C.accent,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _C.textSec, fontSize: 13),
        prefixIcon: Icon(icon, color: _C.textSec, size: 18),
        filled: true,
        fillColor: _C.surfaceAlt,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _C.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _C.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _C.accent, width: 1.5),
        ),
      ),
    );
  }

  void _showDarkDialog({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget content,
    required String confirmLabel,
    required Color confirmColor,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _C.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(title,
                    style: TextStyle(
                        color: _C.textPri,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
              ]),
              const SizedBox(height: 20),
              content,
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: _C.textSec,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: confirmColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: onConfirm,
                    child: Text(confirmLabel,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── BUILD ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.perfil == 'admin';

    return Scaffold(
      backgroundColor: _C.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── AppBar
          SliverAppBar(
            expandedHeight: 130,
            pinned: true,
            backgroundColor: _C.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: _C.border),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.only(left: 20, bottom: 16),
              title: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Logo mark
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_C.accent, _C.primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.verified_rounded,
                        color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAdmin ? 'Os Meus Projetos' : 'Meus Projetos',
                        style: TextStyle(
                          color: _C.textPri,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        isAdmin ? 'Administrador' : 'Trabalhador',
                        style: TextStyle(
                          color: _C.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              background: Container(
                decoration: BoxDecoration(
                  color: _C.surface,
                ),
                child: Stack(
                  children: [
                    // Decorative grid lines
                    Positioned.fill(
                      child: CustomPaint(painter: _GridPainter()),
                    ),
                    // Accent glow top-right
                    Positioned(
                      top: -30,
                      right: -30,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            _C.accent.withOpacity(0.12),
                            Colors.transparent,
                          ]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.logout_rounded, color: _C.textSec, size: 20),
                tooltip: 'Sair',
                onPressed: () async {
                  await Session.logout();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const LoginScreen()),
                  );
                },
              ),
              const SizedBox(width: 4),
            ],
          ),

          // ── Contador de projetos
          if (!_loading)
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(20, 20, 20, 4),
                child: Row(
                  children: [
                    Text(
                      '${projetos.length} projeto${projetos.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        color: _C.textSec,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (isAdmin)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _C.accentDim,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: _C.accent.withOpacity(0.4)),
                        ),
                        child: Row(children: [
                          Icon(Icons.shield_outlined,
                              color: _C.accent, size: 13),
                          const SizedBox(width: 5),
                          Text('Admin',
                              style: TextStyle(
                                  color: _C.accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ]),
                      ),
                  ],
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
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        color: _C.accent,
                        strokeWidth: 2.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('A carregar projetos...',
                        style: TextStyle(
                            color: _C.textSec, fontSize: 13)),
                  ],
                ),
              ),
            )

          // ── Empty state
          else if (projetos.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _C.surfaceAlt,
                        shape: BoxShape.circle,
                        border: Border.all(color: _C.border),
                      ),
                      child: Icon(Icons.work_off_outlined,
                          size: 36, color: _C.textMuted),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Nenhum projeto encontrado',
                      style: TextStyle(
                        color: _C.textPri,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isAdmin
                          ? 'Clica no + para criar o primeiro projeto.'
                          : 'Ainda não foste adicionado a nenhum projeto.',
                      style: TextStyle(
                          color: _C.textSec,
                          fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )

          // ── Lista de projetos
          else
            SliverPadding(
              padding:
                  const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final projeto = projetos[index];
                    return _ProjetoCard(
                      projeto: projeto,
                      isAdmin: isAdmin,
                      index: index,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NosScreen(
                              projeto: projeto,
                              perfil: widget.perfil),
                        ),
                      ).then((_) => _loadProjetos()),
                      onRenomear: () => _renomearProjeto(projeto),
                      onCopiar: () => _copiarProjeto(projeto),
                      onApagar: () =>
                          _confirmarApagarProjeto(projeto),
                    );
                  },
                  childCount: projetos.length,
                ),
              ),
            ),
        ],
      ),

      // ── FAB
      floatingActionButton: isAdmin
          ? ScaleTransition(
              scale: CurvedAnimation(
                  parent: _fabAnim, curve: Curves.elasticOut),
              child: FloatingActionButton.extended(
                onPressed: _mostrarDialogCriarProjeto,
                backgroundColor: _C.accent,
                foregroundColor: Colors.white,
                elevation: 4,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Novo Projeto',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            )
          : null,
    );
  }
}

// ─── CARD DE PROJETO ─────────────────────────────────────

class _ProjetoCard extends StatefulWidget {
  final Projeto projeto;
  final bool isAdmin;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onRenomear;
  final VoidCallback onCopiar;
  final VoidCallback onApagar;

  const _ProjetoCard({
    required this.projeto,
    required this.isAdmin,
    required this.index,
    required this.onTap,
    required this.onRenomear,
    required this.onCopiar,
    required this.onApagar,
  });

  @override
  State<_ProjetoCard> createState() => _ProjetoCardState();
}

class _ProjetoCardState extends State<_ProjetoCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  bool _hovered = false;

  // Cor do avatar baseada no índice
  static const _avatarGradients = [
    [Color(0xFF00C2A8), Color(0xFF0097A7)],
    [Color(0xFF58A6FF), Color(0xFF1565C0)],
    [Color(0xFFD29922), Color(0xFFE65100)],
    [Color(0xFF3FB950), Color(0xFF1B5E20)],
    [Color(0xFFF85149), Color(0xFF880E4F)],
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 350 + widget.index * 60),
    );
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: widget.index * 60), () {
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
    final colors = _avatarGradients[widget.index % _avatarGradients.length];
    final inicial = widget.projeto.nome[0].toUpperCase();

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: MouseRegion(
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                color: _hovered ? _C.surfaceAlt : _C.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _hovered
                      ? _C.accent.withOpacity(0.35)
                      : _C.border,
                  width: 1,
                ),
                boxShadow: _hovered
                    ? [
                        BoxShadow(
                          color: _C.accent.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  splashColor: _C.accent.withOpacity(0.06),
                  highlightColor: Colors.transparent,
                  onTap: widget.onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 13),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: colors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Center(
                            child: Text(
                              inicial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.projeto.nome,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: _C.textPri,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              if (widget.projeto.descricao.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  widget.projeto.descricao,
                                  style: TextStyle(
                                      color: _C.textSec, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Admin menu
                        if (widget.isAdmin)
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_horiz_rounded,
                                color: _C.textMuted, size: 20),
                            color: _C.surfaceAlt,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: _C.border),
                            ),
                            onSelected: (valor) {
                              switch (valor) {
                                case 'renomear':
                                  widget.onRenomear();
                                  break;
                                case 'copiar':
                                  widget.onCopiar();
                                  break;
                                case 'apagar':
                                  widget.onApagar();
                                  break;
                               case 'membros':
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => GerirMembrosScreen(projeto: widget.projeto)),
  );
  break;
                              }
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'renomear',
                                child: Row(children: [
                                  Icon(Icons.edit_outlined,
                                      color: _C.primary, size: 17),
                                  const SizedBox(width: 10),
                                  Text('Renomear',
                                      style: TextStyle(
                                          color: _C.textPri,
                                          fontSize: 14)),
                                ]),
                              ),
                              const PopupMenuItem(
  value: 'membros',
  child: Row(children: [
    Icon(Icons.group_outlined, color: Color(0xFF4527A0), size: 20),
    SizedBox(width: 10),
    Text('Gerir Membros'),
  ]),
),
                              PopupMenuItem(
                                value: 'copiar',
                                child: Row(children: [
                                  Icon(Icons.copy_outlined,
                                      color: _C.accent, size: 17),
                                  const SizedBox(width: 10),
                                  Text('Copiar Projeto',
                                      style: TextStyle(
                                          color: _C.textPri,
                                          fontSize: 14)),
                                ]),
                              ),
                              const PopupMenuDivider(),
                              PopupMenuItem(
                                value: 'apagar',
                                child: Row(children: [
                                  Icon(Icons.delete_outline,
                                      color: _C.danger, size: 17),
                                  const SizedBox(width: 10),
                                  Text('Apagar',
                                      style: TextStyle(
                                          color: _C.danger,
                                          fontSize: 14)),
                                ]),
                              ),
                            ],
                          ),

                        Icon(Icons.chevron_right_rounded,
                            color: _C.textMuted, size: 20),
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

// ─── WIDGET: LINHA DE CONTAGEM ───────────────────────────

class _LinhaContagem extends StatelessWidget {
  final IconData icone;
  final Color cor;
  final String texto;

  const _LinhaContagem(
      {required this.icone, required this.cor, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icone, size: 16, color: cor),
        const SizedBox(width: 8),
        Text(texto,
            style: TextStyle(
                color: cor,
                fontWeight: FontWeight.w600,
                fontSize: 13)),
      ],
    );
  }
}

// ─── CUSTOM PAINTER: GRID DECORATIVO ─────────────────────

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