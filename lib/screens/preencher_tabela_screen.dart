import 'package:flutter/material.dart';
import '../models/models.dart';
import '../database/database_helper.dart';
import '../widgets/campo_widget.dart';
import '../utils/toast.dart';

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
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _loadCampos();
  }

  void _loadCampos() async {
    try {
      final data = await DatabaseHelper.instance.getCampos(widget.no.id!);
      setState(() {
        campos = data;
        _loading = false;
      });
    } catch (e) {
      print('❌ Erro ao carregar campos: $e');
      setState(() => _loading = false);
      Toast.mostrar(context, 'Erro ao carregar campos', tipo: ToastTipo.erro);
    }
  }

  void _salvarRegisto() async {
    // Verificar se há dados preenchidos
    if (dadosPreenchidos.isEmpty) {
      Toast.mostrar(
        context, 
        'Preencha pelo menos um campo antes de submeter!',
        tipo: ToastTipo.aviso
      );
      return;
    }

    // Verificar campos obrigatórios
    for (final campo in campos) {
      final valor = dadosPreenchidos[campo.nomeCampo];
      if (campo.obrigatorio == 1 && 
          (valor == null || valor.toString().isEmpty)) {
        Toast.mostrar(
          context, 
          'O campo "${campo.nomeCampo}" é obrigatório!',
          tipo: ToastTipo.erro
        );
        return;
      }
    }

    // Debug: mostrar o que está a ser enviado
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📝 PREENCHER TABELA - DADOS A GUARDAR');
    print('no_id: ${widget.no.id}');
    print('no_nome: ${widget.no.nome}');
    print('campos_count: ${campos.length}');
    print('dados_preenchidos: $dadosPreenchidos');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    setState(() => _salvando = true);

    try {
      final sucesso = await DatabaseHelper.instance.inserirRegisto({
        'no_id': widget.no.id,
        'dados': dadosPreenchidos,
      });

      if (!mounted) return;

      if (sucesso) {
        Toast.mostrar(
          context, 
          '✅ Registo guardado com sucesso!',
          tipo: ToastTipo.sucesso
        );
        Navigator.pop(context);
      } else {
        Toast.mostrar(
          context, 
          '❌ Erro ao guardar registo. Verifique a ligação ao servidor.',
          tipo: ToastTipo.erro
        );
      }
    } catch (e) {
      print('❌ ERRO AO GUARDAR: $e');
      Toast.mostrar(
        context, 
        'Erro: ${e.toString()}',
        tipo: ToastTipo.erro
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Preencher: ${widget.no.nome}'),
        backgroundColor: const Color(0xFF1A237E),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A237E)))
          : campos.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Nenhum campo definido.',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Pede ao administrador para adicionar campos.',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
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
                                setState(() {
                                  dadosPreenchidos[nomeCampo] = valor;
                                });
                                print('📌 Campo "$nomeCampo" = $valor');
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
                          disabledBackgroundColor: Colors.grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _salvando ? null : _salvarRegisto,
                        child: _salvando
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'SUBMETER DADOS',
                                style: TextStyle(
                                  color: Colors.white, 
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 16
                                ),
                              ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Campos obrigatórios marcados com *',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}