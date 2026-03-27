import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/models.dart';

// ─── PALETA (consistente com as outras screens) ───────────
class _C {
  static const bg         = Color(0xFF0D1117);
  static const surface    = Color(0xFF161B22);
  static const surfaceAlt = Color(0xFF1C2330);
  static const border     = Color(0xFF30363D);
  static const accent     = Color(0xFF00C2A8);
  static const primary    = Color(0xFF58A6FF);
  static const textPri    = Color(0xFFE6EDF3);
  static const textSec    = Color(0xFF8B949E);
  static const textMuted  = Color(0xFF484F58);
  static const success    = Color(0xFF3FB950);
}

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

  // ─── INPUT DECORATION DARK ───────────────────────────────
  InputDecoration _inputDeco({IconData? suffix}) => InputDecoration(
        filled: true,
        fillColor: _C.surfaceAlt,
        labelStyle: const TextStyle(color: _C.textSec, fontSize: 13),
        hintStyle: const TextStyle(color: _C.textMuted, fontSize: 13),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        suffixIcon:
            suffix != null ? Icon(suffix, color: _C.textSec, size: 18) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _C.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _C.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _C.accent, width: 1.5),
        ),
      );

  // ─── DATE PICKER DARK THEME ──────────────────────────────
  Future<DateTime?> _pickDate() => showDatePicker(
        context: context,
        initialDate: _selectedDate ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        builder: (context, child) => Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _C.accent,
              onPrimary: Colors.white,
              surface: Color(0xFF1C2330),
              onSurface: _C.textPri,
              background: Color(0xFF161B22),
            ),
            dialogBackgroundColor: const Color(0xFF161B22),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: _C.accent),
            ),
          ),
          child: child!,
        ),
      );

  @override
  Widget build(BuildContext context) {
    switch (widget.campo.tipoCampo) {

      // ─── TEXTO e NÚMERO ──────────────────────────────────
      case 'texto':
      case 'numero':
        return TextField(
          controller: _controller,
          keyboardType: widget.campo.tipoCampo == 'numero'
              ? TextInputType.number
              : TextInputType.text,
          style: const TextStyle(color: _C.textPri, fontSize: 14),
          cursorColor: _C.accent,
          decoration: _inputDeco(),
          onChanged: (val) =>
              widget.onValueChanged(widget.campo.nomeCampo, val),
        );

      // ─── SELEÇÃO ─────────────────────────────────────────
      case 'selecao':
        final opcoes = widget.campo.opcoes?.split(',') ?? [];
        return Theme(
          // Override do dropdown para dark
          data: Theme.of(context).copyWith(
            canvasColor: const Color(0xFF1C2330),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedValue,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: _C.textSec, size: 20),
            dropdownColor: const Color(0xFF1C2330),
            style: const TextStyle(color: _C.textPri, fontSize: 14),
            decoration: _inputDeco(),
            items: opcoes
                .map((v) => DropdownMenuItem(
                      value: v.trim(),
                      child: Text(
                        v.trim(),
                        style: const TextStyle(
                            color: _C.textPri, fontSize: 14),
                      ),
                    ))
                .toList(),
            selectedItemBuilder: (context) => opcoes
                .map((v) => Text(
                      v.trim(),
                      style: const TextStyle(
                          color: _C.textPri, fontSize: 14),
                    ))
                .toList(),
            onChanged: (val) {
              setState(() => _selectedValue = val);
              widget.onValueChanged(widget.campo.nomeCampo, val);
            },
          ),
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: _C.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasDate ? _C.accent.withOpacity(0.5) : _C.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  color: hasDate ? _C.accent : _C.textSec,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    formatted ?? 'Selecionar data',
                    style: TextStyle(
                      color: hasDate ? _C.textPri : _C.textMuted,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (hasDate)
                  GestureDetector(
                    onTap: () {
                      setState(() => _selectedDate = null);
                      widget.onValueChanged(widget.campo.nomeCampo, null);
                    },
                    child: Icon(Icons.close_rounded,
                        color: _C.textMuted, size: 16),
                  )
                else
                  Icon(Icons.keyboard_arrow_down_rounded,
                      color: _C.textSec, size: 18),
              ],
            ),
          ),
        );

      // ─── FOTO ────────────────────────────────────────────
      case 'foto':
        final temFoto = _base64Image != null || _imagePath != null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
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
                    widget.onValueChanged(
                        widget.campo.nomeCampo, 'base64:$base64');
                  } else {
                    setState(() => _imagePath = photo.path);
                    widget.onValueChanged(
                        widget.campo.nomeCampo, photo.path);
                  }
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: temFoto
                      ? _C.success.withOpacity(0.08)
                      : _C.surfaceAlt,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: temFoto
                        ? _C.success.withOpacity(0.4)
                        : _C.border,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      temFoto
                          ? Icons.check_circle_rounded
                          : Icons.add_photo_alternate_outlined,
                      color: temFoto ? _C.success : _C.textSec,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      temFoto ? 'Foto selecionada' : 'Selecionar foto',
                      style: TextStyle(
                        color: temFoto ? _C.success : _C.textSec,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
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
                          widget.onValueChanged(
                              widget.campo.nomeCampo, null);
                        },
                        child: Icon(Icons.close_rounded,
                            color: _C.textMuted, size: 16),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );

      default:
        return const SizedBox();
    }
  }
}