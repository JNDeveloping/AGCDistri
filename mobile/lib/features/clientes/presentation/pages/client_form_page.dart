import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

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
  String _selectedVat = 'Responsable Inscripto';
  double? _latitude;
  double? _longitude;

  late final TextEditingController _internalCode;
  late final TextEditingController _businessName;
  late final TextEditingController _contactName;
  late final TextEditingController _phone;
  late final TextEditingController _alternatePhone;
  late final TextEditingController _email;
  late final TextEditingController _taxId;
  late final TextEditingController _address;
  late final TextEditingController _city;
  late final TextEditingController _province;
  late final TextEditingController _routeZone;
  late final TextEditingController _notes;
  late final TextEditingController _creditLimit;
  late final TextEditingController _currentBalance;

  @override
  void initState() {
    super.initState();
    final c = widget.client;
    _internalCode = TextEditingController(text: c?.internalCode ?? '');
    _businessName = TextEditingController(text: c?.businessName ?? '');
    _contactName = TextEditingController(text: c?.contactName ?? '');
    _phone = TextEditingController(text: c?.phone ?? '');
    _alternatePhone = TextEditingController(text: c?.alternatePhone ?? '');
    _email = TextEditingController(text: c?.email ?? '');
    _taxId = TextEditingController(text: c?.taxId ?? '');
    _address = TextEditingController(text: c?.addressLine ?? '');
    _city = TextEditingController(text: c?.city ?? '');
    _province = TextEditingController(text: c?.province ?? '');
    _routeZone = TextEditingController(text: c?.routeZone ?? '');
    _notes = TextEditingController(text: c?.notes ?? '');
    _selectedVat = c?.vatCondition ?? 'Responsable Inscripto';
    _creditLimit = TextEditingController(text: (c?.creditLimit ?? 0).toStringAsFixed(2));
    _currentBalance = TextEditingController(text: (c?.currentBalance ?? 0).toStringAsFixed(2));
    _latitude = c?.latitude;
    _longitude = c?.longitude;
  }

  @override
  void dispose() {
    for (final controller in [
      _internalCode,
      _businessName,
      _contactName,
      _phone,
      _alternatePhone,
      _email,
      _taxId,
      _address,
      _city,
      _province,
      _routeZone,
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
              _field(_contactName, 'Contacto', requiredField: true),
              _field(_phone, 'Teléfono', requiredField: true),
              _field(_alternatePhone, 'Teléfono alternativo'),
              _field(_email, 'Email', isEmail: true),
              _field(_taxId, 'CUIT / Identificación fiscal'),
              _field(_address, 'Dirección', requiredField: true),
              _field(_city, 'Localidad', requiredField: true),
              _field(_province, 'Provincia', requiredField: true),
              _field(_routeZone, 'Zona / Ruta', requiredField: true),
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _latitude == null || _longitude == null
                          ? 'Ubicación no guardada'
                          : 'Ubicación: ${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _loadingLocation ? null : _saveLocation,
                    icon: const Icon(Icons.my_location_rounded),
                    label: Text(_loadingLocation ? 'Obteniendo...' : 'Guardar ubicación'),
                  ),
                ],
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
        throw Exception('GPS desactivado. Activá el servicio de ubicación.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw Exception('Permiso de ubicación denegado.');
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ubicación guardada correctamente.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
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
      contactName: _contactName.text.trim(),
      phone: _phone.text.trim(),
      alternatePhone: _alternatePhone.text.trim().isEmpty ? null : _alternatePhone.text.trim(),
      email: _email.text.trim().isEmpty ? null : _email.text.trim(),
      taxId: _taxId.text.trim().isEmpty ? null : _taxId.text.trim(),
      addressLine: _address.text.trim(),
      city: _city.text.trim(),
      province: _province.text.trim(),
      routeZone: _routeZone.text.trim(),
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
}
