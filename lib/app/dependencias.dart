import 'package:flutter/widgets.dart';

import '../repositorios/repositorios.dart';

/// Injeção de dependências simples, sem pacotes: um InheritedWidget
/// no topo da árvore entrega os repositórios e o relógio às telas.
class Dependencias extends InheritedWidget {
  const Dependencias({
    super.key,
    required this.conta,
    required this.agenda,
    required this.relogio,
    required super.child,
  });

  final ContaRepositorio conta;
  final AgendaRepositorio agenda;

  /// "Agora". Nos testes é fixo; no app é DateTime.now.
  final DateTime Function() relogio;

  static Dependencias of(BuildContext context) {
    final d = context.getInheritedWidgetOfExactType<Dependencias>();
    assert(d != null, 'Dependencias não encontrado na árvore.');
    return d!;
  }

  @override
  bool updateShouldNotify(Dependencias oldWidget) =>
      conta != oldWidget.conta || agenda != oldWidget.agenda;
}
