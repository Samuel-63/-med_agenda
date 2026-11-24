import '../../util/datas.dart';
import '../../util/validacao.dart';

/// Resposta crua do servidor falso: status HTTP + corpo JSON.
class RespostaFake {
  const RespostaFake(this.status, [this.corpo]);
  final int status;
  final Object? corpo;

  bool get ok => status >= 200 && status < 300;
}

/// Simula o backend descrito em docs/API.md.
///
/// Recebe método, caminho, query, corpo e token e devolve [RespostaFake],
/// exatamente como um servidor HTTP faria. Os dados ficam em memória e
/// voltam ao estado de `base.json` quando o app reinicia.
///
/// [relogio] permite fixar "agora" nos testes.
class ServidorFake {
  ServidorFake(Map<String, dynamic> base, {DateTime Function()? relogio})
      : _relogio = relogio ?? DateTime.now {
    final hoje = Datas.soData(_relogio());
    for (final p in base['pacientes'] as List) {
      _pacientes.add(Map<String, dynamic>.from(p as Map));
    }
    for (final e in base['especialidades'] as List) {
      _especialidades.add(Map<String, dynamic>.from(e as Map));
    }
    for (final m in base['medicos'] as List) {
      _medicos.add(Map<String, dynamic>.from(m as Map));
    }
    // As consultas da base usam datas relativas a hoje, assim a demonstração
    // sempre tem consultas futuras e passadas, em qualquer dia que rodar.
    for (final c in base['consultas'] as List) {
      final m = Map<String, dynamic>.from(c as Map);
      final dia = hoje.add(Duration(days: m.remove('diasAPartirDeHoje') as int));
      m['inicio'] = '${Datas.iso(dia)}T${m.remove('hora')}';
      _consultas.add(m);
    }
    _proximoId = _consultas.length + 1;
  }

  final DateTime Function() _relogio;
  final _pacientes = <Map<String, dynamic>>[];
  final _especialidades = <Map<String, dynamic>>[];
  final _medicos = <Map<String, dynamic>>[];
  final _consultas = <Map<String, dynamic>>[];
  final _tokens = <String, String>{}; // token -> pacienteId
  int _proximoId = 1;
  int _contadorToken = 0;

  /// Prazo mínimo para cancelar uma consulta.
  static const antecedenciaCancelamento = Duration(hours: 2);

  // ---------------------------------------------------------------- roteador

  RespostaFake atender(
    String metodo,
    String caminho, {
    Map<String, String> query = const {},
    Object? corpo,
    String? token,
  }) {
    final p = Uri.parse(caminho).pathSegments;
    if (p.isEmpty || p.first != 'v1') return _naoEncontrado('ROTA_INEXISTENTE', 'Rota não encontrada.');
    final r = p.sublist(1);

    if (metodo == 'POST' && _eh(r, ['sessoes'])) return _entrar(corpo);
    if (metodo == 'POST' && _eh(r, ['pacientes'])) return _cadastrar(corpo);
    if (metodo == 'GET' && _eh(r, ['pacientes', 'eu'])) {
      return _comLogin(token, (pid) => RespostaFake(200, _pacientePublico(_pacientePorId(pid)!)));
    }
    if (metodo == 'GET' && _eh(r, ['especialidades'])) return _listarEspecialidades();
    if (metodo == 'GET' && _eh(r, ['medicos'])) return _listarMedicos(query);
    if (metodo == 'GET' && r.length == 2 && r[0] == 'medicos') return _buscarMedico(r[1]);
    if (metodo == 'GET' && r.length == 3 && r[0] == 'medicos' && r[2] == 'horarios') {
      return _horarios(r[1], query);
    }
    if (metodo == 'GET' && _eh(r, ['consultas'])) {
      return _comLogin(token, (pid) => _listarConsultas(pid, query));
    }
    if (metodo == 'POST' && _eh(r, ['consultas'])) {
      return _comLogin(token, (pid) => _agendar(pid, corpo));
    }
    if (metodo == 'POST' && r.length == 3 && r[0] == 'consultas' && r[2] == 'cancelamento') {
      return _comLogin(token, (pid) => _cancelar(pid, r[1]));
    }
    return _naoEncontrado('ROTA_INEXISTENTE', 'Rota não encontrada.');
  }

  bool _eh(List<String> r, List<String> alvo) =>
      r.length == alvo.length && List.generate(r.length, (i) => r[i] == alvo[i]).every((b) => b);

  // ------------------------------------------------------------------ erros

  static RespostaFake _erro(int status, String codigo, String mensagem, [Map<String, String>? campos]) =>
      RespostaFake(status, {
        'codigo': codigo,
        'mensagem': mensagem,
        if (campos != null && campos.isNotEmpty) 'campos': campos,
      });

  static RespostaFake _naoEncontrado(String codigo, String msg) => _erro(404, codigo, msg);

  static RespostaFake _invalido(Map<String, String> campos) =>
      _erro(422, 'DADOS_INVALIDOS', 'Alguns campos precisam de atenção.', campos);

  RespostaFake _comLogin(String? token, RespostaFake Function(String pacienteId) acao) {
    final pid = token == null ? null : _tokens[token];
    if (pid == null) return _erro(401, 'NAO_AUTENTICADO', 'Sua sessão expirou. Entre novamente.');
    return acao(pid);
  }

  Map<String, dynamic>? _corpoObjeto(Object? corpo) =>
      corpo is Map ? Map<String, dynamic>.from(corpo) : null;

  // ------------------------------------------------------------------ conta

  Map<String, dynamic>? _pacientePorId(String id) =>
      _pacientes.where((p) => p['id'] == id).firstOrNull;

  Map<String, dynamic> _pacientePublico(Map<String, dynamic> p) =>
      Map.of(p)..remove('senha');

  RespostaFake _novaSessao(Map<String, dynamic> paciente, int status) {
    final token = 'tk_${paciente['id']}_${++_contadorToken}';
    _tokens[token] = paciente['id'] as String;
    return RespostaFake(status, {'token': token, 'paciente': _pacientePublico(paciente)});
  }

  RespostaFake _entrar(Object? corpo) {
    final c = _corpoObjeto(corpo);
    if (c == null) return _erro(400, 'CORPO_INVALIDO', 'Envie um objeto JSON.');
    final email = (c['email'] as String? ?? '').trim().toLowerCase();
    final senha = c['senha'] as String? ?? '';
    final campos = <String, String>{
      if (email.isEmpty) 'email': 'Informe seu e-mail.',
      if (senha.isEmpty) 'senha': 'Informe sua senha.',
    };
    if (campos.isNotEmpty) return _invalido(campos);
    final p = _pacientes
        .where((p) => (p['email'] as String).toLowerCase() == email && p['senha'] == senha)
        .firstOrNull;
    if (p == null) return _erro(401, 'CREDENCIAIS_INCORRETAS', 'E-mail ou senha não conferem.');
    return _novaSessao(p, 200);
  }

  RespostaFake _cadastrar(Object? corpo) {
    final c = _corpoObjeto(corpo);
    if (c == null) return _erro(400, 'CORPO_INVALIDO', 'Envie um objeto JSON.');
    final nome = (c['nome'] as String? ?? '').trim();
    final email = (c['email'] as String? ?? '').trim();
    final celular = Validacao.soDigitos(c['celular'] as String? ?? '');
    final senha = c['senha'] as String? ?? '';
    final nasc = DateTime.tryParse(c['nascimento'] as String? ?? '');

    final campos = <String, String>{};
    void checa(String campo, String? erro) {
      if (erro != null) campos[campo] = erro;
    }

    checa('nome', Validacao.nome(nome));
    checa('email', Validacao.email(email));
    checa('celular', Validacao.celular(celular));
    checa('senha', Validacao.senha(senha));
    checa('nascimento', Validacao.nascimento(nasc, _relogio()));
    if (campos.isNotEmpty) return _invalido(campos);

    final existe = _pacientes.any((p) => (p['email'] as String).toLowerCase() == email.toLowerCase());
    if (existe) {
      return _erro(409, 'EMAIL_EM_USO', 'Já existe uma conta com este e-mail.', {'email': 'E-mail já cadastrado.'});
    }

    final novo = {
      'id': 'p-${(_pacientes.length + 1).toString().padLeft(3, '0')}',
      'nome': nome,
      'email': email,
      'celular': celular,
      'nascimento': Datas.iso(nasc!),
      'senha': senha,
    };
    _pacientes.add(novo);
    return _novaSessao(novo, 201);
  }

  // ---------------------------------------------------------------- catálogo

  Map<String, dynamic>? _medicoPorId(String id) => _medicos.where((m) => m['id'] == id).firstOrNull;

  String _nomeEspecialidade(String id) =>
      _especialidades.firstWhere((e) => e['id'] == id)['nome'] as String;

  Map<String, dynamic> _medicoPublico(Map<String, dynamic> m) =>
      (Map.of(m)..remove('agenda'))..['especialidadeNome'] = _nomeEspecialidade(m['especialidadeId'] as String);

  RespostaFake _listarEspecialidades() => RespostaFake(200, [
        for (final e in _especialidades)
          {...e, 'totalMedicos': _medicos.where((m) => m['especialidadeId'] == e['id']).length},
      ]);

  static String _semAcento(String s) {
    const de = 'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ';
    const para = 'aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC';
    final b = StringBuffer();
    for (final ch in s.split('')) {
      final i = de.indexOf(ch);
      b.write(i < 0 ? ch : para[i]);
    }
    return b.toString().toLowerCase();
  }

  RespostaFake _listarMedicos(Map<String, String> q) {
    final esp = q['especialidade'];
    final busca = _semAcento(q['busca']?.trim() ?? '');
    final ordem = q['ordem'] ?? 'nota';
    if (!['nota', 'valor', 'nome'].contains(ordem)) {
      return _erro(400, 'PARAMETRO_INVALIDO', 'ordem deve ser nota, valor ou nome.');
    }
    final soTele = q['teleconsulta'];
    if (soTele != null && soTele != 'true' && soTele != 'false') {
      return _erro(400, 'PARAMETRO_INVALIDO', 'teleconsulta deve ser true ou false.');
    }

    final lista = _medicos.map(_medicoPublico).where((m) {
      if (esp != null && esp.isNotEmpty && m['especialidadeId'] != esp) return false;
      if (soTele == 'true' && m['teleconsulta'] != true) return false;
      if (busca.isEmpty) return true;
      final alvo = _semAcento('${m['nome']} ${m['especialidadeNome']}');
      return alvo.contains(busca);
    }).toList();

    lista.sort((a, b) => switch (ordem) {
          'valor' => (a['valor'] as num).compareTo(b['valor'] as num),
          'nome' => _semAcento(a['nome'] as String).compareTo(_semAcento(b['nome'] as String)),
          _ => (b['nota'] as num).compareTo(a['nota'] as num),
        });
    final limite = int.tryParse(q['limite'] ?? '');
    return RespostaFake(200, limite == null ? lista : lista.take(limite).toList());
  }

  RespostaFake _buscarMedico(String id) {
    final m = _medicoPorId(id);
    if (m == null) return _naoEncontrado('MEDICO_NAO_ENCONTRADO', 'Profissional não encontrado.');
    return RespostaFake(200, _medicoPublico(m));
  }

  // ------------------------------------------------------------------ agenda

  static int _minutos(String hhmm) =>
      int.parse(hhmm.substring(0, 2)) * 60 + int.parse(hhmm.substring(3, 5));

  static String _hhmm(int minutos) =>
      '${(minutos ~/ 60).toString().padLeft(2, '0')}:${(minutos % 60).toString().padLeft(2, '0')}';

  /// Horários que o profissional oferece num dia da semana (vazio se não atende).
  List<String> _gradeDoDia(Map<String, dynamic> medico, DateTime dia) {
    final a = medico['agenda'] as Map;
    if (!(a['diasSemana'] as List).contains(dia.weekday)) return const [];
    final dur = a['duracao'] as int;
    return [
      for (var t = _minutos(a['inicio'] as String); t + dur <= _minutos(a['fim'] as String); t += dur) _hhmm(t),
    ];
  }

  /// Ocupação "de outros pacientes", determinística para a demonstração
  /// parecer real sem precisar de dados extras: cerca de 1 em cada 5 horários.
  static bool _ocupadoPorTerceiros(String medicoId, String data, String hora) {
    var h = 7;
    for (final c in '$medicoId|$data|$hora'.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return h % 5 == 0;
  }

  bool _horarioLivre(String medicoId, DateTime dia, String hora) {
    final inicio = DateTime.parse('${Datas.iso(dia)}T$hora');
    if (!inicio.isAfter(_relogio())) return false;
    if (_ocupadoPorTerceiros(medicoId, Datas.iso(dia), hora)) return false;
    final iso = Datas.isoComHora(inicio);
    return !_consultas.any((c) => c['medicoId'] == medicoId && c['inicio'] == iso && c['situacao'] == 'agendada');
  }

  RespostaFake _horarios(String medicoId, Map<String, String> q) {
    final m = _medicoPorId(medicoId);
    if (m == null) return _naoEncontrado('MEDICO_NAO_ENCONTRADO', 'Profissional não encontrado.');
    final hoje = Datas.soData(_relogio());
    final inicio = q['inicio'] == null ? hoje : DateTime.tryParse(q['inicio']!);
    final dias = int.tryParse(q['dias'] ?? '7');
    if (inicio == null || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(q['inicio'] ?? Datas.iso(hoje))) {
      return _erro(400, 'PARAMETRO_INVALIDO', 'inicio deve estar no formato AAAA-MM-DD.');
    }
    if (dias == null || dias < 1 || dias > 21) {
      return _erro(400, 'PARAMETRO_INVALIDO', 'dias deve ser um número de 1 a 21.');
    }
    return RespostaFake(200, {
      'medicoId': medicoId,
      'dias': [
        for (var i = 0; i < dias; i++)
          () {
            final dia = DateTime(inicio.year, inicio.month, inicio.day + i);
            final grade = _gradeDoDia(m, dia);
            return {
              'data': Datas.iso(dia),
              'atende': grade.isNotEmpty,
              'horarios': [
                for (final h in grade) {'hora': h, 'livre': _horarioLivre(medicoId, dia, h)},
              ],
            };
          }(),
      ],
    });
  }

  // --------------------------------------------------------------- consultas

  String _situacaoAtual(Map<String, dynamic> c) {
    if (c['situacao'] == 'agendada' && !DateTime.parse(c['inicio'] as String).isAfter(_relogio())) {
      return 'concluida';
    }
    return c['situacao'] as String;
  }

  Map<String, dynamic> _consultaPublica(Map<String, dynamic> c) {
    final m = _medicoPorId(c['medicoId'] as String)!;
    return {
      'id': c['id'],
      'medicoId': c['medicoId'],
      'medicoNome': m['nome'],
      'especialidadeNome': _nomeEspecialidade(m['especialidadeId'] as String),
      'inicio': c['inicio'],
      'modalidade': c['modalidade'],
      'motivo': c['motivo'],
      'situacao': _situacaoAtual(c),
    };
  }

  RespostaFake _listarConsultas(String pid, Map<String, String> q) {
    final periodo = q['periodo'] ?? 'todas';
    if (!['proximas', 'anteriores', 'todas'].contains(periodo)) {
      return _erro(400, 'PARAMETRO_INVALIDO', 'periodo deve ser proximas, anteriores ou todas.');
    }
    final minhas = _consultas.where((c) => c['pacienteId'] == pid).map(_consultaPublica).where((c) {
      final futura = c['situacao'] == 'agendada';
      return switch (periodo) { 'proximas' => futura, 'anteriores' => !futura, _ => true };
    }).toList();
    minhas.sort((a, b) => (a['inicio'] as String).compareTo(b['inicio'] as String));
    return RespostaFake(200, periodo == 'anteriores' ? minhas.reversed.toList() : minhas);
  }

  RespostaFake _agendar(String pid, Object? corpo) {
    final c = _corpoObjeto(corpo);
    if (c == null) return _erro(400, 'CORPO_INVALIDO', 'Envie um objeto JSON.');
    final medicoId = c['medicoId'] as String?;
    final inicioTxt = c['inicio'] as String? ?? '';
    final modalidade = c['modalidade'] as String? ?? 'presencial';
    final motivo = (c['motivo'] as String?)?.trim();

    final campos = <String, String>{
      if (medicoId == null || medicoId.isEmpty) 'medicoId': 'Obrigatório.',
      if (!RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$').hasMatch(inicioTxt)) 'inicio': 'Use AAAA-MM-DDTHH:mm.',
      if (!['presencial', 'teleconsulta'].contains(modalidade)) 'modalidade': 'presencial ou teleconsulta.',
      if (motivo != null && motivo.length > 140) 'motivo': 'Máximo de 140 caracteres.',
    };
    if (campos.isNotEmpty) return _invalido(campos);

    final m = _medicoPorId(medicoId!);
    if (m == null) return _naoEncontrado('MEDICO_NAO_ENCONTRADO', 'Profissional não encontrado.');
    if (modalidade == 'teleconsulta' && m['teleconsulta'] != true) {
      return _erro(422, 'MODALIDADE_INDISPONIVEL', 'Este profissional atende apenas presencialmente.');
    }

    final inicio = DateTime.parse(inicioTxt);
    if (!inicio.isAfter(_relogio())) {
      return _erro(422, 'HORARIO_PASSADO', 'Esse horário já passou. Escolha outro.');
    }
    final dia = Datas.soData(inicio);
    final hora = Datas.hora(inicio);
    if (!_gradeDoDia(m, dia).contains(hora) || !_horarioLivre(medicoId, dia, hora)) {
      return _erro(409, 'HORARIO_INDISPONIVEL', 'Esse horário acabou de ser ocupado. Escolha outro.');
    }
    final choque = _consultas.any((x) => x['pacienteId'] == pid && x['inicio'] == inicioTxt && _situacaoAtual(x) == 'agendada');
    if (choque) {
      return _erro(409, 'CONFLITO_NA_AGENDA', 'Você já tem outra consulta nesse mesmo horário.');
    }

    final nova = {
      'id': 'c-${(_proximoId++).toString().padLeft(3, '0')}',
      'pacienteId': pid,
      'medicoId': medicoId,
      'inicio': inicioTxt,
      'modalidade': modalidade,
      'motivo': (motivo == null || motivo.isEmpty) ? null : motivo,
      'situacao': 'agendada',
    };
    _consultas.add(nova);
    return RespostaFake(201, _consultaPublica(nova));
  }

  RespostaFake _cancelar(String pid, String id) {
    final c = _consultas.where((x) => x['id'] == id && x['pacienteId'] == pid).firstOrNull;
    if (c == null) return _naoEncontrado('CONSULTA_NAO_ENCONTRADA', 'Consulta não encontrada.');
    final situacao = _situacaoAtual(c);
    if (situacao == 'cancelada') return _erro(409, 'JA_CANCELADA', 'Essa consulta já foi cancelada.');
    if (situacao == 'concluida') return _erro(409, 'JA_REALIZADA', 'Consultas já realizadas não podem ser canceladas.');
    final faltam = DateTime.parse(c['inicio'] as String).difference(_relogio());
    if (faltam < antecedenciaCancelamento) {
      return _erro(409, 'PRAZO_ENCERRADO', 'O cancelamento só é possível até 2 horas antes.');
    }
    c['situacao'] = 'cancelada';
    return RespostaFake(200, _consultaPublica(c));
  }
}
