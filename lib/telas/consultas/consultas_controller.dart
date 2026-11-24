import 'package:flutter/foundation.dart';

import '../../modelos/modelos.dart';
import '../../repositorios/repositorios.dart';
import '../../util/estado.dart';

enum Aba { proximas, anteriores }

/// ViewModel de "Minhas consultas" (próximas e histórico na mesma tela).
class ConsultasController extends ChangeNotifier {
  ConsultasController(this._agenda) {
    _agenda.addListener(_aoMudarAgenda);
    carregar();
  }

  final AgendaRepositorio _agenda;
  Aba aba = Aba.proximas;
  Estado<List<Consulta>> lista = const Carregando();
  final Set<String> cancelando = {};
  bool _vivo = true;

  void _aoMudarAgenda() => carregar(silencioso: true);

  void trocarAba(Aba nova) {
    if (nova == aba) return;
    aba = nova;
    carregar();
  }

  Future<void> carregar({bool silencioso = false}) async {
    final pedida = aba;
    if (!silencioso || lista is! Pronto) {
      lista = const Carregando();
      notifyListeners();
    }
    try {
      final r = pedida == Aba.proximas ? await _agenda.proximas() : await _agenda.anteriores();
      if (pedida != aba || !_vivo) return;
      lista = Pronto(r);
    } catch (e) {
      if (pedida != aba || !_vivo) return;
      lista = ComFalha(mensagemDe(e));
    }
    notifyListeners();
  }

  /// Devolve null em caso de sucesso, ou a mensagem de erro.
  Future<String?> cancelar(String id) async {
    cancelando.add(id);
    notifyListeners();
    try {
      await _agenda.cancelar(id); // o repositório avisa e a lista recarrega
      return null;
    } catch (e) {
      return mensagemDe(e);
    } finally {
      cancelando.remove(id);
      if (_vivo) notifyListeners();
    }
  }

  @override
  void dispose() {
    _vivo = false;
    _agenda.removeListener(_aoMudarAgenda);
    super.dispose();
  }
}
