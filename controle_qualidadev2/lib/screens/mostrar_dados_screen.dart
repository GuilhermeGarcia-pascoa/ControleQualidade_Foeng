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

class _MostrarDadosScreenState extends State<MostrarDadosScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollV = ScrollController();
  final ScrollController _scrollH = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();

  bool _loading = true;
  List<Map<String, dynamic>> _campos = [];
  List<dynamic> _todos = [];
  List<dynamic> _filtrados = [];
  No? _no;

  // Paginação
  int _currentPage = 1;
  int _totalPages = 1;
  final int _limit = 30;
  int _total = 0;

  String _filtroBusca = '';
  String? _filtroColuna;
  String? _sortColuna;
  bool _sortAsc = true;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim =
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _carregar();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _scrollV.dispose();
    _scrollH.dispose();
    _searchCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    try {
      final noData =
          await DatabaseHelper.instance.obterNoPorId(widget.noId);
      final camposRaw =
          await DatabaseHelper.instance.getCampos(widget.noId);
      final registosResponse =
          await DatabaseHelper.instance.getRegistos(widget.noId,
              page: _currentPage,
              limit: _limit,
              search: _filtroBusca.isNotEmpty ? _filtroBusca : null,
              filtroColuna: _filtroColuna);
      final registosRaw = registosResponse['registos'];
      final total = registosResponse['total'];
      final totalPages = registosResponse['totalPages'];

      setState(() {
        _no = noData;
        _campos = camposRaw
            .map((c) => {
                  'id': c.id,
                  'nome': c.nomeCampo,
                  'tipo': c.tipoCampo,
                })
            .toList();
        _todos = registosRaw;
        _filtrados = List.from(_todos);
        _total = total;
        _totalPages = totalPages;
        _loading = false;
      });
      _animCtrl.forward(from: 0);
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
    }
  }

  void _onSearch() {
    setState(() {
      _filtroBusca = _searchCtrl.text.trim().toLowerCase();
      _currentPage = 1; // Reset to first page when search changes
      _carregar();
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

  void _previousPage() {
    if (_currentPage > 1) {
      setState(() => _currentPage--);
      _carregar();
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages) {
      setState(() => _currentPage++);
      _carregar();
    }
  }

  void _toggleSort(String coluna) {
    setState(() {
      _sortColuna == coluna
          ? _sortAsc = !_sortAsc
          : (_sortColuna = coluna, _sortAsc = true);
      // Sorting is now handled on backend if needed, but for now keep local
      _filtrados = List.from(_filtrados);
      _filtrados.sort((a, b) {
        String va;
        String vb;
        if (_sortColuna == '_autor') {
          va = (a['nome_utilizador'] ?? '').toString().toLowerCase();
          vb = (b['nome_utilizador'] ?? '').toString().toLowerCase();
        } else {
          va = (_parseDados(a)[_sortColuna] ?? '').toString().toLowerCase();
          vb = (_parseDados(b)[_sortColuna] ?? '').toString().toLowerCase();
        }
        final na = double.tryParse(va);
        final nb = double.tryParse(vb);
        final cmp = (na != null && nb != null)
            ? na.compareTo(nb)
            : va.compareTo(vb);
        return _sortAsc ? cmp : -cmp;
      });
    });
  }

  void _limparFiltros() {
    _searchCtrl.clear();
    setState(() {
      _filtroBusca = '';
      _filtroColuna = null;
      _sortColuna = null;
      _sortAsc = true;
      _currentPage = 1;
      _carregar();
    });
  }

  bool get _temFiltros =>
      _filtroBusca.isNotEmpty || _filtroColuna != null || _sortColuna != null;

  bool _campoEhImagem(Map<String, dynamic> campo) {
    final tipo = (campo['tipo'] ?? '').toString().toLowerCase();
    return tipo == 'foto' || tipo == 'imagem' || tipo == 'file';
  }

  bool _isImagem(String? val) {
    if (val == null || val.isEmpty) return false;
    final lower = val.toLowerCase();
    return lower.startsWith('/uploads/') ||
        (lower.startsWith('http') &&
            (lower.endsWith('.jpg') ||
                lower.endsWith('.jpeg') ||
                lower.endsWith('.png') ||
                lower.endsWith('.gif') ||
                lower.endsWith('.webp')));
  }

  String? _extrairImagemDoRegisto(
      Map<String, dynamic> dados, Map<String, dynamic> campo) {
    final nomeCampo = campo['nome']?.toString();
    final valorDireto = dados[nomeCampo];
    if (_isImagem(valorDireto?.toString())) {
      return valorDireto.toString();
    }

    final ficheiros = dados['_files'];
    if (ficheiros is! List) return null;

    for (final ficheiro in ficheiros) {
      if (ficheiro is! Map) continue;

      final mapa = Map<String, dynamic>.from(ficheiro);
      final caminho = mapa['path']?.toString();
      if (!_isImagem(caminho)) continue;

      final fieldname = mapa['fieldname']?.toString();
      if (fieldname != null &&
          nomeCampo != null &&
          fieldname.toLowerCase() == nomeCampo.toLowerCase()) {
        return caminho;
      }
    }

    return null;
  }

  String _urlImagem(String caminho) {
    if (caminho.startsWith('http')) return caminho;
    return '${AppConfig.serverBaseUrl}$caminho';
  }

  void _verImagemFullscreen(String url) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(0),
        elevation: 0,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Fundo semitransparente - tocável para fechar
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                color: Colors.black.withOpacity(0.85),
              ),
            ),
            
            // Conteúdo centrado
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: InteractiveViewer(
                            minScale: 0.8,
                            maxScale: 4.0,
                            boundaryMargin: const EdgeInsets.all(16),
                            child: Image.network(
                              url,
                              fit: BoxFit.contain,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            (loadingProgress.expectedTotalBytes ?? 1)
                                        : null,
                                    color: Colors.white,
                                  ),
                                );
                              },
                              errorBuilder: (_, __, ___) => Container(
                                color: AppTheme.darkSurfaceHigh,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.broken_image,
                                      size: 64,
                                      color: AppTheme.neutral500,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Erro ao carregar imagem',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Botão fechar no topo direito
            Positioned(
              top: 24,
              right: 24,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.95),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: AppTheme.neutral800,
                    size: 24,
                  ),
                ),
              ),
            ),
            
            // Instruções no topo esquerdo
            Positioned(
              bottom: 24,
              left: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.pinch_rounded,
                      size: 16,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Arraste para ampliar • Toque para fechar',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── SUMMARY STATS ──────────────────────────────────────────────────────
  Map<String, int> _calcularAutores() {
    final contagem = <String, int>{};
    for (final reg in _todos) {
      final autor = reg['nome_utilizador']?.toString() ?? 'Desconhecido';
      contagem[autor] = (contagem[autor] ?? 0) + 1;
    }
    return contagem;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final autores = _calcularAutores();
    final topAutor = autores.entries.isEmpty
        ? null
        : autores.entries.reduce((a, b) => a.value > b.value ? a : b);

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.darkSurface : const Color(0xFFF0F4FF),
      appBar: _buildAppBar(isDark),
      body: _loading
          ? _buildLoader()
          : _todos.isEmpty
              ? _EmptyData(isDark: isDark)
              : FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(children: [
                    // ─── STATS BANNER ────────────────────────────────
                    _StatsBanner(
                      total: _total,
                      filtrado: _filtrados.length,
                      topAutor: topAutor?.key,
                      topCount: topAutor?.value ?? 0,
                      isDark: isDark,
                    ),

                    // ─── FILTER BAR ──────────────────────────────────
                    _FilterBar(
                      searchCtrl: _searchCtrl,
                      campos: _campos,
                      filtroColuna: _filtroColuna,
                      temFiltros: _temFiltros,
                      isDark: isDark,
                      onColumnFilter: (col) => setState(() {
                        _filtroColuna = _filtroColuna == col ? null : col;
                        _currentPage = 1; // Reset to first page when filter changes
                        _carregar();
                      }),
                      onClearFilters: _limparFiltros,
                    ),

                    Divider(
                        height: 1,
                        color: isDark
                            ? AppTheme.darkBorder
                            : AppTheme.neutral200),

                    // ─── TABLE ────────────────────────────────────────
                    Expanded(
                      child: _filtrados.isEmpty
                          ? _NoResults(
                              isDark: isDark, query: _filtroBusca)
                          : Column(
                            children: [
                              Expanded(
                                child: _DataTableView(
                                  campos: _campos,
                                  registos: _filtrados,
                                  sortColuna: _sortColuna,
                                  sortAsc: _sortAsc,
                                  isDark: isDark,
                                  scrollV: _scrollV,
                                  scrollH: _scrollH,
                                  onSort: _toggleSort,
                                  parseDados: _parseDados,
                                  isCampoImagem: _campoEhImagem,
                                  isImagem: _isImagem,
                                  resolveImagePath: _extrairImagemDoRegisto,
                                  urlImagem: _urlImagem,
                                  onViewImage: _verImagemFullscreen,
                                ),
                              ),
                              // ─── PAGINATION CONTROLS ──────────────────────
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isDark ? AppTheme.darkSurfaceRaised : Colors.white,
                                  border: Border(top: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.neutral200)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Página $_currentPage de $_totalPages',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark ? AppTheme.neutral400 : AppTheme.neutral600,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.chevron_left_rounded),
                                          onPressed: _currentPage > 1 ? _previousPage : null,
                                          color: _currentPage > 1
                                              ? (isDark ? AppTheme.neutral300 : AppTheme.neutral700)
                                              : AppTheme.neutral400,
                                          iconSize: 20,
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.chevron_right_rounded),
                                          onPressed: _currentPage < _totalPages ? _nextPage : null,
                                          color: _currentPage < _totalPages
                                              ? (isDark ? AppTheme.neutral300 : AppTheme.neutral700)
                                              : AppTheme.neutral400,
                                          iconSize: 20,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                    ),
                  ]),
                ),
      floatingActionButton: _no != null
          ? FloatingActionButton(
              backgroundColor: AppTheme.accentBlue,
              foregroundColor: Colors.white,
              onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              PreencherTabelaScreen(no: _no!)))
                  .then((ok) {
                if (ok == true) _carregar();
              }),
              child: const Icon(Icons.add_rounded),
            )
          : null,
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: isDark ? AppTheme.darkSurfaceRaised : Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded,
            color: isDark ? const Color(0xFFCBD5E1) : AppTheme.neutral800),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Registos',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
                color: isDark
                    ? const Color(0xFFE2E8F0)
                    : AppTheme.neutral900)),
        Text(
            '${_filtrados.length} de $_total entradas',
            style:
                const TextStyle(fontSize: 11, color: AppTheme.neutral400)),
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
        child: Divider(
            height: 1,
            color: isDark ? AppTheme.darkBorder : AppTheme.neutral100),
      ),
    );
  }

  Widget _buildLoader() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppTheme.accentBlue),
          SizedBox(height: 16),
          Text('A carregar registos...',
              style:
                  TextStyle(color: AppTheme.neutral400, fontSize: 13)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATS BANNER
// ─────────────────────────────────────────────────────────────────────────────

class _StatsBanner extends StatelessWidget {
  final int total;
  final int filtrado;
  final String? topAutor;
  final int topCount;
  final bool isDark;

  const _StatsBanner({
    required this.total,
    required this.filtrado,
    required this.topAutor,
    required this.topCount,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? AppTheme.darkSurfaceRaised : Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(children: [
        _StatPill(
          icon: Icons.table_rows_rounded,
          label: 'Total',
          value: '$total',
          color: AppTheme.accentBlue,
          isDark: isDark,
        ),
        const SizedBox(width: 10),
        _StatPill(
          icon: Icons.filter_list_rounded,
          label: 'Visíveis',
          value: '$filtrado',
          color: AppTheme.accentTeal,
          isDark: isDark,
        ),
        if (topAutor != null) ...[
          const SizedBox(width: 10),
          Expanded(
            child: _AuthorPill(
              autor: topAutor!,
              count: topCount,
              isDark: isDark,
            ),
          ),
        ],
      ]),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color)),
          Text(label,
              style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.neutral400,
                  letterSpacing: 0.3)),
        ]),
      ]),
    );
  }
}

class _AuthorPill extends StatelessWidget {
  final String autor;
  final int count;
  final bool isDark;

  const _AuthorPill(
      {required this.autor, required this.count, required this.isDark});

  String get _initials {
    final parts =
        autor.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceHigh : AppTheme.neutral50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: isDark ? AppTheme.darkBorder : AppTheme.neutral200),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: AppTheme.accentBlue.withOpacity(0.15),
          child: Text(_initials,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accentBlue)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(autor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFFCBD5E1)
                            : AppTheme.neutral800)),
                Text('$count registo${count != 1 ? 's' : ''}',
                    style: const TextStyle(
                        fontSize: 9,
                        color: AppTheme.neutral400,
                        letterSpacing: 0.3)),
              ]),
        ),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.warning.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text('TOP',
              style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.warning,
                  letterSpacing: 0.5)),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FILTER BAR
// ─────────────────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final List<Map<String, dynamic>> campos;
  final String? filtroColuna;
  final bool temFiltros;
  final bool isDark;
  final void Function(String?) onColumnFilter;
  final VoidCallback onClearFilters;

  const _FilterBar({
    required this.searchCtrl,
    required this.campos,
    required this.filtroColuna,
    required this.temFiltros,
    required this.isDark,
    required this.onColumnFilter,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? AppTheme.darkSurfaceRaised : Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(children: [
        // Search
        Container(
          decoration: BoxDecoration(
            color:
                isDark ? AppTheme.darkSurface : AppTheme.neutral50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: isDark
                    ? AppTheme.darkBorder
                    : AppTheme.neutral200)),
          child: Row(children: [
            const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.search_rounded,
                    color: AppTheme.neutral400, size: 18)),
            Expanded(
                child: TextField(
              controller: searchCtrl,
              style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? const Color(0xFFE2E8F0)
                      : AppTheme.neutral900),
              decoration: const InputDecoration(
                  hintText: 'Pesquisar registos ou autores...',
                  hintStyle: TextStyle(
                      color: AppTheme.neutral400, fontSize: 13),
                  border: InputBorder.none,
                  filled: false,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 10)),
            )),
            if (temFiltros)
              IconButton(
                  icon: const Icon(Icons.filter_alt_off_rounded,
                      color: AppTheme.error, size: 18),
                  onPressed: onClearFilters,
                  tooltip: 'Limpar filtros'),
          ]),
        ),
        const SizedBox(height: 10),
        // Column chips (incluindo "Autor")
        SizedBox(
          height: 32,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _ColumnChip(
                  label: 'Todos',
                  selected: filtroColuna == null,
                  onTap: () => onColumnFilter(null)),
              const SizedBox(width: 6),
              // Chip especial para Autor
              _ColumnChip(
                label: 'Autor',
                selected: filtroColuna == '_autor',
                onTap: () => onColumnFilter('_autor'),
                isAuthor: true,
              ),
              const SizedBox(width: 6),
              ...campos.map((c) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _ColumnChip(
                        label: c['nome'] as String,
                        selected: filtroColuna == c['nome'],
                        onTap: () => onColumnFilter(c['nome'])),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DATA TABLE
// ─────────────────────────────────────────────────────────────────────────────

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
  final bool Function(Map<String, dynamic>) isCampoImagem;
  final bool Function(String?) isImagem;
  final String? Function(Map<String, dynamic>, Map<String, dynamic>)
      resolveImagePath;
  final String Function(String) urlImagem;
  final void Function(String) onViewImage;

  const _DataTableView({
    required this.campos,
    required this.registos,
    required this.sortColuna,
    required this.sortAsc,
    required this.isDark,
    required this.scrollV,
    required this.scrollH,
    required this.onSort,
    required this.parseDados,
    required this.isCampoImagem,
    required this.isImagem,
    required this.resolveImagePath,
    required this.urlImagem,
    required this.onViewImage,
  });

  @override
  Widget build(BuildContext context) {
    // Todas as colunas: Autor + campos dinâmicos
    final todasColunas = <Map<String, dynamic>>[
      {'id': '_autor', 'nome': 'Autor', 'isAuthor': true},
      ...campos,
    ];

    return Scrollbar(
      controller: scrollV,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: scrollV,
        child: LayoutBuilder(
          builder: (ctx, constraints) => Scrollbar(
            controller: scrollH,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: scrollH,
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                      isDark
                          ? AppTheme.darkSurfaceHigh
                          : const Color(0xFFF0F4FF)),
                  dataRowMinHeight: 56,
                  dataRowMaxHeight: double.infinity,
                  showCheckboxColumn: false,
                  headingTextStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: AppTheme.neutral500),
                  columns: todasColunas.map((c) {
                    final nome = c['nome'] as String;
                    final colKey =
                        c['isAuthor'] == true ? '_autor' : nome;
                    final isSorted = sortColuna == colKey;
                    final isAuthor = c['isAuthor'] == true;

                    return DataColumn(
                      label: InkWell(
                        onTap: () => onSort(colKey),
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 6, horizontal: 2),
                          child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isAuthor) ...[
                                  Icon(Icons.person_outline_rounded,
                                      size: 12,
                                      color: isSorted
                                          ? AppTheme.accentTeal
                                          : AppTheme.neutral400),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  nome.toUpperCase(),
                                  style: TextStyle(
                                      color: isSorted
                                          ? (isAuthor
                                              ? AppTheme.accentTeal
                                              : AppTheme.accentBlue)
                                          : null,
                                      fontWeight: isSorted
                                          ? FontWeight.w700
                                          : FontWeight.w600),
                                ),
                                if (isSorted) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                      sortAsc
                                          ? Icons.arrow_upward_rounded
                                          : Icons
                                              .arrow_downward_rounded,
                                      size: 12,
                                      color: isAuthor
                                          ? AppTheme.accentTeal
                                          : AppTheme.accentBlue),
                                ],
                              ]),
                        ),
                      ),
                    );
                  }).toList(),
                  rows: registos.map((entry) {
                    final dados = parseDados(entry);
                    final nomeAutor =
                        entry['nome_utilizador']?.toString() ??
                            'Desconhecido';

                    return DataRow(cells: [
                      // ── COLUNA AUTOR ────────────────────────────
                      DataCell(_AuthorCell(
                          nome: nomeAutor, isDark: isDark)),

                      // ── COLUNAS DINÂMICAS ────────────────────────
                      ...campos.map((c) {
                        final val = dados[c['nome']];
                        final imagePath = isCampoImagem(c)
                            ? resolveImagePath(dados, c)
                            : null;
                        final empty = imagePath == null &&
                            (val == null || val.toString().trim().isEmpty);
                        if (empty) {
                          return DataCell(Text(' ',
                              style: TextStyle(
                                  color: isDark
                                      ? AppTheme.neutral600
                                      : AppTheme.neutral300)));
                        }
                        if (imagePath != null || isImagem(val?.toString())) {
                          final caminho = imagePath ?? val.toString();
                          return DataCell(Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8),
                            child: GestureDetector(
                              onTap: () => onViewImage(
                                  urlImagem(caminho)),
                              child: ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(8),
                                child: Image.network(
                                    urlImagem(caminho),
                                    height: 44,
                                    width: 44,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        Container(
                                            height: 44,
                                            width: 44,
                                            decoration: BoxDecoration(
                                                color: isDark
                                                    ? AppTheme
                                                        .darkSurfaceHigh
                                                    : AppTheme
                                                        .neutral100,
                                                borderRadius:
                                                    BorderRadius
                                                        .circular(8)),
                                            child: const Icon(
                                                Icons.broken_image,
                                                size: 18,
                                                color: AppTheme
                                                    .neutral400))),
                              ),
                            ),
                          ));
                        }
                        return DataCell(Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                                maxWidth: 200),
                            child: Text(val.toString(),
                                style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? const Color(0xFFCBD5E1)
                                        : AppTheme.neutral800)),
                          ),
                        ));
                      }),
                    ]);
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

// ─────────────────────────────────────────────────────────────────────────────
// AUTHOR CELL — chip visual com avatar e nome
// ─────────────────────────────────────────────────────────────────────────────

class _AuthorCell extends StatelessWidget {
  final String nome;
  final bool isDark;

  const _AuthorCell({required this.nome, required this.isDark});

  String get _initials {
    final parts =
        nome.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  // Gera uma cor consistente baseada no nome
  Color _avatarColor() {
    final colors = [
      AppTheme.accentBlue,
      AppTheme.accentTeal,
      AppTheme.warning,
      const Color(0xFF7C3AED),
      const Color(0xFFEC4899),
      AppTheme.success,
    ];
    final idx = nome.codeUnits.fold(0, (a, b) => a + b) % colors.length;
    return colors[idx];
  }

  @override
  Widget build(BuildContext context) {
    final color = _avatarColor();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: color.withOpacity(0.25),
            child: Text(_initials,
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: color)),
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 130),
            child: Text(nome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COLUMN CHIP
// ─────────────────────────────────────────────────────────────────────────────

class _ColumnChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isAuthor;

  const _ColumnChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.isAuthor = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor =
        isAuthor ? AppTheme.accentTeal : AppTheme.accentBlue;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? activeColor
              : (isDark
                  ? AppTheme.darkSurfaceHigh
                  : AppTheme.neutral100),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected
                  ? activeColor
                  : (isDark
                      ? AppTheme.darkBorder
                      : AppTheme.neutral200))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (isAuthor) ...[
            Icon(Icons.person_outline_rounded,
                size: 11,
                color: selected
                    ? Colors.white
                    : (isDark
                        ? AppTheme.neutral400
                        : AppTheme.neutral600)),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: selected
                      ? Colors.white
                      : (isDark
                          ? AppTheme.neutral300
                          : AppTheme.neutral600))),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATES
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyData extends StatelessWidget {
  final bool isDark;
  const _EmptyData({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.darkSurfaceHigh
                  : AppTheme.neutral100,
              borderRadius: BorderRadius.circular(20)),
          child: Icon(Icons.table_chart_outlined,
              size: 32,
              color: isDark
                  ? AppTheme.neutral500
                  : AppTheme.neutral400)),
      const SizedBox(height: 16),
      const Text('Sem registos',
          style:
              TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      const Text('Ainda não existem dados submetidos nesta pasta.',
          style: TextStyle(
              fontSize: 13, color: AppTheme.neutral400)),
    ]));
  }
}

class _NoResults extends StatelessWidget {
  final bool isDark;
  final String query;
  const _NoResults({required this.isDark, required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.search_off_rounded,
          size: 48,
          color:
              isDark ? AppTheme.neutral600 : AppTheme.neutral300),
      const SizedBox(height: 12),
      const Text('Sem resultados',
          style:
              TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Text('Nenhum registo encontrado para "$query"',
          style: const TextStyle(
              fontSize: 13, color: AppTheme.neutral400)),
    ]));
  }
}
