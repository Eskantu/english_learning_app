import 'package:flutter/material.dart';

class AppShadows {
  const AppShadows._();

  static List<BoxShadow> soft({double alpha = 0.04}) {
    return <BoxShadow>[
      BoxShadow(
        color: Colors.black.withValues(alpha: alpha),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
    ];
  }

  static List<BoxShadow> medium({double alpha = 0.05}) {
    return <BoxShadow>[
      BoxShadow(
        color: Colors.black.withValues(alpha: alpha),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ];
  }
}
