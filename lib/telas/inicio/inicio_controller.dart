import 'package:flutter/foundation.dart';

import '../../modelos/modelos.dart';
import '../../repositorios/repositorios.dart';
import '../../util/estado.dart';

/// Tudo que o Início mostra, carregado de uma vez.
class PainelInicio {
  const PainelInicio({required this.especialidades, required this.proxima, required this.totalAgendadas, required this.destaques});
  final List<Especialidade> especialidades;
  final Consulta? proxima;
  final int totalAgendadas;
  final List<Medico> destaques;
}

/// ViewModel do Início. Recarrega sozinho quando uma consulta muda.
class InicioController extends ChangeNotifier {
  InicioController(this._agenda) {
    _agenda.addListener(carregar);
    carregar();
  }

  final AgendaRepositorio _agenda;
  Estado<PainelInicio> estado = const Carregando();

  Future<void> carregar() async {
    if (estado is! Pronto) {
      estado = const Carregando();
      notifyListeners();
    }
    try {
      final r = await Future.wait([
        _agenda.especialidades(),
        _agenda.proximas(),
        _agenda.medicos(ordem: 'nota', limite: 5),
      ]);
      final proximas = r[1] as List<Consulta>;
      estado = Pronto(PainelInicio(
        especialidades: r[0] as List<Especialidade>,
        proxima: proximas.firstOrNull,
        totalAgendadas: proximas.length,
        destaques: r[2] as List<Medico>,
      ));
    } catch (e) {
      estado = ComFalha(mensagemDe(e));
    }
    if (_vivo) notifyListeners();
  }

  bool _vivo = true;

  @override
  void dispose() {
    _vivo = false;
    _agenda.removeListener(carregar);
    super.dispose();
  }
}
