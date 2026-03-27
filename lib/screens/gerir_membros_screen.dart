import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../database/database_helper.dart';
import '../theme/app_theme.dart';

class GerirMembrosScreen extends StatefulWidget {
  final Projeto projeto;
  const GerirMembrosScreen({Key? key, required this.projeto}) : super(key: key);

  @override
  _GerirMembrosScreenState createState() => _GerirMembrosScreenState();
}

class _GerirMembrosScreenState extends State<GerirMembrosScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> membros = [];
  bool _loading = true;
  final emailC = TextEditingController();
  
  // ── Variáveis da Pesquisa ──
  List<Map<String, dynamic>> _sugestoes = [];
  bool _carregandoSugestoes = false;
  Map<String, dynamic>? _utilizadorSelecionado;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    _loadMembros();
  }

  @override
  void dispose() {
    _animController.dispose();
    emailC.dispose();
    super.dispose();
  }

  // ── Lógica de Sugestões ─────────────────────────────────
  void _onEmailChanged(String texto) async {
    texto = texto.trim();
    
    setState(() {
      _utilizadorSelecionado = null;
    });

    if (texto.length < 2) {
      setState(() => _sugestoes = []);
      return;
    }

    setState(() => _carregandoSugestoes = true);
    final resultados = await DatabaseHelper.instance.procurarUtilizadoresPorTexto(texto);

    final membroIds = membros.map((m) => m['id']).toSet();
    final filtrados = resultados.where((u) => !membroIds.contains(u['id'])).toList();

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
  // ───────────────────────────────────────────────────────

  void _loadMembros() async {
    setState(() => _loading = true);
    _animController.reset();
    final data = await DatabaseHelper.instance.getMembros(widget.projeto.id!);
    setState(() {
      membros = data;
      _loading = false;
    });
    _animController.forward();
  }

  void _showSnackBar(String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        elevation: 4,
      ),
    );
  }

  void _adicionarMembro() async {
    final email = emailC.text.trim();
    
    if (email.isEmpty) {
      _showSnackBar('O campo de pesquisa está vazio.', Colors.orange, Icons.warning_amber_rounded);
      return;
    }

    try {
      final utilizador = _utilizadorSelecionado ?? await DatabaseHelper.instance.procurarUtilizadorPorEmail(email);

      if (utilizador == null) {
        _showSnackBar('Utilizador não encontrado na base de dados!', Colors.red, Icons.error_outline_rounded);
        return;
      }

      final jaExiste = membros.any((m) => m['id'] == utilizador['id']);
      if (jaExiste) {
        _showSnackBar('Este utilizador já é membro do projeto!', Colors.orange, Icons.warning_amber_rounded);
        return;
      }

      final sucesso = await DatabaseHelper.instance.adicionarMembroAoProjeto(
        utilizador['id'],
        widget.projeto.id!,
      );

      if (sucesso) {
        emailC.clear();
        FocusScope.of(context).unfocus(); 
        setState(() {
          _utilizadorSelecionado = null;
          _sugestoes = [];
        });
        _loadMembros();
        _showSnackBar('${utilizador['nome']} adicionado com sucesso!', Colors.green, Icons.check_circle_outline_rounded);
      } else {
        _showSnackBar('Erro: A base de dados recusou a adição.', Colors.red, Icons.error_outline_rounded);
      }
      
    } catch (e) {
      _showSnackBar('Erro de sistema: $e', Colors.red, Icons.error_outline_rounded);
    }
  }

  void _removerMembro(Map<String, dynamic> membro) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.15), shape: BoxShape.circle),
              child: const Icon(Icons.person_remove_rounded, color: Colors.red, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Remover Membro', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15, height: 1.5),
            children: [
              const TextSpan(text: 'Tens a certeza que queres remover '),
              TextSpan(text: '"${membro['nome']}"', style: const TextStyle(fontWeight: FontWeight.bold)),
              const TextSpan(text: ' do projeto? Esta ação remove-lhe o acesso.'),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.removerMembroDoProjeto(membro['id'], widget.projeto.id!);
      _loadMembros();
      _showSnackBar('Membro removido do projeto.', Colors.grey.shade700, Icons.info_outline_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: theme.scaffoldBackgroundColor.withOpacity(0.8)),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Gerir Membros', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(widget.projeto.nome, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6))),
          ],
        ),
        actions: [
          if (!_loading)
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
                    Icon(Icons.people_alt_rounded, color: theme.colorScheme.primary, size: 14),
                    const SizedBox(width: 4),
                    Text('${membros.length}', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: AppTheme.themeMode,
            builder: (context, currentMode, _) {
              final isDarkTheme = currentMode == ThemeMode.dark || 
                (currentMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);
              return IconButton(
                icon: Icon(isDarkTheme ? Icons.light_mode : Icons.dark_mode),
                onPressed: () {
                  AppTheme.themeMode.value = isDarkTheme ? ThemeMode.light : ThemeMode.dark;
                },
              );
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true, // Para o fundo passar por debaixo da AppBar
      body: Stack(
        children: [
          // Background com Grid dinâmico
          Positioned.fill(child: CustomPaint(painter: _GridPainter(theme.dividerColor))),
          
          // Brilho Radial dinâmico
          Positioned(
            top: -50, right: -50,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [theme.colorScheme.primary.withOpacity(isDark ? 0.15 : 0.08), Colors.transparent],
                  stops: const [0.2, 1.0],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // ── Campo pesquisar / adicionar membro ───────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Row(
                            children: [
                              const SizedBox(width: 12),
                              Icon(Icons.search_rounded, color: theme.colorScheme.onSurface.withOpacity(0.5), size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: emailC,
                                  keyboardType: TextInputType.emailAddress,
                                  style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
                                  onChanged: (texto) => _onEmailChanged(texto), 
                                  onSubmitted: (_) => _adicionarMembro(),
                                  decoration: InputDecoration(
                                    hintText: 'Pesquisar por nome ou email...',
                                    hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4), fontSize: 14),
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                ),
                              ),
                              if (_carregandoSugestoes)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary)),
                                )
                              else if (emailC.text.isNotEmpty)
                                IconButton(
                                  icon: Icon(Icons.clear, color: theme.colorScheme.onSurface.withOpacity(0.5), size: 18),
                                  onPressed: () {
                                    emailC.clear();
                                    setState(() {
                                      _sugestoes = [];
                                      _utilizadorSelecionado = null;
                                    });
                                  },
                                ),
                              ElevatedButton(
                                onPressed: _adicionarMembro, 
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 0,
                                ),
                                child: const Text('Adicionar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── Área de Sugestões ──
                      if (_utilizadorSelecionado != null)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${_utilizadorSelecionado!['nome']} (${_utilizadorSelecionado!['email']})',
                                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (_sugestoes.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.dividerColor),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 10, offset: const Offset(0, 4))
                            ],
                          ),
                          child: Column(
                            children: _sugestoes.take(5).map((u) {
                              final isSugAdmin = u['perfil'] == 'admin';
                              final sugColor = isSugAdmin ? theme.colorScheme.primary : Colors.orange;
                              
                              return InkWell(
                                onTap: () => _selecionarSugestao(u),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36, height: 36,
                                        decoration: BoxDecoration(
                                          color: sugColor.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Center(
                                          child: Text(
                                            (u['nome'] as String)[0].toUpperCase(),
                                            style: TextStyle(color: sugColor, fontSize: 14, fontWeight: FontWeight.w800),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(u['nome'], style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600, fontSize: 14)),
                                            Text(u['email'], style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: sugColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          u['perfil'].toUpperCase(),
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: sugColor),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),

                // Separador
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                  child: Row(
                    children: [
                      Container(width: 4, height: 16, decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 10),
                      Text('MEMBROS DO PROJETO', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                    ],
                  ),
                ),

                // Lista de membros
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : membros.isEmpty
                          ? Center(
                              child: FadeTransition(
                                opacity: _fadeAnim,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 80, height: 80,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.group_outlined, color: theme.disabledColor, size: 36),
                                    ),
                                    const SizedBox(height: 20),
                                    Text('Nenhum membro', style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 8),
                                    Text('Adiciona colegas de equipa\nusando a pesquisa acima.', textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 14, height: 1.4)),
                                  ],
                                ),
                              ),
                            )
                          : FadeTransition(
                              opacity: _fadeAnim,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                                itemCount: membros.length,
                                itemBuilder: (context, index) {
                                  final membro = membros[index];
                                  final isAdmin = membro['perfil'] == 'admin';
                                  final cor = isAdmin ? theme.colorScheme.primary : Colors.orange;
                                  final letra = (membro['nome'] as String)[0].toUpperCase();

                                  return Card(
                                    elevation: 1,
                                    margin: const EdgeInsets.only(bottom: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 48, height: 48,
                                            decoration: BoxDecoration(
                                              color: cor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                            child: Center(
                                              child: Text(
                                                letra,
                                                style: TextStyle(color: cor, fontSize: 18, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  membro['nome'],
                                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  membro['email'],
                                                  style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 13),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: cor.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              membro['perfil'].toUpperCase(),
                                              style: TextStyle(color: cor, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            onPressed: () => _removerMembro(membro),
                                            icon: const Icon(Icons.close_rounded),
                                            color: theme.colorScheme.onSurface.withOpacity(0.4),
                                            tooltip: 'Remover membro',
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color dotColor;
  _GridPainter(this.dotColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = dotColor.withOpacity(0.15);
    const spacing = 32.0; 
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => oldDelegate.dotColor != dotColor;
}