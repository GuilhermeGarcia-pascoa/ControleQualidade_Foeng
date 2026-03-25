import 'package:flutter/material.dart';
import '../models/models.dart';
import '../database/database_helper.dart';
import 'preencher_tabela_screen.dart';
import 'gerir_membros_screen.dart';

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

  void _loadDados() async {
    setState(() => _loading = true);
    final nosData = await DatabaseHelper.instance.getNos(
      widget.projeto.id!,
      paiId: widget.pai?.id,
    );
    final camposData = widget.pai != null
        ? await DatabaseHelper.instance.getCampos(widget.pai!.id!)
        : <CampoDinamico>[];
    setState(() {
      nos = nosData;
      campos = camposData;
      _loading = false;
    });
  }

  void _criarNo() {
    final nomeC = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova Pasta'),
        content: TextField(
          controller: nomeC,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nome',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
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
        content: Text('Tens a certeza que queres apagar "${no.nome}" e todo o seu conteúdo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
    final breadcrumb = [...widget.breadcrumb, if (widget.pai != null) widget.pai!.nome];
    final temCampos = campos.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.pai?.nome ?? widget.projeto.nome),
            if (breadcrumb.isNotEmpty)
              Text(
                breadcrumb.join(' › '),
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
          ],
        ),
        actions: [
          if (widget.perfil == 'admin' && widget.pai == null)
            IconButton(
              icon: const Icon(Icons.group),
              tooltip: 'Gerir Membros',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GerirMembrosScreen(projeto: widget.projeto),
                  ),
                );
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(8),
              children: [
                if (temCampos && widget.pai != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6F00),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      icon: const Icon(Icons.edit_note),
                      label: const Text('Preencher Formulário', style: TextStyle(fontSize: 16)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PreencherTabelaScreen(no: widget.pai!),
                          ),
                        );
                      },
                    ),
                  ),

                if (nos.isEmpty && !temCampos)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'Pasta vazia.\nClica em + para criar subpastas\nou adicionar campos.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 15),
                      ),
                    ),
                  ),

                ...nos.map((no) => Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFF1A237E),
                          child: Icon(Icons.folder, color: Colors.white),
                        ),
                        title: Text(no.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.perfil == 'admin')
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _apagarNo(no),
                              ),
                            const Icon(Icons.arrow_forward_ios, size: 16),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NosScreen(
                                projeto: widget.projeto,
                                perfil: widget.perfil,
                                pai: no,
                                breadcrumb: breadcrumb,
                              ),
                            ),
                          ).then((_) => _loadDados());
                        },
                      ),
                    )),
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
                    backgroundColor: const Color(0xFFFF6F00),
                    tooltip: 'Gerir Campos',
                    child: const Icon(Icons.list_alt, color: Colors.white),
                  ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'pasta',
                  onPressed: _criarNo,
                  backgroundColor: const Color(0xFF1A237E),
                  tooltip: 'Nova Pasta',
                  child: const Icon(Icons.create_new_folder, color: Colors.white),
                ),
              ],
            )
          : null,
    );
  }
}

// ─── ECRÃ DE GERIR CAMPOS ─────────────────────────────────
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
    setState(() {
      _camposExistentes = data;
      _loading = false;
    });
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
                  decoration: const InputDecoration(
                    labelText: 'Nome do Campo',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Tipo:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: ['texto', 'foto', 'selecao', 'numero', 'data'].map((tipo) {
                    return ChoiceChip(
                      label: Text(tipo),
                      selected: tipoCampo == tipo,
                      onSelected: (_) => setStateDialog(() => tipoCampo = tipo),
                    );
                  }).toList(),
                ),
                if (tipoCampo == 'selecao') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: opcoesC,
                    decoration: const InputDecoration(
                      labelText: 'Opções (separadas por vírgula)',
                      hintText: 'ex: Ok, Não Ok, Danificado',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: obrigatorio,
                      onChanged: (v) => setStateDialog(() => obrigatorio = v!),
                    ),
                    const Text('Obrigatório'),
                  ],
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
    if (_camposNovos.isEmpty) {
      Navigator.pop(context);
      return;
    }
    setState(() => _saving = true);
    for (final campo in _camposNovos) {
      await DatabaseHelper.instance.criarCampo({...campo, 'no_id': widget.no.id});
    }
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Campos guardados!')),
    );
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
      appBar: AppBar(
        title: Text('Campos — ${widget.no.nome}'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
          else
            TextButton.icon(
              onPressed: _guardar,
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text('Guardar', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (_camposExistentes.isNotEmpty) ...[
                  const Text('Campos existentes', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  ..._camposExistentes.map((c) => Card(
                        child: ListTile(
                          leading: Text(_iconeCampo(c.tipoCampo), style: const TextStyle(fontSize: 22)),
                          title: Text(c.nomeCampo),
                          subtitle: Text(c.tipoCampo),
                        ),
                      )),
                  const Divider(height: 32),
                ],
                if (_camposNovos.isNotEmpty) ...[
                  const Text('Novos campos (por guardar)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                  const SizedBox(height: 8),
                  ..._camposNovos.asMap().entries.map((e) => Card(
                        child: ListTile(
                          leading: Text(_iconeCampo(e.value['tipo_campo']), style: const TextStyle(fontSize: 22)),
                          title: Text(e.value['nome_campo']),
                          subtitle: Text(e.value['tipo_campo']),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => setState(() => _camposNovos.removeAt(e.key)),
                          ),
                        ),
                      )),
                ],
                if (_camposExistentes.isEmpty && _camposNovos.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'Nenhum campo ainda.\nClica em + para adicionar.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _adicionarCampo,
        backgroundColor: const Color(0xFF1A237E),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}