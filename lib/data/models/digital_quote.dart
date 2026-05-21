class DigitalQuote {
  final String id;
  final String? organizationId;
  final int? quoteNumber;
  final String status;
  final String? title;
  final String? description;
  final String? clientName;
  final String? clientPhone;
  final String? clientDocument;
  final double totalValue;
  final String? approvalToken;
  final String approvalStatus;
  final DateTime? approvalRequestedAt;
  final DateTime? approvalRespondedAt;
  final String? approvalResponse;
  final String? approvalContactName;
  final String? approvalContactDocument;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DigitalQuote({
    required this.id,
    this.organizationId,
    this.quoteNumber,
    this.status = 'rascunho',
    this.title,
    this.description,
    this.clientName,
    this.clientPhone,
    this.clientDocument,
    this.totalValue = 0.0,
    this.approvalToken,
    this.approvalStatus = 'nao_solicitado',
    this.approvalRequestedAt,
    this.approvalRespondedAt,
    this.approvalResponse,
    this.approvalContactName,
    this.approvalContactDocument,
    this.createdAt,
    this.updatedAt,
  });

  factory DigitalQuote.fromJson(Map<String, dynamic> json) {
    return DigitalQuote(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String?,
      quoteNumber: json['quote_number'] as int?,
      status: json['status'] as String? ?? 'rascunho',
      title: json['title'] as String?,
      description: json['description'] as String?,
      clientName: json['client_name'] as String?,
      clientPhone: json['client_phone'] as String?,
      clientDocument: json['client_document'] as String?,
      totalValue: (json['total_value'] as num?)?.toDouble() ?? 0.0,
      approvalToken: json['approval_token'] as String?,
      approvalStatus: json['approval_status'] as String? ?? 'nao_solicitado',
      approvalRequestedAt: json['approval_requested_at'] != null
          ? DateTime.tryParse(json['approval_requested_at'] as String)
          : null,
      approvalRespondedAt: json['approval_responded_at'] != null
          ? DateTime.tryParse(json['approval_responded_at'] as String)
          : null,
      approvalResponse: json['approval_response'] as String?,
      approvalContactName: json['approval_contact_name'] as String?,
      approvalContactDocument: json['approval_contact_document'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (organizationId != null) 'organization_id': organizationId,
      if (quoteNumber != null) 'quote_number': quoteNumber,
      'status': status,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (clientName != null) 'client_name': clientName,
      if (clientPhone != null) 'client_phone': clientPhone,
      if (clientDocument != null) 'client_document': clientDocument,
      'total_value': totalValue,
      if (approvalToken != null) 'approval_token': approvalToken,
      'approval_status': approvalStatus,
      if (approvalRequestedAt != null)
        'approval_requested_at': approvalRequestedAt!.toIso8601String(),
      if (approvalRespondedAt != null)
        'approval_responded_at': approvalRespondedAt!.toIso8601String(),
      if (approvalResponse != null) 'approval_response': approvalResponse,
      if (approvalContactName != null)
        'approval_contact_name': approvalContactName,
      if (approvalContactDocument != null)
        'approval_contact_document': approvalContactDocument,
    };
  }
}
