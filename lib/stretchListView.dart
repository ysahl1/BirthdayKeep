import 'dart:math';
import 'package:flutter/material.dart';

/* =========================
   Liste mit Vita-Effekt
========================= */

// Beim Ziehen über den oberen Rand wachsen die Abstände zwischen den
// Einträgen und federn beim Loslassen zurück
class StretchListView extends StatefulWidget {
  // Wie stark die Abstände wachsen (pro Eintrag, relativ zur Zieh-Distanz)
  static const double _gapFactor = 0.3;

  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final int Function(int index) _gapIndex;

  StretchListView({
    super.key,
    this.controller,
    this.padding,
    required List<Widget> children,
  }) : itemCount = children.length,
       itemBuilder = ((_, i) => children[i]),
       _gapIndex = _countWithoutSpacers(children);

  StretchListView.builder({
    super.key,
    this.controller,
    this.padding,
    required this.itemCount,
    required this.itemBuilder,
  }) : _gapIndex = _sameIndex;

  static int _sameIndex(int index) => index;

  // Reine Abstandshalter zählen nicht, sonst dehnen sich Seiten mit
  // Zwischenräumen doppelt so stark wie Seiten ohne
  static int Function(int) _countWithoutSpacers(List<Widget> children) {
    return (index) =>
        children.take(index).where((child) => child is! SizedBox).length;
  }

  @override
  State<StretchListView> createState() => _StretchListViewState();
}

class _StretchListViewState extends State<StretchListView> {
  final ValueNotifier<double> _overscroll = ValueNotifier(0);
  ScrollController? _ownController;

  ScrollController get _controller =>
      widget.controller ?? (_ownController ??= ScrollController());

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateOverscroll);
  }

  @override
  void didUpdateWidget(StretchListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final old = oldWidget.controller ?? _ownController;
    if (old != _controller) {
      old?.removeListener(_updateOverscroll);
      _controller.addListener(_updateOverscroll);
    }
  }

  void _updateOverscroll() {
    if (!_controller.hasClients) return;
    _overscroll.value = max(0, -_controller.position.pixels);
  }

  @override
  void dispose() {
    _controller.removeListener(_updateOverscroll);
    _ownController?.dispose();
    _overscroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _controller,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: widget.padding,
      itemCount: widget.itemCount,
      itemBuilder:
          (context, i) => ValueListenableBuilder<double>(
            valueListenable: _overscroll,
            builder:
                (_, overscroll, child) => Transform.translate(
                  offset: Offset(
                    0,
                    overscroll *
                        StretchListView._gapFactor *
                        widget._gapIndex(i),
                  ),
                  child: child,
                ),
            child: widget.itemBuilder(context, i),
          ),
    );
  }
}
