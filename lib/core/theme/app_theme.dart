import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

/// Gerenciador de Temas do Aplicativo
/// Utiliza o [FlexColorScheme] para gerar temas Material 3 harmoniosos.
class AppTheme {
  // Impede a instanciação desta classe. Usaremos apenas métodos estáticos.
  AppTheme._();

  /// Define qual paleta base vamos usar (ex: Dracula, Tokyo Night, etc).
  /// Você pode facilmente trocar isso mudando o valor abaixo.
  static const FlexScheme _currentScheme = FlexScheme.dracula; // Ou FlexScheme.tokyoNight

  /// Tema Claro
  static ThemeData get lightTheme {
    return FlexThemeData.light(
      scheme: _currentScheme,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 7,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 10,
        blendOnColors: false,
        useTextTheme: true,
        useM2StyleDividerInM3: true,
        alignedDropdown: true,
        useInputDecoratorThemeInDialogs: true,
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
      swapLegacyOnMaterial3: true,
    );
  }

  /// Tema Escuro
  static ThemeData get darkTheme {
    return FlexThemeData.dark(
      scheme: _currentScheme,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 13,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 20,
        useTextTheme: true,
        useM2StyleDividerInM3: true,
        alignedDropdown: true,
        useInputDecoratorThemeInDialogs: true,
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
      swapLegacyOnMaterial3: true,
    );
  }
}
