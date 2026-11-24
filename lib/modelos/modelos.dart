/// Modelos de domínio do MedAgenda.
///
/// Todos são imutáveis e sabem se montar a partir do JSON da API
/// (ver docs/API.md). Ficam juntos num arquivo porque são pequenos.
library;

import '../util/datas.dart';

class Paciente {
  const Paciente({
    required this.id,
    required this.nome,
    required this.email,
    required this.celular,
    required this.nascimento,
  });

  final String id;
  final String nome;
  final String email;
  final String celular;
  final DateTime nascimento;

  String get primeiroNome => nome.trim().split(' ').first;

  factory Paciente.deJson(Map<String, dynamic> j) => Paciente(
        id: j['id'] as String,
        nome: j['nome'] as String,
        email: j['email'] as String,
        celular: j['celular'] as String,
        nascimento: DateTime.parse(j['nascimento'] as String),
      );
}

class Sessao {
  const Sessao(this.token, this.paciente);
  final String token;
  final Paciente paciente;

  factory Sessao.deJson(Map<String, dynamic> j) => Sessao(
        j['token'] as String,
        Paciente.deJson(j['paciente'] as Map<String, dynamic>),
      );
}

class NovoPaciente {
  const NovoPaciente({
    required this.nome,
    required this.email,
    required this.celular,
    required this.nascimento,
    required this.senha,
  });

  final String nome;
  final String email;
  final String celular;
  final DateTime? nascimento;
  final String senha;

  Map<String, dynamic> paraJson() => {
        'nome': nome.trim(),
        'email': email.trim(),
        'celular': celular,
        'nascimento': nascimento == null ? null : Datas.iso(nascimento!),
        'senha': senha,
      };
}

class Especialidade {
  const Especialidade({
    required this.id,
    required this.nome,
    required this.icone,
    required this.totalMedicos,
  });

  final String id;
  final String nome;
  final String icone;
  final int totalMedicos;

  factory Especialidade.deJson(Map<String, dynamic> j) => Especialidade(
        id: j['id'] as String,
        nome: j['nome'] as String,
        icone: j['icone'] as String,
        totalMedicos: (j['totalMedicos'] as num?)?.toInt() ?? 0,
      );
}

class Medico {
  const Medico({
    required this.id,
    required this.nome,
    required this.especialidadeId,
    required this.especialidadeNome,
    required this.registro,
    required this.nota,
    required this.avaliacoes,
    required this.valor,
    required this.teleconsulta,
    required this.sobre,
  });

  final String id;
  final String nome;
  final String especialidadeId;
  final String especialidadeNome;
  final String registro;
  final double nota;
  final int avaliacoes;
  final double valor;
  final bool teleconsulta;
  final String sobre;

  factory Medico.deJson(Map<String, dynamic> j) => Medico(
        id: j['id'] as String,
        nome: j['nome'] as String,
        especialidadeId: j['especialidadeId'] as String,
        especialidadeNome: j['especialidadeNome'] as String,
        registro: j['registro'] as String,
        nota: (j['nota'] as num).toDouble(),
        avaliacoes: (j['avaliacoes'] as num).toInt(),
        valor: (j['valor'] as num).toDouble(),
        teleconsulta: j['teleconsulta'] as bool,
        sobre: j['sobre'] as String,
      );
}

class Horario {
  const Horario(this.hora, this.livre);
  final String hora; // HH:mm
  final bool livre;

  bool get manha => int.parse(hora.substring(0, 2)) < 12;

  factory Horario.deJson(Map<String, dynamic> j) =>
      Horario(j['hora'] as String, j['livre'] as bool);
}

class DiaAgenda {
  const DiaAgenda({required this.data, required this.atende, required this.horarios});
  final DateTime data;
  final bool atende;
  final List<Horario> horarios;

  bool get temVaga => horarios.any((h) => h.livre);

  factory DiaAgenda.deJson(Map<String, dynamic> j) => DiaAgenda(
        data: DateTime.parse(j['data'] as String),
        atende: j['atende'] as bool,
        horarios: [
          for (final h in j['horarios'] as List) Horario.deJson(h as Map<String, dynamic>),
        ],
      );
}

enum Modalidade {
  presencial('Presencial'),
  teleconsulta('Teleconsulta');

  const Modalidade(this.rotulo);
  final String rotulo;

  static Modalidade porNome(String nome) =>
      Modalidade.values.firstWhere((m) => m.name == nome);
}

enum Situacao {
  agendada('Agendada'),
  concluida('Concluída'),
  cancelada('Cancelada');

  const Situacao(this.rotulo);
  final String rotulo;

  static Situacao porNome(String nome) =>
      Situacao.values.firstWhere((s) => s.name == nome);
}

class Consulta {
  const Consulta({
    required this.id,
    required this.medicoId,
    required this.medicoNome,
    required this.especialidadeNome,
    required this.inicio,
    required this.modalidade,
    required this.situacao,
    this.motivo,
  });

  final String id;
  final String medicoId;
  final String medicoNome;
  final String especialidadeNome;
  final DateTime inicio;
  final Modalidade modalidade;
  final Situacao situacao;
  final String? motivo;

  factory Consulta.deJson(Map<String, dynamic> j) => Consulta(
        id: j['id'] as String,
        medicoId: j['medicoId'] as String,
        medicoNome: j['medicoNome'] as String,
        especialidadeNome: j['especialidadeNome'] as String,
        inicio: DateTime.parse(j['inicio'] as String),
        modalidade: Modalidade.porNome(j['modalidade'] as String),
        situacao: Situacao.porNome(j['situacao'] as String),
        motivo: j['motivo'] as String?,
      );
}
