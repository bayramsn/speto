import 'package:flutter/material.dart';
import '../../app/stock_app_controller.dart';
import '../../app/stock_app_scope.dart';
import '../../theme/app_colors.dart';
import 'register_payment_bank_screen.dart';

class RegisterWorkingHoursScreen extends StatefulWidget {
  const RegisterWorkingHoursScreen({super.key});

  @override
  State<RegisterWorkingHoursScreen> createState() =>
      _RegisterWorkingHoursScreenState();
}

class _RegisterWorkingHoursScreenState
    extends State<RegisterWorkingHoursScreen> {
  @override
  Widget build(BuildContext context) {
    final draft = StockAppScope.of(context).registrationDraft;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Kayıt Ol',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColors.primary,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Adım 4 / 8',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                children: [
                  const Text(
                    'Çalışma Saatleri',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppColors.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'İşletmenizin müşterilere hizmet verdiği zaman aralıklarını belirleyin. "Tatil" işaretlenen günlerde sipariş alımı durdurulacaktır.',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.slate500,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  for (final MapEntry<int, StockWorkingDay> entry
                      in draft.workingDays.asMap().entries) ...[
                    _buildDayRow(entry.key, entry.value),
                    if (entry.key != draft.workingDays.length - 1)
                      const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
            // Bottom Actions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                border: const Border(top: BorderSide(color: Color(0xFFE7E8E9))),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFE7E8E9),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {},
                      child: const Text(
                        'Taslağı Kaydet',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: AppColors.primary.withValues(alpha: 0.4),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterPaymentBankScreen(),
                          ),
                        );
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Devam Et',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.chevron_right, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayRow(int index, StockWorkingDay day) {
    final bool isHoliday = !day.isOpen;
    final IconData icon = switch (index) {
      0 => Icons.calendar_today,
      5 => Icons.event_available,
      6 => Icons.night_shelter,
      _ => Icons.schedule,
    };
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isHoliday ? Colors.white : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isHoliday
              ? AppColors.primaryContainer.withValues(alpha: 0.2)
              : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isHoliday
                      ? AppColors.primaryContainer.withValues(alpha: 0.1)
                      : const Color(0xFFF3F4F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Text(
                day.label,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      day.openTime,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.bold,
                        color: isHoliday
                            ? AppColors.slate400
                            : AppColors.onSurface,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '-',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.slate500,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      day.closeTime,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.bold,
                        color: isHoliday
                            ? AppColors.slate400
                            : AppColors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Switch(
                    value: isHoliday,
                    onChanged: (val) {
                      setState(() {
                        day.isOpen = !val;
                      });
                    },
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppColors.primaryContainer,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: const Color(0xFFE7E8E9),
                  ),
                  Text(
                    'Tatil',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isHoliday ? AppColors.primary : AppColors.slate500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
