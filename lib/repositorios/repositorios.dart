import 'package:flutter/foundation.dart';

import '../modelos/modelos.dart';
import '../servicos/api_med_agenda.dart';

/// Guarda quem está logado. As telas escutam para trocar entre
/// "entrar" e o app principal.
class ContaRepositorio extends ChangeNotifier {
  ContaRepositorio(this._api);
  final ApiMedAgenda _api;

  Sessao? _sessao;
  Paciente? get paciente => _sessao?.paciente;
  bool get logado => _sessao != null;

  Future<void> entrar(String email, String senha) async {
    _sessao = await _api.entrar(email.trim(), senha);
    notifyListeners();
  }

  Future<void> cadastrar(NovoPaciente novo) async {
    _sessao = await _api.cadastrar(novo);
    notifyListeners();
  }

  void sair() {
    _sessao = null;
    _api.token = null;
    notifyListeners();
  }
}

/// Especialidades, profissionais, horários e consultas.
///
/// Avisa os ouvintes sempre que uma consulta é criada ou cancelada, para
/// o Início e a lista de consultas se atualizarem sozinhos.
class AgendaRepositorio extends ChangeNotifier {
  AgendaRepositorio(this._api);
  final ApiMedAgenda _api;

  List<Especialidade>? _especialidadesCache;

  Future<List<Especialidade>> especialidades() async =>
      _especialidadesCache ??= await _api.especialidades();

  Future<List<Medico>> medicos({String? especialidade, String? busca, bool soTeleconsulta = false, String ordem = 'nota', int? limite}) =>
      _api.medicos(especialidade: especialidade, busca: busca, soTeleconsulta: soTeleconsulta, ordem: ordem, limite: limite);

  Future<Medico> medico(String id) => _api.medico(id);

  Future<List<DiaAgenda>> horarios(String medicoId, DateTime inicio, {int dias = 7}) =>
      _api.horarios(medicoId, inicio, dias: dias);

  Future<List<Consulta>> proximas() => _api.consultas('proximas');
  Future<List<Consulta>> anteriores() => _api.consultas('anteriores');

  Future<Consulta> agendar({required String medicoId, required DateTime inicio, required Modalidade modalidade, String? motivo}) async {
    final c = await _api.agendar(medicoId: medicoId, inicio: inicio, modalidade: modalidade, motivo: motivo);
    notifyListeners();
    return c;
  }

  Future<Consulta> cancelar(String id) async {
    final c = await _api.cancelar(id);
    notifyListeners();
    return c;
  }
}
