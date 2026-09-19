import 'package:flutter/material.dart';
import 'package:ruhh/core/theme/ruhh_tokens.dart';

/// Places FAB above the floating bottom nav (avoids nav hit-test stealing taps).
class FabAboveBottomNavLocation extends FloatingActionButtonLocation {
  const FabAboveBottomNavLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final fab = scaffoldGeometry.floatingActionButtonSize;
    final scaffold = scaffoldGeometry.scaffoldSize;
    final end = scaffold.width - fab.width - 16;
    final safe = scaffoldGeometry.minViewPadding.bottom;
    final clearance = ruhhFabBottomClearance(safe);
    final bottom = scaffoldGeometry.contentBottom - fab.height - clearance;
    return Offset(end, bottom);
  }
}

const kFabAboveBottomNavLocation = FabAboveBottomNavLocation();
