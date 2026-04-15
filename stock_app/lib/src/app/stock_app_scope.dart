import 'package:flutter/widgets.dart';

import 'stock_app_controller.dart';

class StockAppScope extends InheritedNotifier<StockAppController> {
  const StockAppScope({
    super.key,
    required StockAppController controller,
    required super.child,
  }) : super(notifier: controller);

  static StockAppController of(BuildContext context) {
    final StockAppScope? scope = context
        .dependOnInheritedWidgetOfExactType<StockAppScope>();
    assert(scope != null, 'StockAppScope not found in context');
    return scope!.notifier!;
  }
}
