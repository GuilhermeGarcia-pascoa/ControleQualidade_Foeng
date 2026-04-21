import 'dart:convert';
import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../database/database_helper.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'preencher_tabela_screen.dart';

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
  No? _no;

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
      final noData = await DatabaseHelper.instance.obterNoPorId(widget.noId);
      final camposRaw = await DatabaseHelper.instance.getCampos(widget.noId);
      final registosRaw = await DatabaseHelper.instance.getRegistos(widget.noId);
      setState(() {
        _no = noData;
        _campos = camposRaw.map((c) => {'id': c.id, 'nome': c.nomeCampo}).toList();
        _todos = registosRaw;
        _filtrados = List.from(_todos);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro: $e'), backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
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
    } catch (_) { return {}; }
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

  bool get _temFiltros =>
      _filtroBusca.isNotEmpty || _filtroColuna != null || _sortColuna != null;

  bool _isImagem(String? val) {
    if (val == null || val.isEmpty) return false;
    final lower = val.toLowerCase();
    return lower.startsWith('/uploads/') ||
        (lower.startsWith('http') &&
            (lower.endsWith('.jpg') || lower.endsWith('.jpeg') ||
             lower.endsWith('.png') || lower.endsWith('.gif') || lower.endsWith('.webp')));
  }

  String _urlImagem(String caminho) {
    if (caminho.startsWith('http')) return caminho;
    return '${AppConfig.serverBaseUrl}$caminho';
  }

  void _verImagemFullscreen(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(clipBehavior: Clip.none, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: InteractiveViewer(
              minScale: 0.5, maxScale: 4.0,
              child: Image.network(url, fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  width: 200, height: 200,
                  color: AppTheme.darkSurfaceHigh,
                  child: const Center(child: Icon(Icons.broken_image, size: 48, color: AppTheme.neutral500))))),
          ),
          Positioned(top: -12, right: -12,
            child: FloatingActionButton.small(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.neutral800,
              onPressed: () => Navigator.pop(context),
              child: const Icon(Icons.close_rounded))),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkSurfaceRaised : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
            color: isDark ? const Color(0xFFCBD5E1) : AppTheme.neutral800),
          onPressed: () => Navigator.pop(context)),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Registos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: isDark ? const Color(0xFFE2E8F0) : AppTheme.neutral900)),
          Text('${_filtrados.length} de ${_todos.length} entradas',
            style: const TextStyle(fontSize: 11, color: AppTheme.neutral400)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: _carregar,
            color: isDark ? AppTheme.neutral400 : AppTheme.neutral600,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1,
            color: isDark ? AppTheme.darkBorder : AppTheme.neutral100)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentBlue))
          : _todos.isEmpty
              ? _EmptyData(isDark: isDark)
              : Column(children: [
                  // ─── FILTER BAR ──────────────────────────────────────
                  Container(
                    color: isDark ? AppTheme.darkSurfaceRaised : Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Column(children: [
                      // Search
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkSurface : AppTheme.neutral50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? AppTheme.darkBorder : AppTheme.neutral200)),
                        child: Row(children: [
                          const Padding(padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Icon(Icons.search_rounded,
                              color: AppTheme.neutral400, size: 18)),
                          Expanded(child: TextField(
                            controller: _searchCtrl,
                            style: TextStyle(fontSize: 13,
                              color: isDark ? const Color(0xFFE2E8F0) : AppTheme.neutral900),
                            decoration: const InputDecoration(
                              hintText: 'Pesquisar registos...',
                              hintStyle: TextStyle(color: AppTheme.neutral400, fontSize: 13),
                              border: InputBorder.none,
                              filled: false,
                              contentPadding: EdgeInsets.symmetric(vertical: 10)),
                          )),
                          if (_temFiltros)
                            IconButton(
                              icon: const Icon(Icons.filter_alt_off_rounded,
                                color: AppTheme.error, size: 18),
                              onPressed: _limparFiltros,
                              tooltip: 'Limpar filtros'),
                        ]),
                      ),
                      // Column chips
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 32,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _ColumnChip(
                              label: 'Todos', selected: _filtroColuna == null,
                              onTap: () => setState(() { _filtroColuna = null; _aplicarFiltros(); })),
                            const SizedBox(width: 6),
                            ..._campos.map((c) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: _ColumnChip(
                                label: c['nome'] as String,
                                selected: _filtroColuna == c['nome'],
                                onTap: () => setState(() {
                                  _filtroColuna = _filtroColuna == c['nome'] ? null : c['nome'];
                                  _aplicarFiltros();
                                })),
                            )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ]),
                  ),
                  Divider(height: 1, color: isDark ? AppTheme.darkBorder : AppTheme.neutral100),
                  // ─── TABLE ────────────────────────────────────────────
                  Expanded(child: _filtrados.isEmpty
                      ? _NoResults(isDark: isDark, query: _filtroBusca)
                      : _DataTableView(
                          campos: _campos,
                          registos: _filtrados,
                          sortColuna: _sortColuna,
                          sortAsc: _sortAsc,
                          isDark: isDark,
                          scrollV: _scrollV,
                          scrollH: _scrollH,
                          onSort: _toggleSort,
                          parseDados: _parseDados,
                          isImagem: _isImagem,
                          urlImagem: _urlImagem,
                          onViewImage: _verImagemFullscreen,
                        )),
                ]),
      floatingActionButton: _no != null
          ? FloatingActionButton(
              backgroundColor: AppTheme.accentBlue,
              foregroundColor: Colors.white,
              onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => PreencherTabelaScreen(no: _no!)))
                  .then((ok) { if (ok == true) _carregar(); }),
              child: const Icon(Icons.add_rounded),
            )
          : null,
    );
  }
}

class _ColumnChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ColumnChip({required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.accentBlue
              : (isDark ? AppTheme.darkSurfaceHigh : AppTheme.neutral100),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.accentBlue
                : (isDark ? AppTheme.darkBorder : AppTheme.neutral200))),
        child: Text(label,
          style: TextStyle(
            fontSize: 12, fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? Colors.white
                : (isDark ? AppTheme.neutral300 : AppTheme.neutral600))),
      ),
    );
  }
}

class _DataTableView extends StatelessWidget {
  final List<Map<String, dynamic>> campos;
  final List<dynamic> registos;
  final String? sortColuna;
  final bool sortAsc;
  final bool isDark;
  final ScrollController scrollV;
  final ScrollController scrollH;
  final void Function(String) onSort;
  final Map<String, dynamic> Function(dynamic) parseDados;
  final bool Function(String?) isImagem;
  final String Function(String) urlImagem;
  final void Function(String) onViewImage;

  const _DataTableView({
    required this.campos, required this.registos, required this.sortColuna,
    required this.sortAsc, required this.isDark, required this.scrollV,
    required this.scrollH, required this.onSort, required this.parseDados,
    required this.isImagem, required this.urlImagem, required this.onViewImage,
  });

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: scrollV, thumbVisibility: true,
      child: SingleChildScrollView(
        controller: scrollV,
        child: LayoutBuilder(
          builder: (ctx, constraints) => Scrollbar(
            controller: scrollH, thumbVisibility: true,
            child: SingleChildScrollView(
              controller: scrollH,
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    isDark ? AppTheme.darkSurfaceHigh : AppTheme.neutral50),
                  dataRowMinHeight: 52,
                  dataRowMaxHeight: double.infinity,
                  showCheckboxColumn: false,
                  headingTextStyle: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    letterSpacing: 0.5, color: AppTheme.neutral500),
                  columns: campos.map((c) {
                    final nome = c['nome'] as String;
                    final isSorted = sortColuna == nome;
                    return DataColumn(
                      label: InkWell(
                        onTap: () => onSort(nome),
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Text(nome.toUpperCase(),
                              style: TextStyle(
                                color: isSorted ? AppTheme.accentBlue : null,
                                fontWeight: isSorted ? FontWeight.w700 : FontWeight.w600)),
                            if (isSorted) ...[
                              const SizedBox(width: 4),
                              Icon(sortAsc ? Icons.arrow_upward_rounded
                                  : Icons.arrow_downward_rounded,
                                size: 12, color: AppTheme.accentBlue),
                            ],
                          ]),
                        ),
                      ),
                    );
                  }).toList(),
                  rows: registos.map((entry) {
                    final dados = parseDados(entry);
                    return DataRow(
                      cells: campos.map((c) {
                        final val = dados[c['nome']];
                        final empty = val == null || val.toString().trim().isEmpty;
                        if (empty) {
                          return DataCell(Text('—',
                            style: TextStyle(
                              color: isDark ? AppTheme.neutral600 : AppTheme.neutral300)));
                        }
                        if (isImagem(val?.toString())) {
                          return DataCell(Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: GestureDetector(
                              onTap: () => onViewImage(urlImagem(val.toString())),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(urlImagem(val.toString()),
                                  height: 44, width: 44, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 44, width: 44,
                                    decoration: BoxDecoration(
                                      color: isDark ? AppTheme.darkSurfaceHigh : AppTheme.neutral100,
                                      borderRadius: BorderRadius.circular(8)),
                                    child: const Icon(Icons.broken_image, size: 18,
                                      color: AppTheme.neutral400)))),
                            ),
                          ));
                        }
                        return DataCell(Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 220),
                            child: Text(val.toString(),
                              style: TextStyle(fontSize: 13,
                                color: isDark ? const Color(0xFFCBD5E1) : AppTheme.neutral800)))));
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
}

class _EmptyData extends StatelessWidget {
  final bool isDark;
  const _EmptyData({required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 72, height: 72,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurfaceHigh : AppTheme.neutral100,
          borderRadius: BorderRadius.circular(20)),
        child: Icon(Icons.table_chart_outlined, size: 32,
          color: isDark ? AppTheme.neutral500 : AppTheme.neutral400)),
      const SizedBox(height: 16),
      const Text('Sem registos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      const Text('Ainda não existem dados submetidos nesta pasta.',
        style: TextStyle(fontSize: 13, color: AppTheme.neutral400)),
    ]));
  }
}

class _NoResults extends StatelessWidget {
  final bool isDark;
  final String query;
  const _NoResults({required this.isDark, required this.query});
  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.search_off_rounded, size: 48,
        color: isDark ? AppTheme.neutral600 : AppTheme.neutral300),
      const SizedBox(height: 12),
      const Text('Sem resultados', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Text('Nenhum registo encontrado para "$query"',
        style: const TextStyle(fontSize: 13, color: AppTheme.neutral400)),
    ]));
  }
}