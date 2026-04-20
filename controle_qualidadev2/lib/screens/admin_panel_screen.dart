import 'package:flutter/material.dart';
import '../services/admin_service.dart';

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

  static const _roles = ['admin', 'utilizador'];

  static const _roleColors = {
    'admin': (bg: Color(0xFFEEEDFE), fg: Color(0xFF534AB7)),
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
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final lista = await _service.getUtilizadores();
      if (!mounted) return;
      setState(() {
        _utilizadores = lista;
        _filtrados = _aplicarFiltro(lista);
        _loading = false;
      });
    } on AdminServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = e.mensagem;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erro = 'Erro de ligação.';
        _loading = false;
      });
    }
  }

  void _filtrar() {
    setState(() {
      _filtrados = _aplicarFiltro(_utilizadores);
    });
  }

  List<UtilizadorAdmin> _aplicarFiltro(List<UtilizadorAdmin> lista) {
    final q = _searchCtrl.text.toLowerCase();
    return lista.where((u) {
      final mq = q.isEmpty ||
          u.nome.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q);
      final mr = _filtroRole.isEmpty || u.role == _filtroRole;
      return mq && mr;
    }).toList();
  }

  ({Color bg, Color fg}) _coresRole(String role) =>
      _roleColors[role] ??
      (bg: const Color(0xFFE6F1FB), fg: const Color(0xFF185FA5));

  void _abrirCriar() => _abrirModal(utilizador: null);

  void _abrirEditar(UtilizadorAdmin u) => _abrirModal(utilizador: u);

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  Widget _secaoTitulo(String titulo) {
    return Text(
      titulo,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF534AB7),
      ),
    );
  }

  void _abrirModal({UtilizadorAdmin? utilizador}) {
    final nomeCtrl = TextEditingController(text: utilizador?.nome ?? '');
    final emailCtrl = TextEditingController(text: utilizador?.email ?? '');
    final passwordCtrl = TextEditingController();
    String roleAtual = utilizador?.role ?? 'utilizador';
    final isEdit = utilizador != null;
    bool mostrarSenha = false;
    bool aGuardar = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final scheme = Theme.of(ctx).colorScheme;
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 22,
                      offset: Offset(0, -6),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: Container(
                            margin: const EdgeInsets.only(top: 12, bottom: 10),
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: scheme.outlineVariant,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 10, 0),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEEDFE),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  isEdit
                                      ? Icons.manage_accounts_rounded
                                      : Icons.person_add_alt_1_rounded,
                                  color: const Color(0xFF534AB7),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isEdit
                                          ? 'Editar utilizador'
                                          : 'Novo utilizador',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isEdit
                                          ? 'Atualiza os dados e define uma nova senha se precisares.'
                                          : 'Cria a conta com nome, email, senha e perfil.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded),
                                onPressed:
                                    aGuardar ? null : () => Navigator.pop(ctx),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: scheme.outlineVariant,
                                width: 0.7,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _secaoTitulo('Dados principais'),
                                const SizedBox(height: 14),
                                _campo(
                                  'Nome',
                                  nomeCtrl,
                                  hint: 'Nome completo',
                                  prefixIcon:
                                      const Icon(Icons.badge_outlined, size: 20),
                                ),
                                const SizedBox(height: 14),
                                _campo(
                                  'Email',
                                  emailCtrl,
                                  hint: 'email@empresa.pt',
                                  keyboard: TextInputType.emailAddress,
                                  prefixIcon:
                                      const Icon(Icons.alternate_email_rounded,
                                          size: 20),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: scheme.outlineVariant,
                                width: 0.7,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _secaoTitulo(
                                  isEdit ? 'Segurança e acesso' : 'Segurança',
                                ),
                                const SizedBox(height: 14),
                                _campo(
                                  isEdit ? 'Nova senha' : 'Senha',
                                  passwordCtrl,
                                  hint: isEdit
                                      ? 'Preenche apenas se quiseres alterar'
                                      : 'Defina uma senha',
                                  obscureText: !mostrarSenha,
                                  prefixIcon:
                                      const Icon(Icons.lock_outline_rounded,
                                          size: 20),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      mostrarSenha
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                    ),
                                    onPressed: () => setModalState(
                                      () => mostrarSenha = !mostrarSenha,
                                    ),
                                  ),
                                ),
                                if (isEdit) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Se deixares a senha vazia, ela não será alterada.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                _secaoTitulo('Perfil'),
                                const SizedBox(height: 10),
                                Row(
                                  children: _roles.map((r) {
                                    final ativo = roleAtual == r;
                                    final cores = _coresRole(r);
                                    return Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                          right: r == _roles.last ? 0 : 10,
                                        ),
                                        child: GestureDetector(
                                          onTap: aGuardar
                                              ? null
                                              : () => setModalState(
                                                    () => roleAtual = r,
                                                  ),
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 180,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: ativo
                                                  ? cores.bg
                                                  : scheme.surface,
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              border: Border.all(
                                                color: ativo
                                                    ? cores.fg
                                                    : scheme.outlineVariant,
                                                width: ativo ? 1.3 : 0.7,
                                              ),
                                            ),
                                            child: Column(
                                              children: [
                                                Icon(
                                                  r == 'admin'
                                                      ? Icons.verified_user_rounded
                                                      : Icons.person_outline_rounded,
                                                  size: 18,
                                                  color: ativo
                                                      ? cores.fg
                                                      : scheme.onSurfaceVariant,
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  r[0].toUpperCase() +
                                                      r.substring(1),
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: ativo
                                                        ? cores.fg
                                                        : scheme
                                                            .onSurfaceVariant,
                                                  ),
                                                ),
                                              ],
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
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          child: Row(
                            children: [
                              if (isEdit) ...[
                                _btnApagar(utilizador, ctx, aGuardar),
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                child: OutlinedButton(
                                  onPressed:
                                      aGuardar ? null : () => Navigator.pop(ctx),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(48),
                                  ),
                                  child: const Text('Cancelar'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FilledButton(
                                  onPressed: aGuardar
                                      ? null
                                      : () async {
                                          final nome = nomeCtrl.text.trim();
                                          final email = emailCtrl.text.trim();
                                          final password =
                                              passwordCtrl.text.trim();

                                          if (nome.isEmpty || email.isEmpty) {
                                            _mostrarMensagem(
                                              'Preenche nome e email.',
                                            );
                                            return;
                                          }

                                          if (!isEdit && password.isEmpty) {
                                            _mostrarMensagem(
                                              'Preenche a senha do utilizador.',
                                            );
                                            return;
                                          }

                                          setModalState(() => aGuardar = true);
                                          try {
                                            if (isEdit) {
                                              await _service.editarUtilizador(
                                                utilizador.id,
                                                nome: nome,
                                                email: email,
                                                role: roleAtual,
                                              );
                                              if (password.isNotEmpty) {
                                                await _service.alterarSenha(
                                                  id: utilizador.id,
                                                  password: password,
                                                );
                                              }
                                            } else {
                                              await _service.criarUtilizador(
                                                nome: nome,
                                                email: email,
                                                password: password,
                                                role: roleAtual,
                                              );
                                            }

                                            if (!context.mounted) return;
                                            Navigator.pop(ctx);
                                            _mostrarMensagem(
                                              isEdit
                                                  ? 'Utilizador atualizado com sucesso.'
                                                  : 'Utilizador criado com sucesso.',
                                            );
                                            await _carregar();
                                          } on AdminServiceException catch (e) {
                                            if (!context.mounted) return;
                                            _mostrarMensagem(e.mensagem);
                                            setModalState(() => aGuardar = false);
                                          } catch (_) {
                                            if (!context.mounted) return;
                                            _mostrarMensagem(
                                              'Não foi possível guardar o utilizador.',
                                            );
                                            setModalState(() => aGuardar = false);
                                          }
                                        },
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size.fromHeight(48),
                                    backgroundColor: const Color(0xFF534AB7),
                                  ),
                                  child: aGuardar
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(isEdit ? 'Guardar' : 'Criar'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _campo(
    String label,
    TextEditingController ctrl, {
    String? hint,
    TextInputType? keyboard,
    bool obscureText = false,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF888780)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboard,
          obscureText: obscureText,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(width: 0.7),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFD9DCE3), width: 0.8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFF534AB7), width: 1.2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _btnApagar(UtilizadorAdmin u, BuildContext ctx, bool disabled) {
    return TextButton.icon(
      onPressed: disabled
          ? null
          : () async {
              final confirmar = await showDialog<bool>(
                context: ctx,
                builder: (_) => AlertDialog(
                  title: const Text('Apagar utilizador'),
                  content:
                      Text('Tens a certeza que queres apagar ${u.nome}?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text(
                        'Apagar',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
              if (confirmar == true) {
                Navigator.pop(ctx);
                await _service.apagarUtilizador(u.id);
                _mostrarMensagem('Utilizador apagado com sucesso.');
                _carregar();
              }
            },
      style: TextButton.styleFrom(foregroundColor: Colors.red),
      icon: const Icon(Icons.delete_outline_rounded),
      label: const Text('Apagar'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Painel Admin',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: _abrirCriar,
              icon: const Icon(Icons.person_add_rounded, size: 18),
              label: const Text('Criar'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF534AB7),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
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
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: _buildHero()),
                      SliverToBoxAdapter(child: _buildSearch()),
                      SliverToBoxAdapter(child: _buildFiltros()),
                      SliverToBoxAdapter(child: _buildStats()),
                      _buildLista(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHero() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFF534AB7), Color(0xFF6C63D9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F534AB7),
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.admin_panel_settings_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gestão de utilizadores',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cria, edita acessos e organiza perfis num único painel.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.86),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F101828),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: SearchBar(
          controller: _searchCtrl,
          hintText: 'Pesquisar por nome ou email...',
          leading: const Icon(Icons.search_rounded, size: 20),
          trailing: [
            if (_searchCtrl.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () {
                  _searchCtrl.clear();
                  _filtrar();
                },
              ),
          ],
          onChanged: (_) => _filtrar(),
          backgroundColor: const WidgetStatePropertyAll(Colors.white),
          elevation: const WidgetStatePropertyAll(0),
          side: const WidgetStatePropertyAll(BorderSide.none),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(18)),
            ),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          ),
        ),
      ),
    );
  }

  Widget _buildFiltros() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            _chip('Todos', ''),
            ..._roles.map((r) => _chip(r[0].toUpperCase() + r.substring(1), r)),
          ],
        ),
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
        onSelected: (_) {
          setState(() => _filtroRole = role);
          _filtrar();
        },
        showCheckmark: false,
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: ativo ? Colors.white : const Color(0xFF525866),
        ),
        selectedColor: const Color(0xFF534AB7),
        side: BorderSide(
          color: ativo
              ? const Color(0xFF534AB7)
              : const Color(0xFFD7DBE4),
          width: 0.8,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
    );
  }

  Widget _buildStats() {
    final total = _filtrados.length;
    final admins = _filtrados.where((u) => u.role == 'admin').length;
    final outros = total - admins;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          _statCard(
            'Total',
            total.toString(),
            Icons.group_rounded,
            const Color(0xFF534AB7),
          ),
          const SizedBox(width: 10),
          _statCard(
            'Admins',
            admins.toString(),
            Icons.verified_user_rounded,
            const Color(0xFF0E8B6F),
          ),
          const SizedBox(width: 10),
          _statCard(
            'Outros',
            outros.toString(),
            Icons.person_outline_rounded,
            const Color(0xFF185FA5),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    String label,
    String valor,
    IconData icon,
    Color accent,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0C101828),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: accent),
            ),
            const SizedBox(height: 12),
            Text(
              valor,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF667085),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLista() {
    if (_filtrados.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: 34,
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Nenhum utilizador encontrado',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              const Text(
                'Experimenta ajustar a pesquisa ou o filtro.',
                style: TextStyle(color: Color(0xFF667085)),
              ),
            ],
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      sliver: SliverList.separated(
        itemCount: _filtrados.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _userCard(_filtrados[i]),
      ),
    );
  }

  Widget _userCard(UtilizadorAdmin u) {
    final cores = _coresRole(u.role);
    return InkWell(
      onTap: () => _abrirEditar(u),
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0C101828),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: cores.bg,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  u.iniciais,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: cores.fg,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      u.nome,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.mail_outline_rounded,
                          size: 14,
                          color: Color(0xFF667085),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            u.email,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF667085),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _roleBadge(u.role),
                  const SizedBox(height: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: Color(0xFF98A2B3),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleBadge(String role) {
    final cores = _coresRole(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cores.bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        role,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: cores.fg,
        ),
      ),
    );
  }

  Widget _buildErro() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 36,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _erro!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 15),
            ),
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
