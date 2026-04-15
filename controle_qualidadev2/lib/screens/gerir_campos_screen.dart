import 'package:flutter/material.dart';
import '../models/models.dart';
import '../database/database_helper.dart';
import '../utils/toast.dart';

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

  final List<String> _tiposDeCampo = ['texto', 'numero', 'data', 'dropdown', 'foto'];

  @override
  void initState() {
    super.initState();
    _loadCampos();
  }

  Future<void> _loadCampos() async {
    setState(() => _loading = true);
    try {
      final campos = await DatabaseHelper.instance.getCampos(widget.no.id!);
      setState(() {
        _campos = campos;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) Toast.mostrar(context, 'Erro ao carregar campos', tipo: ToastTipo.erro);
    }
  }

  void _abrirEditarCampo(CampoDinamico campo) {
    _abrirFormularioCampo(campo: campo);
  }

  void _abrirFormularioCampo({CampoDinamico? campo}) {
    final bool isEdicao = campo != null;
    
    bool obrigatorio = isEdicao ? (campo.obrigatorio == true || campo.obrigatorio == 1) : false;
    
    // CORREÇÃO: Usar tipoCampo em vez de tipo
    String? tipoSelecionado = isEdicao ? campo.tipoCampo : 'texto';
    // CORREÇÃO: Usar nomeCampo em vez de nome
    final nomeC = TextEditingController(text: isEdicao ? campo.nomeCampo : '');
    final opcoesC = TextEditingController(text: isEdicao ? campo.opcoes : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20, right: 20, top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isEdicao ? 'Editar Campo' : 'Novo Campo', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: nomeC,
                decoration: const InputDecoration(labelText: 'Nome do Campo', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                initialValue: tipoSelecionado,
                decoration: const InputDecoration(labelText: 'Tipo de Campo', border: OutlineInputBorder()),
                items: _tiposDeCampo.map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase()))).toList(),
                onChanged: (v) => setModalState(() => tipoSelecionado = v),
              ),
              if (tipoSelecionado == 'dropdown') ...[
                const SizedBox(height: 15),
                TextField(
                  controller: opcoesC,
                  decoration: const InputDecoration(labelText: 'Opções (separadas por vírgula)', border: OutlineInputBorder(), hintText: 'Ex: Sim, Não, Talvez'),
                ),
              ],
              SwitchListTile(
                title: const Text('Obrigatório?'),
                value: obrigatorio,
                onChanged: (v) => setModalState(() => obrigatorio = v),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
  // Capturamos os valores para validar
  final nome = nomeC.text.trim();
  final opcoes = opcoesC.text.trim();

  // 1. Validação do Nome (já tinhas algo parecido)
  if (nome.isEmpty) {
    Toast.mostrar(context, 'O nome do campo é obrigatório', tipo: ToastTipo.aviso);
    return;
  }

  // 2. NOVO: Validação específica para o Dropdown
  if (tipoSelecionado == 'dropdown' && opcoes.isEmpty) {
    Toast.mostrar(
      context, 
      'Para um Dropdown, deves inserir as opções (ex: Sim, Não)', 
      tipo: ToastTipo.erro
    );
    return; // Para aqui e não guarda nada na base de dados
  }

  bool sucesso;
  if (isEdicao) {
    sucesso = await DatabaseHelper.instance.editarCampo(
      campo.id!,
      nome: nome,
      tipo: tipoSelecionado!,
      opcoes: tipoSelecionado == 'dropdown' ? opcoes : null,
      obrigatorio: obrigatorio,
    );
  } else {
    // Para o criarCampo, usamos a variável 'sucesso' para saber se correu bem
    final resultado = await DatabaseHelper.instance.criarCampo({
      'no_id': widget.no.id,
      'nome_campo': nome,
      'tipo_campo': tipoSelecionado,
      'opcoes': tipoSelecionado == 'dropdown' ? opcoes : null,
      'obrigatorio': obrigatorio ? 1 : 0,
      'ordem': _campos.length,
    });
    sucesso = resultado; 
  }

  if (sucesso) {
    Navigator.pop(context);
    _loadCampos();
    Toast.mostrar(context, isEdicao ? 'Campo atualizado!' : 'Campo criado!', tipo: ToastTipo.sucesso);
  }
},
                  child: Text(isEdicao ? 'GUARDAR ALTERAÇÕES' : 'CRIAR CAMPO'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _apagarCampo(CampoDinamico campo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar Campo'),
        // CORREÇÃO: Usar nomeCampo
        content: Text('Deseja apagar o campo "${campo.nomeCampo}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Apagar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.apagarCampo(campo.id!);
      _loadCampos();
      Toast.mostrar(context, 'Campo removido');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Campos: ${widget.no.nome}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _campos.isEmpty
              ? const Center(child: Text('Nenhum campo configurado.'))
              : ReorderableListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _campos.length,
                  onReorder: (oldIndex, newIndex) async {
                    if (newIndex > oldIndex) newIndex -= 1;
                    setState(() {
                      final item = _campos.removeAt(oldIndex);
                      _campos.insert(newIndex, item);
                    });
                    
                    for (int i = 0; i < _campos.length; i++) {
                      await DatabaseHelper.instance.atualizarOrdemCampo(_campos[i].id!, i);
                    }
                  },
                  itemBuilder: (context, index) => _buildCampoItem(_campos[index]),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormularioCampo(),
        label: const Text('Novo Campo'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCampoItem(CampoDinamico campo) {
    return Card(
      key: ValueKey(campo.id),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        // CORREÇÃO: Usar tipoCampo
        leading: Icon(_getTipoIcon(campo.tipoCampo), color: Colors.blue),
        title: Row(
          children: [
            // CORREÇÃO: Usar nomeCampo
            Text(campo.nomeCampo, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            if (campo.obrigatorio == true || campo.obrigatorio == 1)
              const Icon(Icons.star, size: 12, color: Colors.red),
          ],
        ),
        // CORREÇÃO: Usar tipoCampo
        subtitle: Text('Tipo: ${campo.tipoCampo.toUpperCase()}'),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'editar') _abrirEditarCampo(campo);
            if (v == 'apagar') _apagarCampo(campo);
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'editar', child: Row(children: [Icon(Icons.edit, size: 16), SizedBox(width: 8), Text('Editar')])),
            const PopupMenuItem(value: 'apagar', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 16), SizedBox(width: 8), Text('Apagar', style: TextStyle(color: Colors.red))])),
          ],
        ),
      ),
    );
  }

  IconData _getTipoIcon(String tipo) {
    switch (tipo) {
      case 'numero': return Icons.numbers;
      case 'data': return Icons.calendar_today;
      case 'dropdown': return Icons.list;
      case 'foto': return Icons.camera_alt;
      default: return Icons.text_fields;
    }
  }
}