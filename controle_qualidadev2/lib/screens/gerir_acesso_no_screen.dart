import 'package:flutter/material.dart';
import '../models/models.dart';
import '../database/database_helper.dart';

// Modelo auxiliar — representa um utilizador com o seu tipo de acesso
enum TipoAcesso { direto, herdado }

class _EntradaAcesso {
  final Map<String, dynamic> utilizador;
  final TipoAcesso tipo;
  final String? nomePaiFonte; // só preenchido quando tipo == herdado

  const _EntradaAcesso({
    required this.utilizador,
    required this.tipo,
    this.nomePaiFonte,
  });
}

// ════════════════════════════════════════════════════════════════════════════
// ECRÃ PRINCIPAL
// ════════════════════════════════════════════════════════════════════════════
class GerirAcessoNoScreen extends StatefulWidget {
  final No no;
  const GerirAcessoNoScreen({Key? key, required this.no}) : super(key: key);

  @override
  _GerirAcessoNoScreenState createState() => _GerirAcessoNoScreenState();
}

class _GerirAcessoNoScreenState extends State<GerirAcessoNoScreen> {
  List<_EntradaAcesso> _acessosDiretos = [];
  List<_EntradaAcesso> _acessosHerdados = [];
  bool _loading = true;

  final emailC = TextEditingController();
  List<Map<String, dynamic>> _sugestoes = [];
  bool _carregandoSugestoes = false;
  Map<String, dynamic>? _utilizadorSelecionado;

  @override
  void initState() {
    super.initState();
    _loadAcessos();
  }

  @override
  void dispose() {
    emailC.dispose();
    super.dispose();
  }

  Future<void> _loadAcessos() async {
    setState(() => _loading = true);

    print('🔍 [_loadAcessos] Iniciando carregamento de acessos para nó: ${widget.no.id}');

    // 1. Membros com acesso DIRETO a este nó
    final diretos = await DatabaseHelper.instance.getMembrosNo(widget.no.id!);
    final idsDiretos = diretos.map((m) => m['id'] as int).toSet();
    print('✅ [_loadAcessos] Acessos diretos encontrados: ${diretos.length} membros');
    print('📋 [_loadAcessos] IDs com acesso direto: $idsDiretos');

    // 2. Ancestrais deste nó (do pai até à raiz)
    final ancestrais =
        await DatabaseHelper.instance.getAncestoresNo(widget.no.id!);
    print('📁 [_loadAcessos] Ancestrais encontrados: ${ancestrais.length}');
    for (final anc in ancestrais) {
      print('   └─ Ancestral: ${anc.nome} (ID: ${anc.id})');
    }

    // 3. Para cada ancestral, recolher os seus membros diretos
    //    e construir as entradas de acesso herdado
    final Map<int, _EntradaAcesso> herdadosMap = {};

    for (final anc in ancestrais) {
      final membrosAnc =
          await DatabaseHelper.instance.getMembrosNo(anc.id!);
      for (final m in membrosAnc) {
        final uid = m['id'] as int;
        if (!idsDiretos.contains(uid) && !herdadosMap.containsKey(uid)) {
          herdadosMap[uid] = _EntradaAcesso(
            utilizador: m,
            tipo: TipoAcesso.herdado,
            nomePaiFonte: anc.nome,
          );
        }
      }
    }

    // 4. Membros do projeto — também têm acesso herdado a todas as pastas
    final membrosProjeto =
        await DatabaseHelper.instance.getMembros(widget.no.projetoId);
    for (final m in membrosProjeto) {
      final uid = m['id'] as int;
      if (!idsDiretos.contains(uid) && !herdadosMap.containsKey(uid)) {
        herdadosMap[uid] = _EntradaAcesso(
          utilizador: m,
          tipo: TipoAcesso.herdado,
          nomePaiFonte: 'Projeto completo',
        );
      }
    }

    print('📊 [_loadAcessos] Total de acessos herdados: \${herdadosMap.length}');

    setState(() {
      _acessosDiretos = diretos
          .map((m) => _EntradaAcesso(utilizador: m, tipo: TipoAcesso.direto))
          .toList();
      _acessosHerdados = herdadosMap.values.toList();
      _loading = false;
    });
  }

  void _onEmailChanged(String texto) async {
    texto = texto.trim();
    setState(() => _utilizadorSelecionado = null);

    if (texto.length < 2) {
      setState(() => _sugestoes = []);
      return;
    }

    setState(() => _carregandoSugestoes = true);
    final resultados =
        await DatabaseHelper.instance.procurarUtilizadoresPorTexto(texto);

    // Filtrar quem já tem acesso direto
    final idsDiretos =
        _acessosDiretos.map((e) => e.utilizador['id']).toSet();
    final filtrados =
        resultados.where((u) => !idsDiretos.contains(u['id'])).toList();

    if (!mounted) return;
    setState(() {
      _sugestoes = filtrados;
      _carregandoSugestoes = false;
    });
  }

  void _selecionarSugestao(Map<String, dynamic> utilizador) {
    setState(() {
      _utilizadorSelecionado = utilizador;
      _sugestoes = [];
    });
    emailC.text = utilizador['email'];
  }

  void _adicionarAcesso() async {
    final email = emailC.text.trim();
    if (email.isEmpty) {
      _showSnackBar('O campo de pesquisa está vazio.',
          Colors.orange, Icons.warning_amber_rounded);
      return;
    }

    try {
      final utilizador = _utilizadorSelecionado ??
          await DatabaseHelper.instance.procurarUtilizadorPorEmail(email);

      if (utilizador == null) {
        _showSnackBar('Utilizador não encontrado.',
            Colors.red, Icons.error_outline_rounded);
        return;
      }

      final jaTemDireto =
          _acessosDiretos.any((e) => e.utilizador['id'] == utilizador['id']);
      if (jaTemDireto) {
        _showSnackBar('Este utilizador já tem acesso direto a esta pasta.',
            Colors.orange, Icons.warning_amber_rounded);
        return;
      }

      final jaTemHerdado =
          _acessosHerdados.any((e) => e.utilizador['id'] == utilizador['id']);
      if (jaTemHerdado) {
        _showSnackBar('Este utilizador já tem acesso a esta pasta por herança.',
            Colors.orange, Icons.warning_amber_rounded);
        return;
      }

      final sucesso = await DatabaseHelper.instance
          .darAcessoNo(utilizador['id'], widget.no.id!);

      if (sucesso) {
        emailC.clear();
        FocusScope.of(context).unfocus();
        setState(() {
          _utilizadorSelecionado = null;
          _sugestoes = [];
        });
        _loadAcessos();
        _showSnackBar('${utilizador['nome']} agora tem acesso!',
            Colors.green, Icons.check_circle_outline_rounded);
      } else {
        _showSnackBar('Erro: Não foi possível dar acesso.',
            Colors.red, Icons.error_outline_rounded);
      }
    } catch (e) {
      _showSnackBar('Erro de sistema: $e',
          Colors.red, Icons.error_outline_rounded);
    }
  }

  void _removerAcessoDireto(_EntradaAcesso entrada) async {
    final membro = entrada.utilizador;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15), shape: BoxShape.circle),
              child: const Icon(Icons.security_update_warning_rounded,
                  color: Colors.red, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Remover Acesso',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 15,
                height: 1.5),
            children: [
              const TextSpan(text: 'Tens a certeza que queres remover o acesso de '),
              TextSpan(
                  text: '"${membro['nome']}"',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const TextSpan(
                  text:
                      ' a esta pasta?\n\nAs sub-pastas onde o acesso era herdado daqui também serão afetadas.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance
          .removerAcessoNo(membro['id'], widget.no.id!);
      _loadAcessos();
      _showSnackBar('Acesso removido com sucesso.',
          Colors.grey.shade700, Icons.info_outline_rounded);
    }
  }

  void _mostrarInfoHerdado(_EntradaAcesso entrada) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.15),
                  shape: BoxShape.circle),
              child: const Icon(Icons.account_tree_rounded,
                  color: Colors.blue, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Acesso Herdado',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 15,
                    height: 1.5),
                children: [
                  TextSpan(
                      text: '"${entrada.utilizador['nome']}"',
                      style:
                          const TextStyle(fontWeight: FontWeight.bold)),
                  const TextSpan(
                      text:
                          ' tem acesso a esta pasta porque foi partilhada na pasta pai:'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: Colors.blue.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.folder_rounded,
                      color: Colors.blue, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    entrada.nomePaiFonte ?? '—',
                    style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w700,
                        fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Para remover este acesso, vai à pasta "${entrada.nomePaiFonte}" e remove-o lá.',
              style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 13,
                  height: 1.4),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        elevation: 4,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final totalAcessos =
        _acessosDiretos.length + _acessosHerdados.length;

    return Scaffold(
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Gerir Acessos',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(widget.no.nome,
                style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.6))),
          ],
        ),
        actions: [
          if (!_loading && totalAcessos > 0)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock_open_rounded,
                        color: theme.colorScheme.primary, size: 14),
                    const SizedBox(width: 4),
                    Text('$totalAcessos',
                        style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Barra de pesquisa
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        Icon(Icons.person_add_alt_1_rounded,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                            size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: emailC,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(
                                color: theme.colorScheme.onSurface, fontSize: 14),
                            onChanged: _onEmailChanged,
                            onSubmitted: (_) => _adicionarAcesso(),
                            decoration: InputDecoration(
                              hintText: 'Pesquisar para dar acesso...',
                              hintStyle: TextStyle(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.4),
                                  fontSize: 14),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        if (_carregandoSugestoes)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.primary),
                            ),
                          )
                        else if (emailC.text.isNotEmpty)
                          IconButton(
                            icon: Icon(Icons.clear,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.5),
                                size: 18),
                            onPressed: () {
                              emailC.clear();
                              setState(() {
                                _sugestoes = [];
                                _utilizadorSelecionado = null;
                              });
                            },
                          ),
                        ElevatedButton(
                          onPressed: _adicionarAcesso,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.secondary,
                            foregroundColor: theme.colorScheme.onSecondary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: const Text('Adicionar',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_utilizadorSelecionado != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: Colors.green, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${_utilizadorSelecionado!['nome']} (${_utilizadorSelecionado!['email']})',
                            style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                                fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (_sugestoes.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Column(
                      children: _sugestoes.take(5).map((u) {
                        final isSugAdmin = u['perfil'] == 'admin';
                        final sugColor =
                            isSugAdmin ? theme.colorScheme.primary : Colors.orange;
                        return InkWell(
                          onTap: () => _selecionarSugestao(u),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: sugColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      (u['nome'] as String)[0].toUpperCase(),
                                      style: TextStyle(
                                          color: sugColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(u['nome'],
                                          style: TextStyle(
                                              color: theme.colorScheme
                                                  .onSurface,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14)),
                                      Text(u['email'],
                                          style: TextStyle(
                                              color: theme.colorScheme
                                                  .onSurface
                                                  .withOpacity(0.6),
                                              fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: sugColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    u['perfil'].toUpperCase(),
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: sugColor),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                const SizedBox(height: 24),
                const Text('Acessos Diretos',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (_acessosDiretos.isEmpty)
                  const _EmptySection(
                    message: 'Nenhum acesso direto atribuído.',
                    icon: Icons.no_accounts_outlined,
                  )
                else
                  ..._acessosDiretos.map((e) => _AcessoCard(
                        entrada: e,
                        onAction: () => _removerAcessoDireto(e),
                        actionIcon: Icons.close_rounded,
                        actionColor: Colors.red,
                        actionTooltip: 'Remover acesso',
                      )),
                const SizedBox(height: 32),
                const Text('Acessos Herdados',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                if (_acessosHerdados.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Estes utilizadores têm acesso porque uma pasta pai foi partilhada com eles.',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ),
                if (_acessosHerdados.isEmpty)
                  const _EmptySection(
                    message: 'Nenhum acesso herdado de pastas pai.',
                    icon: Icons.account_tree_outlined,
                  )
                else
                  ..._acessosHerdados.map((e) => _AcessoCard(
                        entrada: e,
                        onAction: () => _mostrarInfoHerdado(e),
                        actionIcon: Icons.info_outline_rounded,
                        actionColor: Colors.blue,
                        actionTooltip: 'Ver origem',
                        badge: e.nomePaiFonte,
                      )),
              ],
            ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  final String message;
  final IconData icon;

  const _EmptySection({required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.disabledColor),
          const SizedBox(width: 10),
          Text(message,
              style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                  fontSize: 13)),
        ],
      ),
    );
  }
}

class _AcessoCard extends StatelessWidget {
  final _EntradaAcesso entrada;
  final VoidCallback onAction;
  final IconData actionIcon;
  final Color actionColor;
  final String actionTooltip;
  final String? badge; // nome da pasta pai (só para herdados)

  const _AcessoCard({
    required this.entrada,
    required this.onAction,
    required this.actionIcon,
    required this.actionColor,
    required this.actionTooltip,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final membro = entrada.utilizador;
    final isAdmin = membro['perfil'] == 'admin';
    final cor =
        isAdmin ? theme.colorScheme.primary : theme.colorScheme.secondary;
    final letra = (membro['nome'] as String)[0].toUpperCase();
    final isHerdado = entrada.tipo == TipoAcesso.herdado;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // ── Avatar ──────────────────────────────────────────
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: cor.withOpacity(isHerdado ? 0.06 : 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: isHerdado
                        ? Border.all(
                            color: Colors.blue.withOpacity(0.3),
                            width: 1.5)
                        : null,
                  ),
                  child: Center(
                    child: Text(letra,
                        style: TextStyle(
                            color: cor.withOpacity(isHerdado ? 0.6 : 1),
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                if (isHerdado)
                  Positioned(
                    bottom: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: theme.colorScheme.surface,
                              width: 1.5)),
                      child: const Icon(Icons.account_tree_rounded,
                          size: 10, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),

            // ── Info ─────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(membro['nome'],
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(membro['email'],
                      style: TextStyle(
                          color: theme.colorScheme.onSurface
                              .withOpacity(0.6),
                          fontSize: 13),
                      overflow: TextOverflow.ellipsis),
                  if (badge != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.folder_rounded,
                            size: 12,
                            color: Colors.blue.withOpacity(0.7)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Herdado de: $badge',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue.withOpacity(0.8),
                                fontStyle: FontStyle.italic),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),

            // ── Badge perfil ─────────────────────────────────────
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: cor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                membro['perfil'].toUpperCase(),
                style: TextStyle(
                    color: cor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5),
              ),
            ),
            const SizedBox(width: 8),

            // ── Botão de ação ────────────────────────────────────
            IconButton(
              onPressed: onAction,
              icon: Icon(actionIcon),
              color: actionColor.withOpacity(0.6),
              tooltip: actionTooltip,
            ),
          ],
        ),
      ),
    );
  }
}