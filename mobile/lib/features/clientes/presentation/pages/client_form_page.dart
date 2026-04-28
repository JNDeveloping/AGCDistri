import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/repositories/client_repository.dart';
import '../../domain/constants/arg_locations.dart';
import '../../domain/models/client_model.dart';
import '../cubit/clients_cubit.dart';

class ClientFormPage extends StatefulWidget {
  const ClientFormPage({this.client, super.key});

  final ClientModel? client;

  @override
  State<ClientFormPage> createState() => _ClientFormPageState();
}

class _ClientFormPageState extends State<ClientFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool _loadingLocation = false;
  bool _loadingZones = false;
  String _selectedVat = 'Responsable Inscripto';
  String? _selectedProvince;
  String? _selectedLocality;
  String? _selectedZoneId;
  List<ClientZone> _zones = const [];
  double? _latitude;
  double? _longitude;

  late final TextEditingController _internalCode;
  late final TextEditingController _businessName;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _taxId;
  late final TextEditingController _address;
  late final TextEditingController _notes;
  late final TextEditingController _creditLimit;
  late final TextEditingController _currentBalance;

  @override
  void initState() {
    super.initState();
    final c = widget.client;
    _internalCode = TextEditingController(text: c?.internalCode ?? '');
    _businessName = TextEditingController(text: c?.businessName ?? '');
    _phone = TextEditingController(text: c?.phone ?? '');
    _email = TextEditingController(text: c?.email ?? '');
    _taxId = TextEditingController(text: c?.taxId ?? '');
    _address = TextEditingController(text: c?.addressLine ?? '');
    _selectedProvince = c?.province;
    _selectedLocality = c?.city;
    _selectedZoneId = c?.zoneId;
    _notes = TextEditingController(text: c?.notes ?? '');
    _selectedVat = c?.vatCondition ?? 'Responsable Inscripto';
    _creditLimit = TextEditingController(text: (c?.creditLimit ?? 0).toStringAsFixed(2));
    _currentBalance = TextEditingController(text: (c?.currentBalance ?? 0).toStringAsFixed(2));
    _latitude = c?.latitude;
    _longitude = c?.longitude;
    _loadZones();
  }

  @override
  void dispose() {
    for (final controller in [
      _internalCode,
      _businessName,
      _phone,
      _email,
      _taxId,
      _address,
      _notes,
      _creditLimit,
      _currentBalance,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.client == null ? 'Nuevo cliente' : 'Editar cliente')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _field(_internalCode, 'Código interno', requiredField: true),
              _field(_businessName, 'Razón social / Nombre comercial', requiredField: true),
              _field(_phone, 'Teléfono', requiredField: true),
              _field(_email, 'Email', isEmail: true),
              _field(_taxId, 'CUIT / Identificación fiscal'),
              _field(_address, 'Dirección', requiredField: true),
              DropdownButtonFormField<String>(
                value: argProvinces.contains(_selectedProvince) ? _selectedProvince : null,
                decoration: const InputDecoration(labelText: 'Provincia'),
                items: argProvinces.map((province) => DropdownMenuItem(value: province, child: Text(province))).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedProvince = value;
                    _selectedLocality = null;
                  });
                },
                validator: (value) => value == null || value.isEmpty ? 'Seleccioná una provincia' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: (_selectedProvince != null && (argProvinceLocalities[_selectedProvince] ?? []).contains(_selectedLocality))
                    ? _selectedLocality
                    : null,
                decoration: const InputDecoration(labelText: 'Localidad'),
                items: (argProvinceLocalities[_selectedProvince] ?? [])
                    .map((locality) => DropdownMenuItem(value: locality, child: Text(locality)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedLocality = value),
                validator: (value) => value == null || value.isEmpty ? 'Seleccioná una localidad' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _zones.where((z) => z.id == _selectedZoneId).isNotEmpty ? _selectedZoneId : null,
                      decoration: InputDecoration(
                        labelText: 'Zona / Ruta',
                        suffixIcon: _loadingZones ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        ) : null,
                      ),
                      items: _zones
                          .where((zone) => zone.isActive || zone.id == _selectedZoneId)
                          .map((zone) => DropdownMenuItem(value: zone.id, child: Text(zone.name)))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedZoneId = value),
                    ),
                  ),
                ],
              ),
              DropdownButtonFormField<String>(
                value: _selectedVat,
                decoration: const InputDecoration(labelText: 'Condición IVA'),
                items: const [
                  DropdownMenuItem(value: 'Responsable Inscripto', child: Text('Responsable Inscripto')),
                  DropdownMenuItem(value: 'Monotributista', child: Text('Monotributista')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedVat = value);
                  }
                },
                validator: (value) => value == null || value.isEmpty ? 'Seleccioná una condición de IVA' : null,
              ),
              const SizedBox(height: 12),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined),
                          const SizedBox(width: 8),
                          Text(
                            _latitude != null && _longitude != null ? 'Ubicación guardada' : 'Ubicación no guardada',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_latitude != null && _longitude != null) ...[
                        Text('Latitud: ${_latitude!.toStringAsFixed(6)}'),
                        Text('Longitud: ${_longitude!.toStringAsFixed(6)}'),
                        const SizedBox(height: 8),
                      ],
                      if (_loadingLocation) ...[
                        const LinearProgressIndicator(),
                        const SizedBox(height: 8),
                      ],
                      FilledButton.icon(
                        onPressed: _loadingLocation ? null : _saveLocation,
                        icon: const Icon(Icons.my_location_rounded),
                        label: Text(
                          _loadingLocation
                              ? 'Obteniendo ubicación...'
                              : (_latitude == null || _longitude == null ? 'Guardar ubicación' : 'Actualizar ubicación'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _field(_creditLimit, 'Límite de crédito', isNumber: true, requiredField: true),
              _field(_currentBalance, 'Saldo actual', isNumber: true, requiredField: true),
              _field(_notes, 'Observaciones', maxLines: 3),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: Text(_saving ? 'Guardando...' : 'Guardar cliente'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveLocation() async {
    setState(() => _loadingLocation = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('GPS apagado. Activá la ubicación del dispositivo.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw Exception('Permiso de ubicación denegado.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ubicación guardada correctamente')));
      }
    } catch (error) {
      if (mounted) {
        final message = error.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message.contains('denegado')
                  ? 'Permiso de ubicación denegado.'
                  : message.contains('GPS apagado')
                      ? 'GPS apagado. Activá la ubicación del dispositivo.'
                      : 'No se pudo obtener ubicación.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool requiredField = false,
    bool isEmail = false,
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        decoration: InputDecoration(labelText: label),
        validator: (value) {
          final text = value?.trim() ?? '';
          if (requiredField && text.isEmpty) return 'Campo obligatorio';
          if (isEmail && text.isNotEmpty && !text.contains('@')) return 'Email inválido';
          if (isNumber && text.isNotEmpty && double.tryParse(text) == null) return 'Número inválido';
          return null;
        },
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _saving = true);

    final payload = ClientModel(
      id: widget.client?.id ?? 'new',
      internalCode: _internalCode.text.trim(),
      businessName: _businessName.text.trim(),
      phone: _phone.text.trim(),
      email: _email.text.trim().isEmpty ? null : _email.text.trim(),
      taxId: _taxId.text.trim().isEmpty ? null : _taxId.text.trim(),
      addressLine: _address.text.trim(),
      province: _selectedProvince ?? '',
      city: _selectedLocality ?? '',
      routeZone: _zones.where((z) => z.id == _selectedZoneId).map((z) => z.name).firstOrNull ?? 'Sin zona',
      zoneId: _selectedZoneId,
      zoneName: _zones.where((z) => z.id == _selectedZoneId).map((z) => z.name).firstOrNull,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      vatCondition: _selectedVat,
      creditLimit: double.parse(_creditLimit.text.trim()),
      currentBalance: double.parse(_currentBalance.text.trim()),
      latitude: _latitude,
      longitude: _longitude,
      isActive: widget.client?.isActive ?? true,
      createdAt: widget.client?.createdAt,
    );

    try {
      await context.read<ClientsCubit>().saveClient(payload: payload, id: widget.client?.id);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _loadZones() async {
    setState(() => _loadingZones = true);
    try {
      final zones = await context.read<ClientsCubit>().listZones(includeInactive: true);
      if (mounted) {
        setState(() => _zones = zones);
      }
    } finally {
      if (mounted) setState(() => _loadingZones = false);
    }
  }

}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
