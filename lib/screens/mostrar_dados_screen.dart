import 'dart:ui';

import 'dart:convert';

import 'package:flutter/material.dart';

import '../database/database_helper.dart';
 
// ── Palette premium do Dark Theme ────────────────────────

const Color _bgDark      = Color(0xFF0D1117);

const Color _cardColor   = Color(0xFF161B22);

const Color _accent      = Color(0xFF2F81F7);

const Color _textPrimary = Color(0xFFE6EDF3);

const Color _textSecondary= Color(0xFFC9D1D9);

const Color _textMuted   = Color(0xFF8B949E);

const Color _borderColor = Color(0xFF30363D);

const Color _danger      = Color(0xFFD64045);

// ─────────────────────────────────────────────────────────
 
class MostrarDadosScreen extends StatefulWidget {

  final int noId;
 
  const MostrarDadosScreen({Key? key, required this.noId}) : super(key: key);
 
  @override

  _MostrarDadosScreenState createState() => _MostrarDadosScreenState();

}
 
class _MostrarDadosScreenState extends State<MostrarDadosScreen> {

  final ScrollController _scrollVertical = ScrollController();

  final ScrollController _scrollHorizontal = ScrollController();
 
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
 
    _scrollVertical.addListener(() {

      if (_scrollVertical.position.pixels >=

          _scrollVertical.position.maxScrollExtent - 200) {

        if (!_loadingMore && _hasMore) {

          _carregarMaisDados();

        }

      }

    });

  }
 
  @override

  void dispose() {

    _scrollVertical.dispose();

    _scrollHorizontal.dispose();

    super.dispose();

  }
 
  Future<void> _carregarDadosIniciais() async {

    setState(() {

      _loadingInitial = true;

      _hasMore = true;

      _registos.clear();

    });
 
    try {

      final camposVindosDoDb =

          await DatabaseHelper.instance.getCampos(widget.noId);

      final novosRegistos =

          await DatabaseHelper.instance.getRegistos(widget.noId);
 
      setState(() {

        _campos = camposVindosDoDb.map((c) => {

              'id': c.id,

              'nome_campo': c.nomeCampo,

            }).toList();
 
        _registos = novosRegistos;

        if (novosRegistos.length < _limit) _hasMore = false;

        _loadingInitial = false;

      });

    } catch (e) {

      _tratarErro(e);

    }

  }
 
  Future<void> _carregarMaisDados() async {

    if (_loadingMore || !_hasMore) return;
 
    setState(() => _loadingMore = true);
 
    try {

      final novos = await DatabaseHelper.instance.getRegistos(widget.noId);
 
      setState(() {

        if (novos.isEmpty) {

          _hasMore = false;

        } else {

          _registos.addAll(novos);

          if (novos.length < _limit) _hasMore = false;

        }

        _loadingMore = false;

      });

    } catch (e) {

      setState(() => _loadingMore = false);

    }

  }
 
  void _tratarErro(dynamic e) {

    setState(() => _loadingInitial = false);

    ScaffoldMessenger.of(context).showSnackBar(

      SnackBar(

        content: Row(

          children: [

            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),

            const SizedBox(width: 12),

            Expanded(child: Text('Erro: $e', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),

          ],

        ),

        backgroundColor: _danger,

        behavior: SnackBarBehavior.floating,

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),

      ),

    );

  }
 
  // --- CÉLULA DA TABELA ---

  Widget _buildConteudoCelula(dynamic valor) {

    if (valor == null ||

        valor.toString().trim().isEmpty ||

        valor.toString() == '-') {

      return Container(

        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

        decoration: BoxDecoration(

          color: _borderColor.withOpacity(0.4),

          borderRadius: BorderRadius.circular(6),

        ),

        child: const Text('Sem dados', style: TextStyle(color: _textMuted, fontSize: 12, fontWeight: FontWeight.w500)),

      );

    }
 
    String str = valor.toString();
 
    // Aumentada a largura máxima para o texto não ficar tão espremido

    return ConstrainedBox(

      constraints: const BoxConstraints(maxWidth: 300),

      child: Text(

        str,

        style: const TextStyle(

          color: _textPrimary,

          fontSize: 14,

          height: 1.3,

          fontWeight: FontWeight.w500,

        ),

        maxLines: 2,

        overflow: TextOverflow.ellipsis,

      ),

    );

  }
 
  void _mostrarDetalhesRegisto(dynamic registo) {

    showModalBottomSheet(

      context: context,

      backgroundColor: Colors.transparent,

      isScrollControlled: true,

      builder: (_) => BackdropFilter(

        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),

        child: Container(

          decoration: const BoxDecoration(

            color: _cardColor,

            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),

            border: Border(top: BorderSide(color: _borderColor, width: 1)),

          ),

          padding: EdgeInsets.only(

            bottom: MediaQuery.of(context).viewInsets.bottom + 24,

            top: 16,

            left: 24,

            right: 24,

          ),

          child: Column(

            mainAxisSize: MainAxisSize.min,

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Center(

                child: Container(

                  width: 40,

                  height: 4,

                  margin: const EdgeInsets.only(bottom: 24),

                  decoration: BoxDecoration(

                    color: _borderColor,

                    borderRadius: BorderRadius.circular(2),

                  ),

                ),

              ),

              Row(

                children: [

                  Container(

                    padding: const EdgeInsets.all(10),

                    decoration: BoxDecoration(

                      color: _accent.withOpacity(0.15),

                      borderRadius: BorderRadius.circular(12),

                    ),

                    child: const Icon(Icons.info_outline_rounded, color: _accent, size: 22),

                  ),

                  const SizedBox(width: 16),

                  const Text(

                    "Detalhes do Registo",

                    style: TextStyle(

                      color: _textPrimary,

                      fontSize: 18,

                      fontWeight: FontWeight.bold,

                      letterSpacing: 0.5,

                    ),

                  ),

                ],

              ),

              const SizedBox(height: 24),

              Container(

                width: double.infinity,

                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(

                  color: _bgDark,

                  borderRadius: BorderRadius.circular(12),

                  border: Border.all(color: _borderColor),

                ),

                child: const Text(

                  "A visualização detalhada pode ser implementada aqui.\nNo futuro, os dados completos deste registo aparecerão nesta área.",

                  style: TextStyle(color: _textMuted, fontSize: 14, height: 1.5),

                ),

              ),

              const SizedBox(height: 32),

              SizedBox(

                width: double.infinity,

                child: ElevatedButton(

                  style: ElevatedButton.styleFrom(

                    backgroundColor: _borderColor,

                    foregroundColor: _textPrimary,

                    elevation: 0,

                    shape: RoundedRectangleBorder(

                      borderRadius: BorderRadius.circular(12),

                    ),

                    padding: const EdgeInsets.symmetric(vertical: 16),

                  ),

                  onPressed: () => Navigator.pop(context),

                  child: const Text('Fechar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),

                ),

              ),

            ],

          ),

        ),

      ),

    );

  }
 
  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: _bgDark,

      extendBodyBehindAppBar: true, 

      appBar: AppBar(

        backgroundColor: _bgDark.withOpacity(0.8),

        elevation: 0,

        flexibleSpace: ClipRRect(

          child: BackdropFilter(

            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),

            child: Container(color: Colors.transparent),

          ),

        ),

        bottom: PreferredSize(

          preferredSize: const Size.fromHeight(1),

          child: Container(color: _borderColor.withOpacity(0.5), height: 1),

        ),

        iconTheme: const IconThemeData(color: _textPrimary),

        title: const Text(

          "Registos da Pasta",

          style: TextStyle(

            fontWeight: FontWeight.w700,

            color: _textPrimary,

            fontSize: 17,

            letterSpacing: 0.5,

          ),

        ),

        actions: [

          IconButton(

            icon: const Icon(Icons.refresh_rounded, color: _textSecondary),

            tooltip: 'Atualizar Dados',

            splashRadius: 24,

            onPressed: _carregarDadosIniciais,

          )

        ],

      ),

      body: Stack(

        children: [

          Positioned.fill(child: CustomPaint(painter: _GridPainter())),

          Positioned(

            top: 50,

            right: -100,

            child: Container(

              width: 300,

              height: 300,

              decoration: BoxDecoration(

                shape: BoxShape.circle,

                gradient: RadialGradient(

                  colors: [_accent.withOpacity(0.1), Colors.transparent],

                  stops: const [0.2, 1.0],

                ),

              ),

            ),

          ),

          SafeArea(

            child: _loadingInitial

                ? const Center(child: CircularProgressIndicator(color: _accent, strokeWidth: 3))

                : _buildTabelaDinamica(),

          ),

        ],

      ),

    );

  }
 
  Widget _buildTabelaDinamica() {

    if (_registos.isEmpty) {

      return Center(

        child: Column(

          mainAxisSize: MainAxisSize.min,

          children: [

            Container(

              width: 80, height: 80,

              decoration: BoxDecoration(

                color: _cardColor,

                shape: BoxShape.circle,

                border: Border.all(color: _borderColor, width: 2),

              ),

              child: const Icon(Icons.table_view_outlined, size: 36, color: _textMuted),

            ),

            const SizedBox(height: 20),

            const Text("Sem dados para mostrar", style: TextStyle(color: _textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),

            const SizedBox(height: 8),

            const Text("Ainda não existem registos\nassociados a esta pasta.", textAlign: TextAlign.center, style: TextStyle(color: _textMuted, fontSize: 14, height: 1.4)),

          ],

        ),

      );

    }
 
    return Padding(

      padding: const EdgeInsets.all(16.0),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          // HEADER SIMPLIFICADO

          Padding(

            padding: const EdgeInsets.only(bottom: 12, left: 4),

            child: Row(

              children: [

                Container(width: 4, height: 14, decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(2))),

                const SizedBox(width: 8),

                Text(

                  "${_registos.length} REGISTOS ENCONTRADOS",

                  style: const TextStyle(

                    color: _textMuted,

                    fontSize: 11,

                    fontWeight: FontWeight.w700,

                    letterSpacing: 0.8,

                  ),

                ),

              ],

            ),

          ),
 
          // TABELA COM LAYOUT ADAPTÁVEL

          Expanded(

            child: Container(

              width: double.infinity,

              decoration: BoxDecoration(

                color: _cardColor,

                borderRadius: BorderRadius.circular(16),

                border: Border.all(color: _borderColor),

                boxShadow: [

                  BoxShadow(

                    color: Colors.black.withOpacity(0.25),

                    blurRadius: 16,

                    offset: const Offset(0, 8),

                  )

                ],

              ),

              clipBehavior: Clip.antiAlias,

              child: Scrollbar(

                controller: _scrollVertical,

                thumbVisibility: true,

                child: SingleChildScrollView(

                  controller: _scrollVertical,

                  physics: const BouncingScrollPhysics(),

                  // O LayoutBuilder garante que a tabela se estica!

                  child: LayoutBuilder(

                    builder: (context, constraints) {

                      return Scrollbar(

                        controller: _scrollHorizontal,

                        thumbVisibility: true,

                        child: SingleChildScrollView(

                          controller: _scrollHorizontal,

                          scrollDirection: Axis.horizontal,

                          physics: const BouncingScrollPhysics(),

                          child: ConstrainedBox(

                            // Obriga a tabela a ocupar no mínimo 100% da largura do seu container pai

                            constraints: BoxConstraints(minWidth: constraints.maxWidth),

                            child: DataTable(

                              headingRowColor: MaterialStateProperty.all(_bgDark.withOpacity(0.5)),

                              columnSpacing: 32, // Reduzido ligeiramente para melhor simetria

                              horizontalMargin: 24,

                              headingRowHeight: 56,

                              dataRowMinHeight: 64,

                              dataRowMaxHeight: 64,

                              dividerThickness: 1,

                              headingTextStyle: const TextStyle(

                                color: _textSecondary,

                                fontSize: 12,

                                fontWeight: FontWeight.bold,

                                letterSpacing: 0.8,

                              ),

                              border: const TableBorder(

                                horizontalInside: BorderSide(color: _borderColor, width: 0.5),

                              ),

                              columns: _campos.map((campo) {

                                return DataColumn(

                                  label: Text(

                                    campo['nome_campo'].toString().toUpperCase(),

                                  ),

                                );

                              }).toList(),

                              rows: _registos.asMap().entries.map((entry) {

                                final index = entry.key;

                                final registo = entry.value;
 
                                return DataRow(

                                  color: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {

                                    if (states.contains(MaterialState.hovered)) return _accent.withOpacity(0.1);

                                    return index.isEven ? Colors.transparent : Colors.white.withOpacity(0.015);

                                  }),

                                  onSelectChanged: (_) => _mostrarDetalhesRegisto(registo),

                                  cells: _campos.map((campo) {

                                    final nome = campo['nome_campo'];
 
                                    var dadosJson = {};

                                    if (registo['dados'] != null) {

                                      try {

                                        dadosJson = registo['dados'] is String

                                            ? json.decode(registo['dados'])

                                            : registo['dados'];

                                      } catch (_) {}

                                    }
 
                                    final valor = dadosJson[nome] ?? registo[nome];
 
                                    return DataCell(

                                      InkWell(

                                        onTap: () => _mostrarDetalhesRegisto(registo),

                                        child: Padding(

                                          padding: const EdgeInsets.symmetric(vertical: 8),

                                          child: _buildConteudoCelula(valor),

                                        ),

                                      ),

                                    );

                                  }).toList(),

                                );

                              }).toList(),

                            ),

                          ),

                        ),

                      );

                    }

                  ),

                ),

              ),

            ),

          ),

        ],

      ),

    );

  }

}
 
class _GridPainter extends CustomPainter {

  @override

  void paint(Canvas canvas, Size size) {

    final paint = Paint()..color = const Color(0xFF30363D).withOpacity(0.3);

    const spacing = 32.0;

    for (double x = 0; x < size.width; x += spacing) {

      for (double y = 0; y < size.height; y += spacing) {

        canvas.drawCircle(Offset(x, y), 1.2, paint);

      }

    }

  }
 
  @override

  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

}
 