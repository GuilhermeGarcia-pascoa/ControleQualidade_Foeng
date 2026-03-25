import 'package:flutter/material.dart';
import '../models/models.dart';
import '../database/database_helper.dart';

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

  @override
  void initState() {
    super.initState();
    _loadMembros();
  }

  void _loadMembros() async {
    setState(() => _loading = true);
    final data = await DatabaseHelper.instance.getMembros(widget.projeto.id!);
    setState(() {
      membros = data;
      _loading = false;
    });
  }

  void _adicionarMembro() async {
    final email = emailC.text.trim();
    if (email.isEmpty) return;

    final utilizador = await DatabaseHelper.instance.procurarUtilizadorPorEmail(email);

    if (utilizador == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilizador não encontrado!')),
      );
      return;
    }

    // Verificar se já é membro
    final jaExiste = membros.any((m) => m['id'] == utilizador['id']);
    if (jaExiste) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este utilizador já é membro do projeto!')),
      );
      return;
    }

    final sucesso = await DatabaseHelper.instance.adicionarMembroAoProjeto(
      utilizador['id'],
      widget.projeto.id!,
    );

    if (sucesso) {
      emailC.clear();
      _loadMembros();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${utilizador['nome']} adicionado com sucesso!')),
      );
    }
  }

  void _removerMembro(Map<String, dynamic> membro) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Membro'),
        content: Text('Tens a certeza que queres remover "${membro['nome']}" do projeto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.removerMembroDoProjeto(
        membro['id'],
        widget.projeto.id!,
      );
      _loadMembros();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Membros — ${widget.projeto.nome}')),
      body: Column(
        children: [
          // ─── Pesquisar e adicionar ─────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: emailC,
                    decoration: const InputDecoration(
                      labelText: 'Email do utilizador',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    onSubmitted: (_) => _adicionarMembro(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _adicionarMembro,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  ),
                  child: const Text('Adicionar'),
                ),
              ],
            ),
          ),
          const Divider(),

          // ─── Lista de membros ──────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : membros.isEmpty
                    ? const Center(
                        child: Text(
                          'Nenhum membro neste projeto.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: membros.length,
                        itemBuilder: (context, index) {
                          final membro = membros[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: membro['perfil'] == 'admin'
                                  ? const Color(0xFF1A237E)
                                  : const Color(0xFFFF6F00),
                              child: Text(
                                membro['nome'][0].toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(membro['nome']),
                            subtitle: Text(membro['email']),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                              onPressed: () => _removerMembro(membro),
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