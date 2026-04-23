import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  late final TextEditingController _vat;
  late final TextEditingController _creditLimit;
  late final TextEditingController _currentBalance;
  late final TextEditingController _lat;
  late final TextEditingController _lng;

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
    _vat = TextEditingController(text: c?.vatCondition ?? 'Responsable Inscripto');
    _creditLimit = TextEditingController(text: (c?.creditLimit ?? 0).toStringAsFixed(2));
    _currentBalance = TextEditingController(text: (c?.currentBalance ?? 0).toStringAsFixed(2));
    _lat = TextEditingController(text: c?.latitude?.toString() ?? '');
    _lng = TextEditingController(text: c?.longitude?.toString() ?? '');
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
      _vat,
      _creditLimit,
      _currentBalance,
      _lat,
      _lng,
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
              _field(_vat, 'Condición IVA', requiredField: true),
              _field(_creditLimit, 'Límite de crédito', isNumber: true, requiredField: true),
              _field(_currentBalance, 'Saldo actual', isNumber: true, requiredField: true),
              _field(_lat, 'Latitud', isNumber: true),
              _field(_lng, 'Longitud', isNumber: true),
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
          if (requiredField && text.isEmpty) {
            return 'Campo obligatorio';
          }
          if (isEmail && text.isNotEmpty && !text.contains('@')) {
            return 'Email inválido';
          }
          if (isNumber && text.isNotEmpty && double.tryParse(text) == null) {
            return 'Valor numérico inválido';
          }
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
      vatCondition: _vat.text.trim(),
      creditLimit: double.parse(_creditLimit.text.trim()),
      currentBalance: double.parse(_currentBalance.text.trim()),
      latitude: _lat.text.trim().isEmpty ? null : double.parse(_lat.text.trim()),
      longitude: _lng.text.trim().isEmpty ? null : double.parse(_lng.text.trim()),
      isActive: widget.client?.isActive ?? true,
      createdAt: widget.client?.createdAt,
    );

    try {
      await context.read<ClientsCubit>().saveClient(payload: payload, id: widget.client?.id);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}
