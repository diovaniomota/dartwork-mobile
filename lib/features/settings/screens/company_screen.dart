import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/organization_provider.dart';

class CompanyScreen extends ConsumerStatefulWidget {
  const CompanyScreen({super.key});

  @override
  ConsumerState<CompanyScreen> createState() => _CompanyScreenState();
}

class _CompanyScreenState extends ConsumerState<CompanyScreen> {
  final _nameCtrl = TextEditingController();
  final _cnpjCtrl = TextEditingController();
  final _ieCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  @override
  void initState() {
    super.initState();
    final org = ref.read(currentOrganizationProvider).value;
    if (org != null) {
      _nameCtrl.text = org.name;
      _cnpjCtrl.text = org.cnpj ?? '';
      _ieCtrl.text = org.raw['inscricao_estadual']?.toString() ?? '';
      _addressCtrl.text = org.raw['address']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cnpjCtrl.dispose();
    _ieCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Empresa'), leading: const BackButton()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Dados da Empresa',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Razão Social / Nome Fantasia',
                prefixIcon: Icon(Icons.business),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _cnpjCtrl,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'CNPJ',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ieCtrl,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Inscrição Estadual (Opcional)',
                prefixIcon: Icon(Icons.pin_outlined),
              ),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 32),
            const Text(
              'Endereço',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressCtrl,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Logradouro Completo',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
