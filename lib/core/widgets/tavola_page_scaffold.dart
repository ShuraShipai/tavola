import 'package:flutter/material.dart';

import '../design/tavola_tokens.dart';

class TavolaPageScaffold extends StatelessWidget {
  const TavolaPageScaffold({
    required this.body,
    this.appBar,
    this.floatingActionButton,
    super.key,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: appBar,
    floatingActionButton: floatingActionButton,
    body: SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: TavolaSize.maxContentWidth,
          ),
          child: body,
        ),
      ),
    ),
  );
}
