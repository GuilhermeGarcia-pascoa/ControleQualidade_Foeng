import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum ToastTipo { sucesso, erro, aviso, info }

class Toast {
  static OverlayEntry? _overlayEntry;

  static void mostrar(
    BuildContext context,
    String mensagem, {
    ToastTipo tipo = ToastTipo.info,
    Duration duracao = const Duration(seconds: 3),
  }) {
    _overlayEntry?.remove();
    _overlayEntry = null;

    final config = _getConfig(tipo);
    _overlayEntry = OverlayEntry(
      builder: (_) => _ToastWidget(
        mensagem: mensagem,
        icone: config['icon'] as IconData,
        cor: config['color'] as Color,
        corFundo: config['bg'] as Color,
        corBorda: config['border'] as Color,
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
        return {
          'icon': Icons.check_circle_rounded,
          'color': AppTheme.success,
          'bg': AppTheme.successPale,
          'border': const Color(0xFF6EE7B7),
        };
      case ToastTipo.erro:
        return {
          'icon': Icons.error_rounded,
          'color': AppTheme.error,
          'bg': AppTheme.errorPale,
          'border': const Color(0xFFFCA5A5),
        };
      case ToastTipo.aviso:
        return {
          'icon': Icons.warning_rounded,
          'color': AppTheme.warning,
          'bg': AppTheme.warningPale,
          'border': const Color(0xFFFCD34D),
        };
      case ToastTipo.info:
        return {
          'icon': Icons.info_rounded,
          'color': AppTheme.accentBlue,
          'bg': AppTheme.accentBluePale,
          'border': const Color(0xFF93C5FD),
        };
    }
  }
}

class _ToastWidget extends StatefulWidget {
  final String mensagem;
  final IconData icone;
  final Color cor;
  final Color corFundo;
  final Color corBorda;
  final Duration duracao;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.mensagem, required this.icone, required this.cor,
    required this.corFundo, required this.corBorda,
    required this.duracao, required this.onDismiss,
  });

  @override
  _ToastWidgetState createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(1.1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
    Future.delayed(widget.duracao, () async {
      if (mounted) { await _ctrl.reverse(); widget.onDismiss(); }
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _opacity,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () async { await _ctrl.reverse(); widget.onDismiss(); },
              child: Container(
                constraints: const BoxConstraints(maxWidth: 320, minWidth: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: widget.corFundo,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: widget.corBorda, width: 1),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(widget.icone, color: widget.cor, size: 18),
                  const SizedBox(width: 10),
                  Flexible(child: Text(widget.mensagem,
                    style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500,
                      color: widget.cor, height: 1.4))),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}