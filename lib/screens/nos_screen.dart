import 'package:flutter/material.dart';
import '../models/models.dart';
import '../database/database_helper.dart';
import 'preencher_tabela_screen.dart';
import 'gerir_membros_screen.dart';
import 'mostrar_dados_screen.dart';
import '../utils/toast.dart';
import 'gerir_acesso_no_screen.dart';
import 'dashboard_screen.dart'; // Importante para aceder ao AppTheme

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
        title: const Text('Renomear Pasta'),
        content: TextField(
          controller: nomeC,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Novo nome'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              final novoNome = nomeC.text.trim();
              if (novoNome.isEmpty || novoNome == no.nome) return;
              
              // Verifica se já existe outra pasta com este nome no MESMO local (ignorando maiúsculas/minúsculas)
              final jaExiste = nos.any((n) => n.id != no.id && n.nome.toLowerCase() == novoNome.toLowerCase());
              
              Navigator.pop(context); // Fecha o dialog de texto

              if (jaExiste) {
                // Pergunta se tem a certeza
                final confirmar = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Atenção'),
                    content: Text('Já existe uma pasta chamada "$novoNome" neste local.\n\nQueres renomear na mesma?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Renomear')),
                    ],
                  ),
                );
                if (confirmar != true) return; // Se disser que não, cancela tudo
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
                  title: const Text('Raiz do projeto'),
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
            TextButton(
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
        title: const Text('Copiar Pasta'),
        content: const Text('Queres incluir os registos (dados submetidos) na cópia?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Não, só estrutura'),
          ),
          TextButton(
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
        title: const Text('Nova Pasta'),
        content: TextField(
          controller: nomeC,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nome da pasta'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              final nome = nomeC.text.trim();
              if (nome.isEmpty) return;

              // Verifica se já existe uma pasta com este nome no MESMO local
              final jaExiste = nos.any((n) => n.nome.toLowerCase() == nome.toLowerCase());

              Navigator.pop(context); // Fecha o dialog de texto

              if (jaExiste) {
                // Pergunta se tem a certeza
                final confirmar = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Atenção'),
                    content: Text('Já existe uma pasta chamada "$nome" neste local.\n\nQueres criar outra com o mesmo nome?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Criar na mesma')),
                    ],
                  ),
                );
                if (confirmar != true) return; // Se disser que não, cancela tudo
              }

              // Se não existia, ou se ele confirmou que quer criar na mesma, cria:
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
        title: const Text('Apagar Pasta'),
        content: Text('Tens a certeza que queres apagar "${no.nome}" e todo o seu conteúdo?\n\nEsta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
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

  @override
  Widget build(BuildContext context) {
    final caminhoCompleto = [
      widget.projeto.nome,
      ...widget.breadcrumb,
      if (widget.pai != null) widget.pai!.nome,
    ];
    final temCampos = campos.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.pai?.nome ?? widget.projeto.nome),
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
                                  decoration: isLast ? TextDecoration.none : TextDecoration.underline,
                                  color: isLast ? null : Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                          if (!isLast)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4.0),
                              child: Text('/', style: TextStyle(fontSize: 12)),
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
              padding: const EdgeInsets.all(16),
              children: [
                if (temCampos && widget.pai != null)
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PreencherTabelaScreen(no: widget.pai!)),
                    ),
                    icon: const Icon(Icons.edit_note),
                    label: const Text('Preencher Formulário'),
                  ),
                const SizedBox(height: 8),
                if (temCampos && widget.pai != null)
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MostrarDadosScreen(noId: widget.pai!.id!),
                      ),
                    ),
                    icon: const Icon(Icons.table_view),
                    label: const Text('Ver Registos Desta Pasta'),
                  ),
                const SizedBox(height: 16),
                if (nos.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('${nos.length} pasta(s) encontradas'),
                  ),
                if (nos.isEmpty && !temCampos)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('Pasta vazia.'),
                  )),
                ...nos.asMap().entries.map((entry) {
                  final no = entry.value;
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.folder),
                      title: Text(no.nome),
                      trailing: widget.perfil == 'admin' ? PopupMenuButton<String>(
                        onSelected: (valor) {
                          if (valor == 'renomear') _renomearNo(no);
                          if (valor == 'mover') _moverNo(no);
                          if (valor == 'copiar') _copiarNo(no);
                          if (valor == 'apagar') _apagarNo(no);
                          if (valor == 'acesso') Navigator.push(context, MaterialPageRoute(builder: (_) => GerirAcessoNoScreen(no: no)));
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'renomear', child: Text('Renomear')),
                          PopupMenuItem(value: 'mover', child: Text('Mover para...')),
                          PopupMenuItem(value: 'copiar', child: Text('Copiar para...')),
                          PopupMenuItem(value: 'acesso', child: Text('Gerir Acesso')),
                          PopupMenuItem(value: 'apagar', child: Text('Apagar')),
                        ],
                      ) : const Icon(Icons.chevron_right),
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
              children: [
                if (widget.pai != null)
                  FloatingActionButton(
                    heroTag: 'campos',
                    onPressed: _abrirCriarCampos,
                    tooltip: 'Gerir Campos',
                    child: const Icon(Icons.list_alt),
                  ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'pasta',
                  onPressed: _criarNo,
                  tooltip: 'Nova Pasta',
                  child: const Icon(Icons.create_new_folder),
                ),
              ],
            )
          : null,
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// NAVEGADOR DE DESTINO 
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

    return AlertDialog(
      title: const Text('Destino da Cópia'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButton<int>(
              value: _projetoAtualId,
              isExpanded: true,
              items: widget.projetos
                  .map((p) => DropdownMenuItem<int>(
                        value: p.id!,
                        child: Text(p.nome),
                      ))
                  .toList(),
              onChanged: (id) { if (id != null) _mudarProjeto(id); },
            ),
            const SizedBox(height: 8),
            if (_pilha.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.arrow_back),
                title: const Text('Voltar acima'),
                onTap: () {
                  _pilha.removeLast();
                  _carregarNos();
                },
              ),
            TextField(
              controller: _pesquisaC,
              onChanged: (v) => setState(() => _pesquisa = v),
              decoration: const InputDecoration(
                hintText: 'Pesquisar nesta pasta...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _nosFiltrados.length,
                      itemBuilder: (context, i) {
                        final n = _nosFiltrados[i];
                        return ListTile(
                          leading: const Icon(Icons.folder),
                          title: Text(n.nome),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () => _entrarNaPasta(n),
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

// ─── ECRÃ DE GERIR CAMPOS ─────────────────────
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
          title: const Text('Novo Campo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nomeCampoC,
                  decoration: const InputDecoration(labelText: 'Nome do Campo'),
                ),
                const SizedBox(height: 16),
                const Text('Tipo de Campo:'),
                DropdownButton<String>(
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
                if (tipoCampo == 'selecao')
                  TextField(
                    controller: opcoesC,
                    decoration: const InputDecoration(labelText: 'Opções (separadas por vírgula)'),
                  ),
                CheckboxListTile(
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
            TextButton(
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Campos — ${widget.no.nome}'),
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
            const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())
          else if (_camposNovos.isNotEmpty)
            IconButton(icon: const Icon(Icons.save), onPressed: _guardar),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_camposExistentes.isNotEmpty) ...[
                  const Text('Campos Existentes', style: TextStyle(fontWeight: FontWeight.bold)),
                  ..._camposExistentes.map((c) => ListTile(
                        leading: const Icon(Icons.label),
                        title: Text(c.nomeCampo),
                        subtitle: Text(c.tipoCampo),
                      )),
                  const Divider(),
                ],
                if (_camposNovos.isNotEmpty) ...[
                  const Text('Novos Campos (por guardar)', style: TextStyle(fontWeight: FontWeight.bold)),
                  ..._camposNovos.asMap().entries.map((e) => ListTile(
                        leading: const Icon(Icons.fiber_new),
                        title: Text(e.value['nome_campo']),
                        subtitle: Text(e.value['tipo_campo']),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => setState(() => _camposNovos.removeAt(e.key)),
                        ),
                      )),
                ],
                if (_camposExistentes.isEmpty && _camposNovos.isEmpty)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('Nenhum campo configurado.'),
                  )),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _adicionarCampo,
        child: const Icon(Icons.add),
      ),
    );
  }
}