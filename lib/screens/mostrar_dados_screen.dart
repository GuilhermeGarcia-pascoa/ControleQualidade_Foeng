import 'dart:convert';
import 'package:flutter/material.dart';
import '../database/database_helper.dart';

const Color _bg      = Color(0xFF0D1117);
const Color _surface = Color(0xFF161B22);
const Color _alt     = Color(0xFF1C2330);
const Color _border  = Color(0xFF30363D);
const Color _accent  = Color(0xFF00C2A8);
const Color _textPri = Color(0xFFE6EDF3);
const Color _textSec = Color(0xFF8B949E);
const Color _textMut = Color(0xFF484F58);
const Color _danger  = Color(0xFFF85149);

class MostrarDadosScreen extends StatefulWidget {
  final int noId;
  const MostrarDadosScreen({Key? key, required this.noId}) : super(key: key);

  @override
  State<MostrarDadosScreen> createState() => _MostrarDadosScreenState();
}

class _MostrarDadosScreenState extends State<MostrarDadosScreen> {
  final ScrollController _scrollV = ScrollController();
  final ScrollController _scrollH = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();

  bool _loading = true;
  List<Map<String, dynamic>> _campos = [];
  List<dynamic> _todos = [];
  List<dynamic> _filtrados = [];

  String _filtroBusca = '';
  String? _filtroColuna;
  String? _sortColuna;
  bool _sortAsc = true;

  @override
  void initState() {
    super.initState();
    _carregar();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _scrollV.dispose();
    _scrollH.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    try {
      final camposRaw = await DatabaseHelper.instance.getCampos(widget.noId);
      final registosRaw = await DatabaseHelper.instance.getRegistos(widget.noId);
      setState(() {
        _campos = camposRaw.map((c) => {'id': c.id, 'nome': c.nomeCampo}).toList();
        _todos = registosRaw;
        _filtrados = List.from(_todos);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro: $e'),
        backgroundColor: _danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  void _onSearch() {
    setState(() {
      _filtroBusca = _searchCtrl.text.trim().toLowerCase();
      _aplicarFiltros();
    });
  }

  Map<String, dynamic> _parseDados(dynamic reg) {
    if (reg['dados'] == null) return {};
    try {
      return reg['dados'] is String
          ? json.decode(reg['dados'])
          : Map<String, dynamic>.from(reg['dados']);
    } catch (_) {
      return {};
    }
  }

  void _aplicarFiltros() {
    var lista = List.from(_todos);

    if (_filtroBusca.isNotEmpty) {
      lista = lista.where((reg) {
        final dados = _parseDados(reg);
        if (_filtroColuna != null) {
          return (dados[_filtroColuna] ?? '').toString().toLowerCase().contains(_filtroBusca);
        }
        return dados.values.any((v) => v.toString().toLowerCase().contains(_filtroBusca));
      }).toList();
    }

    if (_sortColuna != null) {
      lista.sort((a, b) {
        final va = (_parseDados(a)[_sortColuna] ?? '').toString().toLowerCase();
        final vb = (_parseDados(b)[_sortColuna] ?? '').toString().toLowerCase();
        final na = double.tryParse(va);
        final nb = double.tryParse(vb);
        final cmp = (na != null && nb != null) ? na.compareTo(nb) : va.compareTo(vb);
        return _sortAsc ? cmp : -cmp;
      });
    }

    _filtrados = lista;
  }

  void _toggleSort(String coluna) {
    setState(() {
      _sortColuna == coluna ? _sortAsc = !_sortAsc : (_sortColuna = coluna, _sortAsc = true);
      _aplicarFiltros();
    });
  }

  void _limparFiltros() {
    _searchCtrl.clear();
    setState(() {
      _filtroBusca = '';
      _filtroColuna = null;
      _sortColuna = null;
      _sortAsc = true;
      _filtrados = List.from(_todos);
    });
  }

  bool get _temFiltros => _filtroBusca.isNotEmpty || _filtroColuna != null || _sortColuna != null;

  // ─── HELPERS DE IMAGEM ────────────────────────────────────

  bool _isImagem(String? val) {
    if (val == null || val.isEmpty) return false;
    final lower = val.toLowerCase();
    if (lower.startsWith('/uploads/')) return true;
    if (lower.startsWith('http') &&
        (lower.endsWith('.jpg') ||
         lower.endsWith('.jpeg') ||
         lower.endsWith('.png') ||
         lower.endsWith('.gif') ||
         lower.endsWith('.webp'))) return true;
    return false;
  }

  String _urlImagem(String caminho) {
    if (caminho.startsWith('http')) return caminho;
    // Remove o '/api' do baseUrl para chegar à raiz do servidor
    final base = DatabaseHelper.instance.baseUrl.replaceFirst('/api', '');
    return '$base$caminho';
  }

  void _verImagemFullscreen(String url) {
  showDialog(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                url,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, __, ___) => Container(
                  width: 200,
                  height: 200,
                  color: _surface,
                  child: const Center(
                    child: Icon(Icons.broken_image_rounded, color: _textMut, size: 48),
                  ),
                ),
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : Container(
                        width: 200,
                        height: 200,
                        color: _surface,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: progress.expectedTotalBytes != null
                                ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                                : null,
                            color: _accent,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
              ),
            ),
          ),
          Positioned(
            top: -12,
            right: -12,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  shape: BoxShape.circle,
                  border: Border.all(color: _border),
                ),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  // ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: _textPri),
        title: const Text('Registos',
            style: TextStyle(color: _textPri, fontSize: 17, fontWeight: FontWeight.w600)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _border),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _textSec, size: 20),
            onPressed: _carregar,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _accent, strokeWidth: 2.5))
          : _todos.isEmpty
              ? _buildEmpty()
              : Column(children: [
                  _buildFiltros(),
                  _buildInfoBar(),
                  Expanded(child: _buildTabela()),
                ]),
    );
  }

  Widget _buildFiltros() {
    return Container(
      color: _surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Barra de pesquisa
        Row(children: [
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: _alt,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _border),
              ),
              child: Row(children: [
                const SizedBox(width: 12),
                const Icon(Icons.search_rounded, color: _textSec, size: 17),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(color: _textPri, fontSize: 14),
                    cursorColor: _accent,
                    decoration: InputDecoration(
                      hintText: _filtroColuna != null
                          ? 'Pesquisar em "$_filtroColuna"...'
                          : 'Pesquisar...',
                      hintStyle: const TextStyle(color: _textMut, fontSize: 13),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                if (_searchCtrl.text.isNotEmpty)
                  GestureDetector(
                    onTap: () { _searchCtrl.clear(); },
                    child: const Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: Icon(Icons.close_rounded, color: _textSec, size: 16),
                    ),
                  ),
              ]),
            ),
          ),
          if (_temFiltros) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _limparFiltros,
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: _danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _danger.withOpacity(0.4)),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.filter_alt_off_rounded, color: _danger, size: 15),
                  SizedBox(width: 5),
                  Text('Limpar', style: TextStyle(color: _danger, fontSize: 13, fontWeight: FontWeight.w500)),
                ]),
              ),
            ),
          ],
        ]),

        // Chips de colunas
        const SizedBox(height: 10),
        SizedBox(
          height: 30,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _Chip(
                label: 'Todos',
                selected: _filtroColuna == null,
                onTap: () => setState(() { _filtroColuna = null; _aplicarFiltros(); }),
              ),
              const SizedBox(width: 6),
              ..._campos.map((c) {
                final nome = c['nome'] as String;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _Chip(
                    label: nome,
                    selected: _filtroColuna == nome,
                    onTap: () => setState(() {
                      _filtroColuna = _filtroColuna == nome ? null : nome;
                      _aplicarFiltros();
                    }),
                  ),
                );
              }),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildInfoBar() {
    return Container(
      color: _surface,
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
      child: Row(children: [
        Container(width: 3, height: 11, decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(
          _temFiltros
              ? '${_filtrados.length} de ${_todos.length} registos'
              : '${_todos.length} registo${_todos.length != 1 ? 's' : ''}',
          style: const TextStyle(color: _textSec, fontSize: 12),
        ),
        if (_sortColuna != null) ...[
          const SizedBox(width: 8),
          Icon(_sortAsc ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              color: _accent, size: 12),
          const SizedBox(width: 3),
          Text('Ordem: "$_sortColuna"',
              style: const TextStyle(color: _accent, fontSize: 12)),
        ],
      ]),
    );
  }

  Widget _buildTabela() {
    if (_filtrados.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.search_off_rounded, size: 36, color: _textMut),
          const SizedBox(height: 10),
          const Text('Sem resultados', style: TextStyle(color: _textPri, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Nenhum registo com "$_filtroBusca"',
              style: const TextStyle(color: _textSec, fontSize: 13)),
        ]),
      );
    }

    return Scrollbar(
      controller: _scrollV,
      child: SingleChildScrollView(
        controller: _scrollV,
        physics: const BouncingScrollPhysics(),
        child: LayoutBuilder(
          builder: (ctx, constraints) => Scrollbar(
            controller: _scrollH,
            child: SingleChildScrollView(
              controller: _scrollH,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(_surface),
                  columnSpacing: 20,
                  horizontalMargin: 16,
                  headingRowHeight: 42,
                  dataRowMinHeight: 56,
                  dataRowMaxHeight: 56,
                  dividerThickness: 0.5,
                  border: TableBorder(
                    horizontalInside: BorderSide(color: _border, width: 0.5),
                    top: BorderSide(color: _border, width: 0.5),
                  ),
                  columns: _campos.map((c) {
                    final nome = c['nome'] as String;
                    final isSorted = _sortColuna == nome;
                    return DataColumn(
                      label: GestureDetector(
                        onTap: () => _toggleSort(nome),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(
                            nome.toUpperCase(),
                            style: TextStyle(
                              color: isSorted ? _accent : _textSec,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Icon(
                            isSorted
                                ? (_sortAsc ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded)
                                : Icons.unfold_more_rounded,
                            size: 12,
                            color: isSorted ? _accent : _textMut,
                          ),
                        ]),
                      ),
                    );
                  }).toList(),
                  rows: _filtrados.asMap().entries.map((entry) {
                    final dados = _parseDados(entry.value);
                    return DataRow(
                      color: MaterialStateProperty.resolveWith((states) =>
                          entry.key.isEven ? Colors.transparent : Colors.white.withOpacity(0.02)),
                      cells: _campos.map((c) {
                        final val = dados[c['nome']];
                        final empty = val == null || val.toString().trim().isEmpty;

                        if (empty) {
                          return const DataCell(
                            Text('—', style: TextStyle(color: _textMut, fontSize: 14)),
                          );
                        }

                        // ─── CÉLULA DE IMAGEM ──────────────────────────────
                        if (_isImagem(val?.toString())) {
                          return DataCell(
                            GestureDetector(
                              onTap: () => _verImagemFullscreen(_urlImagem(val.toString())),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    _urlImagem(val.toString()),
                                    height: 44,
                                    width: 64,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.broken_image_rounded, color: _textMut, size: 18),
                                        SizedBox(width: 4),
                                        Text('Erro', style: TextStyle(color: _textMut, fontSize: 12)),
                                      ],
                                    ),
                                    loadingBuilder: (_, child, progress) => progress == null
                                        ? child
                                        : const SizedBox(
                                            width: 64,
                                            height: 44,
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 1.5,
                                                color: _accent,
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }

                        // ─── CÉLULA DE TEXTO NORMAL ────────────────────────
                        return DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 200),
                            child: Text(
                              val.toString(),
                              style: const TextStyle(color: _textPri, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(color: _surface, shape: BoxShape.circle, border: Border.all(color: _border)),
          child: const Icon(Icons.table_view_outlined, size: 26, color: _textMut),
        ),
        const SizedBox(height: 14),
        const Text('Sem registos', style: TextStyle(color: _textPri, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        const Text('Ainda não existem dados nesta pasta.', style: TextStyle(color: _textSec, fontSize: 13)),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? _accent.withOpacity(0.12) : _alt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? _accent.withOpacity(0.5) : _border),
        ),
        child: Text(label,
            style: TextStyle(
              color: selected ? _accent : _textSec,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            )),
      ),
    );
  }
}