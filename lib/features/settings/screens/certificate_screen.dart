import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/organization_provider.dart';

class CertificateScreen extends ConsumerStatefulWidget {
  const CertificateScreen({super.key});

  @override
  ConsumerState<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends ConsumerState<CertificateScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _certInfo;
  PlatformFile? _certFile;
  final _passwordCtrl = TextEditingController();

  String get _cnpj {
    final org = ref.read(currentOrganizationProvider).value;
    return org?.cnpj ?? '';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkCertificate();
    });
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final session = Supabase.instance.client.auth.currentSession;
    return session?.accessToken;
  }

  Future<void> _checkCertificate() async {
    final cnpj = _cnpj.replaceAll(RegExp(r'\D'), '');
    if (cnpj.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final token = await _getToken();
      final uri = Uri.parse(
        '${AppConstants.webAppUrl}/api/fiscal/certificado?cnpj=$cnpj',
      );
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['tem_certificado'] == true) {
          setState(() => _certInfo = data);
        } else {
          setState(() => _certInfo = null);
        }
      }
    } catch (e) {
      debugPrint('Error checking certificate: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pfx', 'p12'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() => _certFile = result.files.first);
    }
  }

  Future<void> _uploadCertificate() async {
    if (_certFile == null || _certFile!.bytes == null) {
      _showSnackbar('Selecione um arquivo de certificado.', isError: true);
      return;
    }
    if (_passwordCtrl.text.isEmpty) {
      _showSnackbar('Digite a senha do certificado.', isError: true);
      return;
    }

    final cnpj = _cnpj.replaceAll(RegExp(r'\D'), '');
    if (cnpj.isEmpty) {
      _showSnackbar('O CNPJ da empresa não foi encontrado.', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final token = await _getToken();
      final base64Content = base64Encode(_certFile!.bytes!);

      final uri = Uri.parse('${AppConstants.webAppUrl}/api/fiscal/certificado');
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'cnpj': cnpj,
          'fileBase64': base64Content,
          'password': _passwordCtrl.text,
        }),
      );

      final result = json.decode(response.body);

      if (response.statusCode == 200 && result['success'] == true) {
        _showSnackbar('Certificado instalado com sucesso na Focus NFe.');
        setState(() {
          _certFile = null;
          _passwordCtrl.clear();
        });
        await _checkCertificate();
      } else {
        _showSnackbar(result['error'] ?? 'Erro no envio.', isError: true);
      }
    } catch (e) {
      _showSnackbar(
        'Ocorreu um erro ao processar o certificado.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Certificado Digital A1')),
      body: _isLoading && _certInfo == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_certInfo != null &&
                      _certInfo!['tem_certificado'] == true) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.success.withAlpha(25),
                        border: Border.all(
                          color: AppColors.success.withAlpha(50),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.success,
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Certificado Ativo',
                                  style: TextStyle(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Validade: ${_certInfo!['validade']?.split('T')[0] ?? 'N/A'}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                Text(
                                  'CNPJ Vinculado: ${_certInfo!['cnpj_certificado'] ?? _cnpj}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() => _certInfo = null);
                            },
                            child: const Text('Substituir'),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    InkWell(
                      onTap: _pickFile,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _certFile != null
                                ? AppColors.primary
                                : Colors.grey.shade300,
                            style: BorderStyle.solid,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: _certFile != null
                              ? AppColors.primary.withAlpha(15)
                              : Colors.transparent,
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.security,
                              size: 48,
                              color: _certFile != null
                                  ? AppColors.primary
                                  : Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            if (_certFile != null) ...[
                              Text(
                                _certFile!.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${(_certFile!.size / 1024).toStringAsFixed(2)} KB',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ] else ...[
                              const Text(
                                'Selecione o arquivo do certificado (.pfx ou .p12)',
                                style: TextStyle(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Aperte para escolher',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  Opacity(
                    opacity:
                        _certInfo != null &&
                            _certInfo!['tem_certificado'] == true
                        ? 0.6
                        : 1.0,
                    child: IgnorePointer(
                      ignoring:
                          _certInfo != null &&
                          _certInfo!['tem_certificado'] == true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _passwordCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Senha do Certificado',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.lock),
                            ),
                            obscureText: true,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed:
                                _isLoading ||
                                    _certFile == null ||
                                    _passwordCtrl.text.isEmpty
                                ? null
                                : _uploadCertificate,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.upload),
                            label: Text(
                              _isLoading ? 'Enviando...' : 'Enviar Certificado',
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Importante: O certificado digital A1 é necessário para emissão de NFe. '
                      'Certifique-se de que o certificado está válido e dentro do prazo de validade. '
                      'O certificado será enviado de forma segura para a API de emissão.',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
