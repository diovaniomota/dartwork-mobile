import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/company_settings.dart';

class NonFiscalReceiptItem {
  final String description;
  final double quantity;
  final double unitPrice;
  final double total;

  const NonFiscalReceiptItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });
}

class NonFiscalReceiptDialog extends StatelessWidget {
  final String saleId;
  final CompanySettings company;
  final List<NonFiscalReceiptItem> items;
  final double total;
  final String paymentMethod;
  final String? pdfUrl;

  const NonFiscalReceiptDialog({
    super.key,
    required this.saleId,
    required this.company,
    required this.items,
    required this.total,
    required this.paymentMethod,
    this.pdfUrl,
  });

  @override
  Widget build(BuildContext context) {
    // Definindo estilo monospace para simular impressora térmica
    const TextStyle receiptStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: 10,
      color: Colors.black,
      height: 1.2,
    );
    const TextStyle boldStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: 10,
      fontWeight: FontWeight.bold,
      color: Colors.black,
      height: 1.2,
    );

    final String companyName =
        (company.nomeFantasia?.isNotEmpty == true
                ? company.nomeFantasia
                : company.razaoSocial)
            ?.toUpperCase() ??
        'EMPRESA';
    final String city = company.cidade?.toUpperCase() ?? 'CIDADE';
    final formatter = DateFormat('dd/MM/yyyy HH:mm:ss');
    final now = formatter.format(DateTime.now());

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent, // Evitar tint do Material 3
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Container(
        padding: const EdgeInsets.all(16),
        width: 300, // Largura aproximada de 80mm
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Container rolável para o recibo caso fique muito longo
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // --- CABEÇALHO ---
                    Text(
                      '$companyName - $city',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(now, style: receiptStyle),
                    if (company.logradouro != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${company.logradouro}, ${company.numero}${company.bairro != null ? ' - ${company.bairro}' : ''}, ${company.cidade}/${company.uf}',
                        style: receiptStyle,
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (company.cnpj != null) ...[
                      const SizedBox(height: 4),
                      Text('CNPJ: ${company.cnpj}', style: receiptStyle),
                    ],

                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: Colors.black,
                            style: BorderStyle.solid,
                          ),
                          bottom: BorderSide(
                            color: Colors.black,
                            style: BorderStyle.solid,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Cupom Gerencial : $saleId',
                            style: boldStyle.copyWith(fontSize: 11),
                          ),
                          const Text(
                            '(Nao e valido como cupom fiscal)',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 9,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // --- COLUNAS DOS ITENS ---
                    Row(
                      children: [
                        const SizedBox(
                          width: 24,
                          child: Text('#', style: receiptStyle),
                        ),
                        const Expanded(
                          child: Text('DESC', style: receiptStyle),
                        ),
                        const SizedBox(
                          width: 30,
                          child: Text(
                            'QTD',
                            style: receiptStyle,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(
                          width: 20,
                          child: Text(
                            'UN',
                            style: receiptStyle,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(
                          width: 45,
                          child: Text(
                            'VL UN',
                            style: receiptStyle,
                            textAlign: TextAlign.right,
                          ),
                        ),
                        const SizedBox(
                          width: 45,
                          child: Text(
                            'TOTAL',
                            style: receiptStyle,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.black, thickness: 1, height: 8),

                    // --- LISTA DE ITENS ---
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final numString = (index + 1).toString().padLeft(
                          3,
                          '0',
                        );
                        final name = item.description.length > 15
                            ? item.description.substring(0, 15)
                            : item.description;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 24,
                                child: Text(numString, style: receiptStyle),
                              ),
                              Expanded(
                                child: Text(
                                  name,
                                  style: receiptStyle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(
                                width: 30,
                                child: Text(
                                  item.quantity.toStringAsFixed(1),
                                  style: receiptStyle,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(
                                width: 20,
                                child: Text(
                                  'UN',
                                  style: receiptStyle,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              SizedBox(
                                width: 45,
                                child: Text(
                                  item.unitPrice.toStringAsFixed(2),
                                  style: receiptStyle,
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              SizedBox(
                                width: 45,
                                child: Text(
                                  item.total.toStringAsFixed(2),
                                  style: receiptStyle,
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),

                    // --- TOTAIS ---
                    Container(
                      padding: const EdgeInsets.only(top: 4),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: Colors.black,
                            style: BorderStyle.solid,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total itens', style: receiptStyle),
                              Text('${items.length}', style: receiptStyle),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('TOTAL R\$', style: boldStyle),
                              Text(total.toStringAsFixed(2), style: boldStyle),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(paymentMethod, style: receiptStyle),
                              Text(
                                total.toStringAsFixed(2),
                                style: receiptStyle,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),
                    // --- RODAPÉ ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(top: 4),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: Colors.black,
                            style: BorderStyle.solid,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'POS vrs.2.1.0',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 8,
                                  color: Colors.black54,
                                ),
                              ),
                              const Text(
                                'POS:1',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 8,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Operador: $companyName',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 8,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // --- BOTÕES DE AÇÃO ---
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (pdfUrl != null && pdfUrl!.isNotEmpty) ...[
                  ElevatedButton.icon(
                    onPressed: () async {
                      final uri = Uri.parse(
                        pdfUrl!.startsWith('http')
                            ? pdfUrl!
                            : 'https://$pdfUrl',
                      );
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Erro ao abrir comprovante'),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.receipt, size: 18),
                    label: const Text('Comprovante DANFE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                    ); // Fechar dialog para iniciar nova venda
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Nova Venda'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
