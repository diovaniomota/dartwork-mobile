class ServiceOrderPhoto {
  final String name;
  final String path;
  final String? signedUrl;
  final int sizeBytes;
  final DateTime? updatedAt;

  const ServiceOrderPhoto({
    required this.name,
    required this.path,
    this.signedUrl,
    this.sizeBytes = 0,
    this.updatedAt,
  });
}
