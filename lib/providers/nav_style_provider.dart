import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/hive_helper.dart';

final navStyleProvider = NotifierProvider<NavStyleNotifier, NavStyleState>(
  NavStyleNotifier.new,
);

class NavStyleState {
  final bool useBubbleNav;

  const NavStyleState({
    this.useBubbleNav = false,
  });

  NavStyleState copyWith({bool? useBubbleNav}) {
    return NavStyleState(
      useBubbleNav: useBubbleNav ?? this.useBubbleNav,
    );
  }
}

class NavStyleNotifier extends Notifier<NavStyleState> {
  @override
  NavStyleState build() {
    final useBubble = HiveHelper.settings.get('use_bubble_nav') as bool? ?? false;
    return NavStyleState(useBubbleNav: useBubble);
  }

  Future<void> toggle() async {
    final next = !state.useBubbleNav;
    state = state.copyWith(useBubbleNav: next);
    await HiveHelper.settings.put('use_bubble_nav', next);
  }
}
