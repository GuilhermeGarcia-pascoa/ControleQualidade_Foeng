import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/models.dart';
import 'nos_screen.dart';
import '../utils/session.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String perfil;
  const DashboardScreen({Key? key, required this.perfil}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Projeto> projetos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProjetos();
  }

  void _loadProjetos() async {
  setState(() => _loading = true);
  List<Projeto> data;
  if (widget.perfil == 'admin') {
    data = await DatabaseHelper.instance.getProjetos();
  } else {
    data = await DatabaseHelper.instance.getProjetosTrabalhador();
  }
  setState(() {
    projetos = data;
    _loading = false;
  });
}

  void _mostrarDialogCriarProjeto() {
    final nomeC = TextEditingController();
    final descC = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Novo Projeto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeC,
              decoration: const InputDecoration(
                labelText: 'Nome do Projeto',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descC,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nomeC.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('O nome é obrigatório!')),
                );
                return;
              }
              Navigator.pop(context);
              await DatabaseHelper.instance.criarProjeto({
                'nome': nomeC.text.trim(),
                'descricao': descC.text.trim(),
              });
              _loadProjetos();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Projeto criado com sucesso!')),
              );
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.perfil == 'admin' ? 'Dashboard Admin' : 'Meus Projetos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Session.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : projetos.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhum projeto encontrado.\nClica no + para criar um.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: projetos.length,
                  itemBuilder: (context, index) {
                    final projeto = projetos[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF1A237E),
                          child: Text(
                            projeto.nome[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(projeto.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(projeto.descricao.isNotEmpty ? projeto.descricao : 'Sem descrição'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        // No onTap do projeto:
onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => NosScreen(projeto: projeto, perfil: widget.perfil),
    ),
  ).then((_) => _loadProjetos());
},
                      ),
                    );
                  },
                ),
      floatingActionButton: widget.perfil == 'admin'
          ? FloatingActionButton(
              onPressed: _mostrarDialogCriarProjeto,
              backgroundColor: const Color(0xFF1A237E),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}