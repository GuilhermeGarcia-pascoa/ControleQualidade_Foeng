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

  List<UtilizadorAdmin> _utilizadores = [];
  List<UtilizadorAdmin> _filtrados = [];
  bool _loading = true;
  String? _erro;
  String _filtroRole = '';

  // Apenas admin e utilizador
  static const _roles = ['admin', 'utilizador'];

  static const _roleColors = {
    'admin':      (bg: Color(0xFFEEEDFE), fg: Color(0xFF534AB7)),
    'utilizador': (bg: Color(0xFFE6F1FB), fg: Color(0xFF185FA5)),
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

  // ─── Abrir modal de criar ────────────────────────────────────────────────

  void _abrirCriar() {
    _abrirModal(utilizador: null);
  }

  // ─── Abrir modal de editar ───────────────────────────────────────────────

  void _abrirEditar(UtilizadorAdmin u) {
    _abrirModal(utilizador: u);
  }

  void _abrirModal({UtilizadorAdmin? utilizador}) {
    final nomeCtrl  = TextEditingController(text: utilizador?.nome  ?? '');
    final emailCtrl = TextEditingController(text: utilizador?.email ?? '');
    String roleAtual = utilizador?.role ?? 'utilizador';
    final isEdit = utilizador != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        width: 36, height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Cabeçalho
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 8, 0),
                      child: Row(
                        children: [
                          Text(
                            isEdit ? 'Editar utilizador' : 'Novo utilizador',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    // Campos
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _campo('Nome', nomeCtrl, hint: 'Nome completo'),
                          const SizedBox(height: 14),
                          _campo('Email', emailCtrl,
                              hint: 'email@empresa.pt',
                              keyboard: TextInputType.emailAddress),
                          const SizedBox(height: 14),

                          // Toggle de role
                          const Text('Role',
                              style: TextStyle(fontSize: 12, color: Color(0xFF888780))),
                          const SizedBox(height: 8),
                          Row(
                            children: _roles.map((r) {
                              final ativo = roleAtual == r;
                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                      right: r == _roles.last ? 0 : 8),
                                  child: GestureDetector(
                                    onTap: () => setModalState(() => roleAtual = r),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: ativo
                                            ? const Color(0xFFEEEDFE)
                                            : Theme.of(context).colorScheme.surfaceContainerLow,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: ativo
                                              ? const Color(0xFF534AB7)
                                              : Theme.of(context).colorScheme.outlineVariant,
                                          width: ativo ? 1.5 : 0.5,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        r[0].toUpperCase() + r.substring(1),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: ativo
                                              ? const Color(0xFF534AB7)
                                              : Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                    // Rodapé com botões
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      child: Row(
                        children: [
                          if (isEdit) ...[
                            _btnApagar(utilizador, ctx),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton(
                              onPressed: () async {
                                final nome  = nomeCtrl.text.trim();
                                final email = emailCtrl.text.trim();
                                if (nome.isEmpty || email.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Preenche nome e email.')),
                                  );
                                  return;
                                }
                                Navigator.pop(ctx);
                                if (isEdit) {
                                  await _service.editarUtilizador(
                                    utilizador.id, nome: nome, email: email, role: roleAtual,
                                  );
                                } else {
                                  await _service.criarUtilizador(
                                    nome: nome, email: email, password: 'TemporariaSenha123', role: roleAtual,
                                  );
                                }
                                _carregar();
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF534AB7),
                              ),
                              child: Text(isEdit ? 'Guardar' : 'Criar'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _campo(String label, TextEditingController ctrl,
      {String? hint, TextInputType? keyboard}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF888780))),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboard,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(width: 0.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _btnApagar(UtilizadorAdmin u, BuildContext ctx) {
    return TextButton(
      onPressed: () async {
        final confirmar = await showDialog<bool>(
          context: ctx,
          builder: (_) => AlertDialog(
            title: const Text('Apagar utilizador'),
            content: Text('Tens a certeza que queres apagar ${u.nome}?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar')),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Apagar',
                      style: TextStyle(color: Colors.red))),
            ],
          ),
        );
        if (confirmar == true) {
          Navigator.pop(ctx);
          await _service.apagarUtilizador(u.id);
          _carregar();
        }
      },
      style: TextButton.styleFrom(foregroundColor: Colors.red),
      child: const Text('Apagar'),
    );
  }

  // ─── Build principal ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLow,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: scheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Painel Admin',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: _abrirCriar,
              icon: const Icon(Icons.person_add_rounded, size: 16),
              label: const Text('Criar'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF534AB7),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                textStyle:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
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
                    slivers: [
                      SliverToBoxAdapter(child: _buildSearch()),
                      SliverToBoxAdapter(child: _buildFiltros()),
                      SliverToBoxAdapter(child: _buildStats()),
                      _buildLista(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSearch() {
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
            BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 0.5),
          ),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12))),
          ),
          padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 16, vertical: 2)),
        ),
      ),
    );
  }

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
                ..._roles.map((r) =>
                    _chip(r[0].toUpperCase() + r.substring(1), r)),
              ],
            ),
          ),
          Divider(
              height: 1,
              color: Theme.of(context).colorScheme.outlineVariant),
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
          color: ativo
              ? Colors.white
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        selectedColor: const Color(0xFF534AB7),
        checkmarkColor: Colors.white,
        side: BorderSide(
          color: ativo
              ? const Color(0xFF534AB7)
              : Theme.of(context).colorScheme.outlineVariant,
          width: 0.5,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }

  Widget _buildStats() {
    final total  = _filtrados.length;
    final admins = _filtrados.where((u) => u.role == 'admin').length;
    final outros = total - admins;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(children: [
        _statCard('Total',  total.toString()),
        const SizedBox(width: 10),
        _statCard('Admins', admins.toString()),
        const SizedBox(width: 10),
        _statCard('Outros', outros.toString()),
      ]),
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
            Text(label,
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text(valor,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurface)),
          ],
        ),
      ),
    );
  }

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
        itemBuilder: (_, i) => _userCard(_filtrados[i]),
      ),
    );
  }

  Widget _userCard(UtilizadorAdmin u) {
    final scheme = Theme.of(context).colorScheme;
    final cores  = _coresRole(u.role);
    return InkWell(
      onTap: () => _abrirEditar(u),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant, width: 0.5),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: CircleAvatar(
            backgroundColor: cores.bg,
            child: Text(u.iniciais,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cores.fg)),
          ),
          title: Text(u.nome,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500)),
          subtitle: Text(u.email,
              style: TextStyle(
                  fontSize: 12, color: scheme.onSurfaceVariant)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _roleBadge(u.role),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
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
      child: Text(role,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w500, color: cores.fg)),
    );
  }

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
}