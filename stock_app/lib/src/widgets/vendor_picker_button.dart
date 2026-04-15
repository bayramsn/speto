import 'package:flutter/material.dart';

import '../app/stock_app_controller.dart';

class VendorPickerButton extends StatelessWidget {
  const VendorPickerButton({super.key, required this.controller});

  final StockAppController controller;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
