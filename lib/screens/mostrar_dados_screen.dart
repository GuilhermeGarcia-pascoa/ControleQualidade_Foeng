import 'dart:convert';
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'dashboard_screen.dart'; // Importante para aceder ao AppTheme

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
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
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
         lower.endsWith('.webp'))) {
      return true;
    }
    return false;
  }

  String _urlImagem(String caminho) {
    if (caminho.startsWith('http')) return caminho;
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
                  errorBuilder: (_, __, ___) => Container(
                    width: 200,
                    height: 200,
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                    ),
                  ),
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : Container(
                          width: 200,
                          height: 200,
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                ),
              ),
            ),
            Positioned(
              top: -12,
              right: -12,
              child: FloatingActionButton.small(
                onPressed: () => Navigator.pop(context),
                child: const Icon(Icons.close),
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
      appBar: AppBar(
        title: const Text('Registos'),
        actions: [
          // ─── BOTÃO DE TEMA ───
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
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
            onPressed: _carregar,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _todos.isEmpty
              ? _buildEmpty()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildFiltros(),
                    _buildInfoBar(),
                    const Divider(height: 1),
                    Expanded(child: _buildTabela()),
                  ],
                ),
    );
  }

  Widget _buildFiltros() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: _filtroColuna != null
                        ? 'Pesquisar em "$_filtroColuna"...'
                        : 'Pesquisar em tudo...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => _searchCtrl.clear(),
                          )
                        : null,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              if (_temFiltros) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _limparFiltros,
                  icon: const Icon(Icons.filter_alt_off),
                  label: const Text('Limpar'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Todos os campos'),
                  selected: _filtroColuna == null,
                  onSelected: (val) => setState(() {
                    _filtroColuna = null;
                    _aplicarFiltros();
                  }),
                ),
                const SizedBox(width: 8),
                ..._campos.map((c) {
                  final nome = c['nome'] as String;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(nome),
                      selected: _filtroColuna == nome,
                      onSelected: (val) => setState(() {
                        _filtroColuna = _filtroColuna == nome ? null : nome;
                        _aplicarFiltros();
                      }),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16),
          const SizedBox(width: 8),
          Text(
            _temFiltros
                ? 'A mostrar ${_filtrados.length} de ${_todos.length} registos'
                : 'Total de ${_todos.length} registos',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (_sortColuna != null) ...[
            const Spacer(),
            Icon(_sortAsc ? Icons.arrow_upward : Icons.arrow_downward, size: 16),
            const SizedBox(width: 4),
            Text('Ordenado por $_sortColuna', style: const TextStyle(fontSize: 12)),
          ]
        ],
      ),
    );
  }

  Widget _buildTabela() {
    if (_filtrados.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Sem resultados', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Nenhum registo encontrado para "$_filtroBusca"'),
          ],
        ),
      );
    }

    return Scrollbar(
      controller: _scrollV,
      child: SingleChildScrollView(
        controller: _scrollV,
        child: LayoutBuilder(
          builder: (ctx, constraints) => Scrollbar(
            controller: _scrollH,
            child: SingleChildScrollView(
              controller: _scrollH,
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  showCheckboxColumn: false,
                  columns: _campos.map((c) {
                    final nome = c['nome'] as String;
                    final isSorted = _sortColuna == nome;
                    return DataColumn(
                      label: InkWell(
                        onTap: () => _toggleSort(nome),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              nome.toUpperCase(),
                              style: TextStyle(fontWeight: isSorted ? FontWeight.bold : FontWeight.normal),
                            ),
                            if (isSorted) ...[
                              const SizedBox(width: 4),
                              Icon(_sortAsc ? Icons.arrow_upward : Icons.arrow_downward, size: 16),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  rows: _filtrados.map((entry) {
                    final dados = _parseDados(entry);
                    return DataRow(
                      cells: _campos.map((c) {
                        final val = dados[c['nome']];
                        final empty = val == null || val.toString().trim().isEmpty;

                        if (empty) {
                          return const DataCell(Text('—', style: TextStyle(color: Colors.grey)));
                        }

                        // ─── CÉLULA DE IMAGEM ───
                        if (_isImagem(val?.toString())) {
                          return DataCell(
                            GestureDetector(
                              onTap: () => _verImagemFullscreen(_urlImagem(val.toString())),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Image.network(
                                  _urlImagem(val.toString()),
                                  height: 40,
                                  width: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey),
                                ),
                              ),
                            ),
                          );
                        }

                        // ─── CÉLULA DE TEXTO NORMAL ───
                        return DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 250),
                            child: Text(
                              val.toString(),
                              maxLines: 2,
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
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.table_view, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Sem registos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text('Ainda não existem dados submetidos nesta pasta.'),
        ],
      ),
    );
  }
}
