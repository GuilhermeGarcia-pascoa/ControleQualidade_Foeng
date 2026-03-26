import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/models.dart';
import 'nos_screen.dart';
import '../utils/session.dart';
import 'login_screen.dart';
import '../utils/toast.dart';

class DashboardScreen extends StatefulWidget {
  final String perfil;
  const DashboardScreen({Key? key, required this.perfil}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Projeto> projetos = [];
  bool _loading = true;

void _renomearProjeto(Projeto projeto) {
  final nomeC = TextEditingController(text: projeto.nome);
  final descC = TextEditingController(text: projeto.descricao);

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(children: [
        Icon(Icons.edit_outlined, color: Color(0xFF1A237E)),
        SizedBox(width: 10),
        Text('Renomear Projeto'),
      ]),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nomeC,
            decoration: InputDecoration(
              labelText: 'Nome do Projeto',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.work_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: descC,
            decoration: InputDecoration(
              labelText: 'Descrição',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.description_outlined),
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A237E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () async {
            if (nomeC.text.trim().isEmpty) return;
            Navigator.pop(context);
            await DatabaseHelper.instance.renomearProjeto(projeto.id!, nomeC.text.trim(), descC.text.trim());
            _loadProjetos();
            Toast.mostrar(context, 'Projeto renomeado!', tipo: ToastTipo.sucesso);
          },
          child: const Text('Guardar', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

void _copiarProjeto(Projeto projeto) {
  final nomeC = TextEditingController(text: '${projeto.nome} (cópia)');

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(children: [
        Icon(Icons.copy_outlined, color: Color(0xFF00695C)),
        SizedBox(width: 10),
        Text('Copiar Projeto'),
      ]),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nome do novo projeto:', style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 8),
          TextField(
            controller: nomeC,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.work_outline),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Serão copiadas todas as pastas e campos.\nOs registos não são copiados.',
                  style: TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ),
            ]),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00695C),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () async {
            if (nomeC.text.trim().isEmpty) return;
            Navigator.pop(context);
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => const Center(child: CircularProgressIndicator()),
            );
            await DatabaseHelper.instance.copiarProjeto(projeto.id!, nomeC.text.trim());
            Navigator.pop(context);
            _loadProjetos();
            Toast.mostrar(context, 'Projeto copiado com sucesso!', tipo: ToastTipo.sucesso);
          },
          child: const Text('Copiar', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.folder_special, color: Color(0xFF1A237E)),
            SizedBox(width: 10),
            Text('Novo Projeto'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeC,
              decoration: InputDecoration(
                labelText: 'Nome do Projeto',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.work_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descC,
              decoration: InputDecoration(
                labelText: 'Descrição',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.description_outlined),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              if (nomeC.text.trim().isEmpty) {
                Toast.mostrar(context, 'O nome é obrigatório!', tipo: ToastTipo.aviso);
                return;
              }
              Navigator.pop(context);
              await DatabaseHelper.instance.criarProjeto({
                'nome': nomeC.text.trim(),
                'descricao': descC.text.trim(),
              });
              _loadProjetos();
              Toast.mostrar(context, 'Projeto criado com sucesso!', tipo: ToastTipo.sucesso);
            },
            child: const Text('Criar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmarApagarProjeto(Projeto projeto) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final contagem = await DatabaseHelper.instance.getContagemProjeto(projeto.id!);
    Navigator.pop(context);

    final totalNos = contagem['total_nos'] ?? 0;
    final totalRegistos = contagem['total_registos'] ?? 0;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text('Apagar Projeto', style: TextStyle(color: Colors.red)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tens a certeza que queres apagar o projeto "${projeto.nome}"?',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Será permanentemente apagado:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  _LinhaContagem(
                    icone: Icons.folder_rounded,
                    cor: const Color(0xFF1A237E),
                    texto: '$totalNos pasta${totalNos != 1 ? 's' : ''}',
                  ),
                  const SizedBox(height: 6),
                  _LinhaContagem(
                    icone: Icons.assignment_rounded,
                    cor: const Color(0xFFFF6F00),
                    texto: '$totalRegistos registo${totalRegistos != 1 ? 's' : ''} submetido${totalRegistos != 1 ? 's' : ''}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Esta ação não pode ser desfeita.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Apagar Tudo', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final sucesso = await DatabaseHelper.instance.apagarProjeto(projeto.id!);
      if (sucesso) {
        _loadProjetos();
        Toast.mostrar(
          context,
          'Projeto "${projeto.nome}" apagado.',
          tipo: ToastTipo.erro,
        );
      }
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
        title: Text(
          widget.perfil == 'admin' ? 'Os Meus Projetos' : 'Meus Projetos',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Sair',
            onPressed: () async {
              await Session.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A237E)))
          : projetos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.work_off_outlined, size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhum projeto encontrado.',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.perfil == 'admin'
                            ? 'Clica no + para criar o primeiro projeto.'
                            : 'Ainda não foste adicionado a nenhum projeto.',
                        style: TextStyle(color: Colors.grey.shade500),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                  physics: const BouncingScrollPhysics(),
                  itemCount: projetos.length,
                  itemBuilder: (context, index) {
  final projeto = projetos[index];
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Material(
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NosScreen(projeto: projeto, perfil: widget.perfil),
          ),
        ).then((_) => _loadProjetos()),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    projeto.nome[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      projeto.nome,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1A2E)),
                    ),
                    if (projeto.descricao.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        projeto.descricao,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.perfil == 'admin')
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.grey.shade500),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  onSelected: (valor) {
                    switch (valor) {
                      case 'renomear': _renomearProjeto(projeto); break;
                      case 'copiar': _copiarProjeto(projeto); break;
                      case 'apagar': _confirmarApagarProjeto(projeto); break;
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'renomear',
                      child: Row(children: [
                        Icon(Icons.edit_outlined, color: Color(0xFF1A237E), size: 20),
                        SizedBox(width: 10),
                        Text('Renomear'),
                      ]),
                    ),
                    const PopupMenuItem(
                      value: 'copiar',
                      child: Row(children: [
                        Icon(Icons.copy_outlined, color: Color(0xFF00695C), size: 20),
                        SizedBox(width: 10),
                        Text('Copiar Projeto'),
                      ]),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'apagar',
                      child: Row(children: [
                        Icon(Icons.delete_outline, color: Colors.red.shade400, size: 20),
                        const SizedBox(width: 10),
                        Text('Apagar', style: TextStyle(color: Colors.red.shade400)),
                      ]),
                    ),
                  ],
                ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 24),
            ],
          ),
        ),
      ),
    ),
  );
},
                ),
      floatingActionButton: widget.perfil == 'admin'
          ? FloatingActionButton.extended(
              onPressed: _mostrarDialogCriarProjeto,
              backgroundColor: const Color(0xFF1A237E),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Novo Projeto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }
}

// ─── WIDGET: LINHA DE CONTAGEM ────────────────────────────
class _LinhaContagem extends StatelessWidget {
  final IconData icone;
  final Color cor;
  final String texto;

  const _LinhaContagem({required this.icone, required this.cor, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icone, size: 18, color: cor),
        const SizedBox(width: 8),
        Text(texto, style: TextStyle(color: cor, fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }
}