import 'package:alist/util/widget_utils.dart';
import 'package:flutter/material.dart';

class AlistScaffold extends StatelessWidget {
  const AlistScaffold({
    Key? key,
    this.appbarTitle,
    required this.body,
    this.onLeadingDoubleTap,
    this.resizeToAvoidBottomInset,
    this.appbarActions,
    this.showAppbar = true,
  }) : super(key: key);
  final Widget? appbarTitle;
  final Widget body;
  final GestureTapCallback? onLeadingDoubleTap;
  final bool? resizeToAvoidBottomInset;
  final List<Widget>? appbarActions;
  final bool showAppbar;

  @override
  Widget build(BuildContext context) {
    List<Color> colors = List.empty();
    bool isDarkMode = WidgetUtils.isDarkMode(context);

    if (!isDarkMode) {
      Color startColor = Theme.of(context).colorScheme.primaryContainer;
      const Color endColor = Colors.white;
      colors = [startColor, endColor];
    }
    final ModalRoute<dynamic>? parentRoute = ModalRoute.of(context);
    var canPop = null != parentRoute && parentRoute.canPop;

    return DecoratedBox(
        decoration: isDarkMode
            ? const BoxDecoration()
            : BoxDecoration(
                gradient: LinearGradient(
                  colors: colors,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
        child: Scaffold(
          backgroundColor: isDarkMode ? null : Colors.transparent,
          resizeToAvoidBottomInset: resizeToAvoidBottomInset ?? true,
          appBar: !showAppbar
              ? null
              : AppBar(
                  leading: canPop
                      ? GestureDetector(
                          onDoubleTap: onLeadingDoubleTap,
                          child: const BackButton(),
                        )
                      : null,
                  automaticallyImplyLeading: false,
                  backgroundColor: isDarkMode ? null : Colors.transparent,
                  title: appbarTitle,
                  actions: appbarActions,
                ),
          body: SafeArea(child: body),
        ));
  }
}
