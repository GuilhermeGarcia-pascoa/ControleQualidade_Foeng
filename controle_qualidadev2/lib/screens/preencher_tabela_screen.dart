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
      setState(() => _loading = false);
      Toast.mostrar(context, 'Erro ao carregar campos', tipo: ToastTipo.erro);
    }
  }

  void _salvarRegisto() async {
    if (dadosPreenchidos.isEmpty) {
      Toast.mostrar(context, 'Preencha pelo menos um campo antes de submeter!', tipo: ToastTipo.aviso);
      return;
    }

    for (final campo in campos) {
      final valor = dadosPreenchidos[campo.nomeCampo];
      if (campo.obrigatorio == 1 && (valor == null || valor.toString().isEmpty)) {
        Toast.mostrar(context, 'O campo "${campo.nomeCampo}" é obrigatório!', tipo: ToastTipo.erro);
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
        Toast.mostrar(context, 'Registo guardado com sucesso!', tipo: ToastTipo.sucesso);
        Navigator.pop(context);
      } else {
        Toast.mostrar(context, 'Erro ao guardar registo.', tipo: ToastTipo.erro);
      }
    } catch (e) {
      Toast.mostrar(context, 'Erro: ${e.toString()}', tipo: ToastTipo.erro);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      // Fundo ligeiramente diferente para os cartões destacarem-se no modo claro
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.no.nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(
              'Preenchimento de formulário',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6)),
            ),
          ],
        ),
        actions: const [
        ],
      ),
      body: _buildBody(theme, isDark),
      
      bottomNavigationBar: (campos.isEmpty || _loading)
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    )
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _salvando ? null : _salvarRegisto,
                  icon: _salvando 
                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.onPrimary)) 
                    : const Icon(Icons.send_rounded),
                  label: Text(
                    _salvando ? 'A guardar...' : 'SUBMETER DADOS', 
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5)
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildBody(ThemeData theme, bool isDark) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (campos.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_off_rounded, size: 64, color: theme.disabledColor),
            const SizedBox(height: 16),
            const Text('Nenhum campo definido.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: campos.length,
      itemBuilder: (context, index) {
        final campo = campos[index];
        final isObrigatorio = campo.obrigatorio == 1;

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor.withOpacity(isDark ? 0.3 : 0.8)),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${index + 1}', 
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        campo.nomeCampo,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    ),
                    if (isObrigatorio)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Obrigatório',
                          style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // O problema original das cores pretas resolve-se ajustando o código do CampoWidget!
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
      },
    );
  }
}