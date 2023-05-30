import 'package:alist/util/widget_utils.dart';
import 'package:flutter/material.dart';

class AlistScaffold extends StatelessWidget {
  const AlistScaffold({
    Key? key,
    required this.appbarTitle,
    required this.body,
    this.onLeadingDoubleTap,
  }) : super(key: key);
  final Widget appbarTitle;
  final Widget body;
  final GestureTapCallback? onLeadingDoubleTap;

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
          appBar: AppBar(
            leading: canPop
                ? GestureDetector(
                    onDoubleTap: onLeadingDoubleTap,
                    child: const BackButton(),
                  )
                : null,
            backgroundColor: isDarkMode ? null : Colors.transparent,
            title: appbarTitle,
          ),
          body: body,
        ));
  }
}
