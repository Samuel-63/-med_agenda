// Gera as imagens de docs/telas usadas no README.
// flutter test capturas --update-goldens
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_agenda/kit/kit.dart';

import '../test/apoio.dart';

void main() {
  setUp(() {
    final v = TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher.views.first;
    v
      ..physicalSize = const Size(780, 1688)
      ..devicePixelRatio = 2;
  });

  Future<Ambiente> abrir(WidgetTester t, {bool logado = true}) async {
    final amb = Ambiente();
    if (logado) await amb.logar();
    await t.pumpWidget(amb.app());
    await t.pumpAndSettle();
    return amb;
  }

  Future<void> foto(String nome) => expectLater(find.byType(MaterialApp), matchesGoldenFile('../docs/telas/$nome.png'));

  testWidgets('01 entrar', (t) async {
    await abrir(t, logado: false);
    await foto('01_entrar');
  });

  testWidgets('02 cadastro', (t) async {
    await abrir(t, logado: false);
    await t.tap(find.text('Criar conta'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField).at(0), 'Beatriz');
    await t.enterText(find.byType(TextField).at(4), 'abc123');
    await t.pump();
    await t.scrollUntilVisible(find.text('Criar minha conta'), 300, scrollable: find.byType(Scrollable).first);
    await t.tap(find.text('Criar minha conta'));
    await t.pumpAndSettle();
    await t.drag(find.byType(ListView), const Offset(0, 3000));
    await t.pumpAndSettle();
    await foto('02_cadastro');
  });

  testWidgets('03 inicio', (t) async {
    await abrir(t);
    await foto('03_inicio');
  });

  testWidgets('04 buscar', (t) async {
    await abrir(t);
    await t.tap(find.widgetWithText(MaBlocoEspecialidade, 'Cardiologia'));
    await t.pumpAndSettle();
    await foto('04_buscar');
  });

  testWidgets('05 medico', (t) async {
    await abrir(t);
    await t.tap(find.text('Buscar'));
    await t.pumpAndSettle();
    await t.tap(find.text('Dr. Fernando Batista'));
    await t.pumpAndSettle();
    await t.tap(find.byWidgetPredicate((w) => w is MaDiaSemana && w.data.day == 25));
    await t.pump();
    await t.tap(find.byWidgetPredicate((w) => w is MaHorario && w.livre).at(2));
    await t.pumpAndSettle();
    await t.drag(find.byType(CustomScrollView), const Offset(0, -260));
    await t.pumpAndSettle();
    await foto('05_medico_agenda');
  });

  testWidgets('06 consultas', (t) async {
    await abrir(t);
    await t.tap(find.text('Consultas'));
    await t.pumpAndSettle();
    await foto('06_consultas');
    await t.tap(find.text('Histórico'));
    await t.pumpAndSettle();
    await foto('07_historico');
  });

  testWidgets('08 perfil', (t) async {
    await abrir(t);
    await t.tap(find.text('Perfil'));
    await t.pumpAndSettle();
    await foto('08_perfil');
  });

  testWidgets('09 catalogo', (t) async {
    await abrir(t);
    await t.tap(find.text('Perfil'));
    await t.pumpAndSettle();
    await t.tap(find.text('Catálogo de componentes'));
    await t.pumpAndSettle();
    await foto('09_catalogo');
  });
}
