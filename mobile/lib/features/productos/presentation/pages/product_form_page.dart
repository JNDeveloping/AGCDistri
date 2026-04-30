import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../company_settings/presentation/cubit/company_settings_cubit.dart';
import '../../../company_settings/presentation/cubit/company_settings_state.dart';
import '../../domain/models/product_model.dart';
import '../cubit/products_cubit.dart';
import 'barcode_scanner_page.dart';

class ProductFormPage extends StatefulWidget {
  const ProductFormPage({this.product, super.key});

  final ProductModel? product;

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool _manualSalePrice = false;
  bool _costChangedAfterManual = false;

  late final TextEditingController _code;
  late final TextEditingController _name;
  late final TextEditingController _shortDescription;
  late final TextEditingController _brand;
  late final TextEditingController _barcode;
  late final TextEditingController _cost;
  late final TextEditingController _salePrice;
  late final TextEditingController _stock;
  late final TextEditingController _stockMin;

  String? _selectedUnitMeasure;
  String? _selectedCategoryId;
  List<ProductCategory> _categories = [];
  bool _hasVariants = false;

  static const _unitOptions = [
    'Unidad',
    'Pack',
    'Caja',
    'Bulto',
    'Kilogramo',
    'Gramo',
    'Litro',
    'Mililitro',
    'Metro',
    'Centímetro',
    'Docena',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _code = TextEditingController(text: p?.internalCode ?? '');
    _name = TextEditingController(text: p?.name ?? '');
    _shortDescription = TextEditingController(text: p?.shortDescription ?? '');
    _brand = TextEditingController(text: p?.brand ?? '');
    _barcode = TextEditingController(text: p?.barcode ?? '');
    _cost = TextEditingController(text: (p?.cost ?? 0).toStringAsFixed(2));
    _salePrice = TextEditingController(text: p == null ? '0.00' : p.salePrice.toStringAsFixed(2));
    _stock = TextEditingController(text: p?.stockCurrent.toStringAsFixed(2) ?? '0');
    _stockMin = TextEditingController(text: p?.stockMinimum.toStringAsFixed(2) ?? '0');
    _selectedUnitMeasure = p?.unitMeasure;
    _selectedCategoryId = p?.categoryId;
    _manualSalePrice = false;
    _hasVariants = p?.hasVariants ?? false;
    _cost.addListener(_onCostChanged);
    _applyCalculatedSalePrice();
    _loadCategories();
  }

  @override
  void dispose() {
    _cost.removeListener(_onCostChanged);
    _code.dispose();
    _name.dispose();
    _shortDescription.dispose();
    _brand.dispose();
    _barcode.dispose();
    _cost.dispose();
    _salePrice.dispose();
    _stock.dispose();
    _stockMin.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final categories = await context.read<ProductsCubit>().listCategories();
    if (mounted) {
      setState(() {
        _categories = categories.where((c) => c.isActive || c.id == _selectedCategoryId).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CompanySettingsCubit, CompanySettingsState>(
      listener: (_, __) {
        if (!_manualSalePrice) {
          _applyCalculatedSalePrice();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(widget.product == null ? 'Nuevo producto' : 'Editar producto')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
              _field(_name, 'Nombre', requiredField: true),
              _field(
                _salePrice,
                'Precio de venta',
                number: true,
                requiredField: !_hasVariants,
                enabled: !_hasVariants,
                onChanged: (_) {
                  _manualSalePrice = true;
                  setState(() => _costChangedAfterManual = false);
                },
              ),
              if (!_hasVariants)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _manualSalePrice
                          ? (_costChangedAfterManual
                              ? 'Precio modificado manualmente. Costo cambió, podés recalcular.'
                              : 'Precio modificado manualmente.')
                          : 'Calculado con ${context.read<CompanySettingsCubit>().state.settings.defaultProfitPercentage.toStringAsFixed(2)}% de ganancia y '
                              '${context.read<CompanySettingsCubit>().state.settings.priceRoundingEnabled ? 'redondeo a ${context.read<CompanySettingsCubit>().state.settings.priceRoundingMultiple}' : 'sin redondeo'}.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              if (!_hasVariants && _costChangedAfterManual)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _manualSalePrice = false;
                        _costChangedAfterManual = false;
                      });
                      _applyCalculatedSalePrice();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Recalcular precio de venta'),
                  ),
                ),
              _field(_code, 'Código interno', requiredField: false),
              _field(_shortDescription, 'Descripción corta', requiredField: false),
              _field(_brand, 'Marca', requiredField: false),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      value: _selectedCategoryId,
                      decoration: const InputDecoration(labelText: 'Categoría'),
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('Sin categoría')),
                        ..._categories.map((c) => DropdownMenuItem<String?>(value: c.id, child: Text(c.name))),
                      ],
                      onChanged: (value) => setState(() => _selectedCategoryId = value),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _quickCreateCategory,
                    child: const Text('Crear categoría'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _unitOptions.contains(_selectedUnitMeasure) ? _selectedUnitMeasure : null,
                decoration: const InputDecoration(labelText: 'Unidad de medida'),
                items: _unitOptions.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                onChanged: (value) => setState(() => _selectedUnitMeasure = value),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _field(_barcode, 'Código de barras', requiredField: false, enabled: !_hasVariants)),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: _hasVariants ? null : _scanBarcode,
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                  ),
                ],
              ),
              _field(_cost, 'Costo', number: true, requiredField: false, enabled: !_hasVariants),
              if (!_hasVariants) ...[
                _field(_stock, 'Stock actual', number: true, requiredField: false, enabled: true),
                _field(_stockMin, 'Stock mínimo', number: true, requiredField: false, enabled: true),
              ],
              SwitchListTile(
                value: _hasVariants,
                title: const Text('Este producto tiene variantes'),
                onChanged: (value) => setState(() => _hasVariants = value),
              ),
              if (_hasVariants)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Este producto se vende por variantes. El precio, stock y códigos se configuran en cada variante.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Guardando...' : 'Guardar producto')),
            ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool number = false,
    bool requiredField = false,
    bool enabled = true,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: number ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        decoration: InputDecoration(labelText: label),
        onChanged: onChanged,
        validator: (value) {
          final text = value?.trim() ?? '';
          if (requiredField && text.isEmpty) return 'Campo obligatorio';
          if (number && text.isNotEmpty && double.tryParse(text) == null) return 'Número inválido';
          return null;
        },
      ),
    );
  }

  void _onCostChanged() {
    if (_manualSalePrice) {
      setState(() => _costChangedAfterManual = true);
      return;
    }
    _applyCalculatedSalePrice();
  }

  double _suggestedSalePrice() {
    final cost = _toDouble(_cost.text);
    return context.read<CompanySettingsCubit>().suggestedWholesalePrice(cost);
  }

  double _toDouble(String value) => double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;

  void _applyCalculatedSalePrice() {
    final calculated = _suggestedSalePrice().toStringAsFixed(2);
    if (_salePrice.text != calculated) {
      _salePrice.text = calculated;
    }
  }

  Future<void> _scanBarcode() async {
    try {
      final result = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const BarcodeScannerPage()));
      if (result != null && result.isNotEmpty && mounted) {
        setState(() => _barcode.text = result);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Código escaneado correctamente.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo escanear el código.')));
      }
    }
  }

  Future<void> _quickCreateCategory() async {
    final controller = TextEditingController();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: controller, decoration: const InputDecoration(labelText: 'Nombre de categoría')),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                await context.read<ProductsCubit>().saveCategory(name: controller.text.trim());
                if (mounted) Navigator.pop(context, true);
              },
              child: const Text('Crear categoría'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) {
      await _loadCategories();
      if (_categories.isNotEmpty) {
        final created = _categories.firstWhere(
          (c) => c.name.toLowerCase() == controller.text.trim().toLowerCase(),
          orElse: () => _categories.first,
        );
        setState(() => _selectedCategoryId = created.id);
      }
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final model = ProductModel(
      id: widget.product?.id ?? 'new',
      internalCode: _code.text.trim().isEmpty ? null : _code.text.trim(),
      name: _name.text.trim(),
      shortDescription: _shortDescription.text.trim().isEmpty ? null : _shortDescription.text.trim(),
      longDescription: null,
      brand: _brand.text.trim().isEmpty ? null : _brand.text.trim(),
      categoryId: _selectedCategoryId,
      categoryName: _categories.where((c) => c.id == _selectedCategoryId).map((e) => e.name).firstOrNull,
      barcode: _barcode.text.trim().isEmpty ? null : _barcode.text.trim(),
      unitMeasure: _selectedUnitMeasure,
      cost: _cost.text.trim().isEmpty ? null : _toDouble(_cost.text),
      salePrice: _hasVariants ? 0 : _toDouble(_salePrice.text),
      marginPercentage: null,
      stockCurrent: _hasVariants ? 0 : _toDouble(_stock.text),
      stockMinimum: _hasVariants ? 0 : _toDouble(_stockMin.text),
      isActive: widget.product?.isActive ?? true,
      isFeatured: widget.product?.isFeatured ?? false,
      imageUrl: null,
      taxRate: null,
      notes: widget.product?.notes,
      createdAt: widget.product?.createdAt,
      updatedAt: widget.product?.updatedAt,
      lowStock: false,
      hasVariants: _hasVariants,
    );

    try {
      await context.read<ProductsCubit>().save(model, id: widget.product?.id);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
