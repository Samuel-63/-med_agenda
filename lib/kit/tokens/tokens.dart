import 'package:flutter/material.dart';

/// Tokens do design system "Kit MedAgenda".
///
/// Paleta índigo + coral, cantos arredondados grandes e sombras suaves.
/// Nenhuma tela usa cor, espaço ou raio "solto": tudo sai daqui.
abstract final class Paleta {
  static const indigo = Color(0xFF3B4CCA);
  static const indigoEscuro = Color(0xFF26318A);
  static const indigoSuave = Color(0xFFE9EBFB);

  static const coral = Color(0xFFFF7A59);
  static const coralSuave = Color(0xFFFFEDE7);

  static const fundo = Color(0xFFF5F6FB);
  static const superficie = Color(0xFFFFFFFF);
  static const borda = Color(0xFFE1E3EE);

  static const tinta = Color(0xFF1B1E33);
  static const tintaSuave = Color(0xFF666A82);
  static const tintaApagada = Color(0xFFA6A9BC);

  static const verde = Color(0xFF17956A);
  static const verdeSuave = Color(0xFFE2F5EC);
  static const vermelho = Color(0xFFD23F4A);
  static const vermelhoSuave = Color(0xFFFCE7E8);
  static const ambar = Color(0xFFC98A00);
  static const ambarSuave = Color(0xFFFFF4D9);

  static const gradienteTopo = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [indigo, indigoEscuro],
  );
}

abstract final class Espaco {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

abstract final class Raio {
  static const pequeno = 10.0;
  static const medio = 16.0;
  static const grande = 24.0;
  static const pilula = 999.0;

  static BorderRadius get p => BorderRadius.circular(pequeno);
  static BorderRadius get m => BorderRadius.circular(medio);
  static BorderRadius get g => BorderRadius.circular(grande);
}

abstract final class Sombra {
  static const leve = [
    BoxShadow(color: Color(0x141B1E33), blurRadius: 18, offset: Offset(0, 6)),
  ];
}

abstract final class Tipo {
  // Roboto no Android e na web; no iOS cai na fonte do sistema.
  static const _familia = 'Roboto';

  static const display = TextStyle(fontFamily: _familia, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.6, color: Paleta.tinta, height: 1.15);
  static const titulo = TextStyle(fontFamily: _familia, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: Paleta.tinta);
  static const subtitulo = TextStyle(fontFamily: _familia, fontSize: 16, fontWeight: FontWeight.w700, color: Paleta.tinta);
  static const corpo = TextStyle(fontFamily: _familia, fontSize: 15, fontWeight: FontWeight.w400, color: Paleta.tinta, height: 1.4);
  static const apoio = TextStyle(fontFamily: _familia, fontSize: 13, fontWeight: FontWeight.w500, color: Paleta.tintaSuave);
  static const rotulo = TextStyle(fontFamily: _familia, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: Paleta.tintaSuave);
  static const botao = TextStyle(fontFamily: _familia, fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.2);
}

/// Tema Material 3 montado em cima dos tokens.
ThemeData temaMedAgenda() {
  final esquema = ColorScheme.fromSeed(
    seedColor: Paleta.indigo,
    primary: Paleta.indigo,
    secondary: Paleta.coral,
    surface: Paleta.superficie,
    error: Paleta.vermelho,
  );
  final contorno = OutlineInputBorder(borderRadius: Raio.p, borderSide: const BorderSide(color: Paleta.borda));
  return ThemeData(
    useMaterial3: true,
    colorScheme: esquema,
    scaffoldBackgroundColor: Paleta.fundo,
    appBarTheme: const AppBarTheme(
      backgroundColor: Paleta.fundo,
      foregroundColor: Paleta.tinta,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: Tipo.titulo,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Paleta.superficie,
      contentPadding: const EdgeInsets.symmetric(horizontal: Espaco.l, vertical: 14),
      border: contorno,
      enabledBorder: contorno,
      focusedBorder: contorno.copyWith(borderSide: const BorderSide(color: Paleta.indigo, width: 1.6)),
      errorBorder: contorno.copyWith(borderSide: const BorderSide(color: Paleta.vermelho)),
      focusedErrorBorder: contorno.copyWith(borderSide: const BorderSide(color: Paleta.vermelho, width: 1.6)),
      labelStyle: Tipo.apoio,
      prefixIconColor: Paleta.tintaSuave,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Paleta.superficie,
      indicatorColor: Paleta.coralSuave,
      elevation: 0,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontSize: 12,
          fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          color: s.contains(WidgetState.selected) ? Paleta.coral : Paleta.tintaSuave,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(color: s.contains(WidgetState.selected) ? Paleta.coral : Paleta.tintaSuave),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Paleta.tinta,
      shape: RoundedRectangleBorder(borderRadius: Raio.p),
    ),
    dividerTheme: const DividerThemeData(color: Paleta.borda, space: 1),
  );
}
