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
          : projetos
              .where((p) =>
                  p.nome.toLowerCase().contains(texto) ||
                  p.descricao.toLowerCase().contains(texto))
              .toList();

      _nosPartilhadosFiltrados = texto.isEmpty
          ? List.from(_nosPartilhados)
          : _nosPartilhados
              .where((n) =>
                  n.nome.toLowerCase().contains(texto) ||
                  n.projetoNome.toLowerCase().contains(texto))
              .toList();
    });
  }

  Future<void> _loadDados() async {
    setState(() => _loading = true);
    final isAdmin = widget.perfil == 'admin';

    final projetosData = isAdmin
        ? await DatabaseHelper.instance.getProjetos()
        : await DatabaseHelper.instance.getProjetosTrabalhador();

    final partilhados = !isAdmin
        ? await DatabaseHelper.instance.getNosPartilhados()
        : <NoPartilhado>[];

    if (!mounted) return;

    setState(() {
      projetos = projetosData;
      _projetosFiltrados = List.from(projetosData);
      _nosPartilhados = partilhados;
      _nosPartilhadosFiltrados = List.from(partilhados);
      _loading = false;
    });
  }

  // ─── LÓGICA DE GESTÃO ────────────────────────────────────────

  void _renomearProjeto(Projeto projeto) {
    final nomeC = TextEditingController(text: projeto.nome);
    final descC = TextEditingController(text: projeto.descricao);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Projeto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nomeC,
                decoration: const InputDecoration(labelText: 'Nome')),
            const SizedBox(height: 8),
            TextField(
                controller: descC,
                decoration: const InputDecoration(labelText: 'Descrição')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nomeC.text.trim().isEmpty) return;
              Navigator.pop(context);
              await DatabaseHelper.instance.renomearProjeto(
                  projeto.id!, nomeC.text.trim(), descC.text.trim());
              _loadDados();
              if (mounted) {
                Toast.mostrar(context, 'Projeto atualizado!',
                    tipo: ToastTipo.sucesso);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _copiarProjeto(Projeto projeto) {
    final nomeC = TextEditingController(text: '${projeto.nome} (cópia)');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Copiar Projeto'),
        content: TextField(
            controller: nomeC,
            decoration: const InputDecoration(labelText: 'Nome da cópia')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nomeC.text.trim().isEmpty) return;
              Navigator.pop(context);
              await DatabaseHelper.instance
                  .copiarProjeto(projeto.id!, nomeC.text.trim());
              _loadDados();
              if (mounted) {
                Toast.mostrar(context, 'Projeto copiado!',
                    tipo: ToastTipo.sucesso);
              }
            },
            child: const Text('Copiar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogCriarProjeto() {
    final nomeC = TextEditingController();
    final descC = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Novo Projeto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nomeC,
                decoration:
                    const InputDecoration(labelText: 'Nome do Projeto')),
            const SizedBox(height: 8),
            TextField(
                controller: descC,
                decoration: const InputDecoration(labelText: 'Descrição')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nomeC.text.trim().isEmpty) return;
              Navigator.pop(context);
              await DatabaseHelper.instance.criarProjeto({
                'nome': nomeC.text.trim(),
                'descricao': descC.text.trim(),
              });
              _loadDados();
              if (mounted) {
                Toast.mostrar(context, 'Projeto criado!',
                    tipo: ToastTipo.sucesso);
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }

  void _confirmarApagarProjeto(Projeto projeto) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar Projeto'),
        content: Text(
            'Tens a certeza que queres apagar "${projeto.nome}"? Esta ação removerá todas as pastas e dados contidos.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Apagar',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final sucesso =
          await DatabaseHelper.instance.apagarProjeto(projeto.id!);
      if (!mounted) return;
      if (sucesso) {
        _loadDados();
        Toast.mostrar(context, 'Projeto eliminado.', tipo: ToastTipo.sucesso);
      } else {
        Toast.mostrar(context, 'Erro ao eliminar projeto.',
            tipo: ToastTipo.erro);
      }
    }
  }

  // ─── LOGOUT ──────────────────────────────────────────────────
  // CORRIGIDO: fecha o drawer primeiro, espera a animação e só depois
  // mostra o diálogo usando o context raiz do widget (não o do drawer).
  void _confirmarLogout() async {
    // 1. Fecha o drawer
    Navigator.of(context).pop();

    // 2. Aguarda a animação de fecho do drawer
    await Future.delayed(const Duration(milliseconds: 300));

    // 3. Verifica se o widget ainda está montado
    if (!mounted) return;

    // 4. Mostra o diálogo usando o context do widget (não do drawer)
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Terminar Sessão'),
        content: const Text('Tens a certeza que queres sair?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Sair', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    // 5. Se confirmado, faz logout e navega para o ecrã inicial
    if (confirm == true && mounted) {
      await Session.logout();
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true)
          .pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  // ─── INTERFACE ───────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAdmin = widget.perfil == 'admin';

    return Scaffold(
      drawer: _buildDrawer(context),
      body: RefreshIndicator(
        onRefresh: _loadDados,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ─── APP BAR ─────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 140.0,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: colorScheme.surface,
              leading: Builder(
                builder: (context) => IconButton(
                  icon: Icon(Icons.menu, color: colorScheme.onSurface),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding:
                    const EdgeInsetsDirectional.only(start: 16, bottom: 16),
                title: Text(
                  "Dashboard",
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                background: Container(color: colorScheme.surface),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: CircleAvatar(
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(widget.perfil[0].toUpperCase(),
                        style: TextStyle(
                            color: colorScheme.onPrimaryContainer)),
                  ),
                ),
              ],
            ),

            // ─── BARRA DE PESQUISA ────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SearchBar(
                  controller: _searchCtrl,
                  hintText: "Procurar projeto ou pasta...",
                  leading: Icon(Icons.search, color: colorScheme.primary),
                  elevation: WidgetStateProperty.all(0.5),
                  backgroundColor: WidgetStateProperty.all(
                      colorScheme.surfaceContainerHighest.withOpacity(0.3)),
                  shape: WidgetStateProperty.all(RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
                ),
              ),
            ),

            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (isAdmin) ...[
              // ─── ADMIN: PROJETOS ─────────────────────────────────
              if (_projetosFiltrados.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text('Nenhum projeto encontrado.',
                        style: TextStyle(color: Colors.grey)),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(
                      left: 16, right: 16, top: 8, bottom: 80),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildProjectCard(
                          _projetosFiltrados[index], isAdmin, colorScheme),
                      childCount: _projetosFiltrados.length,
                    ),
                  ),
                ),
            ] else ...[
              // ─── TRABALHADOR: PROJETOS + PASTAS PARTILHADAS ──────

              if (_projetosFiltrados.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text('Projetos',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurfaceVariant)),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildProjectCard(
                          _projetosFiltrados[index], false, colorScheme),
                      childCount: _projetosFiltrados.length,
                    ),
                  ),
                ),
              ],

              if (_nosPartilhadosFiltrados.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text('Pastas partilhadas',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurfaceVariant)),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.only(
                      left: 16, right: 16, bottom: 80),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildSharedFolderCard(
                          _nosPartilhadosFiltrados[index], colorScheme),
                      childCount: _nosPartilhadosFiltrados.length,
                    ),
                  ),
                ),
              ],

              if (_projetosFiltrados.isEmpty &&
                  _nosPartilhadosFiltrados.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text('Nenhum conteúdo partilhado.',
                        style: TextStyle(color: Colors.grey)),
                  ),
                ),
            ],
          ],
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: _mostrarDialogCriarProjeto,
              icon: const Icon(Icons.add),
              label: const Text("Novo Projeto"),
            )
          : null,
    );
  }

  // ─── CARD DE PASTA PARTILHADA ─────────────────────────────
  Widget _buildSharedFolderCard(
      NoPartilhado no, ColorScheme colorScheme) {
    final caminhoTexto =
        no.breadcrumb.isNotEmpty ? no.breadcrumb.join(' › ') : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.primary.withOpacity(0.25)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NosScreen(
              projeto: no.toProjeto(),
              perfil: widget.perfil,
              pai: no.toNo(),
              breadcrumb: [no.projetoNome, ...no.breadcrumb],
            ),
          ),
        ).then((_) => _loadDados()),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.folder_shared_rounded,
                      color: colorScheme.primary, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      no.nome,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      caminhoTexto.isNotEmpty
                          ? '${no.projetoNome} › $caminhoTexto'
                          : no.projetoNome,
                      style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: colorScheme.outline, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ─── CARD DE PROJETO ──────────────────────────────────────
  Widget _buildProjectCard(
      Projeto projeto, bool isAdmin, ColorScheme colorScheme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => NosScreen(
                        projeto: projeto, perfil: widget.perfil)))
            .then((_) => _loadDados()),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.inventory_2_rounded,
                      color: colorScheme.primary, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      projeto.nome,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (projeto.descricao.isNotEmpty)
                      Text(
                        projeto.descricao,
                        style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (isAdmin)
                SizedBox(
                  width: 32,
                  height: 32,
                  child: PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.more_vert,
                        size: 18, color: colorScheme.onSurfaceVariant),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    onSelected: (valor) {
                      if (valor == 'renomear') _renomearProjeto(projeto);
                      if (valor == 'copiar') _copiarProjeto(projeto);
                      if (valor == 'apagar') {
                        _confirmarApagarProjeto(projeto);
                      }
                      if (valor == 'membros') {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    GerirMembrosScreen(projeto: projeto)));
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                          value: 'renomear',
                          child: Row(children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Editar')
                          ])),
                      const PopupMenuItem(
                          value: 'membros',
                          child: Row(children: [
                            Icon(Icons.group_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Membros')
                          ])),
                      const PopupMenuItem(
                          value: 'copiar',
                          child: Row(children: [
                            Icon(Icons.copy_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('Duplicar')
                          ])),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                          value: 'apagar',
                          child: Row(children: [
                            Icon(Icons.delete_outline,
                                color: Colors.red, size: 18),
                            SizedBox(width: 8),
                            Text('Apagar',
                                style: TextStyle(color: Colors.red))
                          ])),
                    ],
                  ),
                )
              else
                Icon(Icons.chevron_right,
                    color: colorScheme.outline, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ─── DRAWER ───────────────────────────────────────────────
  Widget _buildDrawer(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isAdmin = widget.perfil == 'admin';

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: colorScheme.primary),
            currentAccountPicture: CircleAvatar(
              backgroundColor: colorScheme.onPrimary,
              child: Icon(Icons.person,
                  color: colorScheme.primary, size: 40),
            ),
            accountName: Text(widget.perfil.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: const Text("Controle de Qualidade"),
          ),

          // ── Tema ──────────────────────────────────────────
          ValueListenableBuilder<ThemeMode>(
            valueListenable: AppTheme.themeMode,
            builder: (context, mode, _) {
              final isDark = mode == ThemeMode.dark;
              return ListTile(
                leading: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                title: Text(isDark ? "Modo Claro" : "Modo Escuro"),
                onTap: () {
                  Navigator.of(context).pop();
                  AppTheme.changeTheme(!isDark);
                },
              );
            },
          ),

          // ── Painel Admin (só visível para admins) ─────────
          if (isAdmin) ...[
            const Divider(height: 1),
            ListTile(
              leading: Icon(
                Icons.admin_panel_settings_rounded,
                color: colorScheme.primary,
              ),
              title: Text(
                'Painel Admin',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text(
                'Gerir utilizadores',
                style: TextStyle(fontSize: 12),
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: colorScheme.primary,
                size: 20,
              ),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminPanelScreen(),
                  ),
                );
              },
            ),
            const Divider(height: 1),
          ],

          const Spacer(),
          const Divider(),

          // ── Logout ────────────────────────────────────────
          // CORRIGIDO: chama _confirmarLogout() sem passar contexto do drawer
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Terminar Sessão',
                style: TextStyle(color: Colors.red)),
            onTap: _confirmarLogout,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}