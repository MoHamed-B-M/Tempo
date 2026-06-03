import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

class ExpressiveOpenContainer extends StatelessWidget {
  final Widget closedChild;
  final WidgetBuilder openBuilder;
  final Color closedColor;
  final Color openColor;
  final double closedBorderRadius;
  final Duration transitionDuration;
  final double closedElevation;
  final double openElevation;

  const ExpressiveOpenContainer({
    super.key,
    required this.closedChild,
    required this.openBuilder,
    required this.closedColor,
    this.openColor = Colors.transparent,
    this.closedBorderRadius = 28.0,
    this.transitionDuration = const Duration(milliseconds: 600),
    this.closedElevation = 0,
    this.openElevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    return OpenContainer(
      closedColor: closedColor,
      openColor: openColor,
      closedElevation: closedElevation,
      openElevation: openElevation,
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(closedBorderRadius),
      ),
      openShape: const RoundedRectangleBorder(),
      transitionDuration: transitionDuration,
      transitionType: ContainerTransitionType.fadeThrough,
      closedBuilder: (context, action) => RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(closedBorderRadius),
          clipBehavior: Clip.antiAliasWithSaveLayer,
          child: closedChild,
        ),
      ),
      openBuilder: (context, action) => RepaintBoundary(
        child: openBuilder(context),
      ),
    );
  }
}
