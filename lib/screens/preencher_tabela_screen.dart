import 'package:flutter/material.dart';
import '../models/models.dart';
import '../database/database_helper.dart';
import '../widgets/campo_widget.dart';
import '../utils/toast.dart';
import 'dashboard_screen.dart'; // Importante para aceder ao AppTheme

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
      setState(() => _loading = false);
      Toast.mostrar(context, 'Erro ao carregar campos', tipo: ToastTipo.erro);
    }
  }

  // Progresso de preenchimento
  int get _camposPreenchidos =>
      campos.where((c) => dadosPreenchidos[c.nomeCampo] != null &&
          dadosPreenchidos[c.nomeCampo].toString().isNotEmpty).length;

  double get _progresso =>
      campos.isEmpty ? 0 : _camposPreenchidos / campos.length;

  int get _obrigatoriosPorPreencher => campos
      .where((c) =>
          c.obrigatorio == 1 &&
          (dadosPreenchidos[c.nomeCampo] == null ||
              dadosPreenchidos[c.nomeCampo].toString().isEmpty))
      .length;

  void _salvarRegisto() async {
    if (dadosPreenchidos.isEmpty) {
      Toast.mostrar(context, 'Preencha pelo menos um campo antes de submeter!',
          tipo: ToastTipo.aviso);
      return;
    }

    for (final campo in campos) {
      final valor = dadosPreenchidos[campo.nomeCampo];
      if (campo.obrigatorio == 1 &&
          (valor == null || valor.toString().isEmpty)) {
        Toast.mostrar(context, 'O campo "${campo.nomeCampo}" é obrigatório!',
            tipo: ToastTipo.erro);
        return;
      }
    }

    setState(() => _salvando = true);

    try {
      final sucesso = await DatabaseHelper.instance.inserirRegisto({
        'no_id': widget.no.id,
        'dados': dadosPreenchidos,
      });

      if (!mounted) return;

      if (sucesso) {
        Toast.mostrar(context, 'Registo guardado com sucesso!',
            tipo: ToastTipo.sucesso);
        Navigator.pop(context);
      } else {
        Toast.mostrar(context,
            'Erro ao guardar registo. Verifique a ligação ao servidor.',
            tipo: ToastTipo.erro);
      }
    } catch (e) {
      Toast.mostrar(context, 'Erro: ${e.toString()}', tipo: ToastTipo.erro);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.no.nome),
            const Text(
              'Preenchimento de dados',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          // ─── BOTÃO DE MUDAR O TEMA ───
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
      body: _buildBody(),
      // Botão de submeter fixo no fundo do ecrã
      bottomNavigationBar: (campos.isEmpty || _loading)
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: _salvando ? null : _salvarRegisto,
                  icon: _salvando 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                    : const Icon(Icons.send),
                  label: Text(_salvando ? 'A guardar...' : 'SUBMETER DADOS'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('A carregar campos...'),
          ],
        ),
      );
    }

    if (campos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit_off, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Nenhum campo definido.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'Pede ao administrador para adicionar campos.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ─── CARTÃO DE PROGRESSO ───
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progresso: $_camposPreenchidos de ${campos.length}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('${(_progresso * 100).toInt()}%'),
                  ],
                ),
                if (_obrigatoriosPorPreencher > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '$_obrigatoriosPorPreencher campo(s) obrigatório(s) pendente(s)',
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: _progresso,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ─── LISTA DE CAMPOS ───
        ...campos.asMap().entries.map((entry) {
          final index = entry.key;
          final campo = entry.value;
          final isObrigatorio = campo.obrigatorio == 1;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        child: Text('${index + 1}', style: const TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          campo.nomeCampo,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (isObrigatorio)
                        const Text(
                          '* Obrigatório',
                          style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CampoWidget(
                    campo: campo,
                    onValueChanged: (nomeCampo, valor) {
                      setState(() => dadosPreenchidos[nomeCampo] = valor);
                    },
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}