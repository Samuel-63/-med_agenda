import '../modelos/modelos.dart';
import '../util/datas.dart';
import 'transporte.dart';

/// Erro devolvido pela API (ver "Formato de erro" em docs/API.md).
class FalhaApi implements Exception {
  const FalhaApi(this.status, this.codigo, this.mensagem, [this.campos = const {}]);

  final int status;
  final String codigo;
  final String mensagem;
  final Map<String, String> campos;

  factory FalhaApi.deResposta(RespostaHttp r) {
    final c = r.corpo;
    if (c is Map) {
      return FalhaApi(
        r.status,
        c['codigo'] as String? ?? 'ERRO',
        c['mensagem'] as String? ?? 'Algo deu errado.',
        {for (final e in ((c['campos'] as Map?) ?? {}).entries) e.key as String: e.value as String},
      );
    }
    return FalhaApi(r.status, 'ERRO', 'Algo deu errado. Tente novamente.');
  }

  @override
  String toString() => 'FalhaApi($status $codigo: $mensagem)';
}

/// Cliente tipado da API do MedAgenda: transforma chamadas em requisições
/// e respostas em modelos. Guarda o token depois do login/cadastro.
class ApiMedAgenda {
  ApiMedAgenda(this._transporte);

  final Transporte _transporte;
  String? token;

  Future<Object?> _chamar(String metodo, String caminho, {Map<String, String> query = const {}, Object? corpo}) async {
    final r = await _transporte.enviar(metodo, '/v1$caminho', query: query, corpo: corpo, token: token);
    if (r.status >= 400) throw FalhaApi.deResposta(r);
    return r.corpo;
  }

  List<T> _lista<T>(Object? corpo, T Function(Map<String, dynamic>) conv) =>
      [for (final i in corpo as List) conv(i as Map<String, dynamic>)];

  // conta
  Future<Sessao> entrar(String email, String senha) async {
    final s = Sessao.deJson(await _chamar('POST', '/sessoes', corpo: {'email': email, 'senha': senha}) as Map<String, dynamic>);
    token = s.token;
    return s;
  }

  Future<Sessao> cadastrar(NovoPaciente novo) async {
    final s = Sessao.deJson(await _chamar('POST', '/pacientes', corpo: novo.paraJson()) as Map<String, dynamic>);
    token = s.token;
    return s;
  }

  Future<Paciente> eu() async => Paciente.deJson(await _chamar('GET', '/pacientes/eu') as Map<String, dynamic>);

  // catálogo
  Future<List<Especialidade>> especialidades() async =>
      _lista(await _chamar('GET', '/especialidades'), Especialidade.deJson);

  Future<List<Medico>> medicos({String? especialidade, String? busca, bool? soTeleconsulta, String? ordem, int? limite}) async =>
      _lista(
        await _chamar('GET', '/medicos', query: {
          'especialidade': ?especialidade,
          if (busca != null && busca.trim().isNotEmpty) 'busca': busca.trim(),
          if (soTeleconsulta == true) 'teleconsulta': 'true',
          'ordem': ?ordem,
          if (limite != null) 'limite': '$limite',
        }),
        Medico.deJson,
      );

  Future<Medico> medico(String id) async => Medico.deJson(await _chamar('GET', '/medicos/$id') as Map<String, dynamic>);

  Future<List<DiaAgenda>> horarios(String medicoId, DateTime inicio, {int dias = 7}) async {
    final r = await _chamar('GET', '/medicos/$medicoId/horarios', query: {'inicio': Datas.iso(inicio), 'dias': '$dias'});
    return _lista((r as Map)['dias'], DiaAgenda.deJson);
  }

  // consultas
  Future<List<Consulta>> consultas(String periodo) async =>
      _lista(await _chamar('GET', '/consultas', query: {'periodo': periodo}), Consulta.deJson);

  Future<Consulta> agendar({required String medicoId, required DateTime inicio, required Modalidade modalidade, String? motivo}) async =>
      Consulta.deJson(await _chamar('POST', '/consultas', corpo: {
        'medicoId': medicoId,
        'inicio': Datas.isoComHora(inicio),
        'modalidade': modalidade.name,
        if (motivo != null && motivo.trim().isNotEmpty) 'motivo': motivo.trim(),
      }) as Map<String, dynamic>);

  Future<Consulta> cancelar(String consultaId) async =>
      Consulta.deJson(await _chamar('POST', '/consultas/$consultaId/cancelamento') as Map<String, dynamic>);
}
