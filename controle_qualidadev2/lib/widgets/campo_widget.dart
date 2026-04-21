import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFE2E8F0) : AppTheme.neutral900;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.neutral200;
    final fillColor = isDark ? AppTheme.darkSurface : AppTheme.neutral50;

    final decoration = InputDecoration(
      filled: true,
      fillColor: fillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: borderColor)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: borderColor)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.accentBlue, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      hintStyle: const TextStyle(color: AppTheme.neutral400, fontSize: 13),
    );

    switch (widget.campo.tipoCampo) {
      case 'texto':
      case 'numero':
        return TextField(
          controller: _controller,
          keyboardType: widget.campo.tipoCampo == 'numero'
              ? TextInputType.number : TextInputType.text,
          style: TextStyle(color: textColor, fontSize: 14),
          cursorColor: AppTheme.accentBlue,
          decoration: decoration.copyWith(
            hintText: widget.campo.tipoCampo == 'numero'
                ? 'Insira um número...' : 'Escreva aqui...'),
          onChanged: (val) => widget.onValueChanged(widget.campo.nomeCampo, val),
        );

      case 'dropdown':
        final opcoes = widget.campo.opcoes?.split(',').map((o) => o.trim()).toList() ?? [];
        return Container(
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _selectedValue != null
                ? AppTheme.accentBlue : borderColor,
              width: _selectedValue != null ? 1.5 : 1)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedValue,
              isExpanded: true,
              hint: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Text('Selecione uma opção',
                  style: TextStyle(color: AppTheme.neutral400, fontSize: 13))),
              icon: const Padding(
                padding: EdgeInsets.only(right: 10),
                child: Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppTheme.neutral400, size: 20)),
              dropdownColor: isDark ? AppTheme.darkSurfaceRaised : Colors.white,
              style: TextStyle(color: textColor, fontSize: 14),
              items: opcoes.map((v) => DropdownMenuItem(
                value: v,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(v)))).toList(),
              onChanged: (val) {
                setState(() => _selectedValue = val);
                widget.onValueChanged(widget.campo.nomeCampo, val);
              },
            ),
          ),
        );

      case 'data':
        final hasDate = _selectedDate != null;
        final formatted = hasDate
            ? '${_selectedDate!.day.toString().padLeft(2, '0')}/'
              '${_selectedDate!.month.toString().padLeft(2, '0')}/'
              '${_selectedDate!.year}'
            : null;
        return GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate ?? DateTime.now(),
              firstDate: DateTime(2000), lastDate: DateTime(2100));
            if (picked != null) {
              setState(() => _selectedDate = picked);
              widget.onValueChanged(widget.campo.nomeCampo,
                '${picked.day.toString().padLeft(2, '0')}/'
                '${picked.month.toString().padLeft(2, '0')}/${picked.year}');
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasDate ? AppTheme.accentBlue : borderColor,
                width: hasDate ? 1.5 : 1)),
            child: Row(children: [
              Icon(Icons.calendar_today_outlined, size: 16,
                color: hasDate ? AppTheme.accentBlue : AppTheme.neutral400),
              const SizedBox(width: 10),
              Expanded(child: Text(formatted ?? 'Selecionar data',
                style: TextStyle(fontSize: 13,
                  color: hasDate ? textColor : AppTheme.neutral400))),
              if (hasDate)
                GestureDetector(
                  onTap: () {
                    setState(() => _selectedDate = null);
                    widget.onValueChanged(widget.campo.nomeCampo, null);
                  },
                  child: const Icon(Icons.close_rounded, size: 16, color: AppTheme.neutral400)),
            ]),
          ),
        );

      case 'foto':
        final temFoto = _base64Image != null || _imagePath != null;
        return GestureDetector(
          onTap: () async {
            final picker = ImagePicker();
            final photo = await picker.pickImage(
              source: ImageSource.gallery, maxWidth: 800, imageQuality: 70);
            if (photo != null) {
              if (kIsWeb) {
                final bytes = await photo.readAsBytes();
                final b64 = base64Encode(bytes);
                setState(() => _base64Image = b64);
                widget.onValueChanged(widget.campo.nomeCampo, 'base64:$b64');
              } else {
                setState(() => _imagePath = photo.path);
                widget.onValueChanged(widget.campo.nomeCampo, photo.path);
              }
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
            decoration: BoxDecoration(
              color: temFoto ? AppTheme.success.withOpacity(0.06) : fillColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: temFoto ? AppTheme.success : borderColor,
                width: temFoto ? 1.5 : 1)),
            child: Row(children: [
              Icon(temFoto ? Icons.check_circle_outline_rounded
                  : Icons.add_photo_alternate_outlined,
                color: temFoto ? AppTheme.success : AppTheme.neutral400, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(temFoto ? 'Foto selecionada' : 'Selecionar fotografia',
                style: TextStyle(fontSize: 13,
                  color: temFoto ? AppTheme.success : AppTheme.neutral400,
                  fontWeight: temFoto ? FontWeight.w600 : FontWeight.w400))),
              if (temFoto)
                GestureDetector(
                  onTap: () {
                    setState(() { _base64Image = null; _imagePath = null; });
                    widget.onValueChanged(widget.campo.nomeCampo, null);
                  },
                  child: const Icon(Icons.close_rounded, size: 16, color: AppTheme.neutral400)),
            ]),
          ),
        );

      default:
        return const SizedBox();
    }
  }
}