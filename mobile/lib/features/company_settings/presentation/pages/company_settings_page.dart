import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../domain/models/company_settings_model.dart';
import '../cubit/company_settings_cubit.dart';
import '../cubit/company_settings_state.dart';

class CompanySettingsPage extends StatefulWidget {
  const CompanySettingsPage({super.key});

  static const path = '/company-settings';
  static const name = 'company-settings';

  @override
  State<CompanySettingsPage> createState() => _CompanySettingsPageState();
}

class _CompanySettingsPageState extends State<CompanySettingsPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _companyName;
  late final TextEditingController _logoUrl;
  late final TextEditingController _primaryColor;
  late final TextEditingController _secondaryColor;
  late final TextEditingController _buttonColor;
  late final TextEditingController _backgroundColor;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _address;
  late final TextEditingController _city;
  late final TextEditingController _province;
  late final TextEditingController _taxId;
  late final TextEditingController _slogan;
  late final TextEditingController _profit;

  bool _roundingEnabled = true;
  int _roundingMultiple = 10;

  @override
  void initState() {
    super.initState();
    _companyName = TextEditingController();
    _logoUrl = TextEditingController();
    _primaryColor = TextEditingController();
    _secondaryColor = TextEditingController();
    _buttonColor = TextEditingController();
    _backgroundColor = TextEditingController();
    _phone = TextEditingController();
    _email = TextEditingController();
    _address = TextEditingController();
    _city = TextEditingController();
    _province = TextEditingController();
    _taxId = TextEditingController();
    _slogan = TextEditingController();
    _profit = TextEditingController();

    _syncFromModel(context.read<CompanySettingsCubit>().state.settings);
    context.read<CompanySettingsCubit>().load();
  }

  @override
  void dispose() {
    _companyName.dispose();
    _logoUrl.dispose();
    _primaryColor.dispose();
    _secondaryColor.dispose();
    _buttonColor.dispose();
    _backgroundColor.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    _city.dispose();
    _province.dispose();
    _taxId.dispose();
    _slogan.dispose();
    _profit.dispose();
    super.dispose();
  }

  void _syncFromModel(CompanySettingsModel settings) {
    _companyName.text = settings.companyName;
    _logoUrl.text = settings.logoUrl ?? '';
    _primaryColor.text = settings.primaryColor;
    _secondaryColor.text = settings.secondaryColor;
    _buttonColor.text = settings.buttonColor;
    _backgroundColor.text = settings.backgroundColor;
    _phone.text = settings.phone ?? '';
    _email.text = settings.email ?? '';
    _address.text = settings.address ?? '';
    _city.text = settings.city ?? '';
    _province.text = settings.province ?? '';
    _taxId.text = settings.taxId ?? '';
    _slogan.text = settings.slogan ?? '';
    _profit.text = settings.defaultProfitPercentage.toStringAsFixed(2);
    _roundingEnabled = settings.priceRoundingEnabled;
    _roundingMultiple = settings.priceRoundingMultiple;
  }

  @override
  Widget build(BuildContext context) {
    final role = context.select((AuthCubit cubit) => cubit.state.session?.user.role ?? 'vendedor');
    final isAdmin = role == 'admin';

    if (!isAdmin) {
      return const Scaffold(body: Center(child: Text('No autorizado')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración de Empresa')),
      body: BlocConsumer<CompanySettingsCubit, CompanySettingsState>(
        listenWhen: (prev, curr) {
          final enteredSuccess = prev.status != CompanySettingsStatus.success && curr.status == CompanySettingsStatus.success;
          final settingsChanged = prev.settings != curr.settings && curr.status == CompanySettingsStatus.success;
          return enteredSuccess || settingsChanged;
        },
        listener: (_, state) => _syncFromModel(state.settings),
        builder: (context, state) {
          if (state.status == CompanySettingsStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionCard('Empresa', [
                    _field(_companyName, 'Nombre de empresa'),
                    _field(_logoUrl, 'Logo URL', requiredField: false),
                    _field(_phone, 'Teléfono', requiredField: false),
                    _field(_email, 'Email', requiredField: false),
                    _field(_address, 'Dirección', requiredField: false),
                    _field(_city, 'Localidad', requiredField: false),
                    _field(_province, 'Provincia', requiredField: false),
                    _field(_taxId, 'CUIT', requiredField: false),
                    _field(_slogan, 'Slogan', requiredField: false),
                  ]),
                  _sectionCard('Apariencia', [
                    _field(_primaryColor, 'Color principal (#RRGGBB)', requiredField: false),
                    _field(_secondaryColor, 'Color secundario (#RRGGBB)', requiredField: false),
                    _field(_buttonColor, 'Color de botones (#RRGGBB)', requiredField: false),
                    _field(_backgroundColor, 'Color de fondo (#RRGGBB)', requiredField: false),
                    const SizedBox(height: 8),
                    _preview(),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await context.read<CompanySettingsCubit>().resetDefaults();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Colores restaurados por defecto.')),
                          );
                        }
                      },
                      icon: const Icon(Icons.restore),
                      label: const Text('Restaurar colores por defecto'),
                    ),
                  ]),
                  _sectionCard('Comercial', [
                    _field(_profit, 'Porcentaje de ganancia', number: true),
                    SwitchListTile(
                      value: _roundingEnabled,
                      onChanged: (value) => setState(() => _roundingEnabled = value),
                      title: const Text('Redondeo automático'),
                    ),
                    DropdownButtonFormField<int>(
                      value: _roundingMultiple,
                      decoration: const InputDecoration(labelText: 'Múltiplo de redondeo'),
                      items: const [10, 50, 100]
                          .map((value) => DropdownMenuItem(value: value, child: Text(value.toString())))
                          .toList(),
                      onChanged: _roundingEnabled ? (value) => setState(() => _roundingMultiple = value ?? 10) : null,
                    ),
                    const SizedBox(height: 8),
                    Text('Ejemplo costo 922 → sugerido ${_examplePrice().toStringAsFixed(0)}'),
                  ]),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: state.status == CompanySettingsStatus.saving ? null : _save,
                    child: Text(state.status == CompanySettingsStatus.saving ? 'Guardando...' : 'Guardar cambios'),
                  ),
                  if (state.status == CompanySettingsStatus.failure && state.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(state.errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sectionCard(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 10), ...children]),
      ),
    );
  }

  Widget _preview() {
    final bg = _safeColor(_backgroundColor.text, CompanySettingsModel.defaults.backgroundColor);
    final primary = _safeColor(_primaryColor.text, CompanySettingsModel.defaults.primaryColor);
    final button = _safeColor(_buttonColor.text, CompanySettingsModel.defaults.buttonColor);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Vista previa', style: TextStyle(color: primary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: button, foregroundColor: Colors.white),
          onPressed: () {},
          child: const Text('Botón ejemplo'),
        ),
      ]),
    );
  }

  Widget _field(TextEditingController controller, String label, {bool number = false, bool requiredField = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: number ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        decoration: InputDecoration(labelText: label),
        validator: (value) {
          final text = value?.trim() ?? '';
          if (requiredField && text.isEmpty) return 'Campo obligatorio';
          if (number && text.isNotEmpty && double.tryParse(text) == null) return 'Número inválido';
          return null;
        },
      ),
    );
  }

  double _examplePrice() {
    const cost = 922.0;
    final margin = double.tryParse(_profit.text.trim()) ?? 0;
    final raw = cost + (cost * margin / 100);
    if (!_roundingEnabled) return raw;
    return (raw / _roundingMultiple).ceil() * _roundingMultiple.toDouble();
  }

  Color _safeColor(String value, String fallback) {
    final hex = RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(value) ? value : fallback;
    return CompanySettingsModel.parseColor(hex);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final isHex = RegExp(r'^#[0-9A-Fa-f]{6}$');
    final current = context.read<CompanySettingsCubit>().state.settings;
    final primaryColor = _primaryColor.text.trim().isEmpty ? current.primaryColor : _primaryColor.text.trim();
    final secondaryColor = _secondaryColor.text.trim().isEmpty ? current.secondaryColor : _secondaryColor.text.trim();
    final buttonColor = _buttonColor.text.trim().isEmpty ? current.buttonColor : _buttonColor.text.trim();
    final backgroundColor = _backgroundColor.text.trim().isEmpty ? current.backgroundColor : _backgroundColor.text.trim();

    if (!isHex.hasMatch(primaryColor)
        || !isHex.hasMatch(secondaryColor)
        || !isHex.hasMatch(buttonColor)
        || !isHex.hasMatch(backgroundColor)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresá colores HEX válidos (#RRGGBB).')));
      return;
    }

    final model = CompanySettingsModel(
      companyName: _companyName.text.trim(),
      logoUrl: _logoUrl.text.trim().isEmpty ? null : _logoUrl.text.trim(),
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
      buttonColor: buttonColor,
      backgroundColor: backgroundColor,
      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      email: _email.text.trim().isEmpty ? null : _email.text.trim(),
      address: _address.text.trim().isEmpty ? null : _address.text.trim(),
      city: _city.text.trim().isEmpty ? null : _city.text.trim(),
      province: _province.text.trim().isEmpty ? null : _province.text.trim(),
      taxId: _taxId.text.trim().isEmpty ? null : _taxId.text.trim(),
      slogan: _slogan.text.trim().isEmpty ? null : _slogan.text.trim(),
      defaultProfitPercentage: double.tryParse(_profit.text.trim()) ?? 0,
      priceRoundingEnabled: _roundingEnabled,
      priceRoundingMultiple: _roundingMultiple,
    );

    try {
      await context.read<CompanySettingsCubit>().save(model);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configuración guardada con éxito.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo guardar la configuración.')));
      }
    }
  }
}
