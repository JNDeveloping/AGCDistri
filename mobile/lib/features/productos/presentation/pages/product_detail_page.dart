import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../company_settings/presentation/cubit/company_settings_cubit.dart';
import '../../domain/models/product_model.dart';
import '../cubit/products_cubit.dart';
import 'barcode_scanner_page.dart';
import 'product_form_page.dart';
import '../../../stock/presentation/pages/stock_product_detail_page.dart';

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({required this.productId, super.key});

  final String productId;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late Future<ProductModel> _future;
  late Future<List<ProductVariantModel>> _variantsFuture;
  late Future<List<ProductActivePromotion>> _promotionsFuture;

  @override
  void initState() {
    super.initState();
    _future = context.read<ProductsCubit>().getById(widget.productId);
    _variantsFuture = context.read<ProductsCubit>().listVariants(widget.productId);
    _promotionsFuture = context.read<ProductsCubit>().getActivePromotions(widget.productId);
  }

  @override
  Widget build(BuildContext context) {
    final role = context.select((AuthCubit cubit) => cubit.state.session?.user.role ?? 'vendedor');
    final canEdit = role == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle producto'),
        actions: [
          if (canEdit)
            IconButton(
              onPressed: () async {
                final product = await _future;
                if (!mounted) return;
                final changed = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => ProductFormPage(product: product)),
                );
                if (changed == true && mounted) {
                  await _refreshAll();
                }
              },
              icon: const Icon(Icons.edit_rounded),
            ),
        ],
      ),
      body: FutureBuilder<ProductModel>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final p = snapshot.data!;
          final subtitleParts = [
            if ((p.internalCode ?? '').isNotEmpty) p.internalCode!,
            if ((p.brand ?? '').isNotEmpty) p.brand!,
            if ((p.categoryName ?? '').isNotEmpty) p.categoryName!,
          ];
          return RefreshIndicator(
            onRefresh: _refreshAll,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(p.name, style: Theme.of(context).textTheme.headlineSmall),
                if (subtitleParts.isNotEmpty) Text(subtitleParts.join(' · ')),
                const SizedBox(height: 12),
                if ((p.shortDescription ?? '').isNotEmpty) Text(p.shortDescription!),
                if (p.longDescription != null) Text(p.longDescription!),
                const Divider(height: 30),
                Text('Costo: ${(p.cost ?? 0).toStringAsFixed(2)}'),
                Text('Precio de venta: ${p.salePrice.toStringAsFixed(2)}'),
                Text('Margen: ${(p.marginPercentage ?? 0).toStringAsFixed(2)}%'),
                if ((p.barcode ?? '').isNotEmpty) Text('Código de barras: ${p.barcode}'),
                const Divider(height: 30),
                if (!p.hasVariants) ...[
                  Text('Stock actual: ${p.stockCurrent.toStringAsFixed(2)}'),
                  Text('Stock mínimo: ${p.stockMinimum.toStringAsFixed(2)}'),
                ] else ...[
                  const Text('Stock por variantes'),
                  Text(
                    'Este producto base no se vende directamente. El stock operativo se gestiona por cada variante.',
                  ),
                ],
                Text('Estado: ${p.isActive ? 'Activo' : 'Inactivo'}'),
                Text('Con variantes: ${p.hasVariants ? 'Sí' : 'No'}'),
                const SizedBox(height: 10),
                FilledButton.tonalIcon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => StockProductDetailPage(productId: p.id)),
                  ),
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: const Text('Ver historial de stock'),
                ),
                const SizedBox(height: 16),
                _PromotionsSection(promotionsFuture: _promotionsFuture),
                const SizedBox(height: 16),
                if (p.hasVariants)
                  _VariantsSection(
                    product: p,
                    variantsFuture: _variantsFuture,
                    canEdit: canEdit,
                    onAdd: () => _openVariantForm(p.id),
                    onEdit: (variant) => _openVariantForm(p.id, variant: variant),
                    onToggleActive: _setVariantActive,
                    onDelete: _deleteVariant,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _refreshAll() async {
    if (!mounted) return;
    setState(() {
      _future = context.read<ProductsCubit>().getById(widget.productId);
      _variantsFuture = context.read<ProductsCubit>().listVariants(widget.productId);
      _promotionsFuture = context.read<ProductsCubit>().getActivePromotions(widget.productId);
    });
    await context.read<ProductsCubit>().refreshAfterVariantMutation();
  }

  Future<void> _openVariantForm(String productId, {ProductVariantModel? variant}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _VariantFormSheet(
        productId: productId,
        variant: variant,
        onSave: (model, variantId) => context.read<ProductsCubit>().saveVariant(productId, model, variantId: variantId),
      ),
    );

    if (saved == true && mounted) {
      await _refreshAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(variant == null ? 'Variante creada con éxito.' : 'Variante actualizada con éxito.')),
      );
    }
  }

  Future<void> _setVariantActive(ProductVariantModel variant, bool active) async {
    await context.read<ProductsCubit>().setVariantActive(variant.id, active);
    if (!mounted) return;
    await _refreshAll();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(active ? 'Variante activada.' : 'Variante desactivada.')),
    );
  }

  Future<void> _deleteVariant(ProductVariantModel variant) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar variante'),
        content: Text('¿Querés eliminar la variante "${variant.name}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await context.read<ProductsCubit>().deleteVariant(variant.id);
      if (!mounted) return;
      await _refreshAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Variante eliminada.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

class _PromotionsSection extends StatelessWidget {
  const _PromotionsSection({required this.promotionsFuture});
  final Future<List<ProductActivePromotion>> promotionsFuture;
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ProductActivePromotion>>(
      future: promotionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final promos = snapshot.data ?? const [];
        if (promos.isEmpty) return const SizedBox.shrink();
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Promociones activas', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              ...promos.map((p) => ListTile(
                    dense: true,
                    title: Text(p.name),
                    subtitle: Text('${p.type} · ${p.scope == 'variant' ? 'Variante' : 'Producto'}'),
                    trailing: Text(
                      p.discountValue != null ? '${p.discountValue}${p.discountType == 'percentage' ? '%' : ''}' : (p.fixedPrice != null ? p.fixedPrice!.toStringAsFixed(2) : '-'),
                    ),
                  )),
            ]),
          ),
        );
      },
    );
  }
}

class _VariantsSection extends StatelessWidget {
  const _VariantsSection({
    required this.product,
    required this.variantsFuture,
    required this.canEdit,
    required this.onAdd,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
  });

  final ProductModel product;
  final Future<List<ProductVariantModel>> variantsFuture;
  final bool canEdit;
  final VoidCallback onAdd;
  final Future<void> Function(ProductVariantModel variant) onEdit;
  final Future<void> Function(ProductVariantModel variant, bool active) onToggleActive;
  final Future<void> Function(ProductVariantModel variant) onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Variantes',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ),
            if (canEdit)
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Agregar variante'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Gestioná precio, costo, stock y estado de cada variante de ${product.name}.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<ProductVariantModel>>(
          future: variantsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(12),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('No se pudieron cargar las variantes: ${snapshot.error}'),
                ),
              );
            }

            final variants = snapshot.data ?? [];
            if (variants.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    canEdit
                        ? 'Todavía no hay variantes. Tocá “Agregar variante” para crear la primera.'
                        : 'No hay variantes cargadas.',
                  ),
                ),
              );
            }

            return Column(
              children: variants
                  .map(
                    (v) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    v.name,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                  ),
                                ),
                                Chip(
                                  label: Text(v.active ? 'Activa' : 'Inactiva'),
                                  avatar: Icon(
                                    v.active ? Icons.check_circle_rounded : Icons.block_rounded,
                                    size: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _chip('Precio', (v.effectivePrice ?? 0).toStringAsFixed(2)),
                                _chip('Costo', (v.cost ?? 0).toStringAsFixed(2)),
                                _chip('Stock', (v.effectiveStock ?? 0).toStringAsFixed(2)),
                                if ((v.internalCode ?? '').isNotEmpty) _chip('Código', v.internalCode!),
                                if ((v.barcode ?? '').isNotEmpty) _chip('Barras', v.barcode!),
                              ],
                            ),
                            if (canEdit) ...[
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () => onEdit(v),
                                    icon: const Icon(Icons.edit_rounded),
                                    label: const Text('Editar'),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => onToggleActive(v, !v.active),
                                    icon: Icon(v.active ? Icons.block_rounded : Icons.check_circle_outline_rounded),
                                    label: Text(v.active ? 'Desactivar' : 'Activar'),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => onDelete(v),
                                    icon: const Icon(Icons.delete_outline_rounded),
                                    label: const Text('Eliminar'),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _chip(String label, String value) {
    return Chip(
      label: Text('$label: $value'),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _VariantFormSheet extends StatefulWidget {
  const _VariantFormSheet({required this.productId, required this.onSave, this.variant});

  final String productId;
  final ProductVariantModel? variant;
  final Future<void> Function(ProductVariantModel model, String? variantId) onSave;

  @override
  State<_VariantFormSheet> createState() => _VariantFormSheetState();
}

class _VariantFormSheetState extends State<_VariantFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _internalCode;
  late final TextEditingController _barcode;
  late final TextEditingController _cost;
  late final TextEditingController _price;
  late final TextEditingController _stock;

  bool _saving = false;
  bool _manualPrice = false;
  bool _costChangedAfterManual = false;

  @override
  void initState() {
    super.initState();
    final v = widget.variant;
    _name = TextEditingController(text: v?.name ?? '');
    _internalCode = TextEditingController(text: v?.internalCode ?? '');
    _barcode = TextEditingController(text: v?.barcode ?? '');
    _cost = TextEditingController(text: v?.cost?.toString() ?? '');
    _price = TextEditingController(text: v?.price?.toString() ?? '');
    _stock = TextEditingController(text: v?.stock?.toString() ?? '');

    _cost.addListener(_onCostChanged);
    if ((v?.price ?? 0) <= 0) {
      _applyCalculatedPrice();
    }
  }

  @override
  void dispose() {
    _cost.removeListener(_onCostChanged);
    _name.dispose();
    _internalCode.dispose();
    _barcode.dispose();
    _cost.dispose();
    _price.dispose();
    _stock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets.bottom;
    final settings = context.watch<CompanySettingsCubit>().state.settings;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 4, 16, insets + 16),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.variant == null ? 'Nueva variante' : 'Editar variante',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _textField(_name, 'Nombre *', requiredField: true),
              _textField(_internalCode, 'Código interno (opcional)'),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: _textField(_barcode, 'Código de barras (opcional)')),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: 'Escanear código',
                    onPressed: _scanBarcode,
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                  ),
                ],
              ),
              _textField(_cost, 'Costo (opcional)', number: true),
              _textField(
                _price,
                'Precio de venta (opcional)',
                number: true,
                onChanged: (_) {
                  _manualPrice = true;
                  setState(() => _costChangedAfterManual = false);
                },
              ),
              const SizedBox(height: 4),
              Text(
                _manualPrice
                    ? (_costChangedAfterManual
                        ? 'Precio modificado manualmente. El costo cambió, podés recalcular.'
                        : 'Precio modificado manualmente.')
                    : 'Calculado con ${settings.defaultProfitPercentage.toStringAsFixed(2)}% de ganancia y '
                        '${settings.priceRoundingEnabled ? 'redondeo a ${settings.priceRoundingMultiple}' : 'sin redondeo'}.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (_costChangedAfterManual)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _manualPrice = false;
                        _costChangedAfterManual = false;
                      });
                      _applyCalculatedPrice();
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Recalcular precio'),
                  ),
                ),
              _textField(_stock, 'Stock (opcional)', number: true),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      child: Text(_saving ? 'Guardando...' : 'Guardar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    bool number = false,
    bool requiredField = false,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: number ? const TextInputType.numberWithOptions(decimal: true) : null,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: requiredField
            ? (value) => (value == null || value.trim().isEmpty) ? 'Campo obligatorio' : null
            : null,
        onChanged: onChanged,
      ),
    );
  }

  void _onCostChanged() {
    if (!_manualPrice) {
      _applyCalculatedPrice();
      return;
    }
    setState(() => _costChangedAfterManual = true);
  }

  void _applyCalculatedPrice() {
    final cost = _parse(_cost.text);
    if (cost == null || cost <= 0) {
      if (!_manualPrice) _price.text = '';
      return;
    }

    final settings = context.read<CompanySettingsCubit>().state.settings;
    var calculated = cost + (cost * settings.defaultProfitPercentage / 100);
    if (settings.priceRoundingEnabled && settings.priceRoundingMultiple > 0) {
      final multiple = settings.priceRoundingMultiple.toDouble();
      calculated = (calculated / multiple).ceil() * multiple;
    }

    _price.text = calculated.toStringAsFixed(2);
  }

  Future<void> _scanBarcode() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerPage()),
    );
    if (!mounted || result == null || result.trim().isEmpty) return;

    setState(() => _barcode.text = result.trim());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Código escaneado: ${result.trim()}')),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final model = ProductVariantModel(
        id: widget.variant?.id ?? 'new',
        productId: widget.productId,
        name: _name.text.trim(),
        internalCode: _clean(_internalCode.text),
        barcode: _clean(_barcode.text),
        price: _parse(_price.text),
        cost: _parse(_cost.text),
        stock: _parse(_stock.text),
        active: widget.variant?.active ?? true,
      );

      await widget.onSave(model, widget.variant?.id);
      if (!mounted) return;
      Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _clean(String value) {
    final v = value.trim();
    return v.isEmpty ? null : v;
  }

  double? _parse(String value) {
    final raw = value.trim().replaceAll(',', '.');
    if (raw.isEmpty) return null;
    return double.tryParse(raw);
  }
}
