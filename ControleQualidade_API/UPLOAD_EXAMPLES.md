# 📱 Exemplos de Upload Seguro - Flutter/Web

## Índice
1. [Flutter - Upload Completo](#flutter---upload-completo)
2. [JavaScript/Fetch](#javascriptfetch)
3. [Tratamento de Erros](#tratamento-de-erros)
4. [Boas Práticas](#boas-práticas)

---

## Flutter - Upload Completo

### 1. Serviço de Upload

```dart
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:convert';

class UploadService {
  static const String baseUrl = 'http://localhost:3000/api';

  /// Upload de um ficheiro com dados adicionais
  static Future<Map<String, dynamic>> uploadSingle({
    required String token,
    required String noId,
    required String utilizadorId,
    required Map<String, dynamic> dados,
    required String filePath,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/registos'),
      );

      // Headers
      request.headers['Authorization'] = 'Bearer $token';

      // Campos de formulário
      request.fields['no_id'] = noId;
      request.fields['utilizador_id'] = utilizadorId;
      request.fields['dados_json'] = jsonEncode(dados);

      // Ficheiro
      request.files.add(
        await http.MultipartFile.fromPath(
          'files',
          filePath,
        ),
      );

      // Enviar
      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return jsonDecode(responseData);
      } else {
        final errorData = jsonDecode(responseData);
        throw Exception(errorData['error'] ?? 'Erro no upload');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Upload múltiplo com lista de ficheiros
  static Future<Map<String, dynamic>> uploadMultiple({
    required String token,
    required String noId,
    required String utilizadorId,
    required Map<String, dynamic> dados,
    required List<String> filePaths,
  }) async {
    try {
      if (filePaths.isEmpty) {
        throw Exception('Nenhum ficheiro selecionado');
      }

      if (filePaths.length > 5) {
        throw Exception('Máximo 5 ficheiros por upload');
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/registos'),
      );

      // Headers
      request.headers['Authorization'] = 'Bearer $token';

      // Campos
      request.fields['no_id'] = noId;
      request.fields['utilizador_id'] = utilizadorId;
      request.fields['dados_json'] = jsonEncode(dados);

      // Ficheiros
      for (final filePath in filePaths) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'files',
            filePath,
          ),
        );
      }

      // Enviar
      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return jsonDecode(responseData);
      } else {
        final errorData = jsonDecode(responseData);
        throw Exception(errorData['error'] ?? 'Erro no upload');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Selecionar e fazer upload de ficheiro
  static Future<Map<String, dynamic>> pickAndUpload({
    required String token,
    required String noId,
    required String utilizadorId,
    required Map<String, dynamic> dados,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        allowCompression: true,
      );

      if (result == null || result.files.isEmpty) {
        throw Exception('Nenhum ficheiro selecionado');
      }

      final filePaths = result.files
          .map((file) => file.path!)
          .toList();

      return await uploadMultiple(
        token: token,
        noId: noId,
        utilizadorId: utilizadorId,
        dados: dados,
        filePaths: filePaths,
      );
    } catch (e) {
      rethrow;
    }
  }
}
```

### 2. Widget de Upload

```dart
import 'package:flutter/material.dart';

class UploadWidget extends StatefulWidget {
  final String token;
  final String noId;
  final String utilizadorId;

  const UploadWidget({
    required this.token,
    required this.noId,
    required this.utilizadorId,
  });

  @override
  State<UploadWidget> createState() => _UploadWidgetState();
}

class _UploadWidgetState extends State<UploadWidget> {
  bool _isLoading = false;
  String? _errorMessage;
  int _uploadedFiles = 0;

  Future<void> _handleUpload() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await UploadService.pickAndUpload(
        token: widget.token,
        noId: widget.noId,
        utilizadorId: widget.utilizadorId,
        dados: {
          'descricao': 'Ficheiros enviados',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (result['success'] == true) {
        setState(() {
          _uploadedFiles = result['files'] ?? 0;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result['files']} ficheiro(s) enviado(s) com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $_errorMessage'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Botão de upload
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _handleUpload,
          icon: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.upload_file),
          label: _isLoading
              ? const Text('A enviar...')
              : const Text('Selecionar e Enviar Imagens'),
        ),

        const SizedBox(height: 8),

        // Mensagem de erro
        if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              border: Border.all(color: Colors.red),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                const Icon(Icons.error, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),

        // Contador de ficheiros
        if (_uploadedFiles > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Ficheiros enviados: $_uploadedFiles',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}
```

### 3. Integração Completa em Screen

```dart
class RegistoScreen extends StatefulWidget {
  final String noId;
  final String token;

  const RegistoScreen({
    required this.noId,
    required this.token,
  });

  @override
  State<RegistoScreen> createState() => _RegistoScreenState();
}

class _RegistoScreenState extends State<RegistoScreen> {
  late TextEditingController _descricaoController;

  @override
  void initState() {
    super.initState();
    _descricaoController = TextEditingController();
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo Registo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Descrição
            TextField(
              controller: _descricaoController,
              decoration: const InputDecoration(
                label: Text('Descrição'),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            // Widget de upload
            UploadWidget(
              token: widget.token,
              noId: widget.noId,
              utilizadorId: '1',
            ),

            const SizedBox(height: 24),

            // Botão de salvar
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Registo guardado com sucesso')),
                );
                Navigator.pop(context);
              },
              child: const Text('Guardar Registo'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## JavaScript/Fetch

### Upload com Validação Prévia

```javascript
class UploadManager {
  constructor(apiUrl = 'http://localhost:3000/api', token) {
    this.apiUrl = apiUrl;
    this.token = token;
    this.maxFileSize = 5 * 1024 * 1024; // 5MB
    this.allowedTypes = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];
  }

  // Validar ficheiro antes de enviar
  validateFile(file) {
    // Verificar tamanho
    if (file.size > this.maxFileSize) {
      throw new Error(`Ficheiro muito grande. Máximo: 5MB`);
    }

    // Verificar MIME type
    if (!this.allowedTypes.includes(file.type)) {
      throw new Error(`Tipo não permitido: ${file.type}`);
    }

    return true;
  }

  // Upload de um ficheiro
  async uploadSingle(noId, utilizadorId, dados, file) {
    try {
      // Validar
      this.validateFile(file);

      // Preparar FormData
      const formData = new FormData();
      formData.append('no_id', noId);
      formData.append('utilizador_id', utilizadorId);
      formData.append('dados_json', JSON.stringify(dados));
      formData.append('files', file);

      // Enviar
      const response = await fetch(`${this.apiUrl}/registos`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${this.token}`
        },
        body: formData
      });

      if (!response.ok) {
        const error = await response.json();
        throw new Error(error.error || 'Erro no upload');
      }

      return await response.json();
    } catch (error) {
      console.error('Erro:', error);
      throw error;
    }
  }

  // Upload múltiplo
  async uploadMultiple(noId, utilizadorId, dados, files) {
    try {
      // Validar todos
      Array.from(files).forEach(file => this.validateFile(file));

      // Limite de 5 ficheiros
      if (files.length > 5) {
        throw new Error('Máximo 5 ficheiros por upload');
      }

      // Preparar FormData
      const formData = new FormData();
      formData.append('no_id', noId);
      formData.append('utilizador_id', utilizadorId);
      formData.append('dados_json', JSON.stringify(dados));

      // Adicionar ficheiros
      Array.from(files).forEach(file => {
        formData.append('files', file);
      });

      // Enviar
      const response = await fetch(`${this.apiUrl}/registos`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${this.token}`
        },
        body: formData
      });

      if (!response.ok) {
        const error = await response.json();
        throw new Error(error.error || 'Erro no upload');
      }

      return await response.json();
    } catch (error) {
      console.error('Erro:', error);
      throw error;
    }
  }
}

// Usar
const uploader = new UploadManager('http://localhost:3000/api', token);

// Upload único
document.getElementById('uploadBtn').addEventListener('click', async () => {
  const fileInput = document.getElementById('fileInput');
  const file = fileInput.files[0];

  try {
    const result = await uploader.uploadSingle(
      '1',
      '1',
      { descricao: 'Teste' },
      file
    );
    console.log('Sucesso:', result);
  } catch (error) {
    alert('Erro: ' + error.message);
  }
});

// Upload múltiplo
document.getElementById('multiUploadBtn').addEventListener('click', async () => {
  const fileInput = document.getElementById('multiFileInput');

  try {
    const result = await uploader.uploadMultiple(
      '1',
      '1',
      { descricao: 'Múltiplos ficheiros' },
      fileInput.files
    );
    console.log('Sucesso:', result);
  } catch (error) {
    alert('Erro: ' + error.message);
  }
});
```

---

## Tratamento de Erros

### Códigos de Erro Comuns

```javascript
const ERROR_CODES = {
  'INVALID_MIME_TYPE': 'Tipo de ficheiro não suportado',
  'INVALID_EXTENSION': 'Extensão não permitida',
  'LIMIT_FILE_SIZE': 'Ficheiro demasiado grande (máximo 5MB)',
  'LIMIT_FILE_COUNT': 'Demasiados ficheiros (máximo 5)',
  'INVALID_FILENAME': 'Nome de ficheiro inválido',
  'UPLOAD_ERROR': 'Erro ao fazer upload'
};

async function handleUploadError(response) {
  const data = await response.json();
  const errorMessage = ERROR_CODES[data.code] || data.error;
  
  console.error(`[${data.code}] ${errorMessage}`);
  
  return {
    success: false,
    code: data.code,
    message: errorMessage
  };
}
```

---

## Boas Práticas

### ✅ Fazer

```javascript
// Validar tamanho antes de enviar
if (file.size > 5 * 1024 * 1024) {
  alert('Ficheiro muito grande');
  return;
}

// Validar MIME type real
if (!['image/jpeg', 'image/png'].includes(file.type)) {
  alert('Tipo não suportado');
  return;
}

// Usar FormData para ficheiros
const formData = new FormData();
formData.append('files', file);

// Sempre usar HTTPS em produção
const apiUrl = process.env.API_URL || 'https://api.example.com';
```

### ❌ Não Fazer

```javascript
// ❌ Não confiar apenas na extensão
if (file.name.endsWith('.jpg')) { // INSEGURO!
  // ... upload
}

// ❌ Não confiar apenas no MIME type reportado pelo cliente
// Multer valida o MIME type real no servidor

// ❌ Não enviar ficheiros sem validação
fetch('/upload', {
  body: formData // Sem validar antes!
});

// ❌ Não usar HTTP em produção
const apiUrl = 'http://api.example.com'; // INSEGURO!
```

---

**Exemplos Práticos Completos** ✅  
**Data**: 22 de Abril de 2026
