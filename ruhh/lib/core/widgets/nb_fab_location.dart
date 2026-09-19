import 'package:flutter/material.dart';

/// Places FAB above the floating bottom nav pill (~88px).
class FabAboveBottomNavLocation extends FloatingActionButtonLocation {
  const FabAboveBottomNavLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final fab = scaffoldGeometry.floatingActionButtonSize;
    final scaffold = scaffoldGeometry.scaffoldSize;
    final end = scaffold.width - fab.width - 16;
    final bottom = scaffoldGeometry.contentBottom - fab.height - 88;
    return Offset(end, bottom);
  }
}

const kFabAboveBottomNavLocation = FabAboveBottomNavLocation();
