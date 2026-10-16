import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:material_ui/material_ui.dart';

/// Gerenciador de Temas do Aplicativo
/// Utiliza o [FlexColorScheme] para gerar temas Material 3 harmoniosos.
class AppTheme {
  // Impede a instanciação desta classe. Usaremos apenas métodos estáticos.
  AppTheme._();

  /// Define qual paleta base vamos usar (ex: Dracula, Tokyo Night, etc).
  /// Você pode facilmente trocar isso mudando o valor abaixo.
  static const FlexScheme _currentScheme = FlexScheme.indigo; // Ou FlexScheme.tokyoNight

  /// Fonte padrão do aplicativo ('ProductSans' ou 'PlusJakartaSans').
  static const String fontFamily = 'ProductSans';

  static ThemeData get lightTheme {
    return FlexThemeData.light(
      scheme: _currentScheme,
      fontFamily: fontFamily,
    );
  }

  /// Tema Escuro
  static ThemeData get darkTheme {
    return FlexThemeData.dark(
      scheme: _currentScheme,
      fontFamily: fontFamily,
    );
  }
}
