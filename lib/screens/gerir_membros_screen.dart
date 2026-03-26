import 'package:flutter/material.dart';
import '../models/models.dart';
import '../database/database_helper.dart';
import '../utils/toast.dart';

class GerirMembrosScreen extends StatefulWidget {
  final Projeto projeto;
  const GerirMembrosScreen({Key? key, required this.projeto}) : super(key: key);

  @override
  _GerirMembrosScreenState createState() => _GerirMembrosScreenState();
}

class _GerirMembrosScreenState extends State<GerirMembrosScreen> {
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
    emailC.addListener(_onEmailChanged);
  }

  @override
  void dispose() {
    emailC.removeListener(_onEmailChanged);
    emailC.dispose();
    super.dispose();
  }

  void _onEmailChanged() async {
    final texto = emailC.text.trim();
    _utilizadorSelecionado = null;

    if (texto.length < 2) {
      setState(() => _sugestoes = []);
      return;
    }

    setState(() => _carregandoSugestoes = true);
    final resultados = await DatabaseHelper.instance.procurarUtilizadoresPorTexto(texto);

    // Filtrar os que já são membros
    final membroIds = membros.map((m) => m['id']).toSet();
    final filtrados = resultados.where((u) => !membroIds.contains(u['id'])).toList();

    setState(() {
      _sugestoes = filtrados;
      _carregandoSugestoes = false;
    });
  }

  void _loadMembros() async {
    setState(() => _loading = true);
    final data = await DatabaseHelper.instance.getMembros(widget.projeto.id!);
    setState(() {
      membros = data;
      _loading = false;
    });
  }

  void _selecionarSugestao(Map<String, dynamic> utilizador) {
    setState(() {
      _utilizadorSelecionado = utilizador;
      _sugestoes = [];
    });
    emailC.text = utilizador['email'];
  }

  void _adicionarMembro() async {
    final utilizador = _utilizadorSelecionado ??
        await DatabaseHelper.instance.procurarUtilizadorPorEmail(emailC.text.trim());

    if (utilizador == null) {
      Toast.mostrar(context, 'Utilizador não encontrado!', tipo: ToastTipo.aviso);
      return;
    }

    final jaExiste = membros.any((m) => m['id'] == utilizador['id']);
    if (jaExiste) {
      Toast.mostrar(context, 'Este utilizador já é membro!', tipo: ToastTipo.aviso);
      return;
    }

    final sucesso = await DatabaseHelper.instance.adicionarMembroAoProjeto(
      utilizador['id'],
      widget.projeto.id!,
    );

    if (sucesso) {
      emailC.clear();
      setState(() {
        _utilizadorSelecionado = null;
        _sugestoes = [];
      });
      _loadMembros();
      Toast.mostrar(context, '${utilizador['nome']} adicionado!', tipo: ToastTipo.sucesso);
    }
  }

  void _removerMembro(Map<String, dynamic> membro) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.person_remove_outlined, color: Colors.red),
          SizedBox(width: 10),
          Text('Remover Membro'),
        ]),
        content: Text('Tens a certeza que queres remover "${membro['nome']}" do projeto?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.removerMembroDoProjeto(membro['id'], widget.projeto.id!);
      _loadMembros();
      Toast.mostrar(context, '${membro['nome']} removido.', tipo: ToastTipo.erro);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Gerir Membros', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Text(widget.projeto.nome, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          ],
        ),
      ),
      body: Column(
        children: [
          // ─── CAMPO DE PESQUISA ────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: emailC,
                        decoration: InputDecoration(
                          labelText: 'Pesquisar por nome ou email',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _carregandoSugestoes
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
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
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _adicionarMembro,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Adicionar'),
                    ),
                  ],
                ),

                // ─── SUGESTÕES ────────────────────────────
                if (_utilizadorSelecionado != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${_utilizadorSelecionado!['nome']} (${_utilizadorSelecionado!['email']})',
                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_sugestoes.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      children: _sugestoes.take(5).map((u) {
                        return InkWell(
                          onTap: () => _selecionarSugestao(u),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: u['perfil'] == 'admin'
                                      ? const Color(0xFF1A237E)
                                      : const Color(0xFFFF6F00),
                                  child: Text(
                                    u['nome'][0].toUpperCase(),
                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(u['nome'], style: const TextStyle(fontWeight: FontWeight.w600)),
                                      Text(u['email'], style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: u['perfil'] == 'admin'
                                        ? const Color(0xFF1A237E).withOpacity(0.1)
                                        : const Color(0xFFFF6F00).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    u['perfil'],
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: u['perfil'] == 'admin' ? const Color(0xFF1A237E) : const Color(0xFFFF6F00),
                                    ),
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

          // ─── LISTA DE MEMBROS ─────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(width: 4, height: 16, decoration: BoxDecoration(color: const Color(0xFF1A237E), borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 8),
                Text(
                  '${membros.length} membro${membros.length != 1 ? 's' : ''}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E), fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A237E)))
                : membros.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.group_off_outlined, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text('Nenhum membro ainda.', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: membros.length,
                        itemBuilder: (context, index) {
                          final membro = membros[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Material(
                              borderRadius: BorderRadius.circular(14),
                              color: Colors.white,
                              elevation: 1,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: membro['perfil'] == 'admin'
                                          ? const Color(0xFF1A237E)
                                          : const Color(0xFFFF6F00),
                                      child: Text(
                                        membro['nome'][0].toUpperCase(),
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(membro['nome'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                          Text(membro['email'], style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: membro['perfil'] == 'admin'
                                            ? const Color(0xFF1A237E).withOpacity(0.1)
                                            : const Color(0xFFFF6F00).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        membro['perfil'],
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: membro['perfil'] == 'admin' ? const Color(0xFF1A237E) : const Color(0xFFFF6F00),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: Icon(Icons.remove_circle_outline, color: Colors.red.shade300),
                                      onPressed: () => _removerMembro(membro),
                                      splashRadius: 20,
                                    ),
                                  ],
                                ),
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