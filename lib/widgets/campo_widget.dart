import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/models.dart';

class CampoWidget extends StatefulWidget {
  final CampoDinamico campo;
  final Function(String, dynamic) onValueChanged;

  const CampoWidget({Key? key, required this.campo, required this.onValueChanged}) : super(key: key);

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
    switch (widget.campo.tipoCampo) {

      // ─── TEXTO e NÚMERO ───────────────────────────────────
      case 'texto':
      case 'numero':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextField(
            controller: _controller,
            keyboardType: widget.campo.tipoCampo == 'numero'
                ? TextInputType.number
                : TextInputType.text,
            decoration: InputDecoration(
              labelText: widget.campo.nomeCampo,
              border: const OutlineInputBorder(),
            ),
            onChanged: (val) => widget.onValueChanged(widget.campo.nomeCampo, val),
          ),
        );

      // ─── SELEÇÃO ──────────────────────────────────────────
      case 'selecao':
        List<String> opcoes = widget.campo.opcoes?.split(',') ?? [];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: widget.campo.nomeCampo,
              border: const OutlineInputBorder(),
            ),
            initialValue: _selectedValue,
            items: opcoes
                .map((v) => DropdownMenuItem(value: v.trim(), child: Text(v.trim())))
                .toList(),
            onChanged: (val) {
              setState(() => _selectedValue = val);
              widget.onValueChanged(widget.campo.nomeCampo, val);
            },
          ),
        );

      // ─── DATA ─────────────────────────────────────────────
      case 'data':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: InkWell(
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
                final formatted =
                    '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                widget.onValueChanged(widget.campo.nomeCampo, formatted);
              }
            },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: widget.campo.nomeCampo,
                border: const OutlineInputBorder(),
                suffixIcon: const Icon(Icons.calendar_today),
              ),
              child: Text(
                _selectedDate != null
                    ? '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}'
                    : 'Selecionar data',
                style: TextStyle(
                  color: _selectedDate != null ? Colors.black : Colors.grey,
                ),
              ),
            ),
          ),
        );

      // ─── FOTO ─────────────────────────────────────────────
      case 'foto':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: Text('Selecionar Foto - ${widget.campo.nomeCampo}'),
                onPressed: () async {
                  final ImagePicker picker = ImagePicker();
                  final XFile? photo = await picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 800,
                    imageQuality: 70,
                  );
                  if (photo != null) {
                    // Na web guarda em base64, noutras plataformas guarda o path
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
              ),
              if (_base64Image != null)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Foto selecionada', style: TextStyle(color: Colors.green)),
                    ],
                  ),
                )
              else if (_imagePath != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_imagePath!, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );

      default:
        return const SizedBox();
    }
  }
}