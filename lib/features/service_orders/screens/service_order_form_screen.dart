import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/vehicle.dart';
import '../../../data/models/service_order_photo.dart';
import '../../../data/repositories/service_order_repository.dart';
import '../../../data/repositories/vehicle_repository.dart';
import '../../../data/repositories/client_repository.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../../shared/widgets/client_picker.dart';
import '../../../shared/widgets/vehicle_picker.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/organization_provider.dart';
import '../../../shared/widgets/common_widgets.dart';
import 'dart:async';

enum _PhotoSource { camera, gallery }

/// Formulário de criação/edição de ordem de serviço.
class ServiceOrderFormScreen extends ConsumerStatefulWidget {
  final String? orderId;
  const ServiceOrderFormScreen({super.key, this.orderId});

  @override
  ConsumerState<ServiceOrderFormScreen> createState() =>
      _ServiceOrderFormScreenState();
}

class _ServiceOrderFormScreenState
    extends ConsumerState<ServiceOrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _isLoadingData = false;
  String _status = 'aberta';

  final _descCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _vehicleSearchCtrl = TextEditingController();
  final _clientSearchCtrl = TextEditingController();

  final _tecnicoCtrl = TextEditingController();
  final _dataPrevisaoCtrl = TextEditingController();
  final _diagnosticoCtrl = TextEditingController();

  String? _selectedClientId;

  String? _selectedVehicleId;
  List<ServiceOrderPhoto> _photos = [];
  bool _photosLoading = false;
  bool _photosUploading = false;
  String? _photosError;
  Timer? _debounce;
  final ImagePicker _imagePicker = ImagePicker();

  bool get isEditing => widget.orderId != null;
  bool get _isReadOnly =>
      isEditing && ['finalizada', 'cancelada'].contains(_status.toLowerCase());
  static const int _maxPhotoSizeBytes = 8 * 1024 * 1024;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _loadOrder();
      _loadPhotos();
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _notesCtrl.dispose();
    _vehicleSearchCtrl.dispose();
    _clientSearchCtrl.dispose();
    _tecnicoCtrl.dispose();
    _dataPrevisaoCtrl.dispose();
    _diagnosticoCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadOrder() async {
    setState(() => _isLoadingData = true);
    try {
      final repo = ref.read(serviceOrderRepositoryProvider);
      final os = await repo.getById(widget.orderId!);
      if (os != null && mounted) {
        var vehicleLabel = os.vehiclePlate ?? '';
        if (vehicleLabel.trim().isEmpty && os.vehicleId != null) {
          final vehicleRepo = ref.read(vehicleRepositoryProvider);
          final vehicle = await vehicleRepo.getById(os.vehicleId!);
          if (!mounted) return;
          vehicleLabel = vehicle?.plate ?? '';
        }

        _descCtrl.text = os.description ?? '';
        _notesCtrl.text = os.notes ?? '';
        _tecnicoCtrl.text = os.tecnicoResponsavel ?? '';
        _dataPrevisaoCtrl.text = os.dataPrevisao != null
            ? DateFormat('dd/MM/yyyy').format(os.dataPrevisao!)
            : '';
        _diagnosticoCtrl.text = os.diagnostico ?? '';
        _status = os.status;
        _selectedClientId = os.clientId;
        // clientName usado apenas para preencher o campo de busca
        _selectedVehicleId = os.vehicleId;
        _vehicleSearchCtrl.text = vehicleLabel;
        if (os.clientName != null) _clientSearchCtrl.text = os.clientName!;
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingData = false);
  }

  void _showVehiclePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VehiclePicker(
        clientId: _selectedClientId,
        onSelected: (vehicle) {
          _handleVehicleSelected(vehicle);
        },
      ),
    );
  }

  Future<void> _handleVehicleSelected(Vehicle vehicle) async {
    setState(() {
      _selectedVehicleId = vehicle.id;
      _vehicleSearchCtrl.text = vehicle.plate;
    });

    final vehicleClientId = vehicle.clientId;
    if (vehicleClientId == null || vehicleClientId.isEmpty) return;

    final clientRepo = ref.read(clientRepositoryProvider);
    final client = await clientRepo.getById(vehicleClientId);
    if (!mounted) return;

    if (client != null) {
      setState(() {
        _selectedClientId = client.id;
        _clientSearchCtrl.text = client.displayName;
      });
      return;
    }

    setState(() => _selectedClientId = vehicleClientId);
  }

  void _showClientPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ClientPicker(
        onSelected: (client) {
          setState(() {
            _selectedClientId = client.id;
            _clientSearchCtrl.text = client.displayName;
          });
        },
      ),
    );
  }

  String _formatBytes(int bytes) {
    final value = bytes < 0 ? 0 : bytes;
    if (value < 1024) return '$value B';
    if (value < 1024 * 1024) {
      return '${(value / 1024).toStringAsFixed(1)} KB';
    }
    if (value < 1024 * 1024 * 1024) {
      return '${(value / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(value / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String _guessImageContentType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.heif')) return 'image/heif';
    return 'application/octet-stream';
  }

  String _extractFileNameFromPath(String path) {
    final normalized = path.replaceAll('\\', '/');
    final parts = normalized.split('/');
    if (parts.isEmpty) return 'foto.jpg';
    final name = parts.last.trim();
    return name.isEmpty ? 'foto.jpg' : name;
  }

  String? _getUploadOrganizationIdOrNotify() {
    final orgId = ref.read(currentOrgIdProvider);
    if (orgId == null || orgId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Organização não identificada.')),
      );
      return null;
    }
    return orgId;
  }

  Future<void> _uploadRawPhotos({
    required String organizationId,
    required List<({String fileName, Uint8List bytes})> files,
  }) async {
    if (widget.orderId == null) return;
    if (files.isEmpty) return;

    setState(() {
      _photosUploading = true;
      _photosError = null;
    });

    try {
      final repo = ref.read(serviceOrderRepositoryProvider);

      for (final file in files) {
        if (file.bytes.isEmpty) {
          throw Exception('Arquivo inválido: ${file.fileName}');
        }

        if (file.bytes.lengthInBytes > _maxPhotoSizeBytes) {
          throw Exception(
            '"${file.fileName}" excede o limite de ${_formatBytes(_maxPhotoSizeBytes)}.',
          );
        }

        await repo.uploadPhoto(
          organizationId: organizationId,
          orderId: widget.orderId!,
          fileName: file.fileName,
          bytes: file.bytes,
          contentType: _guessImageContentType(file.fileName),
        );
      }

      if (!mounted) return;
      await _loadPhotos();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            files.length == 1
                ? 'Foto enviada com sucesso.'
                : '${files.length} fotos enviadas com sucesso.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      setState(() => _photosError = message);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao enviar foto: $message')));
    } finally {
      if (mounted) setState(() => _photosUploading = false);
    }
  }

  Future<void> _pickAndUploadFromGallery() async {
    if (!isEditing || widget.orderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Salve a OS primeiro para habilitar o envio de fotos.'),
        ),
      );
      return;
    }

    final orgId = _getUploadOrganizationIdOrNotify();
    if (orgId == null) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final files = result.files
        .where((f) => f.bytes != null && f.bytes!.isNotEmpty)
        .map((f) => (fileName: f.name, bytes: f.bytes!))
        .toList();

    if (!mounted) return;
    if (files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma imagem válida foi selecionada.')),
      );
      return;
    }

    await _uploadRawPhotos(organizationId: orgId, files: files);
  }

  Future<void> _captureAndUploadFromCamera() async {
    if (!isEditing || widget.orderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Salve a OS primeiro para habilitar o envio de fotos.'),
        ),
      );
      return;
    }

    final orgId = _getUploadOrganizationIdOrNotify();
    if (orgId == null) return;

    try {
      final captured = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 92,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (captured == null) return;

      final bytes = await captured.readAsBytes();
      final fileName = captured.name.isNotEmpty
          ? captured.name
          : _extractFileNameFromPath(captured.path);

      await _uploadRawPhotos(
        organizationId: orgId,
        files: [(fileName: fileName, bytes: bytes)],
      );
    } on MissingPluginException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Câmera indisponível. Reinicie o app para recarregar os plugins.',
          ),
        ),
      );
    } on PlatformException catch (e) {
      if (!mounted) return;
      final message = e.message ?? e.code;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível abrir a câmera: $message')),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível abrir a câmera: $message')),
      );
    }
  }

  Future<void> _handleAddPhoto() async {
    final source = await showModalBottomSheet<_PhotoSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Adicionar foto',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Abrir câmera'),
                subtitle: const Text('Tirar foto agora'),
                onTap: () => Navigator.of(context).pop(_PhotoSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Escolher da galeria'),
                subtitle: const Text('Selecionar uma ou mais imagens'),
                onTap: () => Navigator.of(context).pop(_PhotoSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (!mounted || source == null) return;
    if (source == _PhotoSource.camera) {
      await _captureAndUploadFromCamera();
    } else {
      await _pickAndUploadFromGallery();
    }
  }

  Future<void> _loadPhotos() async {
    if (!isEditing || widget.orderId == null) return;
    final orgId = ref.read(currentOrgIdProvider);
    if (orgId == null || orgId.isEmpty) return;

    setState(() {
      _photosLoading = true;
      _photosError = null;
    });

    try {
      final repo = ref.read(serviceOrderRepositoryProvider);
      final photos = await repo.getPhotos(
        organizationId: orgId,
        orderId: widget.orderId!,
      );
      if (!mounted) return;
      setState(() => _photos = photos);
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _photosError = 'Não foi possível carregar as fotos da OS.',
      );
    } finally {
      if (mounted) setState(() => _photosLoading = false);
    }
  }

  void _openPhotoPreview(ServiceOrderPhoto photo) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(
                photo.name,
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Flexible(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: photo.signedUrl != null
                    ? Image.network(
                        photo.signedUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('Não foi possível abrir a imagem.'),
                        ),
                      )
                    : const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Imagem indisponível no momento.'),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Text('Fotos da OS', style: Theme.of(context).textTheme.titleSmall),
            const Spacer(),
            IconButton(
              tooltip: 'Atualizar',
              onPressed: _photosLoading ? null : _loadPhotos,
              icon: const Icon(Icons.refresh),
            ),
            const SizedBox(width: 6),
            if (!_isReadOnly)
              ElevatedButton.icon(
                onPressed: _photosUploading ? null : _handleAddPhoto,
                icon: _photosUploading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_a_photo_outlined),
                label: Text(_photosUploading ? 'Enviando...' : 'Adicionar'),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Formatos aceitos: JPG, PNG, WEBP e HEIC. Máx. ${_formatBytes(_maxPhotoSizeBytes)} por imagem.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (_photosError != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.withAlpha(15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withAlpha(40)),
            ),
            child: Text(
              _photosError!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
        const SizedBox(height: 10),
        if (_photosLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: LoadingIndicator(message: 'Carregando fotos...'),
          )
        else if (_photos.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.withAlpha(70)),
            ),
            child: const Text('Nenhuma foto anexada nesta OS.'),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = width > 900 ? 5 : (width > 680 ? 4 : 3);
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _photos.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.86,
                ),
                itemBuilder: (context, index) {
                  final photo = _photos[index];
                  return Material(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(10),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _openPhotoPreview(photo),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: photo.signedUrl != null
                                ? Image.network(
                                    photo.signedUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Icon(
                                      Icons.broken_image_outlined,
                                      size: 26,
                                    ),
                                    loadingBuilder: (context, child, progress) {
                                      if (progress == null) return child;
                                      return const Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : const Icon(
                                    Icons.image_not_supported_outlined,
                                  ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 6,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  photo.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  _formatBytes(photo.sizeBytes),
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final orgId = ref.read(currentOrgIdProvider);
      if (orgId == null) {
        throw Exception('Organização não identificada.');
      }
      final repo = ref.read(serviceOrderRepositoryProvider);
      final profile = ref.read(userProfileProvider).value;
      final userId = supabase.auth.currentUser?.id ?? profile?.authId;
      final data = {
        'organization_id': orgId,
        'client_id': _selectedClientId,
        'vehicle_id': _selectedVehicleId,
        'descricao_problema': _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        'diagnostico': _diagnosticoCtrl.text.trim().isEmpty
            ? null
            : _diagnosticoCtrl.text.trim(),
        'observacoes': _notesCtrl.text.trim().isEmpty
            ? null
            : _notesCtrl.text.trim(),
        'tecnico_responsavel': _tecnicoCtrl.text.trim().isEmpty
            ? null
            : _tecnicoCtrl.text.trim(),
        'data_previsao': _dataPrevisaoCtrl.text.trim().isEmpty
            ? null
            : DateFormat(
                'dd/MM/yyyy',
              ).parse(_dataPrevisaoCtrl.text).toIso8601String(),
        'status': _status,
      };
      if (isEditing) {
        await repo.update(widget.orderId!, data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OS atualizada!')),
          );
          context.pop();
        }
      } else {
        if (userId == null || userId.isEmpty) {
          throw Exception('Usuário não autenticado.');
        }
        final newOrder = await repo.create({...data, 'user_id': userId});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OS criada! Adicione os itens.')),
          );
          // Navega para detalhes abrindo na aba Itens (índice 1)
          context.pushReplacement(
            '/ordens-servico/${newOrder.id}',
            extra: {'initialTab': 1},
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return Scaffold(
        appBar: AppBar(title: const Text('Carregando...')),
        body: const LoadingIndicator(),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar OS' : 'Nova OS'),
        actions: [
          if (!_isReadOnly)
            TextButton.icon(
              onPressed: _loading ? null : _save,
              icon: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: const Text('Salvar'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status
              if (isEditing) ...[
                Text('Status', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                if (_isReadOnly)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.withAlpha(50)),
                    ),
                    child: Text(
                      _status.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'aberta', label: Text('Aberta')),
                      ButtonSegment(
                        value: 'em_andamento',
                        label: Text('Andamento'),
                      ),
                      ButtonSegment(
                        value: 'finalizada',
                        label: Text('Finalizada'),
                      ),
                    ],
                    selected: {_status},
                    onSelectionChanged: (v) {
                      if (v.first == 'finalizada') {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Atenção: Finalizar OS'),
                            content: const Text(
                              'Acesse o sistema pelo computador para finalizar esta ordem de serviço e registrar o pagamento.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Entendi'),
                              ),
                            ],
                          ),
                        );
                        return;
                      }
                      setState(() => _status = v.first);
                    },
                  ),
                const SizedBox(height: 16),
              ],

              // Busca de veículo
              Text(
                'Placa do veículo',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _vehicleSearchCtrl,
                readOnly: true,
                onTap: _isReadOnly ? null : _showVehiclePicker,
                decoration: InputDecoration(
                  hintText: 'Selecionar placa...',
                  prefixIcon: const Icon(Icons.directions_car),
                  suffixIcon: (_selectedVehicleId != null && !_isReadOnly)
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() {
                            _selectedVehicleId = null;
                            _vehicleSearchCtrl.clear();
                          }),
                        )
                      : const Icon(Icons.arrow_drop_down),
                ),
              ),

              const SizedBox(height: 16),

              // Busca de cliente
              Text('Cliente', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              TextFormField(
                controller: _clientSearchCtrl,
                readOnly: true,
                onTap: _isReadOnly ? null : _showClientPicker,
                decoration: InputDecoration(
                  hintText: 'Selecionar cliente...',
                  prefixIcon: const Icon(Icons.person_search),
                  suffixIcon: (_selectedClientId != null && !_isReadOnly)
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() {
                            _selectedClientId = null;
                            _clientSearchCtrl.clear();
                            _selectedVehicleId = null;
                            _vehicleSearchCtrl.clear();
                          }),
                        )
                      : const Icon(Icons.arrow_drop_down),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _descCtrl,
                readOnly: _isReadOnly,
                decoration: const InputDecoration(
                  labelText: 'Descrição do problema / serviço',
                ),
                maxLines: 3,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 12),

              // Diagnóstico
              TextFormField(
                controller: _diagnosticoCtrl,
                readOnly: _isReadOnly,
                decoration: const InputDecoration(
                  labelText: 'Diagnóstico Técnico',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),

              // Tecnico / Previsao
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _tecnicoCtrl,
                      readOnly: _isReadOnly,
                      decoration: const InputDecoration(
                        labelText: 'Técnico Resp.',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _dataPrevisaoCtrl,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Prev. Entrega',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: _isReadOnly
                          ? null
                          : () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (date != null) {
                                setState(() {
                                  _dataPrevisaoCtrl.text = DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(date);
                                });
                              }
                            },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Observações
              TextFormField(
                controller: _notesCtrl,
                readOnly: _isReadOnly,
                decoration: const InputDecoration(labelText: 'Observações'),
                maxLines: 2,
              ),
              if (isEditing) ...[
                _buildPhotosSection(),
              ] else ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.withAlpha(70)),
                  ),
                  child: const Text(
                    'Fotos ficam disponíveis após salvar a OS. Abra a ordem novamente para anexar imagens.',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
