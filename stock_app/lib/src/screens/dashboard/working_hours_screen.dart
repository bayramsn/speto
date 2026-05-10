import 'package:flutter/material.dart';

import '../../app/stock_app_controller.dart';
import '../../app/stock_app_scope.dart';
import '../../theme/app_colors.dart';

class WorkingHoursScreen extends StatefulWidget {
  const WorkingHoursScreen({super.key});

  @override
  State<WorkingHoursScreen> createState() => _WorkingHoursScreenState();
}

class _WorkingHoursScreenState extends State<WorkingHoursScreen> {
  bool _initialized = false;
  late List<StockWorkingDay> _workingDays;
  late List<_SpecialDayEntry> _specialDays;
  late bool _temporarilyClosed;
  int _selectedDayIndex = 4;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    final StockAppController controller = StockAppScope.of(context);
    final vendor = controller.selectedVendor;
    _workingDays = _resolveWorkingDays(controller);
    _selectedDayIndex = _resolveInitialSelection(_workingDays);
    _temporarilyClosed = !(vendor?.isActive ?? true);
    _specialDays = <_SpecialDayEntry>[
      _SpecialDayEntry(
        title: '29 Ekim Cumhuriyet Bayramı',
        date: DateTime(2024, 10, 29),
        isOpen: true,
        openTime: '09:00',
        closeTime: '18:00',
      ),
      _SpecialDayEntry(
        title: 'Yılbaşı Tatili',
        date: DateTime(2025, 1, 1),
        isOpen: false,
      ),
    ];
    _initialized = true;
  }

  List<StockWorkingDay> _resolveWorkingDays(StockAppController controller) {
    final vendor = controller.selectedVendor;
    if (vendor?.workingDays.isNotEmpty == true) {
      return vendor!.workingDays
          .map(
            (day) => StockWorkingDay(
              label: day.label,
              shortLabel: day.shortLabel.isEmpty
                  ? _fallbackShortLabel(day.label)
                  : day.shortLabel,
              isOpen: day.isOpen,
              openTime: day.openTime,
              closeTime: day.closeTime,
            ),
          )
          .toList(growable: false);
    }
    if (controller.registrationDraft.workingDays.isNotEmpty) {
      return controller.registrationDraft.workingDays
          .map((StockWorkingDay day) => day.copy())
          .toList(growable: false);
    }
    return <StockWorkingDay>[
      StockWorkingDay(
        label: 'Pazartesi',
        shortLabel: 'Pzt',
        isOpen: true,
        openTime: '09:00',
        closeTime: '23:00',
      ),
      StockWorkingDay(
        label: 'Salı',
        shortLabel: 'Sal',
        isOpen: true,
        openTime: '09:00',
        closeTime: '23:00',
      ),
      StockWorkingDay(
        label: 'Çarşamba',
        shortLabel: 'Çar',
        isOpen: true,
        openTime: '09:00',
        closeTime: '23:00',
      ),
      StockWorkingDay(
        label: 'Perşembe',
        shortLabel: 'Per',
        isOpen: true,
        openTime: '09:00',
        closeTime: '23:00',
      ),
      StockWorkingDay(
        label: 'Cuma',
        shortLabel: 'Cum',
        isOpen: true,
        openTime: '09:00',
        closeTime: '23:30',
      ),
      StockWorkingDay(
        label: 'Cumartesi',
        shortLabel: 'Cmt',
        isOpen: true,
        openTime: '10:00',
        closeTime: '00:00',
      ),
      StockWorkingDay(
        label: 'Pazar',
        shortLabel: 'Paz',
        isOpen: false,
        openTime: '10:00',
        closeTime: '22:00',
      ),
    ];
  }

  String _fallbackShortLabel(String label) {
    if (label.length <= 3) {
      return label;
    }
    return label.substring(0, 3);
  }

  int _resolveInitialSelection(List<StockWorkingDay> workingDays) {
    final int fridayIndex = workingDays.indexWhere(
      (StockWorkingDay day) => day.label == 'Cuma' && day.isOpen,
    );
    if (fridayIndex != -1) {
      return fridayIndex;
    }
    final int firstOpenIndex = workingDays.indexWhere(
      (StockWorkingDay day) => day.isOpen,
    );
    return firstOpenIndex == -1 ? 0 : firstOpenIndex;
  }

  Future<void> _toggleTemporaryClosed() async {
    final bool nextValue = !_temporarilyClosed;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            nextValue ? 'İşletmeyi Geçici Kapat' : 'İşletmeyi Yeniden Aç',
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            nextValue
                ? 'İşletme geçici olarak kapalı olduğunda kullanıcılar sipariş veremez.'
                : 'İşletme yeniden açıldığında sipariş akışı aktif hale gelir.',
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14,
              height: 20 / 14,
              color: AppColors.bodyText,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: nextValue
                    ? AppColors.error
                    : AppColors.primary,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text(nextValue ? 'Kapat' : 'Aç'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }
    setState(() {
      _temporarilyClosed = nextValue;
    });
  }

  Future<void> _pickTime(int index, bool isOpening) async {
    final StockWorkingDay day = _workingDays[index];
    final TimeOfDay initialTime = _parseTime(
      isOpening ? day.openTime : day.closeTime,
    );
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.primary,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: AppColors.onSurface,
              ),
            ),
            child: child!,
          ),
        );
      },
    );
    if (picked == null) {
      return;
    }
    setState(() {
      if (isOpening) {
        day.openTime = _formatTime(picked);
      } else {
        day.closeTime = _formatTime(picked);
      }
      _selectedDayIndex = index;
    });
  }

  Future<void> _showAddSpecialDayDialog() async {
    final TextEditingController titleController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    bool isOpen = false;
    String openTime = '09:00';
    String closeTime = '18:00';

    Future<void> pickDialogTime(
      StateSetter setDialogState,
      bool isOpening,
    ) async {
      final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: _parseTime(isOpening ? openTime : closeTime),
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          );
        },
      );
      if (picked == null) {
        return;
      }
      setDialogState(() {
        if (isOpening) {
          openTime = _formatTime(picked);
        } else {
          closeTime = _formatTime(picked);
        }
      });
    }

    final _SpecialDayEntry? entry = await showDialog<_SpecialDayEntry>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text(
                'Özel Gün Ekle',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Gün Başlığı',
                        hintText: 'Örn. Bayram / Yılbaşı',
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Tarih'),
                      subtitle: Text(_formatDate(selectedDate)),
                      trailing: const Icon(Icons.calendar_today_outlined),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2035),
                        );
                        if (picked == null) {
                          return;
                        }
                        setDialogState(() {
                          selectedDate = picked;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: isOpen,
                      activeThumbColor: AppColors.success,
                      activeTrackColor: AppColors.success.withValues(
                        alpha: 0.32,
                      ),
                      onChanged: (bool value) {
                        setDialogState(() {
                          isOpen = value;
                        });
                      },
                      title: const Text('Bu gün açık'),
                    ),
                    if (isOpen) ...<Widget>[
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  pickDialogTime(setDialogState, true),
                              child: Text(openTime),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('-'),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  pickDialogTime(setDialogState, false),
                              child: Text(closeTime),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Vazgeç'),
                ),
                FilledButton(
                  onPressed: () {
                    if (titleController.text.trim().isEmpty) {
                      return;
                    }
                    Navigator.pop(
                      context,
                      _SpecialDayEntry(
                        title: titleController.text.trim(),
                        date: selectedDate,
                        isOpen: isOpen,
                        openTime: openTime,
                        closeTime: closeTime,
                      ),
                    );
                  },
                  child: const Text('Ekle'),
                ),
              ],
            );
          },
        );
      },
    );
    titleController.dispose();
    if (entry == null) {
      return;
    }
    setState(() {
      _specialDays = <_SpecialDayEntry>[..._specialDays, entry]
        ..sort((a, b) => a.date.compareTo(b.date));
    });
  }

  Future<void> _save() async {
    final StockAppController controller = StockAppScope.of(context);
    await controller.updateWorkingHours(
      workingDays: _workingDays,
      isActive: !_temporarilyClosed,
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Çalışma saatleri güncellendi.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  TimeOfDay _parseTime(String value) {
    final List<String> parts = value.split(':');
    if (parts.length != 2) {
      return const TimeOfDay(hour: 9, minute: 0);
    }
    return TimeOfDay(
      hour: int.tryParse(parts.first) ?? 9,
      minute: int.tryParse(parts.last) ?? 0,
    );
  }

  String _formatTime(TimeOfDay time) {
    final String hour = time.hour.toString().padLeft(2, '0');
    final String minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDate(DateTime date) {
    const List<String> months = <String>[
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final StockAppController controller = StockAppScope.of(context);
    final bool isSaving = controller.isBusy('profile:working-hours');

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: Row(
                children: <Widget>[
                  _TopBarBackButton(onTap: () => Navigator.pop(context)),
                  const SizedBox(width: 16),
                  const Text(
                    'Hesap Ayarları',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 28 / 18,
                      letterSpacing: -0.45,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 672),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const SizedBox(height: 24),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Çalışma Saatleri',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  height: 32 / 24,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'İşletmenizin haftalık ve özel günlerdeki çalışma saatlerini buradan düzenleyebilirsiniz.',
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  height: 20 / 14,
                                  color: AppColors.bodyText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _TemporaryClosedCard(
                          isTemporarilyClosed: _temporarilyClosed,
                          onTap: _toggleTemporaryClosed,
                        ),
                        const SizedBox(height: 24),
                        _WeeklyHoursCard(
                          workingDays: _workingDays,
                          selectedDayIndex: _selectedDayIndex,
                          onSelectDay: (int index) {
                            setState(() {
                              _selectedDayIndex = index;
                            });
                          },
                          onToggleDay: (int index, bool value) {
                            setState(() {
                              _workingDays[index].isOpen = value;
                              if (value) {
                                _selectedDayIndex = index;
                              } else if (_selectedDayIndex == index) {
                                _selectedDayIndex = _resolveInitialSelection(
                                  _workingDays,
                                );
                              }
                            });
                          },
                          onPickOpenTime: (int index) => _pickTime(index, true),
                          onPickCloseTime: (int index) =>
                              _pickTime(index, false),
                        ),
                        const SizedBox(height: 24),
                        _SpecialDaysSection(
                          specialDays: _specialDays,
                          onAdd: _showAddSpecialDayDialog,
                          onRemove: (int index) {
                            setState(() {
                              _specialDays.removeAt(index);
                            });
                          },
                          formatDate: _formatDate,
                        ),
                        const SizedBox(height: 24),
                        _WorkingHoursSaveButton(
                          isLoading: isSaving,
                          onTap: isSaving ? null : _save,
                        ),
                      ],
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

class _TopBarBackButton extends StatelessWidget {
  const _TopBarBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: const SizedBox(
          width: 32,
          height: 32,
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: AppColors.brandGreen,
          ),
        ),
      ),
    );
  }
}

class _TemporaryClosedCard extends StatelessWidget {
  const _TemporaryClosedCard({
    required this.isTemporarilyClosed,
    required this.onTap,
  });

  final bool isTemporarilyClosed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color accent = isTemporarilyClosed
        ? AppColors.success
        : AppColors.error;
    final String label = isTemporarilyClosed
        ? 'İşletmeyi Yeniden Aç'
        : 'Geçici Olarak Kapalı Yap';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                Icon(
                  isTemporarilyClosed
                      ? Icons.check_circle_outline_rounded
                      : Icons.info_outline_rounded,
                  size: 20,
                  color: accent,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 24 / 16,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: AppColors.slate300,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WeeklyHoursCard extends StatelessWidget {
  const _WeeklyHoursCard({
    required this.workingDays,
    required this.selectedDayIndex,
    required this.onSelectDay,
    required this.onToggleDay,
    required this.onPickOpenTime,
    required this.onPickCloseTime,
  });

  final List<StockWorkingDay> workingDays;
  final int selectedDayIndex;
  final ValueChanged<int> onSelectDay;
  final void Function(int index, bool value) onToggleDay;
  final ValueChanged<int> onPickOpenTime;
  final ValueChanged<int> onPickCloseTime;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'GÜN',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 16 / 12,
                      letterSpacing: 0.6,
                      color: Color(0xFF6C7B6D),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'SAAT ARALIĞI',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 16 / 12,
                      letterSpacing: 0.6,
                      color: Color(0xFF6C7B6D),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'DURUM',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 16 / 12,
                      letterSpacing: 0.6,
                      color: Color(0xFF6C7B6D),
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (int index = 0; index < workingDays.length; index++) ...<Widget>[
            _WorkingDayRow(
              day: workingDays[index],
              isSelected:
                  index == selectedDayIndex && workingDays[index].isOpen,
              onTap: () => onSelectDay(index),
              onToggle: (bool value) => onToggleDay(index, value),
              onPickOpenTime: () => onPickOpenTime(index),
              onPickCloseTime: () => onPickCloseTime(index),
            ),
            if (index != workingDays.length - 1) const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}

class _WorkingDayRow extends StatelessWidget {
  const _WorkingDayRow({
    required this.day,
    required this.isSelected,
    required this.onTap,
    required this.onToggle,
    required this.onPickOpenTime,
    required this.onPickCloseTime,
  });

  final StockWorkingDay day;
  final bool isSelected;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPickOpenTime;
  final VoidCallback onPickCloseTime;

  @override
  Widget build(BuildContext context) {
    final bool isClosed = !day.isOpen;
    final Color rowTextColor = isClosed
        ? const Color(0xFF6C7B6D)
        : AppColors.onSurface;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: isSelected
                ? Border.all(color: AppColors.success, width: 2)
                : null,
            boxShadow: isSelected
                ? <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Opacity(
            opacity: isClosed ? 0.7 : 1,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    day.label,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 16,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                      height: 24 / 16,
                      color: rowTextColor,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: isClosed
                        ? const Text(
                            'Kapalı',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              height: 24 / 16,
                              color: Color(0xFF6C7B6D),
                            ),
                          )
                        : isSelected
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              _TimeChip(
                                label: day.openTime,
                                onTap: onPickOpenTime,
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  '-',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    height: 24 / 16,
                                    color: Color(0xFFBBCBBB),
                                  ),
                                ),
                              ),
                              _TimeChip(
                                label: day.closeTime,
                                onTap: onPickCloseTime,
                              ),
                            ],
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                day.openTime,
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  height: 24 / 16,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  '-',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    height: 24 / 16,
                                    color: Color(0xFFBBCBBB),
                                  ),
                                ),
                              ),
                              Text(
                                day.closeTime,
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  height: 24 / 16,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _TinySwitch(
                      value: day.isOpen,
                      activeColor: AppColors.success,
                      inactiveColor: const Color(0xFFBBCBBB),
                      onChanged: onToggle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFEDEEEF),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFBBCBBB)),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 24 / 16,
              color: AppColors.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _TinySwitch extends StatelessWidget {
  const _TinySwitch({
    required this.value,
    required this.activeColor,
    required this.inactiveColor,
    required this.onChanged,
  });

  final bool value;
  final Color activeColor;
  final Color inactiveColor;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 48,
        height: 24,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: value ? activeColor : inactiveColor,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Align(
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: value ? 0.10 : 0.05),
                  blurRadius: value ? 6 : 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SpecialDaysSection extends StatelessWidget {
  const _SpecialDaysSection({
    required this.specialDays,
    required this.onAdd,
    required this.onRemove,
    required this.formatDate,
  });

  final List<_SpecialDayEntry> specialDays;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final String Function(DateTime date) formatDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  'Özel Günler',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 28 / 20,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: onAdd,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.add, size: 12, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'Yeni Ekle',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 20 / 14,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(21),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x4DBBCBBB)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: specialDays.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Henüz özel gün eklenmedi.',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 20 / 14,
                      color: AppColors.bodyText,
                    ),
                  ),
                )
              : Column(
                  children: <Widget>[
                    for (
                      int index = 0;
                      index < specialDays.length;
                      index++
                    ) ...<Widget>[
                      _SpecialDayRow(
                        entry: specialDays[index],
                        dateLabel: formatDate(specialDays[index].date),
                        onRemove: () => onRemove(index),
                      ),
                      if (index != specialDays.length - 1) ...<Widget>[
                        const SizedBox(height: 16),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0xFFEDEEEF),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _SpecialDayRow extends StatelessWidget {
  const _SpecialDayRow({
    required this.entry,
    required this.dateLabel,
    required this.onRemove,
  });

  final _SpecialDayEntry entry;
  final String dateLabel;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final bool isOpen = entry.isOpen;
    final Color pillBackground = isOpen
        ? AppColors.primary.withValues(alpha: 0.10)
        : AppColors.error.withValues(alpha: 0.10);
    final Color pillText = isOpen ? AppColors.primary : AppColors.error;
    final String pillLabel = isOpen
        ? 'Açık (${entry.openTime} - ${entry.closeTime})'
        : 'Kapalı';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                entry.title,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 24 / 16,
                  color: AppColors.onSurface,
                ),
              ),
              Text(
                dateLabel,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 20 / 14,
                  color: AppColors.bodyText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: pillBackground,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                pillLabel,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 16 / 12,
                  color: pillText,
                ),
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: onRemove,
              child: const Text(
                'Kaldır',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 16 / 12,
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WorkingHoursSaveButton extends StatelessWidget {
  const _WorkingHoursSaveButton({required this.isLoading, required this.onTap});

  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment(-0.95, -0.12),
          end: Alignment(1, 0.12),
          colors: <Color>[AppColors.primary, AppColors.success],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.20),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: SizedBox(
            height: 60,
            width: double.infinity,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Değişiklikleri Kaydet',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 28 / 18,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpecialDayEntry {
  _SpecialDayEntry({
    required this.title,
    required this.date,
    required this.isOpen,
    this.openTime = '09:00',
    this.closeTime = '18:00',
  });

  final String title;
  final DateTime date;
  final bool isOpen;
  final String openTime;
  final String closeTime;
}
