import 'package:flutter/material.dart';
import '../models/models.dart';
import '../database/database_helper.dart';
import 'preencher_tabela_screen.dart';
import 'gerir_membros_screen.dart';
import 'mostrar_dados_screen.dart';
import '../utils/toast.dart';
import '../theme/app_theme.dart';
import 'gerir_acesso_no_screen.dart';
import 'gerir_campos_screen.dart';

class NosScreen extends StatefulWidget {
  final Projeto projeto;
  final String perfil;
  final No? pai;
  final List<String> breadcrumb;

  const NosScreen({
    Key? key,
    required this.projeto,
    required this.perfil,
    this.pai,
    this.breadcrumb = const [],
  }) : super(key: key);

  @override
  _NosScreenState createState() => _NosScreenState();
}

class _NosScreenState extends State<NosScreen> {
  List<No> nos = [];
  List<CampoDinamico> campos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDados();
  }

  void _loadDados() async {
    setState(() => _loading = true);
    try {
      final nosData = await DatabaseHelper.instance.getNos(
          widget.projeto.id!, paiId: widget.pai?.id);
      final camposData = widget.pai != null
          ? await DatabaseHelper.instance.getCampos(widget.pai!.id!)
          : <CampoDinamico>[];
      if (!mounted) return;
      setState(() {
        nos = nosData;
        campos = camposData;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) Toast.mostrar(context, 'Erro ao carregar dados', tipo: ToastTipo.erro);
    }
  }

  void _criarNo() {
    final nomeC = TextEditingController();
    _showInputDialog(
      title: 'Nova pasta',
      hint: 'Nome da pasta',
      icon: Icons.create_new_folder_outlined,
      controller: nomeC,
      onConfirm: () async {
        if (nomeC.text.trim().isEmpty) return;
        await DatabaseHelper.instance.criarNo(widget.projeto.id!,
            paiId: widget.pai?.id, nome: nomeC.text.trim());
        _loadDados();
      },
    );
  }

  void _renomearNo(No no) {
    final nomeC = TextEditingController(text: no.nome);
    _showInputDialog(
      title: 'Renomear pasta',
      hint: 'Novo nome',
      icon: Icons.drive_file_rename_outline_rounded,
      controller: nomeC,
      onConfirm: () async {
        if (nomeC.text.trim().isEmpty || nomeC.text.trim() == no.nome) return;
        await DatabaseHelper.instance.renomearNo(no.id!, nomeC.text.trim());
        _loadDados();
        Toast.mostrar(context, 'Pasta renomeada', tipo: ToastTipo.sucesso);
      },
    );
  }

  void _showInputDialog({
    required String title,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(width: 36, height: 36,
                  decoration: BoxDecoration(color: AppTheme.accentBluePale,
                    borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: AppTheme.accentBlue, size: 18)),
                const SizedBox(width: 12),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(hintText: hint),
                onSubmitted: (_) { Navigator.pop(ctx); onConfirm(); },
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: const Text('Cancelar'))),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  onPressed: () { Navigator.pop(ctx); onConfirm(); },
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: const Text('Confirmar'))),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  void _apagarNo(No no) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 52, height: 52,
              decoration: BoxDecoration(color: AppTheme.errorPale,
                borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.delete_outline_rounded,
                color: AppTheme.error, size: 24)),
            const SizedBox(height: 16),
            Text('Apagar "${no.nome}"?',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Todo o conteúdo será eliminado permanentemente.',
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
      await DatabaseHelper.instance.apagarNo(no.id!);
      _loadDados();
    }
  }

  void _duplicarNo(No no) async {
    bool subpastas = true;
    bool campos = true;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Duplicar pasta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('O que copiar de "${no.nome}"?',
                  style: const TextStyle(fontSize: 13, color: AppTheme.neutral500)),
                const SizedBox(height: 20),
                _CheckOption(label: 'Subpastas',
                  subtitle: 'Inclui toda a estrutura interna',
                  value: subpastas,
                  icon: Icons.folder_copy_outlined,
                  onChange: (v) => setS(() => subpastas = v)),
                const SizedBox(height: 8),
                _CheckOption(label: 'Campos do formulário',
                  subtitle: 'Copia os campos configurados',
                  value: campos,
                  icon: Icons.list_alt_outlined,
                  onChange: (v) => setS(() => campos = v)),
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
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: const Text('Duplicar'))),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
    if (confirm == true && mounted) {
      await DatabaseHelper.instance.duplicarNo(no.id!,
        novoPaiId: widget.pai?.id, projetoId: widget.projeto.id!,
        incluirSubpastas: subpastas, incluirCampos: campos);
      _loadDados();
    }
  }

  void _moverNo(No no) async {
    final todosNos = await DatabaseHelper.instance.getTodosNos(widget.projeto.id!);
    final disponiveis = todosNos.where((n) => n.id != no.id && n.paiId != no.id).toList();
    No? destino;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Mover pasta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      RadioListTile<No?>(
                        value: null, groupValue: destino,
                        title: const Text('Raiz do projeto'),
                        contentPadding: EdgeInsets.zero,
                        onChanged: (v) => setS(() => destino = v),
                      ),
                      ...disponiveis.map((n) => RadioListTile<No?>(
                        value: n, groupValue: destino,
                        title: Text(n.nome),
                        contentPadding: EdgeInsets.zero,
                        onChanged: (v) => setS(() => destino = v),
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: const Text('Cancelar'))),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton(
                    onPressed: () async {
                      await DatabaseHelper.instance.moverNo(no.id!, novoPaiId: destino?.id);
                      Navigator.pop(ctx);
                      _loadDados();
                    },
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: const Text('Mover'))),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAdmin = widget.perfil == 'admin';
    final hasActions = campos.isNotEmpty && widget.pai != null;
    final title = widget.pai?.nome ?? widget.projeto.nome;

    // Build breadcrumb path
    final breadcrumbItems = <String>[];
    if (widget.perfil != 'trabalhador' || widget.pai != null) {
      if (widget.perfil != 'trabalhador') breadcrumbItems.add(widget.projeto.nome);
      breadcrumbItems.addAll(widget.breadcrumb);
      if (widget.pai != null) breadcrumbItems.add(widget.pai!.nome);
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkSurfaceRaised : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
            color: isDark ? const Color(0xFFCBD5E1) : AppTheme.neutral800),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
              style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.2,
                color: isDark ? const Color(0xFFE2E8F0) : AppTheme.neutral900)),
            if (breadcrumbItems.length > 1)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: breadcrumbItems.asMap().entries.map((e) {
                    final isLast = e.key == breadcrumbItems.length - 1;
                    return Row(children: [
                      GestureDetector(
                        onTap: isLast ? null : () {
                          final pops = (breadcrumbItems.length - 1) - e.key;
                          for (var i = 0; i < pops; i++) {
                            Navigator.pop(context);
                          }
                        },
                        child: Text(e.value,
                          style: TextStyle(
                            fontSize: 11,
                            color: isLast ? AppTheme.neutral400
                                : AppTheme.accentBlue,
                            fontWeight: isLast ? FontWeight.w500 : FontWeight.w400)),
                      ),
                      if (!isLast) const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2),
                        child: Icon(Icons.chevron_right_rounded,
                          size: 12, color: AppTheme.neutral300)),
                    ]);
                  }).toList(),
                ),
              ),
          ],
        ),
        actions: [
          if (isAdmin && widget.pai == null)
            IconButton(
              icon: const Icon(Icons.group_outlined, size: 20),
              onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => GerirMembrosScreen(projeto: widget.projeto))),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1,
            color: isDark ? AppTheme.darkBorder : AppTheme.neutral100)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentBlue))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ─── ACTION CARDS ──────────────────────────────────────
                if (hasActions) ...[
                  Row(children: [
                    Expanded(child: _ActionTile(
                      icon: Icons.edit_document,
                      label: 'Preencher\nFormulário',
                      color: AppTheme.accentBlue,
                      isDark: isDark,
                      onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) =>
                          PreencherTabelaScreen(no: widget.pai!))),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _ActionTile(
                      icon: Icons.table_chart_outlined,
                      label: 'Ver\nRegistos',
                      color: AppTheme.accentTeal,
                      isDark: isDark,
                      onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) =>
                          MostrarDadosScreen(noId: widget.pai!.id!))),
                    )),
                  ]),
                  const SizedBox(height: 24),
                ],

                // ─── FOLDERS SECTION HEADER ────────────────────────────
                if (nos.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(children: [
                      Text('Subpastas'.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600,
                          color: AppTheme.neutral400, letterSpacing: 0.8)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkSurfaceHigh : AppTheme.neutral100,
                          borderRadius: BorderRadius.circular(20)),
                        child: Text('${nos.length}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                            color: AppTheme.neutral500))),
                    ]),
                  ),
                  ...nos.map((no) => _FolderTile(
                    no: no, isAdmin: isAdmin, isDark: isDark,
                    onTap: () {
                      final newBreadcrumb = widget.perfil == 'trabalhador' && widget.pai == null
                          ? <String>[]
                          : [...widget.breadcrumb,
                              if (widget.pai != null) widget.pai!.nome];
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => NosScreen(
                          projeto: widget.projeto, perfil: widget.perfil,
                          pai: no, breadcrumb: newBreadcrumb),
                      )).then((_) => _loadDados());
                    },
                    onRename: () => _renomearNo(no),
                    onMove: () => _moverNo(no),
                    onDuplicate: () => _duplicarNo(no),
                    onDelete: () => _apagarNo(no),
                    onPermissions: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => GerirAcessoNoScreen(no: no))),
                  )).toList(),
                ],

                // ─── EMPTY ─────────────────────────────────────────────
                if (nos.isEmpty && !hasActions)
                  _EmptyFolderState(isDark: isDark, isAdmin: isAdmin),
              ],
            ),
      floatingActionButton: isAdmin ? _buildFabs() : null,
    );
  }

  Widget _buildFabs() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.pai != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FloatingActionButton.small(
              heroTag: 'campos_fab',
              backgroundColor: AppTheme.accentTeal,
              foregroundColor: Colors.white,
              onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) =>
                  GerirCamposScreen(no: widget.pai!, perfil: widget.perfil)))
                    .then((_) => _loadDados()),
              child: const Icon(Icons.tune_rounded, size: 18),
            ),
          ),
        FloatingActionButton(
          heroTag: 'pasta_fab',
          backgroundColor: AppTheme.accentBlue,
          foregroundColor: Colors.white,
          onPressed: _criarNo,
          child: const Icon(Icons.add_rounded),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionTile({required this.icon, required this.label,
    required this.color, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurfaceRaised : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.neutral200)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20)),
            const SizedBox(height: 12),
            Text(label,
              style: TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13, height: 1.3,
                color: isDark ? const Color(0xFFE2E8F0) : AppTheme.neutral800)),
          ],
        ),
      ),
    );
  }
}

class _FolderTile extends StatelessWidget {
  final No no;
  final bool isAdmin;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onMove;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final VoidCallback onPermissions;

  const _FolderTile({
    required this.no, required this.isAdmin, required this.isDark,
    required this.onTap, required this.onRename, required this.onMove,
    required this.onDuplicate, required this.onDelete, required this.onPermissions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceRaised : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.neutral200)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: AppTheme.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.folder_rounded,
            color: AppTheme.warning, size: 20)),
        title: Text(no.nome,
          style: TextStyle(
            fontWeight: FontWeight.w600, fontSize: 14,
            color: isDark ? const Color(0xFFE2E8F0) : AppTheme.neutral900)),
        trailing: isAdmin
            ? PopupMenuButton<String>(
                icon: Icon(Icons.more_horiz_rounded, size: 18,
                  color: isDark ? AppTheme.neutral500 : AppTheme.neutral400),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (v) {
                  if (v == 'rename') onRename();
                  if (v == 'move') onMove();
                  if (v == 'duplicate') onDuplicate();
                  if (v == 'perms') onPermissions();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  _item('rename', Icons.edit_outlined, 'Renomear'),
                  _item('move', Icons.drive_file_move_outlined, 'Mover'),
                  _item('duplicate', Icons.copy_outlined, 'Duplicar'),
                  _item('perms', Icons.lock_outline_rounded, 'Permissões'),
                  const PopupMenuDivider(),
                  _item('delete', Icons.delete_outline_rounded, 'Apagar', danger: true),
                ])
            : const Icon(Icons.chevron_right_rounded, color: AppTheme.neutral300, size: 18),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  PopupMenuItem<String> _item(String val, IconData icon, String label, {bool danger = false}) {
    final c = danger ? AppTheme.error : AppTheme.neutral600;
    return PopupMenuItem(value: val,
      child: Row(children: [
        Icon(icon, size: 16, color: c),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: 14, color: danger ? AppTheme.error : null)),
      ]));
  }
}

class _EmptyFolderState extends StatelessWidget {
  final bool isDark;
  final bool isAdmin;
  const _EmptyFolderState({required this.isDark, required this.isAdmin});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurfaceHigh : AppTheme.neutral100,
              borderRadius: BorderRadius.circular(20)),
            child: Icon(Icons.folder_open_outlined, size: 32,
              color: isDark ? AppTheme.neutral500 : AppTheme.neutral400)),
          const SizedBox(height: 16),
          const Text('Pasta vazia',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(isAdmin ? 'Crie subpastas usando o botão +' : 'Nenhum conteúdo disponível',
            style: const TextStyle(fontSize: 13, color: AppTheme.neutral400)),
        ]),
      ),
    );
  }
}

class _CheckOption extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final IconData icon;
  final void Function(bool) onChange;

  const _CheckOption({required this.label, required this.subtitle,
    required this.value, required this.icon, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceHigh : AppTheme.neutral50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: value
            ? AppTheme.accentBlue.withOpacity(0.4)
            : (isDark ? AppTheme.darkBorder : AppTheme.neutral200))),
      child: CheckboxListTile(
        value: value,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.neutral400)),
        secondary: Icon(icon, color: value ? AppTheme.accentBlue : AppTheme.neutral400, size: 18),
        activeColor: AppTheme.accentBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onChanged: (v) => onChange(v ?? false),
      ),
    );
  }
}