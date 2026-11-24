import '../servicos/api_med_agenda.dart';

/// Estado de algo que vem da API: carregando, pronto ou com falha.
sealed class Estado<T> {
  const Estado();
}

class Carregando<T> extends Estado<T> {
  const Carregando();
}

class Pronto<T> extends Estado<T> {
  const Pronto(this.dado);
  final T dado;
}

class ComFalha<T> extends Estado<T> {
  const ComFalha(this.mensagem);
  final String mensagem;
}

/// Mensagem amigável para qualquer erro (FalhaApi ou inesperado).
String mensagemDe(Object erro) =>
    erro is FalhaApi ? erro.mensagem : 'Algo deu errado. Verifique sua conexão e tente de novo.';
