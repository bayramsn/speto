import 'package:flutter/material.dart';
import 'package:speto_shared/speto_shared.dart';

import '../../app/stock_app_controller.dart';
import '../../app/stock_app_scope.dart';
import '../../theme/app_colors.dart';

class PaymentFinanceScreen extends StatelessWidget {
  const PaymentFinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final StockAppController controller = StockAppScope.of(context);
    final SpetoVendorFinanceSummary? finance = controller.financeSummary;
    final List<SpetoVendorBankAccount> accounts =
        finance?.bankAccounts ?? const <SpetoVendorBankAccount>[];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Ödeme ve Finans'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: <Color>[AppColors.slate700, AppColors.onSurface],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Mevcut Bakiye',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  _currency(finance?.availableBalance ?? 0),
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'Son aktarım: ${finance?.lastPayoutAt.isNotEmpty == true ? finance!.lastPayoutAt : 'Henüz yok'}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emerald500,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                      ),
                      onPressed: accounts.isEmpty
                          ? null
                          : () => _showPayoutDialog(
                              context,
                              controller,
                              accounts.first,
                            ),
                      child: const Text(
                        'Hemen Çek',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Bekleyen bakiye: ${_currency(finance?.pendingBalance ?? 0)}',
            style: const TextStyle(
              color: AppColors.slate500,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text(
                'Kayıtlı Banka Hesapları',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => _showAddBankAccountDialog(context, controller),
                icon: const Icon(Icons.add_circle, color: AppColors.primary),
              ),
            ],
          ),
          if (accounts.isEmpty)
            const _EmptyFinanceCard()
          else
            for (final account in accounts)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.slate200),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.emerald50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.account_balance,
                        color: AppColors.emerald700,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            account.bankName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            account.maskedIban.isEmpty
                                ? account.iban
                                : account.maskedIban,
                            style: const TextStyle(
                              color: AppColors.slate500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (account.isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.emerald50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Varsayılan',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.emerald700,
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

  Future<void> _showAddBankAccountDialog(
    BuildContext context,
    StockAppController controller,
  ) async {
    final TextEditingController holderController = TextEditingController();
    final TextEditingController bankController = TextEditingController();
    final TextEditingController ibanController = TextEditingController();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Banka Hesabı Ekle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: holderController,
                  decoration: const InputDecoration(labelText: 'Hesap sahibi'),
                ),
                TextField(
                  controller: bankController,
                  decoration: const InputDecoration(labelText: 'Banka adı'),
                ),
                TextField(
                  controller: ibanController,
                  decoration: const InputDecoration(labelText: 'IBAN'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      await controller.addBankAccount(
        holderName: holderController.text,
        bankName: bankController.text,
        iban: ibanController.text,
      );
    }
    holderController.dispose();
    bankController.dispose();
    ibanController.dispose();
  }

  Future<void> _showPayoutDialog(
    BuildContext context,
    StockAppController controller,
    SpetoVendorBankAccount account,
  ) async {
    final TextEditingController amountController = TextEditingController(
      text: '500',
    );
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Bakiye Çek'),
          content: TextField(
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Tutar'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Gönder'),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      await controller.createPayout(
        bankAccountId: account.id,
        amount:
            double.tryParse(amountController.text.replaceAll(',', '.')) ?? 0,
        note: 'SepetPro İşyeri payout request',
      );
    }
    amountController.dispose();
  }

  String _currency(double value) {
    final String fixed = value.toStringAsFixed(2);
    final List<String> parts = fixed.split('.');
    return '₺${parts.first},${parts.last}';
  }
}

class _EmptyFinanceCard extends StatelessWidget {
  const _EmptyFinanceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.slate200),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        'Henüz banka hesabı eklenmemiş.',
        style: TextStyle(
          color: AppColors.slate500,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
