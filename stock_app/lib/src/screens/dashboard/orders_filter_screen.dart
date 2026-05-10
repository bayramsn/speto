import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_colors.dart';

class OrdersFilterResult {
  const OrdersFilterResult({
    required this.dateFilter,
    required this.paymentFilter,
    required this.statusFilter,
  });

  final String dateFilter;
  final String paymentFilter;
  final String statusFilter;
}

class OrdersFilterScreen extends StatefulWidget {
  const OrdersFilterScreen({
    super.key,
    this.initialDate = 'Tümü',
    this.initialPayment = 'Tümü',
    this.initialStatus = 'Tümü',
  });

  final String initialDate;
  final String initialPayment;
  final String initialStatus;

  @override
  State<OrdersFilterScreen> createState() => _OrdersFilterScreenState();
}

class _OrdersFilterScreenState extends State<OrdersFilterScreen> {
  static const List<String> _dateOptions = <String>[
    'Bugün',
    'Dün',
    'Son 7 Gün',
    'Son 30 Gün',
    'Son 3 Ay',
    'Son 1 Yıl',
    'Tümü',
  ];

  static const List<String> _paymentOptions = <String>[
    'Tümü',
    'Kredi Kartı',
    'Sodexo',
  ];

  static const List<String> _statusOptions = <String>[
    'Tümü',
    'Yeni',
    'Hazırlanıyor',
    'Hazır',
    'Tamamlandı',
    'İptal',
  ];

  late String _selectedDate;
  late String _selectedPayment;
  late String _selectedStatus;
  bool _isDateExpanded = true;

  @override
  void initState() {
    super.initState();
    _selectedDate = _dateOptions.contains(widget.initialDate)
        ? widget.initialDate
        : 'Tümü';
    _selectedPayment = _paymentOptions.contains(widget.initialPayment)
        ? widget.initialPayment
        : 'Tümü';
    _selectedStatus = _statusOptions.contains(widget.initialStatus)
        ? widget.initialStatus
        : 'Tümü';
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 30,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const SizedBox(width: 24),
                  Text(
                    'Filtrele',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                      color: const Color(0xFF27AE60),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(999),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close_rounded,
                        size: 24,
                        color: AppColors.slate400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                children: <Widget>[
                  _FilterSectionTitle(label: 'Tarih'),
                  const SizedBox(height: 12),
                  _DateAccordion(
                    selectedDate: _selectedDate,
                    isExpanded: _isDateExpanded,
                    onHeaderTap: () {
                      setState(() {
                        _isDateExpanded = !_isDateExpanded;
                      });
                    },
                    onDateSelected: (String value) {
                      setState(() {
                        _selectedDate = value;
                      });
                    },
                    options: _dateOptions,
                  ),
                  const SizedBox(height: 32),
                  _FilterSectionTitle(label: 'Ödeme Tipi'),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.slate100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: _paymentOptions
                          .map(
                            (String option) => Expanded(
                              child: _PaymentSegment(
                                label: option,
                                selected: _selectedPayment == option,
                                onTap: () {
                                  setState(() {
                                    _selectedPayment = option;
                                  });
                                },
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _FilterSectionTitle(label: 'Durum'),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.slate100),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: <Widget>[
                        for (
                          int index = 0;
                          index < _statusOptions.length;
                          index += 1
                        )
                          DecoratedBox(
                            decoration: BoxDecoration(
                              border: index == _statusOptions.length - 1
                                  ? null
                                  : const Border(
                                      bottom: BorderSide(
                                        color: AppColors.slate100,
                                      ),
                                    ),
                            ),
                            child: _StatusTile(
                              label: _statusOptions[index],
                              selected:
                                  _selectedStatus == _statusOptions[index],
                              onTap: () {
                                setState(() {
                                  _selectedStatus = _statusOptions[index];
                                });
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.slate100)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 25, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop(
                      OrdersFilterResult(
                        dateFilter: _selectedDate,
                        paymentFilter: _selectedPayment,
                        statusFilter: _selectedStatus,
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFF0FDF4),
                    foregroundColor: const Color(0xFF27AE60),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Sonuçları Göster',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterSectionTitle extends StatelessWidget {
  const _FilterSectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.5,
        color: AppColors.inkStrong,
      ),
    );
  }
}

class _DateAccordion extends StatelessWidget {
  const _DateAccordion({
    required this.selectedDate,
    required this.isExpanded,
    required this.onHeaderTap,
    required this.onDateSelected,
    required this.options,
  });

  final String selectedDate;
  final bool isExpanded;
  final VoidCallback onHeaderTap;
  final ValueChanged<String> onDateSelected;
  final List<String> options;

  @override
  Widget build(BuildContext context) {
    final List<String> subOptions = options
        .where((String option) => option != selectedDate)
        .toList(growable: false);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.slate100),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: <Widget>[
          InkWell(
            onTap: onHeaderTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const _SelectionCircle(selected: true),
                      const SizedBox(width: 12),
                      Text(
                        selectedDate,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                          color: AppColors.slate700,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.slate400,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              decoration: const BoxDecoration(
                color: Color(0x80F8FAFC),
                border: Border(top: BorderSide(color: AppColors.slate100)),
              ),
              child: Column(
                children: <Widget>[
                  for (int index = 0; index < subOptions.length; index += 1)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        border: index == 0
                            ? null
                            : const Border(
                                top: BorderSide(color: AppColors.slate100),
                              ),
                      ),
                      child: InkWell(
                        onTap: () => onDateSelected(subOptions[index]),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(48, 16, 16, 16),
                          child: Row(
                            children: <Widget>[
                              const _SelectionCircle(selected: false),
                              const SizedBox(width: 12),
                              Text(
                                subOptions[index],
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  height: 1.43,
                                  color: AppColors.slate700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PaymentSegment extends StatelessWidget {
  const _PaymentSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: selected
              ? <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (selected) ...<Widget>[
              const Icon(
                Icons.check_rounded,
                size: 16,
                color: Color(0xFF27AE60),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                height: 1.43,
                color: selected ? const Color(0xFF27AE60) : AppColors.slate500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              children: <Widget>[
                _SelectionCircle(selected: selected),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                    color: AppColors.slate700,
                  ),
                ),
              ],
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.slate400,
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionCircle extends StatelessWidget {
  const _SelectionCircle({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.success : AppColors.slate300,
          width: 2,
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? AppColors.success : Colors.transparent,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
