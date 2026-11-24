import 'package:flutter_test/flutter_test.dart';
import 'package:med_agenda/servicos/fake/servidor_fake.dart';

import 'apoio.dart';

void main() {
  late ServidorFake s;
  late String token;

  setUp(() {
    s = novoServidor();
    token = (s.atender('POST', '/v1/sessoes', corpo: {'email': 'LUCAS@medagenda.app', 'senha': 'senha123'}).corpo as Map)['token'] as String;
  });

  /// Primeiro horário livre do profissional na data informada.
  String horarioLivre(String medicoId, String data) {
    final r = s.atender('GET', '/v1/medicos/$medicoId/horarios', query: {'inicio': data, 'dias': '1'});
    final dia = ((r.corpo as Map)['dias'] as List).first as Map;
    return ((dia['horarios'] as List).firstWhere((h) => h['livre'] == true) as Map)['hora'] as String;
  }

  group('sessões e cadastro', () {
    test('senha errada devolve 401', () {
      final r = s.atender('POST', '/v1/sessoes', corpo: {'email': 'lucas@medagenda.app', 'senha': 'x'});
      expect(r.status, 401);
      expect((r.corpo as Map)['codigo'], 'CREDENCIAIS_INCORRETAS');
    });

    test('campos vazios devolvem 422 com erro por campo', () {
      final r = s.atender('POST', '/v1/sessoes', corpo: {'email': '', 'senha': ''});
      expect(r.status, 422);
      expect(((r.corpo as Map)['campos'] as Map).keys, containsAll(['email', 'senha']));
    });

    test('a senha nunca sai na resposta', () {
      final r = s.atender('GET', '/v1/pacientes/eu', token: token);
      expect(r.status, 200);
      expect((r.corpo as Map).containsKey('senha'), isFalse);
    });

    test('cadastro válido cria conta e já devolve token', () {
      final r = s.atender('POST', '/v1/pacientes', corpo: {
        'nome': 'Ana Clara',
        'email': 'ana@x.com',
        'celular': '(62) 98888-7777',
        'nascimento': '2000-01-10',
        'senha': 'abc12345',
      });
      expect(r.status, 201);
      final paciente = (r.corpo as Map)['paciente'] as Map;
      expect(paciente['celular'], '62988887777');
    });

    test('cadastro com e-mail repetido devolve 409', () {
      final r = s.atender('POST', '/v1/pacientes', corpo: {
        'nome': 'Outro Lucas',
        'email': 'lucas@medagenda.app',
        'celular': '62988887777',
        'nascimento': '2000-01-10',
        'senha': 'abc12345',
      });
      expect(r.status, 409);
      expect((r.corpo as Map)['codigo'], 'EMAIL_EM_USO');
    });

    test('cadastro inválido lista todos os campos com problema', () {
      final r = s.atender('POST', '/v1/pacientes', corpo: {'nome': 'Ana', 'email': 'x', 'celular': '123', 'senha': 'curta'});
      expect(r.status, 422);
      expect(((r.corpo as Map)['campos'] as Map).keys, containsAll(['nome', 'email', 'celular', 'senha', 'nascimento']));
    });
  });

  group('catálogo', () {
    test('especialidades trazem a contagem de profissionais', () {
      final lista = s.atender('GET', '/v1/especialidades').corpo as List;
      final cardio = lista.firstWhere((e) => e['id'] == 'cardio') as Map;
      expect(cardio['totalMedicos'], 2);
    });

    test('busca ignora acentos e maiúsculas', () {
      final r = s.atender('GET', '/v1/medicos', query: {'busca': 'NUTRICAO'});
      expect((r.corpo as List).single['id'], 'm-08');
    });

    test('filtro de teleconsulta e ordenação por valor', () {
      final lista = s.atender('GET', '/v1/medicos', query: {'teleconsulta': 'true', 'ordem': 'valor'}).corpo as List;
      expect(lista.every((m) => m['teleconsulta'] == true), isTrue);
      final valores = lista.map((m) => m['valor'] as num).toList();
      expect(valores, [...valores]..sort());
    });

    test('parâmetro inválido devolve 400', () {
      expect(s.atender('GET', '/v1/medicos', query: {'ordem': 'preco'}).status, 400);
      expect(s.atender('GET', '/v1/medicos/m-01/horarios', query: {'dias': '99'}).status, 400);
    });

    test('horários: dias sem atendimento vêm marcados e passados ficam ocupados', () {
      final r = s.atender('GET', '/v1/medicos/m-01/horarios', query: {'inicio': '2026-11-24', 'dias': '7'});
      final dias = (r.corpo as Map)['dias'] as List;
      expect(dias, hasLength(7));
      final sabado = dias.firstWhere((d) => d['data'] == '2026-11-28') as Map;
      expect(sabado['atende'], isFalse);
      final hoje = dias.first as Map;
      final oito = (hoje['horarios'] as List).firstWhere((h) => h['hora'] == '08:00') as Map;
      expect(oito['livre'], isFalse, reason: '08:00 já passou (agora são 10:00)');
    });

    test('profissional inexistente devolve 404', () {
      expect(s.atender('GET', '/v1/medicos/zzz').status, 404);
    });
  });

  group('consultas', () {
    test('sem token devolve 401', () {
      expect(s.atender('GET', '/v1/consultas').status, 401);
    });

    test('a base vem com próximas e histórico relativos a hoje', () {
      final proximas = s.atender('GET', '/v1/consultas', query: {'periodo': 'proximas'}, token: token).corpo as List;
      final anteriores = s.atender('GET', '/v1/consultas', query: {'periodo': 'anteriores'}, token: token).corpo as List;
      expect(proximas, hasLength(2));
      expect(anteriores.map((c) => c['situacao']), ['concluida', 'cancelada']);
    });

    test('agendar ocupa o horário e não deixa agendar de novo', () {
      final hora = horarioLivre('m-01', '2026-11-25');
      final corpo = {'medicoId': 'm-01', 'inicio': '2026-11-25T$hora', 'modalidade': 'presencial'};
      final r1 = s.atender('POST', '/v1/consultas', corpo: corpo, token: token);
      expect(r1.status, 201);
      expect((r1.corpo as Map)['situacao'], 'agendada');

      final r2 = s.atender('POST', '/v1/consultas', corpo: corpo, token: token);
      expect(r2.status, 409);
      expect((r2.corpo as Map)['codigo'], 'HORARIO_INDISPONIVEL');
    });

    test('horário passado, fora da grade e teleconsulta não oferecida', () {
      expect(s.atender('POST', '/v1/consultas', corpo: {'medicoId': 'm-01', 'inicio': '2026-11-23T09:00'}, token: token).status, 422);
      expect(s.atender('POST', '/v1/consultas', corpo: {'medicoId': 'm-01', 'inicio': '2026-11-25T08:10'}, token: token).status, 409);
      final r = s.atender('POST', '/v1/consultas', corpo: {'medicoId': 'm-02', 'inicio': '2026-11-25T13:00', 'modalidade': 'teleconsulta'}, token: token);
      expect((r.corpo as Map)['codigo'], 'MODALIDADE_INDISPONIVEL');
    });

    test('cancelar libera o horário; cancelar de novo devolve 409', () {
      final hora = horarioLivre('m-01', '2026-11-26');
      final criada = s.atender('POST', '/v1/consultas', corpo: {'medicoId': 'm-01', 'inicio': '2026-11-26T$hora'}, token: token).corpo as Map;

      final r1 = s.atender('POST', '/v1/consultas/${criada['id']}/cancelamento', token: token);
      expect(r1.status, 200);
      expect((r1.corpo as Map)['situacao'], 'cancelada');
      expect(horarioLivre('m-01', '2026-11-26'), hora);

      final r2 = s.atender('POST', '/v1/consultas/${criada['id']}/cancelamento', token: token);
      expect((r2.corpo as Map)['codigo'], 'JA_CANCELADA');
    });

    test('não cancela consulta concluída nem com menos de 2 h', () {
      expect((s.atender('POST', '/v1/consultas/c-003/cancelamento', token: token).corpo as Map)['codigo'], 'JA_REALIZADA');

      // c-001 é daqui a 2 dias às 14:30; o relógio avança até 13:00 desse dia
      var agora = agoraFixo;
      final perto = ServidorFake(lerBase(), relogio: () => agora);
      final t = (perto.atender('POST', '/v1/sessoes', corpo: {'email': 'lucas@medagenda.app', 'senha': 'senha123'}).corpo as Map)['token'] as String;
      agora = DateTime(2026, 11, 26, 13);
      final r = perto.atender('POST', '/v1/consultas/c-001/cancelamento', token: t);
      expect(r.status, 409);
      expect((r.corpo as Map)['codigo'], 'PRAZO_ENCERRADO');
    });
  });
}
