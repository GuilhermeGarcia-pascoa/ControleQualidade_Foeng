import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/models.dart';
import 'nos_screen.dart';
import '../utils/session.dart';
import 'login_screen.dart';
import '../utils/toast.dart';
import 'gerir_membros_screen.dart';

// ─── GESTOR DE TEMA GLOBAL ────────────────────────────────
// Isto permite que o tema seja alterado em toda a app!
class AppTheme {
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.light);
}
// ──────────────────────────────────────────────────────────

class DashboardScreen extends StatefulWidget {
  final String perfil;
  const DashboardScreen({Key? key, required this.perfil}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Projeto> projetos = [];
  List<Projeto> _projetosFiltrados = [];
  bool _loading = true;
  final TextEditingController _searchCtrl = TextEditingController();
  bool _searchAtivo = false;

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
          : projetos
              .where((p) =>
                  p.nome.toLowerCase().contains(texto) ||
                  p.descricao.toLowerCase().contains(texto))
              .toList();
    });
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
      _projetosFiltrados = List.from(data);
      _loading = false;
    });

    if (_searchCtrl.text.isNotEmpty) _onSearch();
  }

  // ─── DIALOGS BÁSICOS ────────────────────────────────────

  void _renomearProjeto(Projeto projeto) {
    final nomeC = TextEditingController(text: projeto.nome);
    final descC = TextEditingController(text: projeto.descricao);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renomear Projeto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nomeC, decoration: const InputDecoration(labelText: 'Nome')),
            TextField(controller: descC, decoration: const InputDecoration(labelText: 'Descrição')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              if (nomeC.text.trim().isEmpty) return;
              Navigator.pop(context);
              await DatabaseHelper.instance.renomearProjeto(projeto.id!, nomeC.text.trim(), descC.text.trim());
              _loadProjetos();
              Toast.mostrar(context, 'Projeto renomeado!', tipo: ToastTipo.sucesso);
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nomeC, decoration: const InputDecoration(labelText: 'Nome do novo projeto')),
            const SizedBox(height: 10),
            const Text('Serão copiadas todas as pastas e campos. Os registos não são copiados.'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              if (nomeC.text.trim().isEmpty) return;
              Navigator.pop(context);
              
              showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
              await DatabaseHelper.instance.copiarProjeto(projeto.id!, nomeC.text.trim());
              Navigator.pop(context);
              
              _loadProjetos();
              Toast.mostrar(context, 'Projeto copiado com sucesso!', tipo: ToastTipo.sucesso);
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
            TextField(controller: descC, decoration: const InputDecoration(labelText: 'Descrição')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              if (nomeC.text.trim().isEmpty) {
                Toast.mostrar(context, 'O nome é obrigatório!', tipo: ToastTipo.aviso);
                return;
              }
              Navigator.pop(context);
              await DatabaseHelper.instance.criarProjeto({
                'nome': nomeC.text.trim(),
                'descricao': descC.text.trim(),
              });
              _loadProjetos();
              Toast.mostrar(context, 'Projeto criado com sucesso!', tipo: ToastTipo.sucesso);
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }

  void _confirmarApagarProjeto(Projeto projeto) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    final contagem = await DatabaseHelper.instance.getContagemProjeto(projeto.id!);
    Navigator.pop(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar Projeto'),
        content: Text('Tens a certeza que queres apagar "${projeto.nome}"?\n\n'
            'Isto irá apagar:\n'
            '- ${contagem['total_nos'] ?? 0} pastas\n'
            '- ${contagem['total_registos'] ?? 0} registos\n\n'
            'Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Apagar Tudo')),
        ],
      ),
    );

    if (confirm == true) {
      final sucesso = await DatabaseHelper.instance.apagarProjeto(projeto.id!);
      if (sucesso) {
        _loadProjetos();
        Toast.mostrar(context, 'Projeto "${projeto.nome}" apagado.', tipo: ToastTipo.erro);
      }
    }
  }

  // ─── BUILD ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.perfil == 'admin';
    final listaVisivel = _projetosFiltrados;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Projetos'), // <-- Removido o "(Admin)"
        actions: [
          // ─── BOTÃO DE TEMA (MODO CLARO/ESCURO) ───
          ValueListenableBuilder<ThemeMode>(
            valueListenable: AppTheme.themeMode,
            builder: (context, currentMode, _) {
              // Verifica se está escuro (ou pelas defnições do sistema ou pelo botão)
              final isDark = currentMode == ThemeMode.dark || 
                (currentMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);
              
              return IconButton(
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                tooltip: 'Mudar Tema',
                onPressed: () {
                  // Alterna entre o modo claro e o modo escuro
                  AppTheme.themeMode.value = isDark ? ThemeMode.light : ThemeMode.dark;
                },
              );
            },
          ),
          
          IconButton(
            icon: Icon(_searchAtivo ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _searchAtivo = !_searchAtivo;
                if (!_searchAtivo) {
                  _searchCtrl.clear();
                  _projetosFiltrados = List.from(projetos);
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Session.logout();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_searchAtivo)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  hintText: 'Pesquisar projetos...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          
          if (!_loading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('${listaVisivel.length} projetos encontrados'),
            ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : listaVisivel.isEmpty
                    ? const Center(child: Text('Nenhum projeto encontrado.'))
                    : ListView.builder(
                        itemCount: listaVisivel.length,
                        itemBuilder: (context, index) {
                          final projeto = listaVisivel[index];
                          return ListTile(
                            leading: const Icon(Icons.folder),
                            title: Text(projeto.nome),
                            subtitle: Text(projeto.descricao),
                            trailing: isAdmin ? _buildAdminMenu(projeto) : null,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => NosScreen(projeto: projeto, perfil: widget.perfil),
                              ),
                            ).then((_) => _loadProjetos()),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: _mostrarDialogCriarProjeto,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildAdminMenu(Projeto projeto) {
    return PopupMenuButton<String>(
      onSelected: (valor) {
        if (valor == 'renomear') _renomearProjeto(projeto);
        if (valor == 'membros') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => GerirMembrosScreen(projeto: projeto)));
        }
        if (valor == 'copiar') _copiarProjeto(projeto);
        if (valor == 'apagar') _confirmarApagarProjeto(projeto);
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'renomear', child: Text('Renomear')),
        PopupMenuItem(value: 'membros', child: Text('Gerir Membros')),
        PopupMenuItem(value: 'copiar', child: Text('Copiar Projeto')),
        PopupMenuItem(value: 'apagar', child: Text('Apagar')),
      ],
    );
  }
}