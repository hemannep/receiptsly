// lib/core/theme/app_dimensions.dart

import 'package:flutter/material.dart';

/// Dimension constants for Receiptsly
/// Provides consistent spacing, sizing, and layout dimensions
class AppDimensions {
  // Private constructor to prevent instantiation
  AppDimensions._();

  /// ==================== SPACING SYSTEM ====================

  /// Base spacing unit (4dp)
  static const double spaceUnit = 4.0;

  /// Micro spacing
  static const double spaceXS = spaceUnit; // 4dp
  static const double spaceSM = spaceUnit * 2; // 8dp

  /// Standard spacing
  static const double spaceMD = spaceUnit * 3; // 12dp
  static const double spaceLG = spaceUnit * 4; // 16dp
  static const double spaceXL = spaceUnit * 5; // 20dp
  static const double spaceXXL = spaceUnit * 6; // 24dp

  /// Large spacing
  static const double space3XL = spaceUnit * 8; // 32dp
  static const double space4XL = spaceUnit * 10; // 40dp
  static const double space5XL = spaceUnit * 12; // 48dp
  static const double space6XL = spaceUnit * 16; // 64dp

  /// ==================== PADDING & MARGINS ====================

  /// Screen edge padding
  static const double screenPadding = spaceLG; // 16dp
  static const double screenPaddingHorizontal = spaceLG; // 16dp
  static const double screenPaddingVertical = spaceXL; // 20dp

  /// Card padding
  static const double cardPadding = spaceLG; // 16dp
  static const double cardPaddingSmall = spaceMD; // 12dp
  static const double cardPaddingLarge = spaceXL; // 20dp

  /// List item padding
  static const double listItemPadding = spaceLG; // 16dp
  static const double listItemPaddingVertical = spaceMD; // 12dp
  static const double listItemPaddingHorizontal = spaceLG; // 16dp

  /// Button padding
  static const double buttonPadding = spaceLG; // 16dp
  static const double buttonPaddingSmall = spaceMD; // 12dp
  static const double buttonPaddingLarge = spaceXL; // 20dp
  static const double buttonPaddingVertical = spaceMD; // 12dp
  static const double buttonPaddingHorizontal = spaceXXL; // 24dp

  /// Input field padding
  static const double inputPadding = spaceLG; // 16dp
  static const double inputPaddingVertical = spaceMD; // 12dp
  static const double inputPaddingHorizontal = spaceLG; // 16dp

  /// Dialog padding
  static const double dialogPadding = spaceXXL; // 24dp
  static const double dialogContentPadding = spaceLG; // 16dp

  /// Bottom sheet padding
  static const double bottomSheetPadding = spaceXXL; // 24dp
  static const double bottomSheetHandlePadding = spaceMD; // 12dp

  /// ==================== COMPONENT HEIGHTS ====================

  /// AppBar heights
  static const double appBarHeight = 56.0;
  static const double appBarHeightLarge = 64.0;
  static const double appBarHeightSmall = 48.0;

  /// Button heights
  static const double buttonHeight = 48.0;
  static const double buttonHeightSmall = 32.0;
  static const double buttonHeightLarge = 56.0;
  static const double buttonHeightExtraLarge = 64.0;

  /// Input field heights
  static const double inputHeight = 48.0;
  static const double inputHeightSmall = 40.0;
  static const double inputHeightLarge = 56.0;
  static const double textAreaMinHeight = 100.0;

  /// List item heights
  static const double listItemHeight = 56.0;
  static const double listItemHeightSmall = 48.0;
  static const double listItemHeightLarge = 64.0;
  static const double listItemHeightTwoLine = 72.0;
  static const double listItemHeightThreeLine = 88.0;

  /// Tab heights
  static const double tabHeight = 48.0;
  static const double tabHeightSmall = 40.0;

  /// Bottom navigation height
  static const double bottomNavHeight = 60.0;
  static const double bottomNavHeightSmall = 56.0;

  /// Floating Action Button sizes
  static const double fabSize = 56.0;
  static const double fabSizeSmall = 40.0;
  static const double fabSizeLarge = 64.0;

  /// Chip heights
  static const double chipHeight = 32.0;
  static const double chipHeightSmall = 24.0;

  /// Switch/Toggle heights
  static const double switchHeight = 24.0;
  static const double switchTrackHeight = 14.0;
  static const double switchThumbSize = 20.0;

  /// ==================== WIDTHS & BREAKPOINTS ====================

  /// Screen breakpoints
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 905.0;
  static const double desktopBreakpoint = 1240.0;

  /// Maximum content widths
  static const double maxContentWidth = 1200.0;
  static const double maxFormWidth = 400.0;
  static const double maxCardWidth = 600.0;

  /// Minimum tap target size
  static const double minTapTarget = 44.0;

  /// Sidebar widths
  static const double sidebarWidth = 280.0;
  static const double sidebarWidthCompact = 72.0;
  static const double sidebarWidthExpanded = 320.0;

  /// Dialog widths
  static const double dialogWidthSmall = 280.0;
  static const double dialogWidth = 400.0;
  static const double dialogWidthLarge = 600.0;

  /// Modal bottom sheet widths
  static const double bottomSheetMaxWidth = 640.0;

  /// ==================== BORDER RADIUS ====================

  /// Standard border radius
  static const double radiusXS = 2.0;
  static const double radiusSM = 4.0;
  static const double radiusMD = 6.0;
  static const double radiusLG = 8.0;
  static const double radiusXL = 12.0;
  static const double radiusXXL = 16.0;
  static const double radius3XL = 20.0;
  static const double radius4XL = 24.0;
  static const double radiusFull = 999.0; // Fully rounded

  /// Component-specific radius
  static const double buttonRadius = radiusLG; // 8dp
  static const double cardRadius = radiusXL; // 12dp
  static const double inputRadius = radiusLG; // 8dp
  static const double dialogRadius = radiusXXL; // 16dp
  static const double bottomSheetRadius = radiusXXL; // 16dp
  static const double chipRadius = radiusFull; // Fully rounded
  static const double avatarRadius = radiusFull; // Fully rounded
  static const double imageRadius = radiusLG; // 8dp

  /// ==================== BORDER WIDTHS ====================

  /// Border widths
  static const double borderWidth = 1.0;
  static const double borderWidthThin = 0.5;
  static const double borderWidthThick = 2.0;
  static const double borderWidthFocus = 2.0;

  /// Divider thickness
  static const double dividerThickness = 1.0;
  static const double dividerThicknessThin = 0.5;

  /// ==================== ELEVATION SYSTEM ====================

  /// Material elevation levels
  static const double elevation0 = 0.0;
  static const double elevation1 = 1.0;
  static const double elevation2 = 2.0;
  static const double elevation3 = 3.0;
  static const double elevation4 = 4.0;
  static const double elevation6 = 6.0;
  static const double elevation8 = 8.0;
  static const double elevation12 = 12.0;
  static const double elevation16 = 16.0;
  static const double elevation24 = 24.0;

  /// Component elevations
  static const double cardElevation = elevation2;
  static const double dialogElevation = elevation24;
  static const double bottomSheetElevation = elevation16;
  static const double appBarElevation = elevation4;
  static const double fabElevation = elevation6;
  static const double menuElevation = elevation8;
  static const double tooltipElevation = elevation4;

  /// ==================== ICON SIZES ====================

  /// Standard icon sizes
  static const double iconSizeXS = 12.0;
  static const double iconSizeSM = 16.0;
  static const double iconSizeMD = 20.0;
  static const double iconSizeLG = 24.0;
  static const double iconSizeXL = 28.0;
  static const double iconSizeXXL = 32.0;
  static const double iconSize3XL = 40.0;
  static const double iconSize4XL = 48.0;
  static const double iconSize5XL = 56.0;
  static const double iconSize6XL = 64.0;

  /// Component-specific icon sizes
  static const double appBarIconSize = iconSizeLG; // 24dp
  static const double buttonIconSize = iconSizeLG; // 24dp
  static const double listItemIconSize = iconSizeLG; // 24dp
  static const double tabIconSize = iconSizeLG; // 24dp
  static const double navIconSize = iconSizeLG; // 24dp
  static const double chipIconSize = iconSizeSM; // 16dp
  static const double inputIconSize = iconSizeLG; // 24dp

  /// ==================== AVATAR SIZES ====================

  /// Avatar sizes
  static const double avatarSizeXS = 24.0;
  static const double avatarSizeSM = 32.0;
  static const double avatarSizeMD = 40.0;
  static const double avatarSizeLG = 48.0;
  static const double avatarSizeXL = 56.0;
  static const double avatarSizeXXL = 64.0;
  static const double avatarSize3XL = 80.0;
  static const double avatarSize4XL = 96.0;
  static const double avatarSize5XL = 128.0;

  /// ==================== SAFE AREA & SYSTEM UI ====================

  /// System UI dimensions
  static const double statusBarHeight = 24.0;
  static const double statusBarHeightiOS = 44.0;
  static const double navigationBarHeight = 48.0;
  static const double toolbarHeight = 56.0;

  /// Safe area margins
  static const double safeAreaTop = 24.0;
  static const double safeAreaBottom = 24.0;
  static const double safeAreaHorizontal = 16.0;

  /// ==================== ANIMATION DIMENSIONS ====================

  /// Slide distances
  static const double slideDistance = 300.0;
  static const double slideDistanceSmall = 100.0;

  /// Scale factors
  static const double scaleFactorSmall = 0.95;
  static const double scaleFactorMedium = 0.9;
  static const double scaleFactorLarge = 0.8;

  /// ==================== LOADING & PROGRESS ====================

  /// Progress indicator sizes
  static const double progressSizeSM = 16.0;
  static const double progressSizeMD = 24.0;
  static const double progressSizeLG = 32.0;
  static const double progressSizeXL = 40.0;

  /// Loading overlay dimensions
  static const double loadingOverlaySize = 80.0;
  static const double loadingIndicatorSize = 32.0;

  /// ==================== FORM DIMENSIONS ====================

  /// Form spacing
  static const double formFieldSpacing = spaceXL; // 20dp
  static const double formSectionSpacing = space3XL; // 32dp
  static const double formGroupSpacing = spaceLG; // 16dp

  /// Label spacing
  static const double labelSpacing = spaceSM; // 8dp
  static const double helpTextSpacing = spaceXS; // 4dp

  /// ==================== GRID & LAYOUT ====================

  /// Grid spacing
  static const double gridSpacing = spaceLG; // 16dp
  static const double gridSpacingSmall = spaceMD; // 12dp
  static const double gridSpacingLarge = spaceXL; // 20dp

  /// Column counts
  static const int mobileColumns = 4;
  static const int tabletColumns = 8;
  static const int desktopColumns = 12;

  /// Aspect ratios
  static const double aspectRatioSquare = 1.0;
  static const double aspectRatioVideo = 16 / 9;
  static const double aspectRatioCard = 3 / 2;
  static const double aspectRatioPhoto = 4 / 3;
  static const double aspectRatioPortrait = 3 / 4;

  /// ==================== RECEIPT SPECIFIC DIMENSIONS ====================

  /// Receipt card dimensions
  static const double receiptCardHeight = 120.0;
  static const double receiptImageSize = 80.0;
  static const double receiptImageRadius = radiusLG;

  /// Invoice dimensions
  static const double invoicePreviewHeight = 400.0;
  static const double invoiceItemHeight = 48.0;

  /// ==================== RESPONSIVE HELPERS ====================

  /// Get responsive padding based on screen width
  static EdgeInsets getResponsivePadding(double screenWidth) {
    if (screenWidth < mobileBreakpoint) {
      return const EdgeInsets.all(screenPadding);
    } else if (screenWidth < tabletBreakpoint) {
      return const EdgeInsets.all(spaceXXL);
    } else {
      return const EdgeInsets.all(space3XL);
    }
  }

  /// Get responsive card padding
  static EdgeInsets getResponsiveCardPadding(double screenWidth) {
    if (screenWidth < mobileBreakpoint) {
      return const EdgeInsets.all(cardPaddingSmall);
    } else {
      return const EdgeInsets.all(cardPadding);
    }
  }

  /// Get responsive dialog width
  static double getResponsiveDialogWidth(double screenWidth) {
    if (screenWidth < mobileBreakpoint) {
      return screenWidth * 0.9;
    } else if (screenWidth < tabletBreakpoint) {
      return dialogWidth;
    } else {
      return dialogWidthLarge;
    }
  }

  /// Get responsive column count
  static int getResponsiveColumns(double screenWidth) {
    if (screenWidth < mobileBreakpoint) {
      return mobileColumns;
    } else if (screenWidth < tabletBreakpoint) {
      return tabletColumns;
    } else {
      return desktopColumns;
    }
  }

  /// Get responsive icon size
  static double getResponsiveIconSize(double screenWidth) {
    if (screenWidth < mobileBreakpoint) {
      return iconSizeMD;
    } else {
      return iconSizeLG;
    }
  }

  /// ==================== EDGE INSETS HELPERS ====================

  /// All sides padding
  static const EdgeInsets paddingXS = EdgeInsets.all(spaceXS);
  static const EdgeInsets paddingSM = EdgeInsets.all(spaceSM);
  static const EdgeInsets paddingMD = EdgeInsets.all(spaceMD);
  static const EdgeInsets paddingLG = EdgeInsets.all(spaceLG);
  static const EdgeInsets paddingXL = EdgeInsets.all(spaceXL);
  static const EdgeInsets paddingXXL = EdgeInsets.all(spaceXXL);

  /// Horizontal padding
  static const EdgeInsets paddingHorizontalXS = EdgeInsets.symmetric(
    horizontal: spaceXS,
  );
  static const EdgeInsets paddingHorizontalSM = EdgeInsets.symmetric(
    horizontal: spaceSM,
  );
  static const EdgeInsets paddingHorizontalMD = EdgeInsets.symmetric(
    horizontal: spaceMD,
  );
  static const EdgeInsets paddingHorizontalLG = EdgeInsets.symmetric(
    horizontal: spaceLG,
  );
  static const EdgeInsets paddingHorizontalXL = EdgeInsets.symmetric(
    horizontal: spaceXL,
  );

  /// Vertical padding
  static const EdgeInsets paddingVerticalXS = EdgeInsets.symmetric(
    vertical: spaceXS,
  );
  static const EdgeInsets paddingVerticalSM = EdgeInsets.symmetric(
    vertical: spaceSM,
  );
  static const EdgeInsets paddingVerticalMD = EdgeInsets.symmetric(
    vertical: spaceMD,
  );
  static const EdgeInsets paddingVerticalLG = EdgeInsets.symmetric(
    vertical: spaceLG,
  );
  static const EdgeInsets paddingVerticalXL = EdgeInsets.symmetric(
    vertical: spaceXL,
  );

  /// Screen edge padding
  static const EdgeInsets screenEdgePadding = EdgeInsets.all(screenPadding);
  static const EdgeInsets screenEdgePaddingHorizontal = EdgeInsets.symmetric(
    horizontal: screenPaddingHorizontal,
  );
  static const EdgeInsets screenEdgePaddingVertical = EdgeInsets.symmetric(
    vertical: screenPaddingVertical,
  );

  /// ==================== SIZE HELPERS ====================

  /// Create square size
  static Size squareSize(double size) => Size.square(size);

  /// Create size from width and height
  static Size createSize(double width, double height) => Size(width, height);

  /// Get button size
  static Size getButtonSize(String size) {
    switch (size) {
      case 'small':
        return Size(double.infinity, buttonHeightSmall);
      case 'large':
        return Size(double.infinity, buttonHeightLarge);
      case 'extra-large':
        return Size(double.infinity, buttonHeightExtraLarge);
      default:
        return Size(double.infinity, buttonHeight);
    }
  }

  /// ==================== BORDER RADIUS HELPERS ====================

  /// Create border radius
  static BorderRadius createBorderRadius(double radius) =>
      BorderRadius.circular(radius);

  /// Common border radius
  static const BorderRadius borderRadiusXS = BorderRadius.all(
    Radius.circular(radiusXS),
  );
  static const BorderRadius borderRadiusSM = BorderRadius.all(
    Radius.circular(radiusSM),
  );
  static const BorderRadius borderRadiusMD = BorderRadius.all(
    Radius.circular(radiusMD),
  );
  static const BorderRadius borderRadiusLG = BorderRadius.all(
    Radius.circular(radiusLG),
  );
  static const BorderRadius borderRadiusXL = BorderRadius.all(
    Radius.circular(radiusXL),
  );
  static const BorderRadius borderRadiusXXL = BorderRadius.all(
    Radius.circular(radiusXXL),
  );
  static const BorderRadius borderRadiusFull = BorderRadius.all(
    Radius.circular(radiusFull),
  );

  /// Top only border radius
  static const BorderRadius borderRadiusTopLG = BorderRadius.only(
    topLeft: Radius.circular(radiusLG),
    topRight: Radius.circular(radiusLG),
  );

  static const BorderRadius borderRadiusTopXL = BorderRadius.only(
    topLeft: Radius.circular(radiusXL),
    topRight: Radius.circular(radiusXL),
  );

  /// ==================== VALIDATION HELPERS ====================

  /// Check if size is within mobile breakpoint
  static bool isMobile(double width) => width < mobileBreakpoint;

  /// Check if size is within tablet breakpoint
  static bool isTablet(double width) =>
      width >= mobileBreakpoint && width < desktopBreakpoint;

  /// Check if size is desktop
  static bool isDesktop(double width) => width >= desktopBreakpoint;

  /// Get device type string
  static String getDeviceType(double width) {
    if (isMobile(width)) return 'mobile';
    if (isTablet(width)) return 'tablet';
    return 'desktop';
  }
}
