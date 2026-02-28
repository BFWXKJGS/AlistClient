import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProjectorRemoteNavigation extends StatelessWidget {
  const ProjectorRemoteNavigation({
    super.key,
    required this.child,
  });

  final Widget child;

  static const Map<ShortcutActivator, Intent> _projectorShortcuts =
      <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.arrowUp):
        DirectionalFocusIntent(TraversalDirection.up),
    SingleActivator(LogicalKeyboardKey.arrowDown):
        DirectionalFocusIntent(TraversalDirection.down),
    SingleActivator(LogicalKeyboardKey.arrowLeft):
        DirectionalFocusIntent(TraversalDirection.left),
    SingleActivator(LogicalKeyboardKey.arrowRight):
        DirectionalFocusIntent(TraversalDirection.right),
    SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
    SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
    SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
    SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
  };

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: ReadingOrderTraversalPolicy(),
      child: Shortcuts(
        shortcuts: _projectorShortcuts,
        child: Actions(
          actions: <Type, Action<Intent>>{
            DirectionalFocusIntent: DirectionalFocusAction(),
          },
          child: child,
        ),
      ),
    );
  }
}
