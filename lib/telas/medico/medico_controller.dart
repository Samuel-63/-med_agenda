import 'package:flutter/foundation.dart';

import '../../modelos/modelos.dart';
import '../../repositorios/repositorios.dart';
import '../../servicos/api_med_agenda.dart';
import '../../util/datas.dart';
import '../../util/estado.dart';

/// Resultado de uma tentativa de agendamento.
sealed class ResultadoAgendamento {
  const ResultadoAgendamento();
}

class Agendou extends ResultadoAgendamento {
  const Agendou(this.consulta);
  final Consulta consulta;
}

class NaoAgendou extends ResultadoAgendamento {
  const NaoAgendou(this.mensagem);
  final String mensagem;
}

/// ViewModel do perfil do profissional + agenda semanal.
class MedicoController extends ChangeNotifier {
  MedicoController(this._agenda, this.medicoId, this._relogio) {
    _hoje = Datas.soData(_relogio());
    inicioSemana = _hoje;
    _carregarMedico();
    carregarSemana();
  }

  final AgendaRepositorio _agenda;
  final String medicoId;
  final DateTime Function() _relogio;
  late final DateTime _hoje;

  Estado<Medico> medico = const Carregando();
  Estado<List<DiaAgenda>> semana = const Carregando();
  late DateTime inicioSemana;
  DateTime? dia;
  String? hora;
  Modalidade modalidade = Modalidade.presencial;
  String motivo = '';
  bool agendando = false;
  bool _vivo = true;

  static const maxSemanasAFrente = 6;

  bool get podeVoltarSemana => inicioSemana.isAfter(_hoje);
  bool get podeAvancarSemana => inicioSemana.difference(_hoje).inDays < 7 * (maxSemanasAFrente - 1);
  bool get podeAgendar => dia != null && hora != null && !agendando;

  DiaAgenda? get diaSelecionado => switch (semana) {
        Pronto(:final dado) => dado.where((d) => dia != null && Datas.mesmoDia(d.data, dia!)).firstOrNull,
        _ => null,
      };

  DateTime? get inicioEscolhido {
    if (dia == null || hora == null) return null;
    return DateTime(dia!.year, dia!.month, dia!.day, int.parse(hora!.substring(0, 2)), int.parse(hora!.substring(3)));
  }

  void _avisar() {
    if (_vivo) notifyListeners();
  }

  Future<void> _carregarMedico() async {
    try {
      medico = Pronto(await _agenda.medico(medicoId));
    } catch (e) {
      medico = ComFalha(mensagemDe(e));
    }
    _avisar();
  }

  Future<void> tentarDeNovo() async {
    if (medico is ComFalha) {
      medico = const Carregando();
      _avisar();
      await _carregarMedico();
    }
    await carregarSemana();
  }

  /// Carrega os 7 dias a partir de [inicioSemana]. Se [manterEscolha] for
  /// falso, seleciona automaticamente o primeiro dia com vaga.
  Future<void> carregarSemana({bool manterEscolha = false}) async {
    semana = const Carregando();
    if (!manterEscolha) {
      dia = null;
      hora = null;
    }
    _avisar();
    try {
      final dias = await _agenda.horarios(medicoId, inicioSemana);
      semana = Pronto(dias);
      if (dia == null) {
        dia = dias.where((d) => d.temVaga).firstOrNull?.data;
      } else if (hora != null) {
        // se o horário escolhido deixou de estar livre, desmarca
        final h = diaSelecionado?.horarios.where((h) => h.hora == hora).firstOrNull;
        if (h == null || !h.livre) hora = null;
      }
    } catch (e) {
      semana = ComFalha(mensagemDe(e));
    }
    _avisar();
  }

  void mudarSemana(int passo) {
    if (passo < 0 && !podeVoltarSemana) return;
    if (passo > 0 && !podeAvancarSemana) return;
    final novo = inicioSemana.add(Duration(days: 7 * passo));
    inicioSemana = novo.isBefore(_hoje) ? _hoje : novo;
    carregarSemana();
  }

  void escolherDia(DateTime d) {
    dia = d;
    hora = null;
    _avisar();
  }

  void escolherHora(String h) {
    hora = hora == h ? null : h;
    _avisar();
  }

  void escolherModalidade(Modalidade m) {
    modalidade = m;
    _avisar();
  }

  void mudarMotivo(String v) => motivo = v;

  Future<ResultadoAgendamento> agendar() async {
    final inicio = inicioEscolhido;
    if (inicio == null) return const NaoAgendou('Escolha um dia e um horário.');
    agendando = true;
    _avisar();
    try {
      final c = await _agenda.agendar(medicoId: medicoId, inicio: inicio, modalidade: modalidade, motivo: motivo);
      return Agendou(c);
    } on FalhaApi catch (e) {
      if (e.status == 409 || e.codigo == 'HORARIO_PASSADO') {
        // a agenda mudou: recarrega para mostrar a situação atual
        hora = null;
        await carregarSemana(manterEscolha: true);
      }
      return NaoAgendou(e.mensagem);
    } catch (e) {
      return NaoAgendou(mensagemDe(e));
    } finally {
      agendando = false;
      _avisar();
    }
  }

  @override
  void dispose() {
    _vivo = false;
    super.dispose();
  }
}
