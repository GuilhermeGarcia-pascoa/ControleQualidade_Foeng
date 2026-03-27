import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/models.dart';

class CampoWidget extends StatefulWidget {
  final CampoDinamico campo;
  final Function(String, dynamic) onValueChanged;

  const CampoWidget({Key? key, required this.campo, required this.onValueChanged})
      : super(key: key);

  @override
  _CampoWidgetState createState() => _CampoWidgetState();
}

class _CampoWidgetState extends State<CampoWidget> {
  final TextEditingController _controller = TextEditingController();
  String? _selectedValue;
  String? _imagePath;
  String? _base64Image;
  DateTime? _selectedDate;

  // ─── INPUT DECORATION DINÂMICO ───────────────────────────────
  InputDecoration _inputDeco(ThemeData theme, bool isDark, {IconData? suffix}) {
    return InputDecoration(
      filled: true,
      // Fundo adaptável: claro no modo claro, escuro no modo escuro
      fillColor: isDark ? theme.colorScheme.surfaceVariant.withOpacity(0.3) : theme.colorScheme.surface,
      labelStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 13),
      hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4), fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      suffixIcon: suffix != null ? Icon(suffix, color: theme.colorScheme.onSurface.withOpacity(0.5), size: 18) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.dividerColor.withOpacity(isDark ? 0.3 : 0.6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
      ),
    );
  }

  // ─── DATE PICKER NATIVO (Usa o tema global) ──────────────────
  Future<DateTime?> _pickDate() => showDatePicker(
        context: context,
        initialDate: _selectedDate ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        // Removido o "builder" com tema escuro fixo, agora usa o tema do sistema automaticamente!
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;

    switch (widget.campo.tipoCampo) {

      // ─── TEXTO e NÚMERO ──────────────────────────────────
      case 'texto':
      case 'numero':
        return TextField(
          controller: _controller,
          keyboardType: widget.campo.tipoCampo == 'numero'
              ? TextInputType.number
              : TextInputType.text,
          style: TextStyle(color: textColor, fontSize: 15),
          cursorColor: theme.colorScheme.primary,
          decoration: _inputDeco(theme, isDark),
          onChanged: (val) =>
              widget.onValueChanged(widget.campo.nomeCampo, val),
        );

      // ─── SELEÇÃO ─────────────────────────────────────────
      case 'selecao':
        final opcoes = widget.campo.opcoes?.split(',') ?? [];
        return DropdownButtonFormField<String>(
          initialValue: _selectedValue,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: textColor.withOpacity(0.6), size: 22),
          dropdownColor: theme.colorScheme.surface,
          style: TextStyle(color: textColor, fontSize: 15),
          decoration: _inputDeco(theme, isDark),
          items: opcoes
              .map((v) => DropdownMenuItem(
                    value: v.trim(),
                    child: Text(
                      v.trim(),
                      style: TextStyle(color: textColor, fontSize: 15),
                    ),
                  ))
              .toList(),
          selectedItemBuilder: (context) => opcoes
              .map((v) => Text(
                    v.trim(),
                    style: TextStyle(color: textColor, fontSize: 15),
                  ))
              .toList(),
          onChanged: (val) {
            setState(() => _selectedValue = val);
            widget.onValueChanged(widget.campo.nomeCampo, val);
          },
        );

      // ─── DATA ────────────────────────────────────────────
      case 'data':
        final hasDate = _selectedDate != null;
        final formatted = hasDate
            ? '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}'
            : null;

        return GestureDetector(
          onTap: () async {
            final picked = await _pickDate();
            if (picked != null) {
              setState(() => _selectedDate = picked);
              final fmt =
                  '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
              widget.onValueChanged(widget.campo.nomeCampo, fmt);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? theme.colorScheme.surfaceVariant.withOpacity(0.3) : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasDate ? theme.colorScheme.primary.withOpacity(0.5) : theme.dividerColor.withOpacity(isDark ? 0.3 : 0.6),
                width: hasDate ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  color: hasDate ? theme.colorScheme.primary : textColor.withOpacity(0.5),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    formatted ?? 'Selecionar data',
                    style: TextStyle(
                      color: hasDate ? textColor : textColor.withOpacity(0.5),
                      fontSize: 15,
                    ),
                  ),
                ),
                if (hasDate)
                  GestureDetector(
                    onTap: () {
                      setState(() => _selectedDate = null);
                      widget.onValueChanged(widget.campo.nomeCampo, null);
                    },
                    child: Icon(Icons.close_rounded, color: textColor.withOpacity(0.5), size: 18),
                  )
                else
                  Icon(Icons.keyboard_arrow_down_rounded, color: textColor.withOpacity(0.5), size: 20),
              ],
            ),
          ),
        );

      // ─── FOTO ────────────────────────────────────────────
      case 'foto':
        final temFoto = _base64Image != null || _imagePath != null;
        return GestureDetector(
          onTap: () async {
            final picker = ImagePicker();
            final photo = await picker.pickImage(
              source: ImageSource.gallery,
              maxWidth: 800,
              imageQuality: 70,
            );
            if (photo != null) {
              if (kIsWeb) {
                final bytes = await photo.readAsBytes();
                final base64 = base64Encode(bytes);
                setState(() => _base64Image = base64);
                widget.onValueChanged(widget.campo.nomeCampo, 'base64:$base64');
              } else {
                setState(() => _imagePath = photo.path);
                widget.onValueChanged(widget.campo.nomeCampo, photo.path);
              }
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: temFoto
                  ? Colors.green.withOpacity(0.1)
                  : (isDark ? theme.colorScheme.surfaceVariant.withOpacity(0.3) : theme.colorScheme.surface),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: temFoto
                    ? Colors.green.withOpacity(0.5)
                    : theme.dividerColor.withOpacity(isDark ? 0.3 : 0.6),
                width: temFoto ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  temFoto
                      ? Icons.check_circle_rounded
                      : Icons.add_photo_alternate_outlined,
                  color: temFoto ? Colors.green : textColor.withOpacity(0.5),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Text(
                  temFoto ? 'Foto selecionada' : 'Selecionar foto',
                  style: TextStyle(
                    color: temFoto ? Colors.green : textColor.withOpacity(0.7),
                    fontSize: 15,
                    fontWeight: temFoto ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (temFoto) ...[
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _base64Image = null;
                        _imagePath = null;
                      });
                      widget.onValueChanged(widget.campo.nomeCampo, null);
                    },
                    child: Icon(Icons.close_rounded, color: textColor.withOpacity(0.5), size: 20),
                  ),
                ],
              ],
            ),
          ),
        );

      default:
        return const SizedBox();
    }
  }
}