import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Carrega Roboto e os ícones do Material que vêm com o Flutter SDK, para
/// que os testes meçam o texto como no aparelho (a fonte padrão dos testes
/// é bem mais larga e gera "overflows" que não existem de verdade).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final raiz = Platform.environment['FLUTTER_ROOT'];
  if (raiz != null) {
    final pasta = '$raiz/bin/cache/artifacts/material_fonts';
    Future<ByteData> ler(String nome) async => ByteData.sublistView(await File('$pasta/$nome').readAsBytes());
    // "FlutterTest" é a família usada quando o estilo não define fonte.
    for (final familia in ['Roboto', 'FlutterTest']) {
      final loader = FontLoader(familia);
      for (final f in ['roboto-regular.ttf', 'roboto-medium.ttf', 'roboto-bold.ttf', 'roboto-black.ttf', 'roboto-italic.ttf']) {
        if (File('$pasta/$f').existsSync()) loader.addFont(ler(f));
      }
      await loader.load();
    }
    if (File('$pasta/materialicons-regular.otf').existsSync()) {
      await (FontLoader('MaterialIcons')..addFont(ler('materialicons-regular.otf'))).load();
    }
  }
  await testMain();
}
