import 'package:flutter/material.dart';

/// Spacing, radius, and elevation tokens matching Stitch UI specifications
class AppSpacing {
  AppSpacing._();

  // Spacing units
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Layout gutters & margins
  static const double marginMobile = 16.0;
  static const double marginDesktop = 32.0;
  static const double gutterMobile = 16.0;
  static const double gutterDesktop = 24.0;
  static const double maxContentWidth = 1200.0;

  // Corner radius
  static const double radiusSm = 6.0;
  static const double radiusMd = 10.0;
  static const double radiusLg = 14.0;
  static const double radiusXl = 20.0;
  static const double radiusFull = 9999.0;

  static final BorderRadius roundedSm = BorderRadius.circular(radiusSm);
  static final BorderRadius roundedMd = BorderRadius.circular(radiusMd);
  static final BorderRadius roundedLg = BorderRadius.circular(radiusLg);
  static final BorderRadius roundedXl = BorderRadius.circular(radiusXl);
  static final BorderRadius roundedFull = BorderRadius.circular(radiusFull);
}
