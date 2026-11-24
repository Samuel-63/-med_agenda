import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../modelos/modelos.dart';
import '../../repositorios/repositorios.dart';
import '../../util/estado.dart';

enum Ordem {
  nota('Melhor avaliados'),
  valor('Menor valor'),
  nome('Nome (A-Z)');

  const Ordem(this.rotulo);
  final String rotulo;
}

/// ViewModel da Busca: texto (com espera de 350 ms), especialidade,
/// só teleconsulta e ordenação.
class BuscarController extends ChangeNotifier {
  BuscarController(this._agenda, {this.espera = const Duration(milliseconds: 350)}) {
    _carregarEspecialidades();
    buscar();
  }

  final AgendaRepositorio _agenda;
  final Duration espera;

  List<Especialidade> especialidades = const [];
  String texto = '';
  String? especialidadeId;
  bool soTeleconsulta = false;
  Ordem ordem = Ordem.nota;
  Estado<List<Medico>> resultado = const Carregando();

  Timer? _timer;
  int _pedido = 0; // descarta respostas de buscas antigas
  bool _vivo = true;

  bool get temFiltros => especialidadeId != null || soTeleconsulta || texto.isNotEmpty;

  Future<void> _carregarEspecialidades() async {
    try {
      especialidades = await _agenda.especialidades();
      if (_vivo) notifyListeners();
    } catch (_) {/* a lista de chips só não aparece */}
  }

  void mudarTexto(String v) {
    texto = v;
    _timer?.cancel();
    _timer = Timer(espera, buscar);
    notifyListeners();
  }

  void filtrarEspecialidade(String? id) {
    especialidadeId = id;
    buscar();
  }

  void alternarTeleconsulta() {
    soTeleconsulta = !soTeleconsulta;
    buscar();
  }

  void ordenarPor(Ordem o) {
    ordem = o;
    buscar();
  }

  void limpar() {
    texto = '';
    especialidadeId = null;
    soTeleconsulta = false;
    buscar();
  }

  Future<void> buscar() async {
    _timer?.cancel();
    final meu = ++_pedido;
    resultado = const Carregando();
    notifyListeners();
    try {
      final lista = await _agenda.medicos(
        especialidade: especialidadeId,
        busca: texto,
        soTeleconsulta: soTeleconsulta,
        ordem: ordem.name,
      );
      if (meu != _pedido || !_vivo) return;
      resultado = Pronto(lista);
    } catch (e) {
      if (meu != _pedido || !_vivo) return;
      resultado = ComFalha(mensagemDe(e));
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _vivo = false;
    _timer?.cancel();
    super.dispose();
  }
}
