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
  // Controle de scroll e paginação
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

    // Listener para detetar o fim da página
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

  // Carga inicial (Campos + Primeira página de registos)
  Future<void> _carregarDadosIniciais() async {
    if (!mounted) return;
    setState(() {
      _loadingInitial = true;
      _hasMore = true;
      _registos.clear();
    });

    try {
      // 1. Carregar colunas
      final camposVindosDoDb = await DatabaseHelper.instance.getCampos(widget.noId);
      
      // 2. Carregar primeiros registos
      // Nota: Se o teu backend ainda não suporta paginação, ele vai trazer todos, 
      // mas o código já está preparado para quando o backend for atualizado.
      final novosRegistos = await DatabaseHelper.instance.getRegistos(widget.noId);

      if (mounted) {
        setState(() {
          _campos = camposVindosDoDb.map((c) => {
            'id': c.id,
            'nome_campo': c.nomeCampo,
          }).toList();
          
          _registos = novosRegistos;
          
          // Se vierem menos registos que o limite, significa que a BD acabou
          if (novosRegistos.length < _limit) _hasMore = false;
          
          _loadingInitial = false;
        });
      }
    } catch (e) {
      _tratarErro(e);
    }
  }

  // Carregar mais dados quando o user faz scroll
  Future<void> _carregarMaisDados() async {
    if (_loadingMore || !_hasMore) return;

    setState(() => _loadingMore = true);

    try {
      // Aqui o ideal seria passar (_currentPage, _limit) para o teu getRegistos
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
      setState(() {
        _loadingMore = false;
      });
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Registos da Pasta', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Escala de Performance Ativada', style: TextStyle(color: Colors.white70, fontSize: 12)),
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
              ? const Center(child: Text('Nenhum campo configurado nesta pasta.'))
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
            Text('Ainda não há registos nesta pasta.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      controller: _scrollController, // Controller para scroll infinito
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: DataTable(
                  headingRowColor: MaterialStateProperty.resolveWith((states) => Colors.grey.shade100),
                  dataRowMaxHeight: double.infinity,
                  dataRowMinHeight: 50,
                  dividerThickness: 0.5,
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
                        
                        // Extração segura do JSON na coluna 'dados'
                        var dadosJson = {};
                        if (registo['dados'] != null) {
                          try {
                            dadosJson = registo['dados'] is String 
                                ? json.decode(registo['dados']) 
                                : registo['dados'];
                          } catch (e) {
                            print("Erro ao decodificar JSON: $e");
                          }
                        }

                        final valor = dadosJson[nomeDoCampo] ?? registo[nomeDoCampo] ?? '-';

                        return DataCell(
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(valor.toString(), style: TextStyle(color: Colors.grey.shade800)),
                          ),
                        );
                      }).toList(),
                    );
                  }).toList(),
                ),
              ),
            ),
            // Loading discreto no fundo da tabela
            if (_loadingMore)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(color: Color(0xFF1A237E)),
              ),
            if (!_hasMore && _registos.length > 10)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("Fim dos dados carregados.", style: TextStyle(color: Colors.grey)),
              ),
          ],
        ),
      ),
    );
  }
}