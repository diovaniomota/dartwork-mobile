/// Model de Fornecedor — alinhado com a tabela `suppliers` real do Supabase.
class Supplier {
  final String id;
  final String organizationId;
  final String name;
  final String? document; // CNPJ ou CPF
  final String? contactName;
  final String? phone;
  final String? email;
  final String? address;
  final String? number;
  final String? complement;
  final String? neighborhood;
  final String? city;
  final String? state; // UF
  final String? zipCode; // CEP
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Supplier({
    required this.id,
    required this.organizationId,
    required this.name,
    this.document,
    this.contactName,
    this.phone,
    this.email,
    this.address,
    this.number,
    this.complement,
    this.neighborhood,
    this.city,
    this.state,
    this.zipCode,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) => Supplier(
    id: json['id']?.toString() ?? '',
    organizationId: json['organization_id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    document: json['document']?.toString(),
    contactName: json['contact_name']?.toString(),
    phone: json['phone']?.toString(),
    email: json['email']?.toString(),
    address: json['address']?.toString(),
    number: json['number']?.toString(),
    complement: json['complement']?.toString(),
    neighborhood: json['neighborhood']?.toString(),
    city: json['city']?.toString(),
    state: (json['state'] ?? json['uf'])?.toString(), // Compatibilidade com UF
    zipCode: (json['zip_code'] ?? json['cep'])?.toString(), // Compatibilidade
    notes: json['notes']?.toString(),
    createdAt: json['created_at'] != null
        ? DateTime.tryParse(json['created_at'].toString())
        : null,
    updatedAt: json['updated_at'] != null
        ? DateTime.tryParse(json['updated_at'].toString())
        : null,
  );

  Map<String, dynamic> toJson() => {
    'organization_id': organizationId,
    'name': name,
    'document': document,
    'contact_name': contactName,
    'phone': phone,
    'email': email,
    'address': address,
    'number': number,
    'complement': complement,
    'neighborhood': neighborhood,
    'city': city,
    'state': state,
    'zip_code': zipCode,
    'notes': notes,
  };
}
