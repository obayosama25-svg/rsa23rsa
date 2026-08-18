import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../transfer_screen.dart';
import '../../request_screen.dart';
import '../../topup_screen.dart';
import '../../more_services_screen.dart';

class ServicesGrid extends StatelessWidget {
  const ServicesGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> services = [
      {
        'title': 'إرسال',
        'icon': Icons.north_east_rounded,
      },
      {
        'title': 'طلب',
        'icon': Icons.south_west_rounded,
      },
      {
        'title': 'شحن',
        'icon': Icons.account_balance_wallet_outlined,
      },
      {
        'title': 'المزيد',
        'icon': Icons.more_horiz_rounded,
      },
    ];

    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return FadeInUp(
      delay: const Duration(milliseconds: 300),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: services.map((s) {
            return Column(
              children: [
                GestureDetector(
                  onTap: () {
                    if (s['title'] == 'إرسال') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TransferScreen(),
                        ),
                      );
                    } else if (s['title'] == 'طلب') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RequestScreen(),
                        ),
                      );
                    } else if (s['title'] == 'شحن') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TopupScreen(),
                        ),
                      );
                    } else if (s['title'] == 'المزيد') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MoreServicesScreen(),
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: 65,
                    height: 65,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Icon(
                      s['icon'],
                      color: isDark ? Colors.white : Colors.black87,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  s['title'],
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
