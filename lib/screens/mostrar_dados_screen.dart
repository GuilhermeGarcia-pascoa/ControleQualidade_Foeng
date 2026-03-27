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
        content: Text('Erro: $e', style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red.shade800,
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
              borderRadius: BorderRadius.circular(16),
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
                backgroundColor: Theme.of(context).colorScheme.surface,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Registos da Tabela', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Consulta e pesquisa de dados', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6))),
          ],
        ),
        actions: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: AppTheme.themeMode,
            builder: (context, currentMode, _) {
              final isDarkTheme = currentMode == ThemeMode.dark || 
                (currentMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);
              return IconButton(
                icon: Icon(isDarkTheme ? Icons.light_mode : Icons.dark_mode),
                tooltip: 'Mudar Tema',
                onPressed: () {
                  AppTheme.themeMode.value = isDarkTheme ? ThemeMode.light : ThemeMode.dark;
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Atualizar',
            onPressed: _carregar,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _todos.isEmpty
              ? _buildEmpty(theme)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildFiltros(theme, isDark),
                    _buildInfoBar(theme),
                    Expanded(child: _buildTabela(theme, isDark)),
                  ],
                ),
    );
  }

  Widget _buildFiltros(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
                        : 'Pesquisar em todos os campos...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () => _searchCtrl.clear(),
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? theme.colorScheme.surfaceVariant.withOpacity(0.3) : theme.colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                  ),
                ),
              ),
              if (_temFiltros) ...[
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: IconButton(
                    onPressed: _limparFiltros,
                    icon: const Icon(Icons.filter_alt_off_rounded, color: Colors.red),
                    tooltip: 'Limpar Filtros',
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Todos'),
                  selected: _filtroColuna == null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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

  Widget _buildInfoBar(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.bar_chart_rounded, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _temFiltros
                  ? 'A mostrar ${_filtrados.length} de ${_todos.length} registos'
                  : 'Total de ${_todos.length} registos submetidos',
              style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
            ),
          ),
          if (_sortColuna != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text('Ordem: $_sortColuna', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 4),
                  Icon(_sortAsc ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 14),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildTabela(ThemeData theme, bool isDark) {
    if (_filtrados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: theme.disabledColor),
            const SizedBox(height: 16),
            const Text('Sem resultados', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Nenhum registo encontrado para "$_filtroBusca"', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
          ],
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      elevation: isDark ? 1 : 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isDark ? BorderSide.none : BorderSide(color: theme.dividerColor.withOpacity(0.5)),
      ),
      clipBehavior: Clip.antiAlias, // Para a tabela não sair dos cantos arredondados
      child: Scrollbar(
        controller: _scrollV,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _scrollV,
          physics: const BouncingScrollPhysics(),
          child: LayoutBuilder(
            builder: (ctx, constraints) => Scrollbar(
              controller: _scrollH,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scrollH,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(theme.colorScheme.surfaceVariant.withOpacity(isDark ? 0.3 : 0.5)),
                    dataRowMinHeight: 56,
                    dataRowMaxHeight: double.infinity,
                    showCheckboxColumn: false,
                    columns: _campos.map((c) {
                      final nome = c['nome'] as String;
                      final isSorted = _sortColuna == nome;
                      return DataColumn(
                        label: InkWell(
                          onTap: () => _toggleSort(nome),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  nome.toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: isSorted ? FontWeight.bold : FontWeight.w600,
                                    color: isSorted ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                if (isSorted) ...[
                                  const SizedBox(width: 4),
                                  Icon(_sortAsc ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 16, color: theme.colorScheme.primary),
                                ],
                              ],
                            ),
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
                            return DataCell(Text('—', style: TextStyle(color: theme.disabledColor)));
                          }

                          // ─── CÉLULA DE IMAGEM ───
                          if (_isImagem(val?.toString())) {
                            return DataCell(
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: GestureDetector(
                                  onTap: () => _verImagemFullscreen(_urlImagem(val.toString())),
                                  child: Hero(
                                    tag: val.toString(), // Efeito suave ao abrir a imagem
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          _urlImagem(val.toString()),
                                          height: 48,
                                          width: 48,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            height: 48, width: 48,
                                            color: theme.colorScheme.surfaceVariant,
                                            child: const Icon(Icons.broken_image, color: Colors.grey, size: 24),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }

                          // ─── CÉLULA DE TEXTO NORMAL ───
                          return DataCell(
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12.0),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 250),
                                child: Text(
                                  val.toString(),
                                  style: const TextStyle(fontSize: 14),
                                ),
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
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.table_chart_outlined, size: 64, color: theme.disabledColor),
          ),
          const SizedBox(height: 24),
          const Text('Sem registos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Ainda não existem dados submetidos nesta pasta.',
            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 15),
          ),
        ],
      ),
    );
  }
}