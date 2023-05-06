import 'package:alist/util/widget_utils.dart';
import 'package:flutter/material.dart';

class AlistScaffold extends StatelessWidget {
  const AlistScaffold({Key? key, required this.appbarTitle, required this.body})
      : super(key: key);
  final Widget appbarTitle;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    List<Color> colors = List.empty();
    bool isDarkMode = WidgetUtils.isDarkMode(context);

    if (!isDarkMode) {
      Color startColor = Theme.of(context).colorScheme.primaryContainer;
      const Color endColor = Colors.white;
      colors = [startColor, endColor];
    }

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
            backgroundColor: isDarkMode ? null : Colors.transparent,
            title: appbarTitle,
          ),
          body: body,
        ));
  }
}
