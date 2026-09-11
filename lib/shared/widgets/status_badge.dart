import 'package:flutter/material.dart';
import '../../core/constants/payment_status.dart';

class StatusBadge extends StatelessWidget {
  final PaymentStatus status;
  final bool showIcon;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.status,
    this.showIcon = true,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status.borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Text(
              status.iconSymbol,
              style: TextStyle(
                color: status.textColor,
                fontWeight: FontWeight.bold,
                fontSize: fontSize + 1,
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            status.labelArabic,
            style: TextStyle(
              color: status.textColor,
              fontWeight: FontWeight.w700,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }
}
