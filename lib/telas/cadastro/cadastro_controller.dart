import 'package:flutter/foundation.dart';

import '../../modelos/modelos.dart';
import '../../repositorios/repositorios.dart';
import '../../servicos/api_med_agenda.dart';
import '../../util/estado.dart';
import '../../util/validacao.dart';

/// ViewModel do Cadastro. Valida no app (para resposta imediata) e também
/// mostra os erros por campo que vierem da API.
class CadastroController extends ChangeNotifier {
  CadastroController(this._conta, this._relogio);
  final ContaRepositorio _conta;
  final DateTime Function() _relogio;

  String nome = '';
  String email = '';
  String celular = '';
  DateTime? nascimento;
  String senha = '';
  String confirmacao = '';
  bool aceitouTermos = false;

  Map<String, String> erros = {};
  String? falha;
  bool enviando = false;

  int get forcaSenha => Validacao.forcaSenha(senha);

  void mudar(String campo, Object? valor) {
    switch (campo) {
      case 'nome':
        nome = valor as String;
      case 'email':
        email = valor as String;
      case 'celular':
        celular = valor as String;
      case 'nascimento':
        nascimento = valor as DateTime?;
      case 'senha':
        senha = valor as String;
      case 'confirmacao':
        confirmacao = valor as String;
      case 'termos':
        aceitouTermos = valor as bool;
    }
    erros = Map.of(erros)..remove(campo);
    falha = null;
    notifyListeners();
  }

  Map<String, String> _validar() {
    final e = <String, String>{};
    void checa(String campo, String? erro) {
      if (erro != null) e[campo] = erro;
    }

    checa('nome', Validacao.nome(nome));
    checa('email', Validacao.email(email));
    checa('celular', Validacao.celular(celular));
    checa('nascimento', Validacao.nascimento(nascimento, _relogio()));
    checa('senha', Validacao.senha(senha));
    if (confirmacao != senha) e['confirmacao'] = 'As senhas não são iguais.';
    if (!aceitouTermos) e['termos'] = 'Aceite os termos para continuar.';
    return e;
  }

  Future<bool> enviar() async {
    erros = _validar();
    falha = null;
    if (erros.isNotEmpty) {
      notifyListeners();
      return false;
    }
    enviando = true;
    notifyListeners();
    try {
      await _conta.cadastrar(NovoPaciente(
        nome: nome,
        email: email,
        celular: Validacao.soDigitos(celular),
        nascimento: nascimento,
        senha: senha,
      ));
      return true;
    } on FalhaApi catch (e) {
      erros = e.campos;
      falha = e.mensagem;
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
