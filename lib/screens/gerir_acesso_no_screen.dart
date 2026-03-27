import 'package:flutter/material.dart';
import '../models/models.dart';
import '../database/database_helper.dart';
import 'dashboard_screen.dart'; // Importante para aceder ao AppTheme

class GerirAcessoNoScreen extends StatefulWidget {
  final No no;
  const GerirAcessoNoScreen({Key? key, required this.no}) : super(key: key);

  @override
  _GerirAcessoNoScreenState createState() => _GerirAcessoNoScreenState();
}

class _GerirAcessoNoScreenState extends State<GerirAcessoNoScreen> {
  List<Map<String, dynamic>> membros = [];
  bool _loading = true;
  final emailC = TextEditingController();
  List<Map<String, dynamic>> _sugestoes = [];
  bool _carregandoSugestoes = false;
  Map<String, dynamic>? _utilizadorSelecionado;

  @override
  void initState() {
    super.initState();
    _loadMembros();
  }

  @override
  void dispose() {
    emailC.dispose();
    super.dispose();
  }

  void _onEmailChanged(String texto) async {
    texto = texto.trim();
    setState(() => _utilizadorSelecionado = null);

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

  void _selecionarSugestao(Map<String, dynamic> u) {
    setState(() {
      _utilizadorSelecionado = u;
      _sugestoes = [];
    });
    emailC.text = u['email'];
  }

  void _loadMembros() async {
    setState(() => _loading = true);
    final data = await DatabaseHelper.instance.getMembrosNo(widget.no.id!);
    setState(() {
      membros = data;
      _loading = false;
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  void _darAcesso() async {
    final email = emailC.text.trim();
    if (email.isEmpty) {
      _showSnackBar('O campo de pesquisa está vazio.', isError: true);
      return;
    }

    try {
      final utilizador = _utilizadorSelecionado ??
          await DatabaseHelper.instance.procurarUtilizadorPorEmail(email);

      if (utilizador == null) {
        _showSnackBar('Utilizador não encontrado!', isError: true);
        return;
      }

      final jaExiste = membros.any((m) => m['id'] == utilizador['id']);
      if (jaExiste) {
        _showSnackBar('Este utilizador já tem acesso a esta pasta!', isError: true);
        return;
      }

      final sucesso = await DatabaseHelper.instance.darAcessoNo(utilizador['id'], widget.no.id!);

      if (sucesso) {
        emailC.clear();
        FocusScope.of(context).unfocus();
        setState(() {
          _utilizadorSelecionado = null;
          _sugestoes = [];
        });
        _loadMembros();
        _showSnackBar('${utilizador['nome']} tem agora acesso a esta pasta!');
      } else {
        _showSnackBar('Erro ao dar acesso.', isError: true);
      }
    } catch (e) {
      _showSnackBar('Erro de sistema: $e', isError: true);
    }
  }

  void _removerAcesso(Map<String, dynamic> membro) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Acesso'),
        content: Text('Remover acesso de "${membro['nome']}" à pasta "${widget.no.nome}"?\n\nEle perderá acesso a esta pasta e a todas as subpastas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.removerAcessoNo(membro['id'], widget.no.id!);
      _loadMembros();
      _showSnackBar('Acesso removido com sucesso.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Gerir Acesso'),
            Text(
              widget.no.nome,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
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
        ],
      ),
      body: Column(
        children: [
          // ── Aviso Informativo ──
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'O acesso a esta pasta inclui automaticamente todas as subpastas dentro dela.',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),

          // ── Pesquisa e Adição ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: emailC,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: _onEmailChanged,
                        onSubmitted: (_) => _darAcesso(),
                        decoration: InputDecoration(
                          hintText: 'Pesquisar por nome ou email...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _carregandoSugestoes
                              ? const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : emailC.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        emailC.clear();
                                        setState(() {
                                          _sugestoes = [];
                                          _utilizadorSelecionado = null;
                                        });
                                      },
                                    )
                                  : null,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _darAcesso,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      child: const Text('Dar Acesso'),
                    ),
                  ],
                ),

                // ── Sugestões ──
                if (_utilizadorSelecionado != null)
                  Card(
                    color: Colors.green.withOpacity(0.1),
                    margin: const EdgeInsets.only(top: 8),
                    child: ListTile(
                      leading: const Icon(Icons.check_circle, color: Colors.green),
                      title: Text('${_utilizadorSelecionado!['nome']} (${_utilizadorSelecionado!['email']})'),
                    ),
                  )
                else if (_sugestoes.isNotEmpty)
                  Card(
                    margin: const EdgeInsets.only(top: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: _sugestoes.take(5).map((u) {
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text((u['nome'] as String)[0].toUpperCase()),
                          ),
                          title: Text(u['nome']),
                          subtitle: Text(u['email']),
                          trailing: Text(u['perfil'].toUpperCase(), style: const TextStyle(fontSize: 10)),
                          onTap: () => _selecionarSugestao(u),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Row(
              children: [
                Text(
                  'UTILIZADORES COM ACESSO',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Lista de Utilizadores ──
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : membros.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_open, size: 48, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Nenhum acesso atribuído',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Usa a pesquisa acima para dar\nacesso a utilizadores específicos.',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: membros.length,
                        itemBuilder: (context, index) {
                          final membro = membros[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text((membro['nome'] as String)[0].toUpperCase()),
                              ),
                              title: Text(membro['nome']),
                              subtitle: Text(membro['email']),
                              trailing: IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                tooltip: 'Remover acesso',
                                onPressed: () => _removerAcesso(membro),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}