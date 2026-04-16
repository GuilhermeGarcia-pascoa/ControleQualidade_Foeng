import 'package:flutter/material.dart';
import 'admin_service.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final _service = AdminService.instance;
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  List<UtilizadorAdmin> _utilizadores = [];
  List<UtilizadorAdmin> _filtrados = [];
  bool _loading = true;
  String? _erro;
  String _filtroRole = '';

  static const _roles = ['admin', 'gestor', 'utilizador', 'viewer'];

  static const _roleColors = {
    'admin':      (bg: Color(0xFFEEEDFE), fg: Color(0xFF534AB7)),
    'gestor':     (bg: Color(0xFFE1F5EE), fg: Color(0xFF0F6E56)),
    'utilizador': (bg: Color(0xFFE6F1FB), fg: Color(0xFF185FA5)),
    'viewer':     (bg: Color(0xFFF1EFE8), fg: Color(0xFF5F5E5A)),
  };

  @override
  void initState() {
    super.initState();
    _carregar();
    _searchCtrl.addListener(_filtrar);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() { _loading = true; _erro = null; });
    try {
      final lista = await _service.getUtilizadores();
      setState(() { _utilizadores = lista; _filtrar(); _loading = false; });
    } on AdminServiceException catch (e) {
      setState(() { _erro = e.mensagem; _loading = false; });
    } catch (_) {
      setState(() { _erro = 'Erro de ligação.'; _loading = false; });
    }
  }

  void _filtrar() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtrados = _utilizadores.where((u) {
        final mq = q.isEmpty || u.nome.toLowerCase().contains(q) || u.email.toLowerCase().contains(q);
        final mr = _filtroRole.isEmpty || u.role == _filtroRole;
        return mq && mr;
      }).toList();
    });
  }

  ({Color bg, Color fg}) _coresRole(String role) =>
      _roleColors[role] ?? (bg: const Color(0xFFE6F1FB), fg: const Color(0xFF185FA5));

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final surfaceDim = scheme.surfaceContainerLow;

    return Scaffold(
      backgroundColor: surfaceDim,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: scheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Painel Admin', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: _abrirCriarUtilizador,
              icon: const Icon(Icons.person_add_rounded, size: 18),
              label: const Text('Criar'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? _buildErro()
              : RefreshIndicator(
                  onRefresh: _carregar,
                  child: CustomScrollView(
                    controller: _scrollCtrl,
                    slivers: [
                      SliverToBoxAdapter(child: _buildSearchBar()),
                      SliverToBoxAdapter(child: _buildFiltros()),
                      SliverToBoxAdapter(child: _buildStats()),
                      _buildLista(),
                    ],
                  ),
                ),
    );
  }

  // ─── Barra de pesquisa ───────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: SearchBar(
          controller: _searchCtrl,
          hintText: 'Pesquisar por nome ou email...',
          leading: const Icon(Icons.search_rounded, size: 20),
          trailing: [
            if (_searchCtrl.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () { _searchCtrl.clear(); _filtrar(); },
              ),
          ],
          onChanged: (_) => _filtrar(),
          elevation: const WidgetStatePropertyAll(0),
          side: WidgetStatePropertyAll(
            BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 0.5),
          ),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          ),
        ),
      ),
    );
  }

  // ─── Chips de filtro ─────────────────────────────────────────────────────

  Widget _buildFiltros() {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _chip('Todos', ''),
                ..._roles.map((r) => _chip(
                  r[0].toUpperCase() + r.substring(1),
                  r,
                )),
              ],
            ),
          ),
          Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
        ],
      ),
    );
  }

  Widget _chip(String label, String role) {
    final ativo = _filtroRole == role;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: ativo,
        onSelected: (_) { setState(() => _filtroRole = role); _filtrar(); },
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: ativo ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        selectedColor: const Color(0xFF534AB7),
        checkmarkColor: Colors.white,
        side: BorderSide(
          color: ativo
              ? const Color(0xFF534AB7)
              : Theme.of(context).colorScheme.outlineVariant,
          width: 0.5,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      ),
    );
  }

  // ─── Cards de estatísticas ───────────────────────────────────────────────

  Widget _buildStats() {
    final total  = _filtrados.length;
    final admins = _filtrados.where((u) => u.role == 'admin').length;
    final outros = total - admins;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        children: [
          _statCard('Total', total.toString()),
          const SizedBox(width: 10),
          _statCard('Admins', admins.toString()),
          const SizedBox(width: 10),
          _statCard('Outros', outros.toString()),
        ],
      ),
    );
  }

  Widget _statCard(String label, String valor) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text(valor, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: scheme.onSurface)),
          ],
        ),
      ),
    );
  }

  // ─── Lista de utilizadores ───────────────────────────────────────────────

  Widget _buildLista() {
    if (_filtrados.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text('Nenhum utilizador encontrado',
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      sliver: SliverList.separated(
        itemCount: _filtrados.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) => _userCard(_filtrados[i]),
      ),
    );
  }

  Widget _userCard(UtilizadorAdmin u) {
    final scheme = Theme.of(context).colorScheme;
    final cores = _coresRole(u.role);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant, width: 0.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: cores.bg,
          child: Text(
            u.iniciais,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cores.fg),
          ),
        ),
        title: Text(u.nome,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: Text(u.email,
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
        trailing: _roleBadge(u.role),
        onTap: () => _abrirDetalhes(u),
      ),
    );
  }

  Widget _roleBadge(String role) {
    final cores = _coresRole(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cores.bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        role,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: cores.fg),
      ),
    );
  }

  // ─── Estado de erro ──────────────────────────────────────────────────────

  Widget _buildErro() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 52, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_erro!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 15)),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _carregar,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Navegação (placeholder) ─────────────────────────────────────────────

  void _abrirCriarUtilizador() {
    // Navigator.of(context).push(...)
  }

  void _abrirDetalhes(UtilizadorAdmin u) {
    // Navigator.of(context).push(...)
  }
}