import 'package:flutter/foundation.dart';

import '../../repositorios/repositorios.dart';
import '../../servicos/api_med_agenda.dart';
import '../../util/estado.dart';
import '../../util/validacao.dart';

/// ViewModel da tela Entrar.
class EntrarController extends ChangeNotifier {
  EntrarController(this._conta);
  final ContaRepositorio _conta;

  static const emailDemo = 'lucas@medagenda.app';
  static const senhaDemo = 'senha123';

  String email = '';
  String senha = '';
  String? erroEmail;
  String? erroSenha;
  String? falha;
  bool enviando = false;

  bool get podeEnviar => email.trim().isNotEmpty && senha.isNotEmpty && !enviando;

  void mudarEmail(String v) {
    email = v;
    erroEmail = null;
    falha = null;
    notifyListeners();
  }

  void mudarSenha(String v) {
    senha = v;
    erroSenha = null;
    falha = null;
    notifyListeners();
  }

  /// Devolve true quando entrou. A troca de tela é feita pelo portão de sessão.
  Future<bool> entrar() async {
    erroEmail = Validacao.email(email);
    erroSenha = senha.isEmpty ? 'Informe sua senha.' : null;
    falha = null;
    if (erroEmail != null || erroSenha != null) {
      notifyListeners();
      return false;
    }
    enviando = true;
    notifyListeners();
    try {
      await _conta.entrar(email, senha);
      return true;
    } on FalhaApi catch (e) {
      erroEmail = e.campos['email'];
      erroSenha = e.campos['senha'];
      falha = e.campos.isEmpty ? e.mensagem : null;
      return false;
    } catch (e) {
      falha = mensagemDe(e);
      return false;
    } finally {
      enviando = false;
      notifyListeners();
    }
  }
}
