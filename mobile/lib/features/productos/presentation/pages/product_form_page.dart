import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../company_settings/presentation/cubit/company_settings_cubit.dart';
import '../../domain/models/product_model.dart';
import '../cubit/products_cubit.dart';

class ProductFormPage extends StatefulWidget {
  const ProductFormPage({this.product, super.key});

  final ProductModel? product;

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late final TextEditingController _code;
  late final TextEditingController _name;
  late final TextEditingController _shortDescription;
  late final TextEditingController _brand;
  late final TextEditingController _categoryName;
  late final TextEditingController _presentation;
  late final TextEditingController _unit;
  late final TextEditingController _cost;
  late final TextEditingController _wholesale;
  late final TextEditingController _retail;
  late final TextEditingController _stock;
  late final TextEditingController _stockMin;
  bool _manualWholesale = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _code = TextEditingController(text: p?.internalCode ?? '');
    _name = TextEditingController(text: p?.name ?? '');
    _shortDescription = TextEditingController(text: p?.shortDescription ?? '');
    _brand = TextEditingController(text: p?.brand ?? '');
    _categoryName = TextEditingController(text: p?.categoryName ?? '');
    _presentation = TextEditingController(text: p?.presentation ?? '');
    _unit = TextEditingController(text: p?.unitMeasure ?? 'unidad');
    _cost = TextEditingController(text: (p?.cost ?? 0).toStringAsFixed(2));
    _wholesale = TextEditingController(text: (p?.wholesalePrice ?? 0).toStringAsFixed(2));
    _retail = TextEditingController(text: (p?.retailPrice ?? 0).toStringAsFixed(2));
    _stock = TextEditingController(text: p?.stockCurrent.toStringAsFixed(2) ?? '0');
    _stockMin = TextEditingController(text: p?.stockMinimum.toStringAsFixed(2) ?? '0');
    _manualWholesale = widget.product != null;
    _cost.addListener(_onCostChanged);
    if (widget.product == null) {
      _wholesale.text = _suggestedWholesale().toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _cost.removeListener(_onCostChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.product == null ? 'Nuevo producto' : 'Editar producto')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _field(_code, 'Código interno'),
              _field(_name, 'Nombre'),
              _field(_shortDescription, 'Descripción corta'),
              _field(_brand, 'Marca'),
              _field(_categoryName, 'Categoría', requiredField: false),
              _field(_presentation, 'Presentación'),
              _field(_unit, 'Unidad de medida'),
              _field(_cost, 'Costo', number: true),
              _field(
                _wholesale,
                'Precio mayorista sugerido',
                number: true,
                onChanged: (_) => _manualWholesale = true,
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Sugerido: ${_suggestedWholesale().toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
              _field(_retail, 'Precio minorista', number: true, requiredField: false),
              _field(_stock, 'Stock actual', number: true),
              _field(_stockMin, 'Stock mínimo', number: true),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Guardando...' : 'Guardar producto'),
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
    bool number = false,
    bool requiredField = true,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
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
    if (_manualWholesale) return;
    _wholesale.text = _suggestedWholesale().toStringAsFixed(2);
  }

  double _suggestedWholesale() {
    final cost = double.tryParse(_cost.text.trim()) ?? 0;
    return context.read<CompanySettingsCubit>().suggestedWholesalePrice(cost);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final model = ProductModel(
      id: widget.product?.id ?? 'new',
      internalCode: _code.text.trim(),
      name: _name.text.trim(),
      shortDescription: _shortDescription.text.trim(),
      longDescription: null,
      brand: _brand.text.trim(),
      categoryId: widget.product?.categoryId,
      categoryName: _categoryName.text.trim().isEmpty ? null : _categoryName.text.trim(),
      barcode: null,
      unitMeasure: _unit.text.trim(),
      presentation: _presentation.text.trim(),
      cost: double.tryParse(_cost.text.trim()) ?? 0,
      wholesalePrice: double.tryParse(_wholesale.text.trim()) ?? 0,
      retailPrice: double.tryParse(_retail.text.trim()) ?? 0,
      marginPercentage: null,
      stockCurrent: double.tryParse(_stock.text.trim()) ?? 0,
      stockMinimum: double.tryParse(_stockMin.text.trim()) ?? 0,
      isActive: widget.product?.isActive ?? true,
      isFeatured: widget.product?.isFeatured ?? false,
      imageUrl: null,
      taxRate: 21,
      notes: widget.product?.notes,
      createdAt: widget.product?.createdAt,
      updatedAt: widget.product?.updatedAt,
      lowStock: false,
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
