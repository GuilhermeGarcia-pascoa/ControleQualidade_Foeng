import 'package:flutter/material.dart';
import '../models/models.dart';
import '../database/database_helper.dart';
import 'preencher_tabela_screen.dart';
import 'gerir_membros_screen.dart';
import 'mostrar_dados_screen.dart';
import '../utils/toast.dart';
import 'gerir_acesso_no_screen.dart';

// --- CORES BASE DO DARK MODE ---
const Color bgColor = Color(0xFF121212);
const Color cardColor = Color(0xFF1E1E1E);
const Color dialogColor = Color(0xFF2C2C2C);
const Color textPrimary = Colors.white;
const Color textSecondary = Colors.white70;
const Color textMuted = Colors.white38;

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

  void _renomearNo(No no) {
    final nomeC = TextEditingController(text: no.nome);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.edit_outlined, color: Colors.blueAccent),
          SizedBox(width: 10),
          Text('Renomear Pasta', style: TextStyle(color: textPrimary)),
        ]),
        content: TextField(
          controller: nomeC,
          autofocus: true,
          style: const TextStyle(color: textPrimary),
          decoration: InputDecoration(
            labelText: 'Novo nome',
            labelStyle: const TextStyle(color: textSecondary),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: textMuted),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blueAccent),
            ),
            prefixIcon: const Icon(Icons.folder_outlined, color: textSecondary),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              if (nomeC.text.trim().isEmpty) return;
              Navigator.pop(context);
              await DatabaseHelper.instance.renomearNo(no.id!, nomeC.text.trim());
              _loadDados();
              Toast.mostrar(context, 'Pasta renomeada!', tipo: ToastTipo.sucesso);
            },
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
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
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(children: [
            Icon(Icons.drive_file_move_outlined, color: Colors.lightBlue),
            SizedBox(width: 10),
            Text('Mover Pasta', style: TextStyle(color: textPrimary)),
          ]),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mover "${no.nome}" para:', style: const TextStyle(fontSize: 13, color: textSecondary)),
                const SizedBox(height: 8),
                RadioListTile<No?>(
                  value: null,
                  groupValue: destinoSelecionado,
                  activeColor: Colors.lightBlue,
                  title: const Text('Raiz do projeto', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary)),
                  secondary: const Icon(Icons.home_outlined, color: Colors.lightBlue),
                  onChanged: (v) => setStateDialog(() => destinoSelecionado = v),
                ),
                const Divider(color: textMuted),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 250),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: nosDisponiveis.length,
                    itemBuilder: (context, i) => RadioListTile<No?>(
                      value: nosDisponiveis[i],
                      groupValue: destinoSelecionado,
                      activeColor: Colors.lightBlue,
                      title: Text(nosDisponiveis[i].nome, style: const TextStyle(color: textPrimary)),
                      secondary: const Icon(Icons.folder_outlined, color: textSecondary),
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
                child: const Text('Cancelar', style: TextStyle(color: textSecondary))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                Navigator.pop(context);
                await DatabaseHelper.instance.moverNo(no.id!, novoPaiId: destinoSelecionado?.id);
                _loadDados();
                Toast.mostrar(context, 'Pasta movida com sucesso!', tipo: ToastTipo.sucesso);
              },
              child: const Text('Mover', style: TextStyle(color: Colors.white)),
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
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.copy_outlined, color: Colors.tealAccent),
          SizedBox(width: 10),
          Text('Copiar Pasta', style: TextStyle(color: textPrimary)),
        ]),
        content: const Text('Queres incluir os registos (dados submetidos) na cópia?', style: TextStyle(color: textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Não, só estrutura', style: TextStyle(color: textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sim, incluir registos', style: TextStyle(color: Colors.white)),
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
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.tealAccent)),
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

  // Se for trabalhador, filtra só os nós a que tem acesso
  if (widget.perfil == 'trabalhador') {
    if (widget.pai == null) {
      // Na raiz do projeto: só mostra pastas a que tem acesso direto
      final nosComAcesso = await DatabaseHelper.instance.getNosComAcesso(widget.projeto.id!);
      nosFiltrados = nosData.where((n) => nosComAcesso.contains(n.id)).toList();
    }
    // Dentro de uma pasta com acesso: mostra todas as subpastas (sem filtro)
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

  void _criarNo() {
    final nomeC = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.create_new_folder, color: Colors.blueAccent),
            SizedBox(width: 10),
            Text('Nova Pasta', style: TextStyle(color: textPrimary)),
          ],
        ),
        content: TextField(
          controller: nomeC,
          autofocus: true,
          style: const TextStyle(color: textPrimary),
          decoration: InputDecoration(
            labelText: 'Nome da pasta',
            labelStyle: const TextStyle(color: textSecondary),
            filled: true,
            fillColor: dialogColor,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.transparent),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blueAccent),
            ),
            prefixIcon: const Icon(Icons.folder, color: Colors.blueAccent),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              if (nomeC.text.trim().isEmpty) return;
              Navigator.pop(context);
              await DatabaseHelper.instance.criarNo(
                widget.projeto.id!,
                paiId: widget.pai?.id,
                nome: nomeC.text.trim(),
              );
              _loadDados();
            },
            child: const Text('Criar', style: TextStyle(color: Colors.white)),
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
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Apagar Pasta', style: TextStyle(color: Colors.redAccent)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 48),
            const SizedBox(height: 12),
            Text(
              'Tens a certeza que queres apagar "${no.nome}" e todo o seu conteúdo?\n\nEsta ação não pode ser desfeita.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: textPrimary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Apagar', style: TextStyle(color: Colors.white)),
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
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF151521), Color(0xFF1E1E2C)], // Mais escuro que o original
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.pai?.nome ?? widget.projeto.nome,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
            ),
            if (caminhoCompleto.length > 1)
              _BreadcrumbWidget(
                caminho: caminhoCompleto,
                onTapBreadcrumb: (index) {
                  int popsNecessarios = caminhoCompleto.length - 1 - index;
                  if (popsNecessarios > 0) {
                    int count = 0;
                    Navigator.of(context).popUntil((_) => count++ >= popsNecessarios);
                  }
                },
              ),
          ],
        ),
        actions: [
          if (widget.perfil == 'admin' && widget.pai == null)
            IconButton(
              icon: const Icon(Icons.group, color: Colors.white),
              tooltip: 'Gerir Membros',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => GerirMembrosScreen(projeto: widget.projeto)),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              physics: const BouncingScrollPhysics(),
              children: [
                if (temCampos && widget.pai != null)
                  _BotaoPreencherFormulario(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PreencherTabelaScreen(no: widget.pai!)),
                    ),
                  ),
                if (temCampos && widget.pai != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MostrarDadosScreen(noId: widget.pai!.id!),
                        ),
                      ),
                      icon: const Icon(Icons.table_view, color: Colors.white),
                      label: const Text('Ver Registos Desta Pasta', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: dialogColor,
                        side: const BorderSide(color: Colors.blueAccent, width: 1),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ),
                if (nos.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12, left: 4),
                    child: Text(
                      '${nos.length} pasta${nos.length != 1 ? 's' : ''}',
                      style: const TextStyle(fontSize: 13, color: textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ),
                if (nos.isEmpty && !temCampos)
                  _PastaVaziaWidget(isAdmin: widget.perfil == 'admin'),
                ...nos.asMap().entries.map((entry) {
  final no = entry.value;
  return _PastaCard(
    no: no,
    index: entry.key,
    isAdmin: widget.perfil == 'admin',
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
    onDelete: () => _apagarNo(no),
    onRenomear: () => _renomearNo(no),
    onMover: () => _moverNo(no),
    onCopiar: () => _copiarNo(no),
    onAcesso: () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GerirAcessoNoScreen(no: no)),
    ),
  );
}),
              ],
            ),
      floatingActionButton: widget.perfil == 'admin'
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.pai != null) ...[
                  _FabLabel(
                    label: 'Gerir Campos',
                    child: FloatingActionButton(
                      heroTag: 'campos',
                      onPressed: _abrirCriarCampos,
                      backgroundColor: Colors.orangeAccent,
                      tooltip: 'Gerir Campos',
                      child: const Icon(Icons.list_alt, color: bgColor),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                _FabLabel(
                  label: 'Nova Pasta',
                  child: FloatingActionButton(
                    heroTag: 'pasta',
                    onPressed: _criarNo,
                    backgroundColor: Colors.blueAccent,
                    tooltip: 'Nova Pasta',
                    child: const Icon(Icons.create_new_folder, color: Colors.white),
                  ),
                ),
              ],
            )
          : null,
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// NAVEGADOR DE DESTINO — adaptado para Dark Mode
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

  void _voltarAtras() {
    if (_pilha.isNotEmpty) {
      _pilha.removeLast();
      _carregarNos();
    }
  }

  void _mudarProjeto(int novoId) {
    setState(() {
      _projetoAtualId = novoId;
      _pilha.clear();
    });
    _carregarNos();
  }

  void _navegarParaNivel(int nivelNaPilha) {
    while (_pilha.length > nivelNaPilha + 1) {
      _pilha.removeLast();
    }
    _carregarNos();
  }

  String get _nomeProjeto =>
      widget.projetos.firstWhere((p) => p.id == _projetoAtualId).nome;

  List<No> get _nosFiltrados {
    if (_pesquisa.isEmpty) return _nosAtuais;
    return _nosAtuais
        .where((n) => n.nome.toLowerCase().contains(_pesquisa.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final int? paiIdAtual = _pilha.isEmpty ? null : _pilha.last.id;

    return Dialog(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 36),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cabeçalho escuro
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF004D40), Color(0xFF00695C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [
                      Icon(Icons.copy_outlined, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('Destino da Cópia',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                    ]),
                    const SizedBox(height: 10),
                    const Text('Projeto:', style: TextStyle(color: Colors.white70, fontSize: 11)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _projetoAtualId,
                          dropdownColor: const Color(0xFF004D40),
                          iconEnabledColor: Colors.white,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                          isExpanded: true,
                          items: widget.projetos
                              .map((p) => DropdownMenuItem<int>(
                                    value: p.id!,
                                    child: Text(p.nome, style: const TextStyle(color: Colors.white)),
                                  ))
                              .toList(),
                          onChanged: (id) { if (id != null) _mudarProjeto(id); },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Breadcrumb (Fundo Escuro)
              Container(
                color: bgColor,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    if (_pilha.isNotEmpty) ...[
                      InkWell(
                        onTap: _voltarAtras,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.tealAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              size: 13, color: Colors.tealAccent),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        reverse: true,
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: _pilha.isNotEmpty
                                  ? () { _pilha.clear(); _carregarNos(); }
                                  : null,
                              child: Row(children: [
                                Icon(Icons.home_rounded,
                                    size: 15,
                                    color: _pilha.isEmpty ? Colors.tealAccent : textMuted),
                                const SizedBox(width: 3),
                                Text(
                                  _nomeProjeto,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: _pilha.isEmpty ? FontWeight.bold : FontWeight.normal,
                                    color: _pilha.isEmpty ? Colors.tealAccent : textSecondary,
                                    decoration: _pilha.isNotEmpty ? TextDecoration.underline : null,
                                    decorationColor: textMuted,
                                  ),
                                ),
                              ]),
                            ),
                            ..._pilha.asMap().entries.map((e) {
                              final isLast = e.key == _pilha.length - 1;
                              return Row(children: [
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 3),
                                  child: Icon(Icons.chevron_right, size: 13, color: textMuted),
                                ),
                                GestureDetector(
                                  onTap: isLast ? null : () => _navegarParaNivel(e.key),
                                  child: Text(
                                    e.value.nome,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                                      color: isLast ? Colors.tealAccent : textSecondary,
                                      decoration: !isLast ? TextDecoration.underline : null,
                                      decorationColor: textMuted,
                                    ),
                                  ),
                                ),
                              ]);
                            }),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Barra de pesquisa
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                child: TextField(
                  controller: _pesquisaC,
                  onChanged: (v) => setState(() => _pesquisa = v),
                  style: const TextStyle(color: textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Pesquisar nesta pasta...',
                    hintStyle: const TextStyle(color: textMuted),
                    prefixIcon: const Icon(Icons.search, size: 19, color: textSecondary),
                    suffixIcon: _pesquisa.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 17, color: textSecondary),
                            onPressed: () { _pesquisaC.clear(); setState(() => _pesquisa = ''); },
                          )
                        : null,
                    isDense: true,
                    filled: true,
                    fillColor: dialogColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  ),
                ),
              ),

              // Lista
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: Colors.tealAccent))
                    : _nosFiltrados.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.folder_open_rounded, size: 44, color: textMuted),
                                const SizedBox(height: 8),
                                Text(
                                  _pesquisa.isNotEmpty ? 'Nenhuma pasta encontrada' : 'Sem subpastas aqui',
                                  style: const TextStyle(color: textSecondary, fontSize: 13),
                                ),
                                if (_pesquisa.isEmpty) ...[
                                  const SizedBox(height: 4),
                                  const Text('Podes copiar para esta localização',
                                      style: TextStyle(color: textMuted, fontSize: 11)),
                                ],
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            itemCount: _nosFiltrados.length,
                            itemBuilder: (context, i) {
                              final n = _nosFiltrados[i];
                              return ListTile(
                                dense: true,
                                leading: Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.tealAccent.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: const Icon(Icons.folder_rounded, color: Colors.tealAccent, size: 20),
                                ),
                                title: Text(n.nome,
                                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: textPrimary)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 15, color: textMuted),
                                  tooltip: 'Entrar na pasta',
                                  onPressed: () => _entrarNaPasta(n),
                                  splashRadius: 18,
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                              );
                            },
                          ),
              ),

              const Divider(height: 1, color: textMuted),

              // Rodapé
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.teal.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.my_location_rounded, size: 15, color: Colors.tealAccent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _pilha.isEmpty
                                  ? 'Raiz de "$_nomeProjeto"'
                                  : '$_nomeProjeto › ${_pilha.map((n) => n.nome).join(' › ')}',
                              style: const TextStyle(
                                fontSize: 12, color: Colors.tealAccent, fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar', style: TextStyle(color: textSecondary)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.copy_rounded, color: Colors.white, size: 17),
                            label: const Text('Copiar Aqui',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            onPressed: () => Navigator.pop(context, {
                              'projetoId': _projetoAtualId,
                              'paiId': paiIdAtual,
                            }),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── WIDGET: BREADCRUMB ───────────────────────────────────
class _BreadcrumbWidget extends StatelessWidget {
  final List<String> caminho;
  final void Function(int) onTapBreadcrumb;

  const _BreadcrumbWidget({Key? key, required this.caminho, required this.onTapBreadcrumb})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> itens = [];
    if (caminho.length <= 3) {
      for (int i = 0; i < caminho.length; i++) {
        itens.add({'texto': caminho[i], 'indexOriginal': i});
      }
    } else {
      itens.add({'texto': caminho.first, 'indexOriginal': 0});
      itens.add({'texto': '...', 'indexOriginal': -1});
      itens.add({'texto': caminho[caminho.length - 2], 'indexOriginal': caminho.length - 2});
      itens.add({'texto': caminho.last, 'indexOriginal': caminho.length - 1});
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: itens.asMap().entries.map((e) {
          final isLast = e.key == itens.length - 1;
          final isEllipsis = e.value['texto'] == '...';
          final int originalIndex = e.value['indexOriginal'] as int;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: (isLast || isEllipsis) ? null : () => onTapBreadcrumb(originalIndex),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    e.value['texto'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      color: isLast ? Colors.white : Colors.white60,
                      fontWeight: isLast ? FontWeight.w600 : FontWeight.normal,
                      fontStyle: isEllipsis ? FontStyle.italic : FontStyle.normal,
                      decoration: (!isLast && !isEllipsis) ? TextDecoration.underline : TextDecoration.none,
                      decorationColor: Colors.white60,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.chevron_right, size: 14, color: Colors.white38),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─── WIDGET: BOTÃO PREENCHER FORMULÁRIO ───────────────────
class _BotaoPreencherFormulario extends StatelessWidget {
  final VoidCallback onTap;
  const _BotaoPreencherFormulario({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Material(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // BUG CORRIGIDO AQUI
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE65100), Color(0xFFFF8F00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: const Color(0xFFE65100).withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 5)),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.edit_note, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Preencher Formulário',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 2),
                      Text('Submeter novos dados para esta pasta',
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── WIDGET: CARD DE PASTA (DARK MODE) ────────────────────
class _PastaCard extends StatelessWidget {
  final No no;
  final int index;
  final bool isAdmin;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onRenomear;
  final VoidCallback onMover;
  final VoidCallback onCopiar;
  final VoidCallback onAcesso;

  const _PastaCard({
    required this.no, required this.index, required this.isAdmin,
    required this.onTap, required this.onDelete, required this.onRenomear,
    required this.onMover, required this.onCopiar, required this.onAcesso,
  });

  Color _corPasta(int index) {
    final cores = [
      Colors.blueAccent, Colors.purpleAccent, Colors.cyanAccent,
      Colors.tealAccent, Colors.greenAccent, Colors.orangeAccent,
    ];
    return cores[index % cores.length];
  }

  @override
  Widget build(BuildContext context) {
    final cor = _corPasta(index);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: cardColor,
        elevation: 0, 
        shape: RoundedRectangleBorder( // BUG CORRIGIDO AQUI (remoção do borderRadius redundante)
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.05)), 
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: cor.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                  child: Icon(Icons.folder_rounded, color: cor, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(child: Text(no.nome,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: textPrimary))),
                if (isAdmin)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: textSecondary, size: 20),
                    color: dialogColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    onSelected: (valor) {
                      switch (valor) {
                        case 'renomear': onRenomear(); break;
                        case 'mover': onMover(); break;
                        case 'copiar': onCopiar(); break;
                        case 'apagar': onDelete(); break;
                        case 'acesso': onAcesso(); break;
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'renomear', child: Row(children: [
                        Icon(Icons.edit_outlined, color: Colors.blueAccent, size: 20), SizedBox(width: 10), Text('Renomear', style: TextStyle(color: textPrimary)),
                      ])),
                      const PopupMenuItem(value: 'mover', child: Row(children: [
                        Icon(Icons.drive_file_move_outlined, color: Colors.lightBlue, size: 20), SizedBox(width: 10), Text('Mover para...', style: TextStyle(color: textPrimary)),
                      ])),
                      const PopupMenuItem(value: 'copiar', child: Row(children: [
                        Icon(Icons.copy_outlined, color: Colors.tealAccent, size: 20), SizedBox(width: 10), Text('Copiar para...', style: TextStyle(color: textPrimary)),
                      ])),
                      const PopupMenuDivider(height: 1),
                      const PopupMenuItem(value: 'apagar', child: Row(children: [
                        Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                        SizedBox(width: 10),
                        Text('Apagar', style: TextStyle(color: Colors.redAccent)),
                      ])),
                      const PopupMenuItem(value: 'acesso', child: Row(children: [
  Icon(Icons.lock_open_outlined, color: Color(0xFF4527A0), size: 20),
  SizedBox(width: 10),
  Text('Gerir Acesso'),
])),
                    ],
                  ),
                const Icon(Icons.chevron_right_rounded, color: textMuted, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── WIDGET: PASTA VAZIA (DARK MODE) ──────────────────────
class _PastaVaziaWidget extends StatelessWidget {
  final bool isAdmin;
  const _PastaVaziaWidget({required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: dialogColor, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20)],
              ),
              child: const Icon(Icons.folder_open_rounded, size: 64, color: textMuted),
            ),
            const SizedBox(height: 24),
            const Text('Pasta vazia',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textSecondary)),
            const SizedBox(height: 8),
            Text(
              isAdmin ? 'Clica em 📁 para criar subpastas\nou em 📋 para adicionar campos.' : 'Ainda não há conteúdo aqui.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: textMuted, fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── WIDGET: FAB COM LABEL ────────────────────────────────
class _FabLabel extends StatelessWidget {
  final String label;
  final Widget child;
  const _FabLabel({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
          child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ),
        const SizedBox(width: 8),
        child,
      ],
    );
  }
}

// ─── ECRÃ DE GERIR CAMPOS (DARK MODE) ─────────────────────
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
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Novo Campo', style: TextStyle(color: textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nomeCampoC,
                  style: const TextStyle(color: textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Nome do Campo',
                    labelStyle: const TextStyle(color: textSecondary),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: textMuted)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blueAccent)),
                    prefixIcon: const Icon(Icons.label_outline, color: textSecondary),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Tipo de Campo:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: [
                    {'tipo': 'texto', 'icon': '📝'}, {'tipo': 'foto', 'icon': '📷'},
                    {'tipo': 'selecao', 'icon': '📋'}, {'tipo': 'numero', 'icon': '🔢'},
                    {'tipo': 'data', 'icon': '📅'},
                  ].map((item) {
                    final tipo = item['tipo']!;
                    final selected = tipoCampo == tipo;
                    return GestureDetector(
                      onTap: () => setStateDialog(() => tipoCampo = tipo),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? Colors.blueAccent : dialogColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: selected ? Colors.blueAccent : textMuted),
                        ),
                        child: Text('${item['icon']} $tipo',
                            style: TextStyle(
                              color: selected ? Colors.white : textSecondary,
                              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            )),
                      ),
                    );
                  }).toList(),
                ),
                if (tipoCampo == 'selecao') ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: opcoesC,
                    style: const TextStyle(color: textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Opções (separadas por vírgula)',
                      labelStyle: const TextStyle(color: textSecondary),
                      hintText: 'ex: Ok, Não Ok, Danificado',
                      hintStyle: const TextStyle(color: textMuted),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: textMuted)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blueAccent)),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: obrigatorio,
                      activeColor: Colors.blueAccent,
                      checkColor: Colors.white,
                      side: const BorderSide(color: textSecondary),
                      onChanged: (v) => setStateDialog(() => obrigatorio = v!),
                    ),
                    const Text('Preenchimento Obrigatório', style: TextStyle(color: textPrimary)),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
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
              child: const Text('Adicionar', style: TextStyle(color: Colors.white)),
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
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('✅ Campos guardados com sucesso!', style: TextStyle(color: Colors.white)),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
    ));
    Navigator.pop(context);
  }

  String _iconeCampo(String tipo) {
    switch (tipo) {
      case 'foto': return '📷';
      case 'selecao': return '📋';
      case 'numero': return '🔢';
      case 'data': return '📅';
      default: return '📝';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF151521), Color(0xFF1E1E2C)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Campos — ${widget.no.nome}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const Text('Gerir campos do formulário', style: TextStyle(color: Colors.white60, fontSize: 12)),
          ],
        ),
        actions: [
          if (_saving)
            const Padding(padding: EdgeInsets.all(16),
                child: SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
          else if (_camposNovos.isNotEmpty)
            TextButton.icon(
              onPressed: _guardar,
              icon: const Icon(Icons.save_rounded, color: Colors.white),
              label: const Text('Guardar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              physics: const BouncingScrollPhysics(),
              children: [
                if (_camposExistentes.isNotEmpty) ...[
                  const _SectionHeader(title: 'Campos Existentes', color: Colors.grey),
                  const SizedBox(height: 8),
                  ..._camposExistentes.map((c) => _CampoCard(
                      icone: _iconeCampo(c.tipoCampo), nome: c.nomeCampo, tipo: c.tipoCampo, isNovo: false)),
                  const SizedBox(height: 16),
                ],
                if (_camposNovos.isNotEmpty) ...[
                  const _SectionHeader(title: 'Novos Campos (por guardar)', color: Colors.orangeAccent),
                  const SizedBox(height: 8),
                  ..._camposNovos.asMap().entries.map((e) => _CampoCard(
                      icone: _iconeCampo(e.value['tipo_campo']), nome: e.value['nome_campo'],
                      tipo: e.value['tipo_campo'], isNovo: true,
                      onDelete: () => setState(() => _camposNovos.removeAt(e.key)))),
                ],
                if (_camposExistentes.isEmpty && _camposNovos.isEmpty)
                  const _PastaVaziaWidget(isAdmin: true),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _adicionarCampo,
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Novo Campo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ─── WIDGET: SECTION HEADER ───────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;
  const _SectionHeader({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 4, height: 16,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
      ],
    );
  }
}

// ─── WIDGET: CAMPO CARD (DARK MODE) ───────────────────────
class _CampoCard extends StatelessWidget {
  final String icone;
  final String nome;
  final String tipo;
  final bool isNovo;
  final VoidCallback? onDelete;

  const _CampoCard({required this.icone, required this.nome, required this.tipo,
      required this.isNovo, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), // BUG CORRIGIDO AQUI
        color: cardColor,
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isNovo ? Colors.orangeAccent.withOpacity(0.5) : Colors.white.withOpacity(0.05)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: isNovo ? Colors.orangeAccent.withOpacity(0.1) : dialogColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text(icone, style: const TextStyle(fontSize: 22))),
            ),
            title: Text(nome, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: textPrimary)),
            subtitle: Text(tipo.toUpperCase(),
                style: const TextStyle(fontSize: 11, color: textSecondary, letterSpacing: 0.5)),
            trailing: onDelete != null
                ? IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: onDelete, splashRadius: 20)
                : null,
          ),
        ),
      ),
    );
  }
}