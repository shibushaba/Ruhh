import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

/// B.2 list entrance wrapper.
class StaggeredEntranceList extends StatelessWidget {
  const StaggeredEntranceList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return AnimationLimiter(
      child: ListView.builder(
        padding: padding,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 320),
            delay: const Duration(milliseconds: 40),
            child: SlideAnimation(
              verticalOffset: 16,
              child: FadeInAnimation(child: itemBuilder(context, index)),
            ),
          );
        },
      ),
    );
  }
}

class StaggeredEntranceColumn extends StatelessWidget {
  const StaggeredEntranceColumn({
    super.key,
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AnimationLimiter(
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++)
            AnimationConfiguration.staggeredList(
              position: i,
              duration: const Duration(milliseconds: 320),
              delay: const Duration(milliseconds: 40),
              child: SlideAnimation(
                verticalOffset: 16,
                child: FadeInAnimation(child: children[i]),
              ),
            ),
        ],
      ),
    );
  }
}
