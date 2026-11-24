import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../kit/kit.dart';
import '../telas/cadastro/cadastro_page.dart';
import '../telas/catalogo/catalogo_page.dart';
import '../telas/entrar/entrar_page.dart';
import '../telas/medico/medico_page.dart';
import '../telas/shell/shell_page.dart';
import 'dependencias.dart';

abstract final class Rotas {
  static const cadastro = '/cadastro';
  static const medico = '/medico'; // argumento: id do profissional
  static const catalogo = '/catalogo';
}

class MedAgendaApp extends StatelessWidget {
  const MedAgendaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MedAgenda',
      debugShowCheckedModeBanner: false,
      theme: temaMedAgenda(),
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const _Portao(),
      onGenerateRoute: (s) => MaterialPageRoute(
        settings: s,
        builder: (_) => switch (s.name) {
          Rotas.cadastro => const CadastroPage(),
          Rotas.medico => MedicoPage(medicoId: s.arguments! as String),
          Rotas.catalogo => const CatalogoPage(),
          _ => const _Portao(),
        },
      ),
    );
  }
}

/// Mostra "Entrar" ou o app logado, conforme a sessão.
class _Portao extends StatelessWidget {
  const _Portao();

  @override
  Widget build(BuildContext context) {
    final conta = Dependencias.of(context).conta;
    return ListenableBuilder(
      listenable: conta,
      builder: (context, _) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: conta.logado ? const ShellPage(key: ValueKey('shell')) : const EntrarPage(key: ValueKey('entrar')),
      ),
    );
  }
}
