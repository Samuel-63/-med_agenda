import 'package:flutter/material.dart';

import 'kit/kit.dart';
import 'telas/catalogo/catalogo_page.dart';

/// Abre direto o catálogo do design system:
/// flutter run -t lib/main_catalogo.dart
void main() {
  runApp(MaterialApp(
    title: 'Kit MedAgenda',
    debugShowCheckedModeBanner: false,
    theme: temaMedAgenda(),
    home: const CatalogoPage(),
  ));
}
