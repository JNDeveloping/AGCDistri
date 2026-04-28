import 'package:flutter/material.dart';

class ReportsFilters {
  const ReportsFilters({
    required this.period,
    this.dateFrom,
    this.dateTo,
    this.zoneId,
    this.clientId,
    this.sellerId,
    this.category,
  });

  final String period;
  final String? dateFrom;
  final String? dateTo;
  final String? zoneId;
  final String? clientId;
  final String? sellerId;
  final String? category;

  ReportsFilters copyWith({
    String? period,
    String? dateFrom,
    String? dateTo,
    String? zoneId,
    String? clientId,
    String? sellerId,
    String? category,
    bool clearDates = false,
  }) =>
      ReportsFilters(
        period: period ?? this.period,
        dateFrom: clearDates ? null : (dateFrom ?? this.dateFrom),
        dateTo: clearDates ? null : (dateTo ?? this.dateTo),
        zoneId: zoneId ?? this.zoneId,
        clientId: clientId ?? this.clientId,
        sellerId: sellerId ?? this.sellerId,
        category: category ?? this.category,
      );

  Map<String, dynamic> toQuery() => {
        'period': period,
        if (dateFrom != null && dateFrom!.isNotEmpty) 'dateFrom': dateFrom,
        if (dateTo != null && dateTo!.isNotEmpty) 'dateTo': dateTo,
        if (zoneId != null && zoneId!.isNotEmpty) 'zoneId': zoneId,
        if (clientId != null && clientId!.isNotEmpty) 'clientId': clientId,
        if (sellerId != null && sellerId!.isNotEmpty) 'sellerId': sellerId,
        if (category != null && category!.isNotEmpty) 'category': category,
      };
}

class ReportsFilterBar extends StatefulWidget {
  const ReportsFilterBar({
    required this.filters,
    required this.onFiltersChanged,
    super.key,
  });

  final ReportsFilters filters;
  final ValueChanged<ReportsFilters> onFiltersChanged;

  @override
  State<ReportsFilterBar> createState() => _ReportsFilterBarState();
}

class _ReportsFilterBarState extends State<ReportsFilterBar> {
  late final TextEditingController _zoneIdCtrl;
  late final TextEditingController _clientIdCtrl;
  late final TextEditingController _sellerIdCtrl;
  late final TextEditingController _categoryCtrl;

  @override
  void initState() {
    super.initState();
    _zoneIdCtrl = TextEditingController(text: widget.filters.zoneId ?? '');
    _clientIdCtrl = TextEditingController(text: widget.filters.clientId ?? '');
    _sellerIdCtrl = TextEditingController(text: widget.filters.sellerId ?? '');
    _categoryCtrl = TextEditingController(text: widget.filters.category ?? '');
  }

  @override
  void dispose() {
    _zoneIdCtrl.dispose();
    _clientIdCtrl.dispose();
    _sellerIdCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filters = widget.filters;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in const [('today', 'Hoy'), ('week', 'Esta semana'), ('month', 'Este mes'), ('custom', 'Personalizado')])
                  ChoiceChip(
                    label: Text(p.$2),
                    selected: filters.period == p.$1,
                    onSelected: (_) => widget.onFiltersChanged(filters.copyWith(period: p.$1, clearDates: p.$1 != 'custom')),
                  ),
              ],
            ),
            if (filters.period == 'custom') ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDate(isFrom: true),
                      icon: const Icon(Icons.date_range_rounded),
                      label: Text(filters.dateFrom ?? 'Fecha desde'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDate(isFrom: false),
                      icon: const Icon(Icons.event_rounded),
                      label: Text(filters.dateTo ?? 'Fecha hasta'),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Filtros avanzados'),
              children: [
                TextField(
                  controller: _zoneIdCtrl,
                  decoration: const InputDecoration(labelText: 'Zona ID (UUID)', prefixIcon: Icon(Icons.route_rounded)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _clientIdCtrl,
                  decoration: const InputDecoration(labelText: 'Cliente ID (UUID)', prefixIcon: Icon(Icons.store_rounded)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _sellerIdCtrl,
                  decoration: const InputDecoration(labelText: 'Vendedor ID (UUID)', prefixIcon: Icon(Icons.person_rounded)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _categoryCtrl,
                  decoration: const InputDecoration(labelText: 'Categoría', prefixIcon: Icon(Icons.category_rounded)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: () => widget.onFiltersChanged(
                        filters.copyWith(
                          zoneId: _zoneIdCtrl.text.trim().isEmpty ? null : _zoneIdCtrl.text.trim(),
                          clientId: _clientIdCtrl.text.trim().isEmpty ? null : _clientIdCtrl.text.trim(),
                          sellerId: _sellerIdCtrl.text.trim().isEmpty ? null : _sellerIdCtrl.text.trim(),
                          category: _categoryCtrl.text.trim().isEmpty ? null : _categoryCtrl.text.trim(),
                        ),
                      ),
                      icon: const Icon(Icons.filter_alt_rounded),
                      label: const Text('Aplicar'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        _zoneIdCtrl.clear();
                        _clientIdCtrl.clear();
                        _sellerIdCtrl.clear();
                        _categoryCtrl.clear();
                        widget.onFiltersChanged(const ReportsFilters(period: 'month'));
                      },
                      child: const Text('Limpiar'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2100, 12, 31),
      initialDate: DateTime.now(),
    );
    if (picked == null) return;
    final value = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    if (isFrom) {
      widget.onFiltersChanged(widget.filters.copyWith(dateFrom: value));
      return;
    }
    widget.onFiltersChanged(widget.filters.copyWith(dateTo: value));
  }
}
