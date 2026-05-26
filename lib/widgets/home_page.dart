import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import 'time_picker_wheel.dart';
import 'bottom_control.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),
            Text(
              '09:41',
              style: AppTextStyles.heading,
            ),
            const SizedBox(height: 8),
            Text(
              'The next alarm in 19 min',
              style: AppTextStyles.body.copyWith(
                color: AppColors.primaryText.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(12, (index) {
                  final highlighted = index == 5;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 6,
                    height: highlighted ? 60 : 36,
                    decoration: BoxDecoration(
                      color: highlighted
                          ? AppColors.accentRed
                          : AppColors.primaryText.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),
            const Expanded(child: TimePickerWheel()),
            const BottomControl(),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: () {},
              color: AppColors.primaryText,
            ),
            FloatingActionButton(
              onPressed: () {},
              backgroundColor: AppColors.accentRed,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
