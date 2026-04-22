import 'package:flutter/material.dart';
import '../models/models.dart';
import '../database/database_helper.dart';
import '../widgets/campo_widget.dart';
import '../utils/toast.dart';
import '../theme/app_theme.dart';

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
  int _preenchidos = 0;

  @override
  void initState() {
    super.initState();
    _loadCampos();
  }

  void _loadCampos() async {
    try {
      final data = await DatabaseHelper.instance.getCampos(widget.no.id!);
      setState(() { campos = data; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
      Toast.mostrar(context, 'Erro ao carregar campos', tipo: ToastTipo.erro);
    }
  }

  void _onValueChanged(String nome, dynamic valor) {
    setState(() {
      dadosPreenchidos[nome] = valor;
      _preenchidos = dadosPreenchidos.values
          .where((v) => v != null && v.toString().isNotEmpty).length;
    });
  }

  Future<void> _salvarRegisto() async {
    if (dadosPreenchidos.isEmpty) {
      Toast.mostrar(context, 'Preencha pelo menos um campo', tipo: ToastTipo.aviso);
      return;
    }
    for (final campo in campos) {
      final valor = dadosPreenchidos[campo.nomeCampo];
      if (campo.obrigatorio == 1 && (valor == null || valor.toString().isEmpty)) {
        Toast.mostrar(context, '"${campo.nomeCampo}" é obrigatório', tipo: ToastTipo.erro);
        return;
      }
    }
    setState(() => _salvando = true);
    try {
      final ok = await DatabaseHelper.instance.inserirRegisto({
        'no_id': widget.no.id, 'dados': dadosPreenchidos});
      if (!mounted) return;
      if (ok) {
        Toast.mostrar(context, 'Registo guardado com sucesso', tipo: ToastTipo.sucesso);
        Navigator.pop(context);
      } else {
        Toast.mostrar(context, 'Erro ao guardar registo', tipo: ToastTipo.erro);
      }
    } catch (e) {
      Toast.mostrar(context, 'Erro: $e', tipo: ToastTipo.erro);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = campos.isEmpty ? 0.0 : _preenchidos / campos.length;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkSurfaceRaised : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded,
            color: isDark ? const Color(0xFFCBD5E1) : AppTheme.neutral800),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.no.nome,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.2,
              color: isDark ? const Color(0xFFE2E8F0) : AppTheme.neutral900)),
          const Text('Preenchimento de formulário',
            style: TextStyle(fontSize: 11, color: AppTheme.neutral400)),
        ]),
        actions: [
          if (!_loading && campos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text('$_preenchidos/${campos.length}',
                  style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: AppTheme.neutral400)),
              ),
            ),
        ],
        bottom: _loading || campos.isEmpty ? null : PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: isDark ? AppTheme.darkBorder : AppTheme.neutral200,
            valueColor: AlwaysStoppedAnimation<Color>(
              progress == 1.0 ? AppTheme.success : AppTheme.accentBlue),
            minHeight: 3,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentBlue))
          : campos.isEmpty
              ? _EmptyFields(isDark: isDark)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                  itemCount: campos.length,
                  itemBuilder: (ctx, i) {
                    final campo = campos[i];
                    final isRequired = campo.obrigatorio == 1;
                    final isFilled = dadosPreenchidos[campo.nomeCampo] != null &&
                        dadosPreenchidos[campo.nomeCampo].toString().isNotEmpty;

                    return _FieldCard(
                      index: i + 1,
                      campo: campo,
                      isRequired: isRequired,
                      isFilled: isFilled,
                      isDark: isDark,
                      onValueChanged: _onValueChanged,
                    );
                  },
                ),
      bottomNavigationBar: _loading || campos.isEmpty ? null : _SubmitBar(
        loading: _salvando,
        progress: progress,
        onSubmit: _salvarRegisto,
        isDark: isDark,
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  final int index;
  final CampoDinamico campo;
  final bool isRequired;
  final bool isFilled;
  final bool isDark;
  final Function(String, dynamic) onValueChanged;

  const _FieldCard({
    required this.index, required this.campo, required this.isRequired,
    required this.isFilled, required this.isDark, required this.onValueChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceRaised : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFilled
              ? AppTheme.accentBlue.withOpacity(0.3)
              : (isDark ? AppTheme.darkBorder : AppTheme.neutral200)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Field header
          Row(children: [
            Container(
              width: 26, height: 26,
              decoration: BoxDecoration(
                color: isFilled
                    ? AppTheme.accentBlue.withOpacity(0.1)
                    : (isDark ? AppTheme.darkSurfaceHigh : AppTheme.neutral100),
                shape: BoxShape.circle),
              child: isFilled
                  ? const Icon(Icons.check_rounded, size: 14, color: AppTheme.accentBlue)
                  : Center(child: Text('$index',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                        color: AppTheme.neutral500))),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(campo.nomeCampo,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFE2E8F0) : AppTheme.neutral800))),
            if (isRequired)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.errorPale,
                  borderRadius: BorderRadius.circular(20)),
                child: const Text('Obrigatório',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                    color: AppTheme.error))),
          ]),
          const SizedBox(height: 14),
          CampoWidget(campo: campo, onValueChanged: onValueChanged),
        ]),
      ),
    );
  }
}

class _SubmitBar extends StatelessWidget {
  final bool loading;
  final double progress;
  final VoidCallback onSubmit;
  final bool isDark;

  const _SubmitBar({required this.loading, required this.progress,
    required this.onSubmit, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16,
        MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceRaised : Colors.white,
        border: Border(top: BorderSide(
          color: isDark ? AppTheme.darkBorder : AppTheme.neutral200))),
      child: SizedBox(
        height: 52,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: loading ? null : onSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: progress == 1.0 ? AppTheme.success : AppTheme.accentBlue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          child: loading
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(progress == 1.0
                    ? Icons.check_circle_rounded : Icons.send_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text(loading ? 'A guardar...' : 'Submeter dados',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                      letterSpacing: 0.2)),
                ]),
        ),
      ),
    );
  }
}

class _EmptyFields extends StatelessWidget {
  final bool isDark;
  const _EmptyFields({required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurfaceHigh : AppTheme.neutral100,
            borderRadius: BorderRadius.circular(20)),
          child: Icon(Icons.edit_off_outlined, size: 32,
            color: isDark ? AppTheme.neutral500 : AppTheme.neutral400)),
        const SizedBox(height: 16),
        const Text('Sem campos configurados',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        const Text('Adicione campos a esta pasta primeiro',
          style: TextStyle(fontSize: 13, color: AppTheme.neutral400)),
      ]),
    );
  }
}