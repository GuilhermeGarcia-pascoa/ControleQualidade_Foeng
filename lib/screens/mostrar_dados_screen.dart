import 'package:flutter/material.dart';
import 'dart:convert';
import '../database/database_helper.dart';

class MostrarDadosScreen extends StatefulWidget {
  final int noId;

  const MostrarDadosScreen({Key? key, required this.noId}) : super(key: key);

  @override
  _MostrarDadosScreenState createState() => _MostrarDadosScreenState();
}

class _MostrarDadosScreenState extends State<MostrarDadosScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _loadingInitial = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  final int _limit = 50;

  List<dynamic> _campos = [];
  List<dynamic> _registos = [];

  @override
  void initState() {
    super.initState();
    _carregarDadosIniciais();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        if (!_loadingMore && _hasMore) {
          _carregarMaisDados();
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _carregarDadosIniciais() async {
    if (!mounted) return;
    setState(() {
      _loadingInitial = true;
      _hasMore = true;
      _registos.clear();
    });

    try {
      final camposVindosDoDb = await DatabaseHelper.instance.getCampos(widget.noId);
      final novosRegistos = await DatabaseHelper.instance.getRegistos(widget.noId);

      if (mounted) {
        setState(() {
          _campos = camposVindosDoDb.map((c) => {
                'id': c.id,
                'nome_campo': c.nomeCampo,
              }).toList();

          _registos = novosRegistos;
          if (novosRegistos.length < _limit) _hasMore = false;
          _loadingInitial = false;
        });
      }
    } catch (e) {
      _tratarErro(e);
    }
  }

  Future<void> _carregarMaisDados() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);

    try {
      final novos = await DatabaseHelper.instance.getRegistos(widget.noId);
      if (mounted) {
        setState(() {
          if (novos.isEmpty) {
            _hasMore = false;
          } else {
            _registos.addAll(novos);
            if (novos.length < _limit) _hasMore = false;
          }
          _loadingMore = false;
        });
      }
    } catch (e) {
      setState(() => _loadingMore = false);
    }
  }

  void _tratarErro(dynamic e) {
    if (mounted) {
      setState(() => _loadingInitial = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // --- FUNÇÃO PARA EXPANDIR A IMAGEM ---
  void _expandirImagem(String base64String) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Imagem em ecrã total
            InteractiveViewer( // Permite fazer Zoom com os dedos
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4,
              child: Image.memory(
                base64Decode(base64String),
                fit: BoxFit.contain,
              ),
            ),
            // Botão de fechar
            Positioned(
              top: 10,
              right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.white24,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConteudoCelula(dynamic valor) {
    if (valor == null || valor.toString() == '-' || valor.toString().isEmpty) {
      return const Text('-');
    }

    String str = valor.toString().trim();

    // Limpeza de prefixos "Base64:"
    if (str.toLowerCase().startsWith("base64:")) {
      str = str.substring(7).trim();
    }

    // Se detetar que é uma imagem (Base64 longo)
    if (str.length > 100 && !str.contains(' ')) {
      try {
        String base64Limpo = str.contains(',') ? str.split(',').last : str;
        
        return GestureDetector( // <--- Detecta o toque do user
          onTap: () => _expandirImagem(base64Limpo),
          child: MouseRegion( // Feedback visual para Web/Desktop
            cursor: SystemMouseCursors.click,
            child: Container(
              width: 80,
              height: 80,
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                ],
                border: Border.all(color: Colors.blue.shade100, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Stack(
                  children: [
                    Image.memory(
                      base64Decode(base64Limpo),
                      width: 80, height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, color: Colors.orange),
                    ),
                    // Ícone de lupa discreto no canto
                    Positioned(
                      bottom: 2, right: 2,
                      child: Icon(Icons.zoom_in, size: 16, color: Colors.white.withOpacity(0.8)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      } catch (e) {
        return const Icon(Icons.broken_image, color: Colors.red);
      }
    }

    return Text(str, style: TextStyle(color: Colors.grey.shade800));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Registos da Pasta',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Toque na imagem para expandir',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarDadosIniciais,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _loadingInitial
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A237E)))
          : _campos.isEmpty
              ? const Center(child: Text('Nenhum campo configurado.'))
              : _buildTabelaDinamica(),
    );
  }

  Widget _buildTabelaDinamica() {
    if (_registos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.table_chart_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('Ainda não há registos.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                  dataRowMaxHeight: 100, 
                  dataRowMinHeight: 60,
                  columns: _campos.map((campo) {
                    return DataColumn(
                      label: Text(
                        campo['nome_campo'] ?? 'Sem Nome',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                      ),
                    );
                  }).toList(),
                  rows: _registos.map((registo) {
                    return DataRow(
                      cells: _campos.map((campo) {
                        final nomeDoCampo = campo['nome_campo'];
                        var dadosJson = {};
                        if (registo['dados'] != null) {
                          try {
                            dadosJson = registo['dados'] is String
                                ? json.decode(registo['dados'])
                                : registo['dados'];
                          } catch (e) { debugPrint("Erro JSON: $e"); }
                        }
                        final valor = dadosJson[nomeDoCampo] ?? registo[nomeDoCampo];
                        return DataCell(_buildConteudoCelula(valor));
                      }).toList(),
                    );
                  }).toList(),
                ),
              ),
            ),
            if (_loadingMore)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(color: Color(0xFF1A237E)),
              ),
          ],
        ),
      ),
    );
  }
}