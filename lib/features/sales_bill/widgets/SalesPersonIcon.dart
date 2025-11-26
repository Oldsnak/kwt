import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/utils/helpers.dart';

class SalesPersonIcon extends StatelessWidget {
  const SalesPersonIcon({
    super.key,
    required this.image,
    required this.title,
    required this.salesPersonId,
    this.onTap,
  });

  final String image, title;
  final String salesPersonId;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool dark = SHelperFunctions.isDarkMode(context);

    return GestureDetector(
      onTap: onTap, // <-- FIX: Do NOT trigger old controller logic
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: dark ? SColors.black : SColors.white,
                border: Border.all(color: SColors.accent, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: Image.asset(image)),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 55,
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: SColors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
