import 'package:flutter/material.dart';
import '../models/models.dart';
import '../database/database_helper.dart';
import 'preencher_tabela_screen.dart';
import 'gerir_membros_screen.dart';
import 'mostrar_dados_screen.dart';

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.create_new_folder, color: Color(0xFF1A237E)),
            SizedBox(width: 10),
            Text('Nova Pasta'),
          ],
        ),
        content: TextField(
          controller: nomeC,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Nome da pasta',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
            prefixIcon: const Icon(Icons.folder, color: Color(0xFF1A237E)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Apagar Pasta', style: TextStyle(color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 48),
            const SizedBox(height: 12),
            Text(
              'Tens a certeza que queres apagar "${no.nome}" e todo o seu conteúdo?\n\nEsta ação não pode ser desfeita.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
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
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
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
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            // ─── BREADCRUMB INTELIGENTE ───────────────
            if (caminhoCompleto.length > 1)
              _BreadcrumbWidget(
                caminho: caminhoCompleto,
                onTapBreadcrumb: (index) {
                  int indexOriginal = index;
                  int popsNecessarios = caminhoCompleto.length - 1 - indexOriginal;
                  
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
                MaterialPageRoute(
                  builder: (_) => GerirMembrosScreen(projeto: widget.projeto),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A237E)))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              physics: const BouncingScrollPhysics(),
              children: [
                // ─── BOTÃO PREENCHER FORMULÁRIO ──────────
                // ─── BOTÃO PREENCHER FORMULÁRIO ──────────
                if (temCampos && widget.pai != null)
                  _BotaoPreencherFormulario(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PreencherTabelaScreen(no: widget.pai!),
                      ),
                    ),
                  ),

                // 👇 COLE ESTE NOVO BOTÃO AQUI 👇
                // ─── BOTÃO VER DADOS (NOVO) ──────────────
                if (temCampos && widget.pai != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Passamos o ID automaticamente para o novo ecrã!
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MostrarDadosScreen(noId: widget.pai!.id!),
                          ),
                        );
                      },
                      icon: const Icon(Icons.table_view),
                      label: const Text('Ver Registos Desta Pasta'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        minimumSize: const Size(double.infinity, 50), // Ocupa a largura toda
                      ),
                    ),
                  ),
                // 👆 FIM DO NOVO BOTÃO 👆

                // ─── CONTADOR DE PASTAS ───────────────────
                if (nos.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12, left: 4),
                    child: Text(
                      '${nos.length} pasta${nos.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                // ─── PASTA VAZIA ──────────────────────────
                if (nos.isEmpty && !temCampos)
                  _PastaVaziaWidget(isAdmin: widget.perfil == 'admin'),

                // ─── LISTA DE PASTAS ──────────────────────
                ...nos.asMap().entries.map((entry) {
                  final index = entry.key;
                  final no = entry.value;
                  return _PastaCard(
                    no: no,
                    index: index,
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
                      backgroundColor: const Color(0xFFFF6F00),
                      tooltip: 'Gerir Campos',
                      child: const Icon(Icons.list_alt, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                _FabLabel(
                  label: 'Nova Pasta',
                  child: FloatingActionButton(
                    heroTag: 'pasta',
                    onPressed: _criarNo,
                    backgroundColor: const Color(0xFF1A237E),
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

// ─── WIDGET: BREADCRUMB INTELIGENTE ───────────────────────
class _BreadcrumbWidget extends StatelessWidget {
  final List<String> caminho;
  final void Function(int) onTapBreadcrumb;
  
  const _BreadcrumbWidget({
    Key? key,
    required this.caminho, 
    required this.onTapBreadcrumb,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> itens = [];

    if (caminho.length <= 3) {
      for (int i = 0; i < caminho.length; i++) {
        itens.add({'texto': caminho[i], 'indexOriginal': i});
      }
    } else {
      // Mostra: primeiro › ... › penúltimo › último
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
                      decoration: (!isLast && !isEllipsis) 
                          ? TextDecoration.underline 
                          : TextDecoration.none,
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
        borderRadius: BorderRadius.circular(16),
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6F00), Color(0xFFFF8F00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6F00).withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.edit_note, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preencher Formulário',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Submeter novos dados para esta pasta',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
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

// ─── WIDGET: CARD DE PASTA ────────────────────────────────
class _PastaCard extends StatelessWidget {
  final No no;
  final int index;
  final bool isAdmin;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PastaCard({
    required this.no,
    required this.index,
    required this.isAdmin,
    required this.onTap,
    required this.onDelete,
  });

  // Cores alternadas para dar vida à lista
  Color _corPasta(int index) {
    final cores = [
      const Color(0xFF1A237E),
      const Color(0xFF1565C0),
      const Color(0xFF0277BD),
      const Color(0xFF00695C),
      const Color(0xFF2E7D32),
      const Color(0xFF4527A0),
    ];
    return cores[index % cores.length];
  }

  @override
  Widget build(BuildContext context) {
    final cor = _corPasta(index);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black12,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Ícone colorido
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: cor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.folder_rounded, color: cor, size: 28),
                ),
                const SizedBox(width: 14),
                // Nome
                Expanded(
                  child: Text(
                    no.nome,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ),
                // Botão apagar (só admin)
                if (isAdmin)
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red.shade300, size: 22),
                    onPressed: onDelete,
                    splashRadius: 20,
                  ),
                // Seta
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── WIDGET: PASTA VAZIA ──────────────────────────────────
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
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20),
                ],
              ),
              child: Icon(Icons.folder_open_rounded, size: 64, color: Colors.grey.shade300),
            ),
            const SizedBox(height: 24),
            Text(
              'Pasta vazia',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isAdmin
                  ? 'Clica em 📁 para criar subpastas\nou em 📋 para adicionar campos.'
                  : 'Ainda não há conteúdo aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14, height: 1.5),
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
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ),
        const SizedBox(width: 8),
        child,
      ],
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Novo Campo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nomeCampoC,
                  decoration: InputDecoration(
                    labelText: 'Nome do Campo',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.label_outline),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Tipo de Campo:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    {'tipo': 'texto', 'icon': '📝'},
                    {'tipo': 'foto', 'icon': '📷'},
                    {'tipo': 'selecao', 'icon': '📋'},
                    {'tipo': 'numero', 'icon': '🔢'},
                    {'tipo': 'data', 'icon': '📅'},
                  ].map((item) {
                    final tipo = item['tipo']!;
                    final selected = tipoCampo == tipo;
                    return GestureDetector(
                      onTap: () => setStateDialog(() => tipoCampo = tipo),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? const Color(0xFF1A237E) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected ? const Color(0xFF1A237E) : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          '${item['icon']} $tipo',
                          style: TextStyle(
                            color: selected ? Colors.white : Colors.black87,
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (tipoCampo == 'selecao') ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: opcoesC,
                    decoration: InputDecoration(
                      labelText: 'Opções (separadas por vírgula)',
                      hintText: 'ex: Ok, Não Ok, Danificado',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: obrigatorio,
                      activeColor: const Color(0xFF1A237E),
                      onChanged: (v) => setStateDialog(() => obrigatorio = v!),
                    ),
                    const Text('Preenchimento Obrigatório'),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
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
      const SnackBar(
        content: Text('✅ Campos guardados com sucesso!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
      ),
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
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Campos — ${widget.no.nome}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const Text('Gerir campos do formulário', style: TextStyle(color: Colors.white60, fontSize: 12)),
          ],
        ),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
            )
          else if (_camposNovos.isNotEmpty)
            TextButton.icon(
              onPressed: _guardar,
              icon: const Icon(Icons.save_rounded, color: Colors.white),
              label: const Text('Guardar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A237E)))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              physics: const BouncingScrollPhysics(),
              children: [
                if (_camposExistentes.isNotEmpty) ...[
                  _SectionHeader(title: 'Campos Existentes', color: Colors.grey.shade600),
                  const SizedBox(height: 8),
                  ..._camposExistentes.map((c) => _CampoCard(
                        icone: _iconeCampo(c.tipoCampo),
                        nome: c.nomeCampo,
                        tipo: c.tipoCampo,
                        isNovo: false,
                      )),
                  const SizedBox(height: 16),
                ],
                if (_camposNovos.isNotEmpty) ...[
                  _SectionHeader(title: 'Novos Campos (por guardar)', color: Colors.orange.shade700),
                  const SizedBox(height: 8),
                  ..._camposNovos.asMap().entries.map((e) => _CampoCard(
                        icone: _iconeCampo(e.value['tipo_campo']),
                        nome: e.value['nome_campo'],
                        tipo: e.value['tipo_campo'],
                        isNovo: true,
                        onDelete: () => setState(() => _camposNovos.removeAt(e.key)),
                      )),
                ],
                if (_camposExistentes.isEmpty && _camposNovos.isEmpty)
                  _PastaVaziaWidget(isAdmin: true),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _adicionarCampo,
        backgroundColor: const Color(0xFF1A237E),
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
        Container(width: 4, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
      ],
    );
  }
}

// ─── WIDGET: CAMPO CARD ───────────────────────────────────
class _CampoCard extends StatelessWidget {
  final String icone;
  final String nome;
  final String tipo;
  final bool isNovo;
  final VoidCallback? onDelete;

  const _CampoCard({
    required this.icone,
    required this.nome,
    required this.tipo,
    required this.isNovo,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
        elevation: isNovo ? 2 : 1,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: isNovo ? Border.all(color: Colors.orange.shade200) : null,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isNovo ? Colors.orange.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text(icone, style: const TextStyle(fontSize: 22))),
            ),
            title: Text(nome, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            subtitle: Text(tipo.toUpperCase(), style: TextStyle(fontSize: 11, color: Colors.grey.shade500, letterSpacing: 0.5)),
            trailing: onDelete != null
                ? IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
                    onPressed: onDelete,
                    splashRadius: 20,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}