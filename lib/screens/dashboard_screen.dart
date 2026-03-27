import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/models.dart';
import 'nos_screen.dart';
import '../utils/toast.dart';
import 'gerir_membros_screen.dart';
import '../theme/app_theme.dart'; // <--- Importa o ficheiro central do tema

class DashboardScreen extends StatefulWidget {
  final String perfil;
  const DashboardScreen({Key? key, required this.perfil}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}
// ... resto do ficheiro igual
 
class _DashboardScreenState extends State<DashboardScreen> {
  List<Projeto> projetos = [];
  List<Projeto> _projetosFiltrados = [];
  bool _loading = true;
  final TextEditingController _searchCtrl = TextEditingController();
 
  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearch);
    _loadProjetos();
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
          : projetos.where((p) => p.nome.toLowerCase().contains(texto) || p.descricao.toLowerCase().contains(texto)).toList();
    });
  }
 
  void _loadProjetos() async {
    setState(() => _loading = true);
    final data = widget.perfil == 'admin'
        ? await DatabaseHelper.instance.getProjetos()
        : await DatabaseHelper.instance.getProjetosTrabalhador();
    setState(() {
      projetos = data;
      _projetosFiltrados = List.from(data);
      _loading = false;
    });
  }
 
  // ─── LÓGICA DE GESTÃO (PRESERVADA) ───────────────────────────
 
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
            TextField(controller: nomeC, decoration: const InputDecoration(labelText: 'Nome')),
            const SizedBox(height: 8),
            TextField(controller: descC, decoration: const InputDecoration(labelText: 'Descrição')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nomeC.text.trim().isEmpty) return;
              Navigator.pop(context);
              await DatabaseHelper.instance.renomearProjeto(projeto.id!, nomeC.text.trim(), descC.text.trim());
              _loadProjetos();
              Toast.mostrar(context, 'Projeto atualizado!', tipo: ToastTipo.sucesso);
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
        content: TextField(controller: nomeC, decoration: const InputDecoration(labelText: 'Nome da cópia')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nomeC.text.trim().isEmpty) return;
              Navigator.pop(context);
              await DatabaseHelper.instance.copiarProjeto(projeto.id!, nomeC.text.trim());
              _loadProjetos();
              Toast.mostrar(context, 'Projeto copiado!', tipo: ToastTipo.sucesso);
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
            TextField(controller: nomeC, decoration: const InputDecoration(labelText: 'Nome do Projeto')),
            const SizedBox(height: 8),
            TextField(controller: descC, decoration: const InputDecoration(labelText: 'Descrição')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nomeC.text.trim().isEmpty) return;
              Navigator.pop(context);
              await DatabaseHelper.instance.criarProjeto({
                'nome': nomeC.text.trim(),
                'descricao': descC.text.trim(),
              });
              _loadProjetos();
              Toast.mostrar(context, 'Projeto criado!', tipo: ToastTipo.sucesso);
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
        content: Text('Tens a certeza que queres apagar "${projeto.nome}"? Esta ação removerá todas as pastas e dados contidos.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Apagar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
 
    if (confirm == true) {
      await DatabaseHelper.instance.apagarProjeto(projeto.id!);
      _loadProjetos();
      Toast.mostrar(context, 'Projeto eliminado.', tipo: ToastTipo.erro);
    }
  }
 
  // ─── INTERFACE MODERNA ──────────────────────────────────────
 
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAdmin = widget.perfil == 'admin';
 
    return Scaffold(
      drawer: _buildDrawer(context),
      body: CustomScrollView(
        slivers: [
          // Header Estilizado
          SliverAppBar(
            expandedHeight: 140.0,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: colorScheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(start: 16, bottom: 16),
              title: Text(
                "Meus Projetos",
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
                  child: Text(widget.perfil[0].toUpperCase(), style: TextStyle(color: colorScheme.onPrimaryContainer)),
                ),
              ),
            ],
          ),
 
          // Barra de Pesquisa Fixa
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SearchBar(
                controller: _searchCtrl,
                hintText: "Procurar projeto...",
                leading: Icon(Icons.search, color: colorScheme.primary),
                elevation: MaterialStateProperty.all(0.5),
                backgroundColor: MaterialStateProperty.all(colorScheme.surfaceVariant.withOpacity(0.3)),
                shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
          ),
 
          // Lista de Projetos
          _loading
              ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
              : _projetosFiltrados.isEmpty
                  ? const SliverFillRemaining(child: Center(child: Text("Nenhum projeto encontrado.", style: TextStyle(color: Colors.grey))))
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildProjectCard(_projetosFiltrados[index], isAdmin, colorScheme),
                          childCount: _projetosFiltrados.length,
                        ),
                      ),
                    ),
        ],
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
 
  Widget _buildProjectCard(Projeto projeto, bool isAdmin, ColorScheme colorScheme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NosScreen(projeto: projeto, perfil: widget.perfil))).then((_) => _loadProjetos()),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Ícone lateral com fundo
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.inventory_2_rounded, color: colorScheme.primary),
              ),
              const SizedBox(width: 16),
              // Conteúdo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      projeto.nome,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    if (projeto.descricao.isNotEmpty)
                      Text(
                        projeto.descricao,
                        style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              // Menu de Ações
              if (isAdmin)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (valor) {
                    if (valor == 'renomear') _renomearProjeto(projeto);
                    if (valor == 'copiar') _copiarProjeto(projeto);
                    if (valor == 'apagar') _confirmarApagarProjeto(projeto);
                    if (valor == 'membros') Navigator.push(context, MaterialPageRoute(builder: (_) => GerirMembrosScreen(projeto: projeto)));
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'renomear', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Editar')])),
                    const PopupMenuItem(value: 'membros', child: Row(children: [Icon(Icons.group_outlined, size: 18), SizedBox(width: 8), Text('Membros')])),
                    const PopupMenuItem(value: 'copiar', child: Row(children: [Icon(Icons.copy_rounded, size: 18), SizedBox(width: 8), Text('Duplicar')])),
                    const PopupMenuDivider(),
                    const PopupMenuItem(value: 'apagar', child: Row(children: [Icon(Icons.delete_outline, color: Colors.red, size: 18), SizedBox(width: 8), Text('Apagar', style: TextStyle(color: Colors.red))])),
                  ],
                )
              else
                Icon(Icons.chevron_right, color: colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
 
  Widget _buildDrawer(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
 
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: colorScheme.primary),
            currentAccountPicture: CircleAvatar(
              backgroundColor: colorScheme.onPrimary,
              child: Icon(Icons.person, color: colorScheme.primary, size: 40),
            ),
            accountName: Text(widget.perfil.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: const Text("Controle de Qualidade"),
          ),
ListTile(
  leading: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
  title: Text(isDark ? "Modo Claro" : "Modo Escuro"),
  onTap: () {
    // É esta linha que faz a magia de alterar e guardar ao mesmo tempo!
    AppTheme.changeTheme(!isDark); 
  },
),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}