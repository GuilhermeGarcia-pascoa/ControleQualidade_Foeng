import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/models.dart';
import 'nos_screen.dart';
import '../utils/toast.dart';
import '../utils/session.dart';
import 'gerir_membros_screen.dart';
import '../theme/app_theme.dart';
import 'admin_panel_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String perfil;
  const DashboardScreen({Key? key, required this.perfil}) : super(key: key);
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Projeto> projetos = [];
  List<Projeto> _projetosFiltrados = [];
  List<NoPartilhado> _nosPartilhados = [];
  List<NoPartilhado> _nosPartilhadosFiltrados = [];
  bool _loading = true;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearch);
    _loadDados();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final texto = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _projetosFiltrados = texto.isEmpty
          ? List.from(projetos)
          : projetos.where((p) =>
              p.nome.toLowerCase().contains(texto) ||
              p.descricao.toLowerCase().contains(texto)).toList();
      _nosPartilhadosFiltrados = texto.isEmpty
          ? List.from(_nosPartilhados)
          : _nosPartilhados.where((n) =>
              n.nome.toLowerCase().contains(texto) ||
              n.projetoNome.toLowerCase().contains(texto)).toList();
    });
  }

  Future<void> _loadDados() async {
    setState(() => _loading = true);
    final canManageProjects =
        widget.perfil == 'admin' || widget.perfil == 'gestor';
    try {
      final projetosData = canManageProjects
          ? await DatabaseHelper.instance.getProjetos()
          : await DatabaseHelper.instance.getProjetosTrabalhador();

      List<NoPartilhado> partilhados = [];
      if (!canManageProjects) {
        try {
          partilhados = await DatabaseHelper.instance.getNosPartilhados();
        } catch (_) {
          if (mounted) {
            Toast.mostrar(
              context,
              'Nao foi possivel carregar as pastas partilhadas.',
              tipo: ToastTipo.aviso,
            );
          }
        }
      }

      if (!mounted) return;
      setState(() {
        projetos = projetosData;
        _projetosFiltrados = List.from(projetosData);
        _nosPartilhados = partilhados;
        _nosPartilhadosFiltrados = List.from(partilhados);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        projetos = [];
        _projetosFiltrados = [];
        _nosPartilhados = [];
        _nosPartilhadosFiltrados = [];
        _loading = false;
      });
      Toast.mostrar(
        context,
        'Nao foi possivel carregar o dashboard.',
        tipo: ToastTipo.erro,
      );
    }
  }

  void _renomearProjeto(Projeto projeto) {
    final nomeC = TextEditingController(text: projeto.nome);
    final descC = TextEditingController(text: projeto.descricao);
    _showFormDialog(
      title: 'Editar Projeto',
      icon: Icons.edit_outlined,
      fields: [
        _DialogField(controller: nomeC, label: 'Nome do projeto'),
        _DialogField(controller: descC, label: 'Descrição', optional: true),
      ],
      onConfirm: () async {
        if (nomeC.text.trim().isEmpty) return;
        await DatabaseHelper.instance.renomearProjeto(
            projeto.id!, nomeC.text.trim(), descC.text.trim());
        _loadDados();
        if (mounted) Toast.mostrar(context, 'Projeto atualizado!', tipo: ToastTipo.sucesso);
      },
    );
  }

  void _copiarProjeto(Projeto projeto) {
    final nomeC = TextEditingController(text: '${projeto.nome} (cópia)');
    _showFormDialog(
      title: 'Duplicar Projeto',
      icon: Icons.copy_rounded,
      fields: [_DialogField(controller: nomeC, label: 'Nome da cópia')],
      onConfirm: () async {
        if (nomeC.text.trim().isEmpty) return;
        await DatabaseHelper.instance.copiarProjeto(projeto.id!, nomeC.text.trim());
        _loadDados();
        if (mounted) Toast.mostrar(context, 'Projeto duplicado!', tipo: ToastTipo.sucesso);
      },
    );
  }

  void _mostrarDialogCriarProjeto() {
    final nomeC = TextEditingController();
    final descC = TextEditingController();
    _showFormDialog(
      title: 'Novo Projeto',
      icon: Icons.add_rounded,
      fields: [
        _DialogField(controller: nomeC, label: 'Nome do projeto'),
        _DialogField(controller: descC, label: 'Descrição', optional: true),
      ],
      onConfirm: () async {
        if (nomeC.text.trim().isEmpty) return;
        await DatabaseHelper.instance.criarProjeto({
          'nome': nomeC.text.trim(),
          'descricao': descC.text.trim(),
        });
        _loadDados();
        if (mounted) Toast.mostrar(context, 'Projeto criado!', tipo: ToastTipo.sucesso);
      },
    );
  }

  void _showFormDialog({
    required String title,
    required IconData icon,
    required List<_DialogField> fields,
    required VoidCallback onConfirm,
  }) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.accentBluePale,
                    borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: AppTheme.accentBlue, size: 18),
                ),
                const SizedBox(width: 12),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 20),
              for (final f in fields) ...[
                TextField(
                  controller: f.controller,
                  decoration: InputDecoration(
                    labelText: f.label + (f.optional ? ' (opcional)' : ''),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () { Navigator.pop(ctx); onConfirm(); },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Confirmar'),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmarApagarProjeto(Projeto projeto) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.errorPale,
                  borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 24),
              ),
              const SizedBox(height: 16),
              const Text('Apagar projeto?',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('Esta ação remove permanentemente "${projeto.nome}" e todos os seus dados.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppTheme.neutral500, height: 1.5)),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.error,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Apagar', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
    if (confirm == true) {
      final sucesso = await DatabaseHelper.instance.apagarProjeto(projeto.id!);
      if (!mounted) return;
      if (sucesso) {
        _loadDados();
        Toast.mostrar(context, 'Projeto eliminado.', tipo: ToastTipo.sucesso);
      } else {
        Toast.mostrar(context, 'Erro ao eliminar.', tipo: ToastTipo.erro);
      }
    }
  }

  void _confirmarLogout() async {
    Navigator.of(context).pop();
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 52, height: 52,
              decoration: BoxDecoration(color: AppTheme.neutral100, borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.logout_rounded, color: AppTheme.neutral700, size: 24)),
            const SizedBox(height: 16),
            const Text('Terminar sessão?',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Vai ser redirecionado para o ecrã de login.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppTheme.neutral500)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx, false),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text('Cancelar'))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text('Sair'))),
            ]),
          ]),
        ),
      ),
    );
    if (confirm == true && mounted) {
      await Session.logout();
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true)
          .pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAdmin = widget.perfil == 'admin';
    final canManageProjects = isAdmin || widget.perfil == 'gestor';
    final total = _projetosFiltrados.length + _nosPartilhadosFiltrados.length;

    return Scaffold(
      drawer: _buildDrawer(context, isDark),
      body: RefreshIndicator(
        onRefresh: _loadDados,
        color: AppTheme.accentBlue,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ─── HEADER ────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 160,
              floating: false,
              pinned: true,
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: isDark ? AppTheme.darkSurfaceRaised : Colors.white,
              leading: Builder(
                builder: (ctx) => IconButton(
                  icon: Icon(Icons.menu_rounded,
                    color: isDark ? const Color(0xFFCBD5E1) : AppTheme.neutral800),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.accentBlue.withOpacity(0.12),
                    child: Text(widget.perfil[0].toUpperCase(),
                      style: const TextStyle(color: AppTheme.accentBlue,
                        fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsetsDirectional.only(start: 20, bottom: 16),
                title: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dashboard',
                      style: TextStyle(
                        color: isDark ? const Color(0xFFE2E8F0) : AppTheme.neutral900,
                        fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                    if (!_loading)
                      Text('$total ${total == 1 ? 'projeto' : 'projetos'}',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF64748B) : AppTheme.neutral400,
                          fontSize: 12, fontWeight: FontWeight.w400)),
                  ],
                ),
                background: Container(
                  color: isDark ? AppTheme.darkSurfaceRaised : Colors.white),
              ),
            ),

            // ─── SEARCH ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                color: isDark ? AppTheme.darkSurfaceRaised : Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : AppTheme.neutral50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppTheme.darkBorder : AppTheme.neutral200),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    style: TextStyle(
                      color: isDark ? const Color(0xFFE2E8F0) : AppTheme.neutral900,
                      fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Pesquisar projetos...',
                      hintStyle: const TextStyle(color: AppTheme.neutral400, fontSize: 14),
                      prefixIcon: const Icon(Icons.search_rounded,
                        color: AppTheme.neutral400, size: 20),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded,
                                color: AppTheme.neutral400, size: 18),
                              onPressed: () { _searchCtrl.clear(); })
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 12),
                      filled: false,
                    ),
                  ),
                ),
              ),
            ),

            // ─── DIVIDER ────────────────────────────────────────────
            SliverToBoxAdapter(child: Divider(height: 1,
              color: isDark ? AppTheme.darkBorder : AppTheme.neutral100)),

            // ─── CONTENT ────────────────────────────────────────────
            if (_loading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.accentBlue)),
              )
            else if (canManageProjects) ...[
              if (_projetosFiltrados.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: _searchCtrl.text.isEmpty
                        ? 'Nenhum projeto ainda'
                        : 'Sem resultados',
                    subtitle: _searchCtrl.text.isEmpty
                        ? 'Crie o seu primeiro projeto para começar'
                        : 'Tente uma pesquisa diferente',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _ProjectCard(
                        projeto: _projetosFiltrados[i],
                        isAdmin: true,
                        onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => NosScreen(
                            projeto: _projetosFiltrados[i], perfil: widget.perfil)))
                              .then((_) => _loadDados()),
                        onRename: () => _renomearProjeto(_projetosFiltrados[i]),
                        onDuplicate: () => _copiarProjeto(_projetosFiltrados[i]),
                        onDelete: () => _confirmarApagarProjeto(_projetosFiltrados[i]),
                        onMembers: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => GerirMembrosScreen(
                            projeto: _projetosFiltrados[i]))),
                      ),
                      childCount: _projetosFiltrados.length,
                    ),
                  ),
                ),
            ] else ...[
              if (_projetosFiltrados.isNotEmpty) ...[
                SliverToBoxAdapter(child: _SectionHeader(label: 'Os meus projetos',
                  count: _projetosFiltrados.length)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _ProjectCard(
                        projeto: _projetosFiltrados[i],
                        isAdmin: false,
                        onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => NosScreen(
                            projeto: _projetosFiltrados[i], perfil: widget.perfil)))
                              .then((_) => _loadDados()),
                      ),
                      childCount: _projetosFiltrados.length,
                    ),
                  ),
                ),
              ],
              SliverToBoxAdapter(
                child: _SectionHeader(
                  label: 'Partilhado comigo',
                  count: _nosPartilhadosFiltrados.length,
                ),
              ),
              if (_nosPartilhadosFiltrados.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _SharedFolderCard(
                        no: _nosPartilhadosFiltrados[i],
                        onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => NosScreen(
                            projeto: _nosPartilhadosFiltrados[i].toProjeto(),
                            perfil: widget.perfil,
                            pai: _nosPartilhadosFiltrados[i].toNo(),
                            breadcrumb: [_nosPartilhadosFiltrados[i].projetoNome,
                              ..._nosPartilhadosFiltrados[i].breadcrumb],
                          ))).then((_) => _loadDados()),
                      ),
                      childCount: _nosPartilhadosFiltrados.length,
                    ),
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    child: _SharedFoldersEmptyCard(
                      hasSearch: _searchCtrl.text.isNotEmpty,
                    ),
                  ),
                ),
              if (_projetosFiltrados.isEmpty && _nosPartilhadosFiltrados.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(
                    icon: Icons.folder_off_outlined,
                    title: 'Nenhum conteúdo',
                    subtitle: 'Ainda não foram partilhados projetos consigo',
                  ),
                ),
            ],
          ],
        ),
      ),
      floatingActionButton: canManageProjects
          ? FloatingActionButton.extended(
              onPressed: _mostrarDialogCriarProjeto,
              backgroundColor: AppTheme.accentBlue,
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Novo Projeto',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            )
          : null,
    );
  }

  Widget _buildDrawer(BuildContext context, bool isDark) {
    final isAdmin = widget.perfil == 'admin';
    return Drawer(
      backgroundColor: isDark ? AppTheme.darkSurfaceRaised : Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.accentBlue,
                    borderRadius: BorderRadius.circular(14)),
                  child: const Center(child: Text('F',
                    style: TextStyle(color: Colors.white, fontSize: 22,
                      fontWeight: FontWeight.w700))),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('FOENG CQ',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.3)),
                    Text(widget.perfil,
                      style: const TextStyle(color: AppTheme.neutral400,
                        fontSize: 12, letterSpacing: 0.2)),
                  ],
                )),
              ]),
            ),
            Divider(height: 1, color: isDark ? AppTheme.darkBorder : AppTheme.neutral100),
            const SizedBox(height: 8),

            // Theme toggle
            ValueListenableBuilder<ThemeMode>(
              valueListenable: AppTheme.themeMode,
              builder: (ctx, mode, _) {
                final isDark = mode == ThemeMode.dark;
                return _DrawerItem(
                  icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  label: isDark ? 'Modo claro' : 'Modo escuro',
                  onTap: () {
                    Navigator.pop(ctx);
                    AppTheme.changeTheme(!isDark);
                  },
                );
              },
            ),

            if (isAdmin) ...[
              const SizedBox(height: 4),
              Divider(height: 1, color: isDark ? AppTheme.darkBorder : AppTheme.neutral100),
              const SizedBox(height: 4),
              _DrawerItem(
                icon: Icons.shield_outlined,
                label: 'Painel de administração',
                accent: true,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const AdminPanelScreen()));
                },
              ),
            ],

            const Spacer(),
            Divider(height: 1, color: isDark ? AppTheme.darkBorder : AppTheme.neutral100),
            const SizedBox(height: 4),
            _DrawerItem(
              icon: Icons.logout_rounded,
              label: 'Terminar sessão',
              danger: true,
              onTap: _confirmarLogout,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool accent;
  final bool danger;

  const _DrawerItem({
    required this.icon, required this.label, required this.onTap,
    this.accent = false, this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppTheme.error
        : accent ? AppTheme.accentBlue
        : null;
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 20, color: color),
      title: Text(label,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;
  const _SectionHeader({required this.label, required this.count});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Text(label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600,
              color: AppTheme.neutral400, letterSpacing: 0.8)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.neutral100,
              borderRadius: BorderRadius.circular(20)),
            child: Text('$count',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                color: AppTheme.neutral500)),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState({required this.icon, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurfaceHigh : AppTheme.neutral100,
                borderRadius: BorderRadius.circular(20)),
              child: Icon(icon, size: 32,
                color: isDark ? AppTheme.neutral500 : AppTheme.neutral400),
            ),
            const SizedBox(height: 16),
            Text(title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppTheme.neutral400, height: 1.5)),
          ],
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final Projeto projeto;
  final bool isAdmin;
  final VoidCallback onTap;
  final VoidCallback? onRename;
  final VoidCallback? onDuplicate;
  final VoidCallback? onDelete;
  final VoidCallback? onMembers;

  const _ProjectCard({
    required this.projeto, required this.isAdmin, required this.onTap,
    this.onRename, this.onDuplicate, this.onDelete, this.onMembers,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceRaised : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.neutral200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            // Icon
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppTheme.accentBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.inventory_2_outlined,
                color: AppTheme.accentBlue, size: 20),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(projeto.nome,
                  style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 15,
                    color: isDark ? const Color(0xFFE2E8F0) : AppTheme.neutral900),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                if (projeto.donoNome != null && projeto.donoNome!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text('Dono: ${projeto.donoNome}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.neutral500),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
                if (projeto.descricao.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(projeto.descricao,
                    style: const TextStyle(fontSize: 12, color: AppTheme.neutral400),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ],
            )),
            const SizedBox(width: 8),
            // Action
            if (isAdmin)
              PopupMenuButton<String>(
                icon: Icon(Icons.more_horiz_rounded, size: 20,
                  color: isDark ? AppTheme.neutral500 : AppTheme.neutral400),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (v) {
                  if (v == 'rename') onRename?.call();
                  if (v == 'members') onMembers?.call();
                  if (v == 'duplicate') onDuplicate?.call();
                  if (v == 'delete') onDelete?.call();
                },
                itemBuilder: (_) => [
                  _menuItem('rename', Icons.edit_outlined, 'Editar'),
                  _menuItem('members', Icons.group_outlined, 'Membros'),
                  _menuItem('duplicate', Icons.copy_outlined, 'Duplicar'),
                  const PopupMenuDivider(),
                  _menuItem('delete', Icons.delete_outline_rounded, 'Apagar', danger: true),
                ],
              )
            else
              const Icon(Icons.chevron_right_rounded, color: AppTheme.neutral300),
          ]),
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label,
      {bool danger = false}) {
    final color = danger ? AppTheme.error : null;
    return PopupMenuItem(
      value: value,
      child: Row(children: [
        Icon(icon, size: 16, color: color ?? AppTheme.neutral600),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: 14, color: color)),
      ]),
    );
  }
}

class _SharedFolderCard extends StatelessWidget {
  final NoPartilhado no;
  final VoidCallback onTap;
  const _SharedFolderCard({required this.no, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final path = no.breadcrumb.isNotEmpty
        ? '${no.projetoNome} › ${no.breadcrumb.join(' › ')}'
        : no.projetoNome;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceRaised : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF0D4C7A) : AppTheme.accentBlue.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppTheme.accentTeal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.folder_shared_outlined,
                color: AppTheme.accentTeal, size: 20)),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(no.nome,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15,
                    color: isDark ? const Color(0xFFE2E8F0) : AppTheme.neutral900),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(path,
                  style: const TextStyle(fontSize: 11, color: AppTheme.neutral400),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            )),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.neutral300),
          ]),
        ),
      ),
    );
  }
}

class _SharedFoldersEmptyCard extends StatelessWidget {
  final bool hasSearch;

  const _SharedFoldersEmptyCard({required this.hasSearch});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceRaised : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.neutral200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.accentTeal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.folder_shared_outlined,
                color: AppTheme.accentTeal,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasSearch
                        ? 'Nenhuma pasta encontrada'
                        : 'Nenhuma pasta partilhada',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color:
                          isDark ? const Color(0xFFE2E8F0) : AppTheme.neutral900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    hasSearch
                        ? 'Tente alterar o texto da pesquisa.'
                        : 'Quando alguem partilhar uma pasta consigo, ela aparece aqui.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.neutral400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogField {
  final TextEditingController controller;
  final String label;
  final bool optional;
  const _DialogField({required this.controller, required this.label, this.optional = false});
}
