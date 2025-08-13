// lib/core/theme/form_control_themes.dart

import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_dimensions.dart';

/// Form control theme configurations for light and dark themes
class FormControlThemes {
  FormControlThemes._();

  /// ==================== SWITCH THEMES ====================

  static SwitchThemeData get lightSwitchTheme => SwitchThemeData(
    thumbColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.disabled)) {
        return AppColors.gray300;
      }
      if (states.contains(MaterialState.selected)) {
        return AppColors.primary;
      }
      return AppColors.white;
    }),
    trackColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.disabled)) {
        return AppColors.gray200;
      }
      if (states.contains(MaterialState.selected)) {
        return AppColors.primaryExtraLight;
      }
      return AppColors.gray300;
    }),
    trackOutlineColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return AppColors.transparent;
      }
      return AppColors.gray400;
    }),
    overlayColor: MaterialStateProperty.all(AppColors.rippleLight),
    splashRadius: 20.0,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );

  static SwitchThemeData get darkSwitchTheme => SwitchThemeData(
    thumbColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.disabled)) {
        return AppColors.slate600;
      }
      if (states.contains(MaterialState.selected)) {
        return AppColors.primaryLight;
      }
      return AppColors.slate200;
    }),
    trackColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.disabled)) {
        return AppColors.slate700;
      }
      if (states.contains(MaterialState.selected)) {
        return AppColors.primaryDark;
      }
      return AppColors.slate600;
    }),
    trackOutlineColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return AppColors.transparent;
      }
      return AppColors.slate500;
    }),
    overlayColor: MaterialStateProperty.all(AppColors.rippleDark),
    splashRadius: 20.0,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );

  /// ==================== CHECKBOX THEMES ====================

  static CheckboxThemeData get lightCheckboxTheme => CheckboxThemeData(
    fillColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.disabled)) {
        return AppColors.gray200;
      }
      if (states.contains(MaterialState.selected)) {
        return AppColors.primary;
      }
      return AppColors.transparent;
    }),
    checkColor: MaterialStateProperty.all(AppColors.white),
    overlayColor: MaterialStateProperty.all(AppColors.rippleLight),
    splashRadius: 20.0,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    visualDensity: VisualDensity.standard,
    side: const BorderSide(
      color: AppColors.lightBorder,
      width: AppDimensions.borderWidth,
    ),
    shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderRadiusSM),
  );

  static CheckboxThemeData get darkCheckboxTheme => CheckboxThemeData(
    fillColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.disabled)) {
        return AppColors.slate700;
      }
      if (states.contains(MaterialState.selected)) {
        return AppColors.primaryLight;
      }
      return AppColors.transparent;
    }),
    checkColor: MaterialStateProperty.all(AppColors.black),
    overlayColor: MaterialStateProperty.all(AppColors.rippleDark),
    splashRadius: 20.0,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    visualDensity: VisualDensity.standard,
    side: const BorderSide(
      color: AppColors.darkBorder,
      width: AppDimensions.borderWidth,
    ),
    shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderRadiusSM),
  );

  /// ==================== RADIO THEMES ====================

  static RadioThemeData get lightRadioTheme => RadioThemeData(
    fillColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.disabled)) {
        return AppColors.gray300;
      }
      if (states.contains(MaterialState.selected)) {
        return AppColors.primary;
      }
      return AppColors.lightBorder;
    }),
    overlayColor: MaterialStateProperty.all(AppColors.rippleLight),
    splashRadius: 20.0,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    visualDensity: VisualDensity.standard,
  );

  static RadioThemeData get darkRadioTheme => RadioThemeData(
    fillColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.disabled)) {
        return AppColors.slate600;
      }
      if (states.contains(MaterialState.selected)) {
        return AppColors.primaryLight;
      }
      return AppColors.darkBorder;
    }),
    overlayColor: MaterialStateProperty.all(AppColors.rippleDark),
    splashRadius: 20.0,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    visualDensity: VisualDensity.standard,
  );

  /// ==================== HELPER METHODS ====================

  /// Get theme-appropriate switch theme
  static SwitchThemeData getSwitchTheme(Brightness brightness) {
    return brightness == Brightness.dark ? darkSwitchTheme : lightSwitchTheme;
  }

  /// Get theme-appropriate checkbox theme
  static CheckboxThemeData getCheckboxTheme(Brightness brightness) {
    return brightness == Brightness.dark
        ? darkCheckboxTheme
        : lightCheckboxTheme;
  }

  /// Get theme-appropriate radio theme
  static RadioThemeData getRadioTheme(Brightness brightness) {
    return brightness == Brightness.dark ? darkRadioTheme : lightRadioTheme;
  }

  /// Create custom switch theme
  static SwitchThemeData createCustomSwitchTheme({
    required Color activeThumbColor,
    required Color activeTrackColor,
    required Color inactiveThumbColor,
    required Color inactiveTrackColor,
    Brightness brightness = Brightness.light,
  }) {
    final baseTheme = getSwitchTheme(brightness);

    return baseTheme.copyWith(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.disabled)) {
          return brightness == Brightness.dark
              ? AppColors.slate600
              : AppColors.gray300;
        }
        if (states.contains(MaterialState.selected)) {
          return activeThumbColor;
        }
        return inactiveThumbColor;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.disabled)) {
          return brightness == Brightness.dark
              ? AppColors.slate700
              : AppColors.gray200;
        }
        if (states.contains(MaterialState.selected)) {
          return activeTrackColor;
        }
        return inactiveTrackColor;
      }),
    );
  }

  /// Create custom checkbox theme
  static CheckboxThemeData createCustomCheckboxTheme({
    required Color fillColor,
    required Color checkColor,
    Color? borderColor,
    Brightness brightness = Brightness.light,
  }) {
    final baseTheme = getCheckboxTheme(brightness);

    return baseTheme.copyWith(
      fillColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.disabled)) {
          return brightness == Brightness.dark
              ? AppColors.slate700
              : AppColors.gray200;
        }
        if (states.contains(MaterialState.selected)) {
          return fillColor;
        }
        return AppColors.transparent;
      }),
      checkColor: MaterialStateProperty.all(checkColor),
      side: BorderSide(
        color:
            borderColor ??
            (brightness == Brightness.dark
                ? AppColors.darkBorder
                : AppColors.lightBorder),
        width: AppDimensions.borderWidth,
      ),
    );
  }

  /// Create custom radio theme
  static RadioThemeData createCustomRadioTheme({
    required Color fillColor,
    Color? borderColor,
    Brightness brightness = Brightness.light,
  }) {
    final baseTheme = getRadioTheme(brightness);

    return baseTheme.copyWith(
      fillColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.disabled)) {
          return brightness == Brightness.dark
              ? AppColors.slate600
              : AppColors.gray300;
        }
        if (states.contains(MaterialState.selected)) {
          return fillColor;
        }
        return borderColor ??
            (brightness == Brightness.dark
                ? AppColors.darkBorder
                : AppColors.lightBorder);
      }),
    );
  }
}
