import 'package:flutter/material.dart';
import '../models/models.dart';
import '../database/database_helper.dart';
import '../widgets/campo_widget.dart';

class PreencherTabelaScreen extends StatefulWidget {
  final No no;
  const PreencherTabelaScreen({Key? key, required this.no}) : super(key: key);

  @override
  _PreencherTabelaScreenState createState() => _PreencherTabelaScreenState();
}

class _PreencherTabelaScreenState extends State<PreencherTabelaScreen> {
  List<CampoDinamico> campos = [];
  Map<String, dynamic> dadosPreenchidos = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCampos();
  }

  void _loadCampos() async {
    final data = await DatabaseHelper.instance.getCampos(widget.no.id!);
    setState(() {
      campos = data;
      _loading = false;
    });
  }

  void _salvarRegisto() async {
    // Verificar campos obrigatórios
    for (final campo in campos) {
      if (campo.obrigatorio == 1 && 
          (dadosPreenchidos[campo.nomeCampo] == null || 
           dadosPreenchidos[campo.nomeCampo].toString().isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('O campo "${campo.nomeCampo}" é obrigatório!')),
        );
        return;
      }
    }

    await DatabaseHelper.instance.inserirRegisto({
      'no_id': widget.no.id,
      'dados': dadosPreenchidos,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registo guardado com sucesso!')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Preencher: ${widget.no.nome}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : campos.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhum campo definido.\nPede ao administrador para adicionar campos.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: campos.length,
                          itemBuilder: (context, index) {
                            return CampoWidget(
                              campo: campos[index],
                              onValueChanged: (nomeCampo, valor) {
                                dadosPreenchidos[nomeCampo] = valor;
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: const Color(0xFFFF6F00),
                        ),
                        onPressed: _salvarRegisto,
                        child: const Text(
                          'SUBMETER DADOS',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}