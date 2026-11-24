import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_agenda/kit/kit.dart';

import 'apoio.dart';

void main() {
  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 2.75;
  });

  testWidgets('erro de login aparece e a conta demo entra no Início', (t) async {
    final amb = Ambiente();
    await t.pumpWidget(amb.app());
    await t.pumpAndSettle();

    await t.enterText(find.byKey(const Key('campo-email')).last, 'lucas@medagenda.app');
    await t.enterText(find.byType(TextField).at(1), 'errada1');
    await t.pump();
    await t.tap(find.widgetWithText(MaBotao, 'Entrar'));
    await t.pumpAndSettle();
    expect(find.text('E-mail ou senha não conferem.'), findsOneWidget);

    await t.tap(find.text('Preencher conta de demonstração'));
    await t.pump();
    await t.tap(find.widgetWithText(MaBotao, 'Entrar'));
    await t.pumpAndSettle();

    expect(find.text('Lucas'), findsOneWidget);
    expect(find.text('Dra. Patrícia Nunes'), findsWidgets);
    expect(find.text('Especialidades'), findsOneWidget);
  });

  testWidgets('agendar pela busca e cancelar em Consultas', (t) async {
    final amb = Ambiente();
    await amb.logar();
    await t.pumpWidget(amb.app());
    await t.pumpAndSettle();

    // Início -> especialidade "Clínico geral" abre a busca filtrada
    await t.tap(find.text('Clínico geral').first);
    await t.pumpAndSettle();
    expect(find.text('1 profissional'), findsOneWidget);

    await t.tap(find.text('Dr. Fernando Batista'));
    await t.pumpAndSettle();
    expect(find.text('Agenda'), findsOneWidget);

    // escolhe um dia depois de hoje (cancelamento exige 2 h de antecedência)
    final amanhaEmDiante = find.byWidgetPredicate((w) => w is MaDiaSemana && w.atende && w.temVaga && w.data.day != agoraFixo.day);
    await t.tap(amanhaEmDiante.first);
    await t.pump();

    // primeiro horário livre do dia escolhido
    final livre = find.byWidgetPredicate((w) => w is MaHorario && w.livre).first;
    final hora = (t.widget(livre) as MaHorario).hora;
    await t.ensureVisible(livre);
    await t.tap(livre);
    await t.pump();

    await t.tap(find.widgetWithText(MaBotao, 'Agendar'));
    await t.pumpAndSettle();
    await t.tap(find.widgetWithText(MaBotao, 'Confirmar'));
    await t.pumpAndSettle();
    expect(find.textContaining('Consulta marcada'), findsOneWidget);

    // aba Consultas mostra a nova consulta
    await t.tap(find.text('Consultas'));
    await t.pumpAndSettle();
    expect(find.text('Dr. Fernando Batista'), findsOneWidget);
    expect(find.text(hora), findsOneWidget);

    final cartao = find.ancestor(of: find.text('Dr. Fernando Batista'), matching: find.byType(MaCartaoConsulta));
    await t.tap(find.descendant(of: cartao, matching: find.widgetWithText(MaBotao, 'Cancelar')));
    await t.pumpAndSettle();
    await t.tap(find.widgetWithText(MaBotao, 'Sim, cancelar'));
    await t.pumpAndSettle();

    expect(find.text('Consulta cancelada.'), findsOneWidget);
    expect(find.text('Dr. Fernando Batista'), findsNothing);

    await t.tap(find.text('Histórico'));
    await t.pumpAndSettle();
    expect(find.text('Dr. Fernando Batista'), findsWidgets);
  });

  testWidgets('catálogo do design system abre sem erros', (t) async {
    final amb = Ambiente();
    await amb.logar();
    await t.pumpWidget(amb.app());
    await t.pumpAndSettle();
    await t.tap(find.text('Perfil'));
    await t.pumpAndSettle();
    await t.tap(find.text('Catálogo de componentes'));
    await t.pumpAndSettle();
    expect(find.text('Kit MedAgenda'), findsOneWidget);
    await t.scrollUntilVisible(find.text('Diálogos'), 400, scrollable: find.byType(Scrollable).first);
    expect(find.text('Diálogos'), findsOneWidget);
  });
}
