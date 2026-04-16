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
      setState(() {
        _utilizadores = lista;
        _filtrar();
        _loading = false;
      });
    } on AdminServiceException catch (e) {
      setState(() {
        _erro = e.mensagem;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _erro = 'Erro de ligação.';
        _loading = false;
      });
    }
  }

  void _filtrar() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtrados = _utilizadores.where((u) {
        final matchQuery = query.isEmpty ||
            u.nome.toLowerCase().contains(query) ||
            u.email.toLowerCase().contains(query);
        final matchRole = _filtroRole.isEmpty || u.role == _filtroRole;
        return matchQuery && matchRole;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel Admin'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_rounded,
                            size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(_erro!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _carregar,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _carregar,
                  child: ListView.builder(
                    itemCount: _filtrados.length,
                    itemBuilder: (context, index) {
                      final u = _filtrados[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(u.iniciais),
                        ),
                        title: Text(u.nome),
                        subtitle: Text(u.email),
                        trailing: Text(u.role),
                      );
                    },
                  ),
                ),
    );
  }
}
