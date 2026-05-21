class Transporter {
  final String id;
  final String organizationId;
  final String name; // Razão Social / Nome completo
  final String? document; // CNPJ ou CPF
  final String? stateRegistration; // Inscrição Estadual (IE)
  final String? phone;
  final String? email;
  final String? address;
  final String? number;
  final String? complement;
  final String? neighborhood;
  final String? city;
  final String? state; // UF
  final String? zipCode;
  final String? notes; // RNTRC ou outras observações

  const Transporter({
    required this.id,
    required this.organizationId,
    required this.name,
    this.document,
    this.stateRegistration,
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
  });

  factory Transporter.fromJson(Map<String, dynamic> json) => Transporter(
    id: json['id']?.toString() ?? '',
    organizationId: json['organization_id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    document: json['document']?.toString(),
    stateRegistration:
        json['state_registration']?.toString() ?? json['ie']?.toString(),
    phone: json['phone']?.toString(),
    email: json['email']?.toString(),
    address: json['address']?.toString(),
    number: json['number']?.toString(),
    complement: json['complement']?.toString(),
    neighborhood: json['neighborhood']?.toString(),
    city: json['city']?.toString(),
    state: json['state']?.toString() ?? json['uf']?.toString(),
    zipCode: json['zip_code']?.toString() ?? json['cep']?.toString(),
    notes: json['notes']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'organization_id': organizationId,
    'name': name,
    'document': document,
    'state_registration': stateRegistration,
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
