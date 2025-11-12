import 'package:flutter/material.dart';
import '../../../app/theme/colors.dart';
import 'circular_container.dart';
import '../curved_container/curved_edges_widget.dart';

class PrimaryHeaderContainer extends StatelessWidget {
  const PrimaryHeaderContainer({
    super.key,
    required this.child
  });

  final Widget child;
  @override
  Widget build(BuildContext context) {
    return TCurvedEdgeWidget(
      child: Container(
        color: SColors.primary,
        child: Stack(
          children: [
            Positioned(top: -180, right: -250,child: SCircularContainer(backgroundColor: SColors.white.withOpacity(0.1))),
            Positioned(top: 60, right: -300,child: SCircularContainer(backgroundColor: SColors.white.withAlpha((0.1 * 255).round()),)),
            child,
          ],
        ),
      ),
    );
  }
}