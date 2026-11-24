import 'package:flutter/services.dart';

/// Regras de validação compartilhadas entre os controllers e o backend falso.
/// Cada função devolve `null` quando o valor é válido ou a mensagem de erro.
class Validacao {
  Validacao._();

  static final _email = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

  static String soDigitos(String v) => v.replaceAll(RegExp(r'\D'), '');

  static String? nome(String v) {
    final t = v.trim();
    if (t.isEmpty) return 'Informe seu nome.';
    if (!t.contains(' ')) return 'Informe nome e sobrenome.';
    return null;
  }

  static String? email(String v) {
    final t = v.trim();
    if (t.isEmpty) return 'Informe seu e-mail.';
    if (!_email.hasMatch(t)) return 'E-mail em formato inválido.';
    return null;
  }

  static String? celular(String v) {
    final d = soDigitos(v);
    if (d.isEmpty) return 'Informe seu celular.';
    if (d.length != 11 || d[2] != '9') return 'Use DDD + 9 dígitos.';
    return null;
  }

  static String? senha(String v) {
    if (v.isEmpty) return 'Crie uma senha.';
    if (v.length < 8) return 'Mínimo de 8 caracteres.';
    if (!RegExp(r'\d').hasMatch(v)) return 'Inclua pelo menos um número.';
    return null;
  }

  static String? nascimento(DateTime? d, DateTime hoje) {
    if (d == null) return 'Informe a data de nascimento.';
    if (d.isAfter(hoje)) return 'Data no futuro.';
    return null;
  }

  /// Força da senha de 0 a 4, usada na barrinha do cadastro.
  static int forcaSenha(String v) {
    var pontos = 0;
    if (v.length >= 8) pontos++;
    if (v.length >= 12) pontos++;
    if (RegExp(r'\d').hasMatch(v) && RegExp(r'[A-Za-z]').hasMatch(v)) pontos++;
    if (RegExp(r'[A-Z]').hasMatch(v) && RegExp(r'[^\w]').hasMatch(v)) pontos++;
    return pontos;
  }
}

/// Máscara "(62) 99123-4567" aplicada enquanto o usuário digita.
class MascaraCelular extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue antigo, TextEditingValue novo) {
    final d = Validacao.soDigitos(novo.text);
    final digitos = d.length > 11 ? d.substring(0, 11) : d;
    final b = StringBuffer();
    for (var i = 0; i < digitos.length; i++) {
      if (i == 0) b.write('(');
      if (i == 2) b.write(') ');
      if (i == 7) b.write('-');
      b.write(digitos[i]);
    }
    final texto = b.toString();
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }

  static String formatar(String digitos) =>
      MascaraCelular().formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: digitos)).text;
}
