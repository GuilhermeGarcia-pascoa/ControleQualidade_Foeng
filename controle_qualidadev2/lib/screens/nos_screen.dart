import 'package:flutter/material.dart';
import '../models/models.dart';
import '../database/database_helper.dart';
import 'preencher_tabela_screen.dart';
import 'gerir_membros_screen.dart';
import 'mostrar_dados_screen.dart';
import '../utils/toast.dart';
import 'gerir_acesso_no_screen.dart';
import 'gerir_campos_screen.dart'; // Importante para o GerirCamposScreen funcionar

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
        widget.projeto.id!,
        paiId: widget.pai?.id,
      );

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

  // ... (Mantenho as funções _renomearNo, _moverNo, _criarNo, _apagarNo, _duplicarNo iguais às que tinhas)

  void _renomearNo(No no) {
    final nomeC = TextEditingController(text: no.nome);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Renomear Pasta'),
        content: TextField(
          controller: nomeC,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Novo nome', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final novoNome = nomeC.text.trim();
              if (novoNome.isEmpty || novoNome == no.nome) return;
              await DatabaseHelper.instance.renomearNo(no.id!, novoNome);
              Navigator.pop(context);
              _loadDados();
              Toast.mostrar(context, 'Pasta renomeada!', tipo: ToastTipo.sucesso);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _moverNo(No no) async {
    final todosNos = await DatabaseHelper.instance.getTodosNos(widget.projeto.id!);
    final nosDisponiveis = todosNos.where((n) => n.id != no.id && n.paiId != no.id).toList();
    No? destinoSelecionado;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Mover Pasta'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<No?>(
                  value: null,
                  groupValue: destinoSelecionado,
                  title: const Text('Raiz do projeto'),
                  onChanged: (v) => setStateDialog(() => destinoSelecionado = v),
                ),
                const Divider(),
                if (nosDisponiveis.isEmpty)
                  const Padding(padding: EdgeInsets.all(8.0), child: Text("Nenhuma pasta destino disponível")),
                if (nosDisponiveis.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: nosDisponiveis.length,
                      itemBuilder: (context, i) => RadioListTile<No?>(
                        value: nosDisponiveis[i],
                        groupValue: destinoSelecionado,
                        title: Text(nosDisponiveis[i].nome),
                        onChanged: (v) => setStateDialog(() => destinoSelecionado = v),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                await DatabaseHelper.instance.moverNo(no.id!, novoPaiId: destinoSelecionado?.id);
                Navigator.pop(context);
                _loadDados();
              },
              child: const Text('Mover'),
            ),
          ],
        ),
      ),
    );
  }

  void _criarNo() {
    final nomeC = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova Pasta'),
        content: TextField(controller: nomeC, autofocus: true, decoration: const InputDecoration(hintText: "Nome da pasta")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nomeC.text.trim().isEmpty) return;
              await DatabaseHelper.instance.criarNo(widget.projeto.id!, paiId: widget.pai?.id, nome: nomeC.text.trim());
              Navigator.pop(context);
              _loadDados();
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }

  void _apagarNo(No no) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar Pasta'),
        content: Text('Tem a certeza que deseja apagar "${no.nome}" e todo o seu conteúdo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Apagar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseHelper.instance.apagarNo(no.id!);
      _loadDados();
    }
  }

  void _duplicarNo(No no) async {
    bool incluirSubpastas = true;
    bool incluirCampos = true;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.copy_all_rounded, size: 22),
              SizedBox(width: 8),
              Text('Duplicar Pasta'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('O que pretende copiar de "${no.nome}"?'),
              const SizedBox(height: 16),
              CheckboxListTile(
                value: incluirSubpastas,
                contentPadding: EdgeInsets.zero,
                title: const Text('Subpastas'),
                subtitle: const Text('Copia toda a estrutura de pastas internas'),
                secondary: const Icon(Icons.folder_copy_outlined),
                onChanged: (val) => setStateDialog(() => incluirSubpastas = val ?? true),
              ),
              CheckboxListTile(
                value: incluirCampos,
                contentPadding: EdgeInsets.zero,
                title: const Text('Campos do formulário'),
                subtitle: const Text('Copia os campos configurados, sem registos'),
                secondary: const Icon(Icons.list_alt_outlined),
                onChanged: (val) => setStateDialog(() => incluirCampos = val ?? true),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.copy_all_rounded, size: 18),
              label: const Text('Duplicar'),
            ),
          ],
        ),
      ),
    );

    if (confirm == true && mounted) {
      await DatabaseHelper.instance.duplicarNo(
        no.id!,
        novoPaiId: widget.pai?.id,
        projetoId: widget.projeto.id!,
        incluirSubpastas: incluirSubpastas,
        incluirCampos: incluirCampos,
      );
      _loadDados();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    List<String> caminhoExibido = [];
    if (widget.perfil != 'trabalhador' || widget.pai != null) {
      if (widget.perfil != 'trabalhador') caminhoExibido.add(widget.projeto.nome);
      caminhoExibido.addAll(widget.breadcrumb);
      if (widget.pai != null) caminhoExibido.add(widget.pai!.nome);
    }

    return Scaffold(
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.pai?.nome ?? widget.projeto.nome, 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            if (caminhoExibido.length > 1)
              SizedBox(
                height: 24,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: caminhoExibido.asMap().entries.map((entry) {
                      final int index = entry.key;
                      final String nome = entry.value;
                      final bool isLast = index == caminhoExibido.length - 1;
                      return Row(
                        children: [
                          InkWell(
                            onTap: isLast ? null : () {
                              int saltos = (caminhoExibido.length - 1) - index;
                              for (int i = 0; i < saltos && Navigator.canPop(context); i++) {
                                Navigator.pop(context);
                              }
                            },
                            child: Text(
                              nome,
                              style: TextStyle(
                                fontSize: 12,
                                color: isLast ? theme.colorScheme.onSurface : theme.colorScheme.primary,
                                fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (!isLast) const Icon(Icons.chevron_right, size: 14, color: Colors.grey),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
        actions: [
          if (widget.perfil == 'admin' && widget.pai == null)
            IconButton(
              icon: const Icon(Icons.group),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GerirMembrosScreen(projeto: widget.projeto))),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (campos.isNotEmpty && widget.pai != null) ...[
                  _buildAcoesRapidas(theme, isDark),
                  const SizedBox(height: 24),
                ],
                const Text('Pastas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (nos.isEmpty && campos.isEmpty)
                  const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('Esta pasta está vazia.'))),
                
                ...nos.map((no) => _buildFolderTile(no, theme, isDark, caminhoExibido)),
              ],
            ),
      floatingActionButton: widget.perfil == 'admin' ? _buildFab(theme) : null,
    );
  }

  Widget _buildAcoesRapidas(ThemeData theme, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.edit_document,
            title: 'Preencher\nFormulário',
            color: theme.colorScheme.primary,
            isDark: isDark,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PreencherTabelaScreen(no: widget.pai!))),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(
            icon: Icons.table_chart,
            title: 'Ver\nRegistos',
            color: Colors.orange,
            isDark: isDark,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MostrarDadosScreen(noId: widget.pai!.id!))),
          ),
        ),
      ],
    );
  }

  Widget _buildFolderTile(No no, ThemeData theme, bool isDark, List<String> caminhoAtual) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: ListTile(
        leading: Icon(Icons.folder, color: theme.colorScheme.primary, size: 30),
        title: Text(no.nome, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: widget.perfil == 'admin' ? _buildAdminMenu(no) : const Icon(Icons.chevron_right),
        onTap: () {
          List<String> novoBreadcrumb;
          if (widget.perfil == 'trabalhador' && widget.pai == null) {
            novoBreadcrumb = [];
          } else {
            novoBreadcrumb = List.from(widget.breadcrumb);
            if (widget.pai != null) novoBreadcrumb.add(widget.pai!.nome);
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NosScreen(
                projeto: widget.projeto,
                perfil: widget.perfil,
                pai: no,
                breadcrumb: novoBreadcrumb,
              ),
            ),
          ).then((_) => _loadDados());
        },
      ),
    );
  }

  Widget _buildAdminMenu(No no) {
    return PopupMenuButton<String>(
      onSelected: (v) {
        if (v == 'renomear') _renomearNo(no);
        if (v == 'mover') _moverNo(no);
        if (v == 'duplicar') _duplicarNo(no);
        if (v == 'acesso') Navigator.push(context, MaterialPageRoute(builder: (_) => GerirAcessoNoScreen(no: no)));
        if (v == 'apagar') _apagarNo(no);
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'renomear', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Renomear')])),
        const PopupMenuItem(value: 'mover', child: Row(children: [Icon(Icons.drive_file_move, size: 18), SizedBox(width: 8), Text('Mover')])),
        const PopupMenuItem(value: 'duplicar', child: Row(children: [Icon(Icons.copy_all_rounded, size: 18), SizedBox(width: 8), Text('Duplicar')])),
        const PopupMenuItem(value: 'acesso', child: Row(children: [Icon(Icons.lock_person, size: 18), SizedBox(width: 8), Text('Permissões')])),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'apagar', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 18), SizedBox(width: 8), Text('Apagar', style: TextStyle(color: Colors.red))])),
      ],
    );
  }

  Widget _buildFab(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.pai != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: FloatingActionButton.small(
              heroTag: 'fab_campos',
              // AQUI MUDOU: Agora abre o GerirCamposScreen
              onPressed: () => Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => GerirCamposScreen(no: widget.pai!, perfil: widget.perfil))
              ).then((_) => _loadDados()),
              child: const Icon(Icons.list_alt),
            ),
          ),
        FloatingActionButton(
          heroTag: 'fab_nova_pasta',
          onPressed: _criarNo,
          child: const Icon(Icons.add),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionCard({required this.icon, required this.title, required this.color, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}