import 'package:flutter/material.dart';
import '../models/models.dart';
import '../database/database_helper.dart';
import 'preencher_tabela_screen.dart';
import 'gerir_membros_screen.dart';
import 'mostrar_dados_screen.dart';
import '../utils/toast.dart';
import 'gerir_acesso_no_screen.dart';
import '../theme/app_theme.dart';

class NosScreen extends StatefulWidget {
  final Projeto projeto;
  final String perfil;
  final No? pai;
  final List<String> breadcrumb;

  const NosScreen({
    Key? key,
    required this.projeto,
    required this.perfil,
    this.pai,
    this.breadcrumb = const [],
  }) : super(key: key);

  @override
  _NosScreenState createState() => _NosScreenState();
}

class _NosScreenState extends State<NosScreen> {
  List<No> nos = [];
  List<CampoDinamico> campos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDados();
  }

  // ─── RENOMEAR COM AVISO DE DUPLICADO ───
  void _renomearNo(No no) {
    final nomeC = TextEditingController(text: no.nome);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Renomear Pasta'),
        content: TextField(
          controller: nomeC,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Novo nome', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () async {
              final novoNome = nomeC.text.trim();
              if (novoNome.isEmpty || novoNome == no.nome) return;
              
              final jaExiste = nos.any((n) => n.id != no.id && n.nome.toLowerCase() == novoNome.toLowerCase());
              
              Navigator.pop(context);

              if (jaExiste) {
                final confirmar = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text('Atenção'),
                    content: Text('Já existe uma pasta chamada "$novoNome" neste local.\n\nQueres renomear na mesma?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        onPressed: () => Navigator.pop(context, true), 
                        child: const Text('Renomear'),
                      ),
                    ],
                  ),
                );
                if (confirmar != true) return;
              }

              await DatabaseHelper.instance.renomearNo(no.id!, novoNome);
              _loadDados();
              Toast.mostrar(context, 'Pasta renomeada!', tipo: ToastTipo.sucesso);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _moverNo(No no) async {
    final todosNos = await DatabaseHelper.instance.getTodosNos(widget.projeto.id!);
    final nosDisponiveis = todosNos.where((n) => n.id != no.id && n.paiId != no.id).toList();
    No? destinoSelecionado;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Mover Pasta'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mover "${no.nome}" para:'),
                const SizedBox(height: 8),
                RadioListTile<No?>(
                  value: null,
                  groupValue: destinoSelecionado,
                  title: const Text('Raiz do projeto', style: TextStyle(fontWeight: FontWeight.bold)),
                  onChanged: (v) => setStateDialog(() => destinoSelecionado = v),
                ),
                const Divider(),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 250),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: nosDisponiveis.length,
                    itemBuilder: (context, i) => RadioListTile<No?>(
                      value: nosDisponiveis[i],
                      groupValue: destinoSelecionado,
                      title: Text(nosDisponiveis[i].nome),
                      onChanged: (v) => setStateDialog(() => destinoSelecionado = v),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              onPressed: () async {
                Navigator.pop(context);
                await DatabaseHelper.instance.moverNo(no.id!, novoPaiId: destinoSelecionado?.id);
                _loadDados();
                Toast.mostrar(context, 'Pasta movida com sucesso!', tipo: ToastTipo.sucesso);
              },
              child: const Text('Mover'),
            ),
          ],
        ),
      ),
    );
  }

  void _copiarNo(No no) async {
    bool? incluirRegistos = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Copiar Pasta'),
        content: const Text('Queres incluir os registos (dados submetidos) na cópia?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Não, só estrutura'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sim, incluir registos'),
          ),
        ],
      ),
    );

    if (incluirRegistos == null) return;

    final projetos = await DatabaseHelper.instance.getProjetos();
    if (!mounted) return;

    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _NavegadorDestinoCopia(
        projetos: projetos,
        projetoInicialId: widget.projeto.id!,
      ),
    );

    if (resultado == null) return;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    await DatabaseHelper.instance.copiarNo(
      no.id!,
      novoPaiId: resultado['paiId'] as int?,
      novoProjetoId: resultado['projetoId'] as int,
      incluirRegistos: incluirRegistos,
    );

    if (!mounted) return;
    Navigator.pop(context);
    _loadDados();
    Toast.mostrar(context, 'Pasta copiada com sucesso!', tipo: ToastTipo.sucesso);
  }

  void _loadDados() async {
    setState(() => _loading = true);

    final nosData = await DatabaseHelper.instance.getNos(
      widget.projeto.id!,
      paiId: widget.pai?.id,
    );

    List<No> nosFiltrados = nosData;

    if (widget.perfil == 'trabalhador') {
      if (widget.pai == null) {
        final nosComAcesso = await DatabaseHelper.instance.getNosComAcesso(widget.projeto.id!);
        nosFiltrados = nosData.where((n) => nosComAcesso.contains(n.id)).toList();
      }
    }

    final camposData = widget.pai != null
        ? await DatabaseHelper.instance.getCampos(widget.pai!.id!)
        : <CampoDinamico>[];

    setState(() {
      nos = nosFiltrados;
      campos = camposData;
      _loading = false;
    });
  }

  // ─── CRIAR COM AVISO DE DUPLICADO ───
  void _criarNo() {
    final nomeC = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Nova Pasta'),
        content: TextField(
          controller: nomeC,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nome da pasta', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () async {
              final nome = nomeC.text.trim();
              if (nome.isEmpty) return;

              final jaExiste = nos.any((n) => n.nome.toLowerCase() == nome.toLowerCase());

              Navigator.pop(context); 

              if (jaExiste) {
                final confirmar = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text('Atenção'),
                    content: Text('Já existe uma pasta chamada "$nome" neste local.\n\nQueres criar outra com o mesmo nome?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        onPressed: () => Navigator.pop(context, true), 
                        child: const Text('Criar na mesma'),
                      ),
                    ],
                  ),
                );
                if (confirmar != true) return;
              }

              await DatabaseHelper.instance.criarNo(
                widget.projeto.id!,
                paiId: widget.pai?.id,
                nome: nome,
              );
              _loadDados();
              Toast.mostrar(context, 'Pasta criada!', tipo: ToastTipo.sucesso);
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }

  void _abrirCriarCampos() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CriarCamposScreen(no: widget.pai!, perfil: widget.perfil),
      ),
    ).then((_) => _loadDados());
  }

  void _apagarNo(No no) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Apagar Pasta', style: TextStyle(color: Colors.red)),
        content: Text('Tens a certeza que queres apagar "${no.nome}" e todo o seu conteúdo?\n\nEsta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseHelper.instance.apagarNo(no.id!);
      _loadDados();
    }
  }

  // ─── BUILD PRINCIPAL ───

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final temCampos = campos.isNotEmpty;
    
    final caminhoCompleto = [
      widget.projeto.nome,
      ...widget.breadcrumb,
      if (widget.pai != null) widget.pai!.nome,
    ];

    return Scaffold(
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.pai?.nome ?? widget.projeto.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (caminhoCompleto.length > 1)
              SizedBox(
                height: 20,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: caminhoCompleto.asMap().entries.map((entry) {
                      final int index = entry.key;
                      final String nome = entry.value;
                      final bool isLast = index == caminhoCompleto.length - 1;

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: isLast ? null : () {
                              int saltosParaTras = (caminhoCompleto.length - 1) - index;
                              for (int i = 0; i < saltosParaTras; i++) {
                                Navigator.pop(context);
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.0),
                              child: Text(
                                nome,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                                  color: isLast ? theme.colorScheme.onSurface : theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                          if (!isLast)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: Icon(Icons.chevron_right, size: 14, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                            ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
        actions: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: AppTheme.themeMode,
            builder: (context, currentMode, _) {
              final isDark = currentMode == ThemeMode.dark || 
                (currentMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);
              return IconButton(
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                tooltip: 'Mudar Tema',
                onPressed: () {
                  AppTheme.themeMode.value = isDark ? ThemeMode.light : ThemeMode.dark;
                },
              );
            },
          ),
          if (widget.perfil == 'admin' && widget.pai == null)
            IconButton(
              icon: const Icon(Icons.group),
              tooltip: 'Gerir Membros',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => GerirMembrosScreen(projeto: widget.projeto)),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // ─── BOTÕES LADO A LADO (Se a pasta tiver formulário) ───
                if (temCampos && widget.pai != null) ...[
                  Text(
                    'Ações Rápidas',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.edit_document,
                          title: 'Preencher\nFormulário',
                          color: theme.colorScheme.primary,
                          isDark: isDark,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => PreencherTabelaScreen(no: widget.pai!)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.table_chart_rounded,
                          title: 'Ver\nRegistos',
                          color: Colors.orange.shade400,
                          isDark: isDark,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => MostrarDadosScreen(noId: widget.pai!.id!)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                // ─── CABEÇALHO DA LISTA DE PASTAS ───
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pastas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (nos.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${nos.length}',
                          style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                        ),
                      )
                  ],
                ),
                const SizedBox(height: 12),

                // ─── ESTADO VAZIO ───
                if (nos.isEmpty && !temCampos)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_open, size: 64, color: theme.disabledColor),
                          const SizedBox(height: 16),
                          Text(
                            'Pasta vazia.',
                            style: TextStyle(color: theme.disabledColor, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ─── LISTA DE PASTAS (Cards Modernos) ───
                ...nos.asMap().entries.map((entry) {
                  final no = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.dividerColor.withOpacity(isDark ? 0.2 : 0.6)),
                      boxShadow: [
                        if (!isDark)
                          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.folder_rounded, color: theme.colorScheme.secondary),
                      ),
                      title: Text(no.nome, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      trailing: widget.perfil == 'admin' ? _buildAdminMenu(no) : const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NosScreen(
                            projeto: widget.projeto,
                            perfil: widget.perfil,
                            pai: no,
                            breadcrumb: caminhoCompleto.skip(1).toList(),
                          ),
                        ),
                      ).then((_) => _loadDados()),
                    ),
                  );
                }),
              ],
            ),
      floatingActionButton: widget.perfil == 'admin'
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (widget.pai != null)
                  FloatingActionButton.small(
                    heroTag: 'campos',
                    onPressed: _abrirCriarCampos,
                    tooltip: 'Gerir Campos (Formulário)',
                    child: const Icon(Icons.list_alt),
                  ),
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  heroTag: 'pasta',
                  onPressed: _criarNo,
                  icon: const Icon(Icons.create_new_folder),
                  label: const Text('Nova Pasta', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildAdminMenu(No no) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (valor) {
        if (valor == 'renomear') _renomearNo(no);
        if (valor == 'mover') _moverNo(no);
        if (valor == 'copiar') _copiarNo(no);
        if (valor == 'acesso') Navigator.push(context, MaterialPageRoute(builder: (_) => GerirAcessoNoScreen(no: no)));
        if (valor == 'apagar') _apagarNo(no);
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'renomear', child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 10), Text('Renomear')])),
        PopupMenuItem(value: 'mover', child: Row(children: [Icon(Icons.drive_file_move, size: 20), SizedBox(width: 10), Text('Mover para...')])),
        PopupMenuItem(value: 'copiar', child: Row(children: [Icon(Icons.copy, size: 20), SizedBox(width: 10), Text('Copiar para...')])),
        PopupMenuItem(value: 'acesso', child: Row(children: [Icon(Icons.security, size: 20), SizedBox(width: 10), Text('Gerir Acesso')])),
        PopupMenuDivider(),
        PopupMenuItem(value: 'apagar', child: Row(children: [Icon(Icons.delete, size: 20, color: Colors.red), SizedBox(width: 10), Text('Apagar', style: TextStyle(color: Colors.red))])),
      ],
    );
  }
}

// ─── WIDGET AUXILIAR PARA OS CARTÕES DE AÇÃO LADO A LADO ───
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(isDark ? 0.15 : 0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        splashColor: color.withOpacity(0.2),
        highlightColor: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// NAVEGADOR DE DESTINO (MANTIDO INTACTO)
// ════════════════════════════════════════════════════════════════════════════
class _NavegadorDestinoCopia extends StatefulWidget {
  final List<Projeto> projetos;
  final int projetoInicialId;

  const _NavegadorDestinoCopia({
    required this.projetos,
    required this.projetoInicialId,
  });

  @override
  State<_NavegadorDestinoCopia> createState() => _NavegadorDestinoCopiaState();
}

class _NavegadorDestinoCopiaState extends State<_NavegadorDestinoCopia> {
  late int _projetoAtualId;
  final List<No> _pilha = [];
  List<No> _nosAtuais = [];
  bool _loading = true;
  final TextEditingController _pesquisaC = TextEditingController();
  String _pesquisa = '';

  @override
  void initState() {
    super.initState();
    _projetoAtualId = widget.projetoInicialId;
    _carregarNos();
  }

  @override
  void dispose() {
    _pesquisaC.dispose();
    super.dispose();
  }

  Future<void> _carregarNos() async {
    setState(() => _loading = true);
    final paiId = _pilha.isEmpty ? null : _pilha.last.id;
    final nos = await DatabaseHelper.instance.getNos(_projetoAtualId, paiId: paiId);
    setState(() {
      _nosAtuais = nos;
      _loading = false;
      _pesquisaC.clear();
      _pesquisa = '';
    });
  }

  void _entrarNaPasta(No no) {
    _pilha.add(no);
    _carregarNos();
  }

  void _mudarProjeto(int novoId) {
    setState(() {
      _projetoAtualId = novoId;
      _pilha.clear();
    });
    _carregarNos();
  }

  List<No> get _nosFiltrados {
    if (_pesquisa.isEmpty) return _nosAtuais;
    return _nosAtuais
        .where((n) => n.nome.toLowerCase().contains(_pesquisa.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final int? paiIdAtual = _pilha.isEmpty ? null : _pilha.last.id;
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Destino da Cópia'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.dividerColor),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _projetoAtualId,
                  isExpanded: true,
                  items: widget.projetos
                      .map((p) => DropdownMenuItem<int>(
                            value: p.id!,
                            child: Text(p.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ))
                      .toList(),
                  onChanged: (id) { if (id != null) _mudarProjeto(id); },
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pesquisaC,
              onChanged: (v) => setState(() => _pesquisa = v),
              decoration: InputDecoration(
                hintText: 'Pesquisar nesta pasta...',
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
            const SizedBox(height: 8),
            if (_pilha.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.drive_folder_upload, color: Colors.blue),
                title: const Text('Subir um nível', style: TextStyle(color: Colors.blue)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                onTap: () {
                  _pilha.removeLast();
                  _carregarNos();
                },
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _nosFiltrados.isEmpty 
                    ? const Center(child: Text('Nenhuma pasta aqui.'))
                    : ListView.builder(
                      itemCount: _nosFiltrados.length,
                      itemBuilder: (context, i) {
                        final n = _nosFiltrados[i];
                        return Card(
                          elevation: 0,
                          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          child: ListTile(
                            leading: Icon(Icons.folder, color: theme.colorScheme.primary),
                            title: Text(n.nome),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                            onTap: () => _entrarNaPasta(n),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          onPressed: () => Navigator.pop(context, {
            'projetoId': _projetoAtualId,
            'paiId': paiIdAtual,
          }),
          child: const Text('Copiar Aqui'),
        ),
      ],
    );
  }
}

// ─── ECRÃ DE GERIR CAMPOS (MANTIDO INTACTO) ─────────────────────
class CriarCamposScreen extends StatefulWidget {
  final No no;
  final String perfil;
  const CriarCamposScreen({Key? key, required this.no, required this.perfil}) : super(key: key);

  @override
  _CriarCamposScreenState createState() => _CriarCamposScreenState();
}

class _CriarCamposScreenState extends State<CriarCamposScreen> {
  List<CampoDinamico> _camposExistentes = [];
  final List<Map<String, dynamic>> _camposNovos = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCampos();
  }

  void _loadCampos() async {
    final data = await DatabaseHelper.instance.getCampos(widget.no.id!);
    setState(() { _camposExistentes = data; _loading = false; });
  }

  void _adicionarCampo() {
    final nomeCampoC = TextEditingController();
    String tipoCampo = 'texto';
    final opcoesC = TextEditingController();
    bool obrigatorio = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Novo Campo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nomeCampoC,
                  decoration: const InputDecoration(labelText: 'Nome do Campo', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Tipo de Campo', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: tipoCampo,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'texto', child: Text('Texto')),
                        DropdownMenuItem(value: 'foto', child: Text('Foto')),
                        DropdownMenuItem(value: 'selecao', child: Text('Seleção Múltipla')),
                        DropdownMenuItem(value: 'numero', child: Text('Número')),
                        DropdownMenuItem(value: 'data', child: Text('Data')),
                      ],
                      onChanged: (v) => setStateDialog(() => tipoCampo = v!),
                    ),
                  ),
                ),
                if (tipoCampo == 'selecao') ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: opcoesC,
                    decoration: const InputDecoration(labelText: 'Opções (separadas por vírgula)', border: OutlineInputBorder()),
                  ),
                ],
                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Preenchimento Obrigatório'),
                  value: obrigatorio,
                  onChanged: (v) => setStateDialog(() => obrigatorio = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              onPressed: () {
                if (nomeCampoC.text.trim().isEmpty) return;
                setState(() {
                  _camposNovos.add({
                    'nome_campo': nomeCampoC.text.trim(),
                    'tipo_campo': tipoCampo,
                    'opcoes': tipoCampo == 'selecao' ? opcoesC.text.trim() : null,
                    'obrigatorio': obrigatorio ? 1 : 0,
                    'ordem': _camposExistentes.length + _camposNovos.length,
                  });
                });
                Navigator.pop(context);
              },
              child: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );
  }

  void _guardar() async {
    if (_camposNovos.isEmpty) { Navigator.pop(context); return; }
    setState(() => _saving = true);
    for (final campo in _camposNovos) {
      await DatabaseHelper.instance.criarCampo({...campo, 'no_id': widget.no.id});
    }
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Campos guardados!')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Configurar Campos', style: TextStyle(fontSize: 14)),
            Text(widget.no.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: AppTheme.themeMode,
            builder: (context, currentMode, _) {
              final isDark = currentMode == ThemeMode.dark || 
                (currentMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);
              return IconButton(
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                onPressed: () {
                  AppTheme.themeMode.value = isDark ? ThemeMode.light : ThemeMode.dark;
                },
              );
            },
          ),
          if (_saving)
            const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
          else if (_camposNovos.isNotEmpty)
            IconButton(icon: const Icon(Icons.save), tooltip: 'Guardar Alterações', onPressed: _guardar),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_camposExistentes.isNotEmpty) ...[
                  Text('Campos Existentes', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                  const SizedBox(height: 8),
                  ..._camposExistentes.map((c) => Card(
                        elevation: 0,
                        color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.background,
                            child: const Icon(Icons.label_outline, size: 20),
                          ),
                          title: Text(c.nomeCampo, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(c.tipoCampo.toUpperCase(), style: const TextStyle(fontSize: 12)),
                          trailing: c.obrigatorio == 1 ? const Icon(Icons.star, color: Colors.amber, size: 16) : null,
                        ),
                      )),
                  const SizedBox(height: 24),
                ],
                
                if (_camposNovos.isNotEmpty) ...[
                  Text('Novos Campos (por guardar)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 8),
                  ..._camposNovos.asMap().entries.map((e) => Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.green, width: 1)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green.withOpacity(0.2),
                            child: const Icon(Icons.fiber_new, color: Colors.green),
                          ),
                          title: Text(e.value['nome_campo'], style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(e.value['tipo_campo'].toString().toUpperCase(), style: const TextStyle(fontSize: 12)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => setState(() => _camposNovos.removeAt(e.key)),
                          ),
                        ),
                      )),
                ],
                
                if (_camposExistentes.isEmpty && _camposNovos.isEmpty)
                  Center(child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.list_alt, size: 64, color: theme.disabledColor),
                        const SizedBox(height: 16),
                        Text('Nenhum campo configurado.', style: TextStyle(color: theme.disabledColor, fontSize: 16)),
                      ],
                    ),
                  )),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _adicionarCampo,
        icon: const Icon(Icons.add),
        label: const Text('Adicionar Campo'),
      ),
    );
  }
} 