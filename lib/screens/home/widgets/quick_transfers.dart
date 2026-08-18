import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

class QuickTransfers extends StatelessWidget {
  const QuickTransfers({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        itemBuilder: (context, index) {
          return FadeInRight(
            delay: Duration(milliseconds: 500 + (index * 100)),
            child: Container(
              width: 70,
              margin: const EdgeInsets.only(left: 16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: isDark 
                      ? Colors.white.withValues(alpha: 0.05) 
                      : Colors.black.withValues(alpha: 0.05),
                    child: Icon(
                      Icons.person_outline,
                      color: isDark ? Colors.white.withValues(alpha: 0.8) : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'مستفيد',
                    style: TextStyle(
                      color: isDark ? Colors.white.withValues(alpha: 0.6) : Colors.black54, 
                      fontSize: 10,
                      fontWeight: isDark ? FontWeight.w400 : FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
