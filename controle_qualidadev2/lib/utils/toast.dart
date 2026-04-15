import 'package:flutter/material.dart';

enum ToastTipo { sucesso, erro, aviso, info }

class Toast {
  static OverlayEntry? _overlayEntry;

  static void mostrar(
    BuildContext context,
    String mensagem, {
    ToastTipo tipo = ToastTipo.info,
    Duration duracao = const Duration(seconds: 3),
  }) {
    // Remove toast anterior se existir
    _overlayEntry?.remove();
    _overlayEntry = null;

    final config = _getConfig(tipo);

    _overlayEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        mensagem: mensagem,
        icone: config['icone'] as IconData,
        cor: config['cor'] as Color,
        duracao: duracao,
        onDismiss: () {
          _overlayEntry?.remove();
          _overlayEntry = null;
        },
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  static Map<String, dynamic> _getConfig(ToastTipo tipo) {
    switch (tipo) {
      case ToastTipo.sucesso:
        return {'icone': Icons.check_circle_rounded, 'cor': const Color(0xFF2E7D32)};
      case ToastTipo.erro:
        return {'icone': Icons.error_rounded, 'cor': const Color(0xFFC62828)};
      case ToastTipo.aviso:
        return {'icone': Icons.warning_rounded, 'cor': const Color(0xFFE65100)};
      case ToastTipo.info:
        return {'icone': Icons.info_rounded, 'cor': const Color(0xFF1A237E)};
    }
  }
}

class _ToastWidget extends StatefulWidget {
  final String mensagem;
  final IconData icone;
  final Color cor;
  final Duration duracao;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.mensagem,
    required this.icone,
    required this.cor,
    required this.duracao,
    required this.onDismiss,
  });

  @override
  _ToastWidgetState createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slide = Tween<Offset>(
      begin: const Offset(1.2, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();

    // Auto-dismiss
    Future.delayed(widget.duracao, () async {
      if (mounted) {
        await _controller.reverse();
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 60,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _opacity,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () async {
                await _controller.reverse();
                widget.onDismiss();
              },
              child: Container(
                constraints: const BoxConstraints(maxWidth: 320, minWidth: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: widget.cor.withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border(
                    left: BorderSide(color: widget.cor, width: 4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: widget.cor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(widget.icone, color: widget.cor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        widget.mensagem,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.close_rounded, size: 16, color: Colors.grey.shade400),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}