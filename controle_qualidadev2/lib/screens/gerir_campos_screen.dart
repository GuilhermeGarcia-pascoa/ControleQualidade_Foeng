import 'package:flutter/material.dart';
import '../models/models.dart';
import '../database/database_helper.dart';
import '../utils/toast.dart';
import '../theme/app_theme.dart';

class GerirCamposScreen extends StatefulWidget {
  final No no;
  final String perfil;

  const GerirCamposScreen({Key? key, required this.no, required this.perfil}) : super(key: key);

  @override
  _GerirCamposScreenState createState() => _GerirCamposScreenState();
}

class _GerirCamposScreenState extends State<GerirCamposScreen> {
  List<CampoDinamico> _campos = [];
  bool _loading = true;

  final List<Map<String, dynamic>> _tiposDeCampo = [
    {'value': 'texto', 'label': 'Texto', 'icon': Icons.text_fields_rounded},
    {'value': 'numero', 'label': 'Número', 'icon': Icons.pin_outlined},
    {'value': 'data', 'label': 'Data', 'icon': Icons.calendar_today_outlined},
    {'value': 'dropdown', 'label': 'Seleção', 'icon': Icons.list_rounded},
    {'value': 'foto', 'label': 'Fotografia', 'icon': Icons.camera_alt_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _loadCampos();
  }

  Future<void> _loadCampos() async {
    setState(() => _loading = true);
    try {
      final campos = await DatabaseHelper.instance.getCampos(widget.no.id!);
      setState(() { _campos = campos; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) Toast.mostrar(context, 'Erro ao carregar campos', tipo: ToastTipo.erro);
    }
  }

  void _abrirFormularioCampo({CampoDinamico? campo}) {
    final isEdicao = campo != null;
    bool obrigatorio = isEdicao ? (campo.obrigatorio == 1) : false;
    String? tipoSelecionado = isEdicao ? campo.tipoCampo : 'texto';
    final nomeC = TextEditingController(text: isEdicao ? campo.nomeCampo : '');
    final opcoesC = TextEditingController(text: isEdicao ? campo.opcoes : '');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurfaceRaised : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            top: 8, left: 20, right: 20),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Handle
              Center(child: Container(
                width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.neutral600 : AppTheme.neutral200,
                  borderRadius: BorderRadius.circular(2)))),

              // Title
              Row(children: [
                Container(width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.accentBluePale,
                    borderRadius: BorderRadius.circular(10)),
                  child: Icon(isEdicao ? Icons.edit_outlined : Icons.add_rounded,
                    color: AppTheme.accentBlue, size: 18)),
                const SizedBox(width: 12),
                Text(isEdicao ? 'Editar campo' : 'Novo campo',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 20),

              // Name
              TextField(
                controller: nomeC,
                decoration: const InputDecoration(labelText: 'Nome do campo'),
              ),
              const SizedBox(height: 16),

              // Type selector
              Text('Tipo de campo', style: TextStyle(
                fontSize: 12, color: isDark ? AppTheme.neutral400 : AppTheme.neutral500,
                fontWeight: FontWeight.w500)),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8,
                children: _tiposDeCampo.map((t) {
                  final selected = tipoSelecionado == t['value'];
                  return GestureDetector(
                    onTap: () => setS(() => tipoSelecionado = t['value'] as String),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppTheme.accentBlue
                            : (isDark ? AppTheme.darkSurfaceHigh : AppTheme.neutral100),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? AppTheme.accentBlue
                              : (isDark ? AppTheme.darkBorder : AppTheme.neutral200))),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(t['icon'] as IconData, size: 14,
                          color: selected ? Colors.white
                              : (isDark ? AppTheme.neutral400 : AppTheme.neutral600)),
                        const SizedBox(width: 6),
                        Text(t['label'] as String,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                            color: selected ? Colors.white
                                : (isDark ? AppTheme.neutral300 : AppTheme.neutral700))),
                      ]),
                    ),
                  );
                }).toList()),
              const SizedBox(height: 16),

              // Dropdown options
              if (tipoSelecionado == 'dropdown') ...[
                TextField(
                  controller: opcoesC,
                  decoration: const InputDecoration(
                    labelText: 'Opções (separadas por vírgula)',
                    hintText: 'Ex: Aprovado, Reprovado, Pendente'),
                ),
                const SizedBox(height: 16),
              ],

              // Required toggle
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurfaceHigh : AppTheme.neutral50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppTheme.darkBorder : AppTheme.neutral200)),
                child: SwitchListTile(
                  value: obrigatorio,
                  activeColor: AppTheme.accentBlue,
                  title: const Text('Campo obrigatório',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  subtitle: const Text('Utilizadores devem preencher este campo',
                    style: TextStyle(fontSize: 12, color: AppTheme.neutral400)),
                  onChanged: (v) => setS(() => obrigatorio = v),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),

              // Actions
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Cancelar'))),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  onPressed: () async {
                    final nome = nomeC.text.trim();
                    final opcoes = opcoesC.text.trim();
                    if (nome.isEmpty) {
                      Toast.mostrar(ctx, 'O nome é obrigatório', tipo: ToastTipo.aviso);
                      return;
                    }
                    if (tipoSelecionado == 'dropdown' && opcoes.isEmpty) {
                      Toast.mostrar(ctx, 'Adicione as opções do dropdown', tipo: ToastTipo.erro);
                      return;
                    }
                    bool sucesso;
                    if (isEdicao) {
                      sucesso = await DatabaseHelper.instance.editarCampo(
                        campo.id!, nome: nome, tipo: tipoSelecionado!,
                        opcoes: tipoSelecionado == 'dropdown' ? opcoes : null,
                        obrigatorio: obrigatorio);
                    } else {
                      sucesso = await DatabaseHelper.instance.criarCampo({
                        'no_id': widget.no.id, 'nome_campo': nome,
                        'tipo_campo': tipoSelecionado,
                        'opcoes': tipoSelecionado == 'dropdown' ? opcoes : null,
                        'obrigatorio': obrigatorio ? 1 : 0,
                        'ordem': _campos.length,
                      });
                    }
                    if (sucesso) {
                      Navigator.pop(ctx);
                      _loadCampos();
                      Toast.mostrar(context,
                        isEdicao ? 'Campo atualizado!' : 'Campo criado!',
                        tipo: ToastTipo.sucesso);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text(isEdicao ? 'Guardar' : 'Criar'))),
              ]),
              const SizedBox(height: 16),
            ]),
          ),
        ),
      ),
    );
  }

  void _apagarCampo(CampoDinamico campo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 52, height: 52,
              decoration: BoxDecoration(
                color: AppTheme.errorPale, borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 24)),
            const SizedBox(height: 16),
            Text('Apagar "${campo.nomeCampo}"?',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text('Os dados associados a este campo serão afetados.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.neutral500, height: 1.5)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx, false),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text('Cancelar'))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text('Apagar', style: TextStyle(color: Colors.white)))),
            ]),
          ]),
        ),
      ),
    );
    if (confirm == true) {
      await DatabaseHelper.instance.apagarCampo(campo.id!);
      _loadCampos();
      Toast.mostrar(context, 'Campo removido');
    }
  }

  IconData _iconForType(String tipo) {
    switch (tipo) {
      case 'numero': return Icons.pin_outlined;
      case 'data': return Icons.calendar_today_outlined;
      case 'dropdown': return Icons.list_rounded;
      case 'foto': return Icons.camera_alt_outlined;
      default: return Icons.text_fields_rounded;
    }
  }

  Color _colorForType(String tipo) {
    switch (tipo) {
      case 'numero': return AppTheme.accentTeal;
      case 'data': return AppTheme.warning;
      case 'dropdown': return const Color(0xFF7C3AED);
      case 'foto': return const Color(0xFFEC4899);
      default: return AppTheme.accentBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkSurfaceRaised : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
            color: isDark ? const Color(0xFFCBD5E1) : AppTheme.neutral800),
          onPressed: () => Navigator.pop(context)),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Campos do formulário',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFE2E8F0) : AppTheme.neutral900)),
          Text(widget.no.nome,
            style: const TextStyle(fontSize: 11, color: AppTheme.neutral400)),
        ]),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1,
            color: isDark ? AppTheme.darkBorder : AppTheme.neutral100)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentBlue))
          : _campos.isEmpty
              ? _EmptyCampos(isDark: isDark)
              : ReorderableListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: _campos.length,
                  onReorder: (oldIndex, newIndex) async {
                    if (newIndex > oldIndex) newIndex -= 1;
                    setState(() {
                      final item = _campos.removeAt(oldIndex);
                      _campos.insert(newIndex, item);
                    });
                    for (var i = 0; i < _campos.length; i++) {
                      await DatabaseHelper.instance
                          .atualizarOrdemCampo(_campos[i].id!, i);
                    }
                  },
                  itemBuilder: (ctx, i) {
                    final campo = _campos[i];
                    final cor = _colorForType(campo.tipoCampo);
                    return Container(
                      key: ValueKey(campo.id),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurfaceRaised : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? AppTheme.darkBorder : AppTheme.neutral200)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 2),
                        leading: Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                            color: cor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10)),
                          child: Icon(_iconForType(campo.tipoCampo),
                            color: cor, size: 18)),
                        title: Row(children: [
                          Text(campo.nomeCampo,
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14,
                              color: isDark ? const Color(0xFFE2E8F0) : AppTheme.neutral900)),
                          if (campo.obrigatorio == 1) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.errorPale,
                                borderRadius: BorderRadius.circular(20)),
                              child: const Text('*',
                                style: TextStyle(fontSize: 11, color: AppTheme.error,
                                  fontWeight: FontWeight.w700))),
                          ],
                        ]),
                        subtitle: Text(campo.tipoCampo.toUpperCase(),
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                            letterSpacing: 0.5, color: cor.withOpacity(0.7))),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.drag_handle_rounded, size: 18,
                            color: isDark ? AppTheme.neutral600 : AppTheme.neutral300),
                          const SizedBox(width: 4),
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_horiz_rounded, size: 18,
                              color: isDark ? AppTheme.neutral500 : AppTheme.neutral400),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                            onSelected: (v) {
                              if (v == 'editar') _abrirFormularioCampo(campo: campo);
                              if (v == 'apagar') _apagarCampo(campo);
                            },
                            itemBuilder: (_) => [
                              _menuItem('editar', Icons.edit_outlined, 'Editar'),
                              const PopupMenuDivider(),
                              _menuItem('apagar', Icons.delete_outline_rounded, 'Apagar',
                                danger: true),
                            ]),
                        ]),
                      ),
                    );
                  }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormularioCampo(),
        backgroundColor: AppTheme.accentBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo campo',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label,
      {bool danger = false}) {
    return PopupMenuItem(value: value,
      child: Row(children: [
        Icon(icon, size: 16,
          color: danger ? AppTheme.error : AppTheme.neutral600),
        const SizedBox(width: 10),
        Text(label,
          style: TextStyle(fontSize: 14, color: danger ? AppTheme.error : null)),
      ]));
  }
}

class _EmptyCampos extends StatelessWidget {
  final bool isDark;
  const _EmptyCampos({required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 72, height: 72,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurfaceHigh : AppTheme.neutral100,
          borderRadius: BorderRadius.circular(20)),
        child: Icon(Icons.list_alt_outlined, size: 32,
          color: isDark ? AppTheme.neutral500 : AppTheme.neutral400)),
      const SizedBox(height: 16),
      const Text('Nenhum campo configurado',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      const Text('Adicione campos para estruturar o seu formulário',
        style: TextStyle(fontSize: 13, color: AppTheme.neutral400)),
    ]));
  }
}