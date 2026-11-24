import 'package:flutter_test/flutter_test.dart';
import 'package:med_agenda/modelos/modelos.dart';
import 'package:med_agenda/telas/buscar/buscar_controller.dart';
import 'package:med_agenda/telas/cadastro/cadastro_controller.dart';
import 'package:med_agenda/telas/consultas/consultas_controller.dart';
import 'package:med_agenda/telas/entrar/entrar_controller.dart';
import 'package:med_agenda/telas/inicio/inicio_controller.dart';
import 'package:med_agenda/telas/medico/medico_controller.dart';
import 'package:med_agenda/util/estado.dart';
import 'package:med_agenda/util/validacao.dart';

import 'apoio.dart';

/// Deixa as Futures pendentes terminarem.
Future<void> esperar() => Future<void>.delayed(Duration.zero);

void main() {
  late Ambiente amb;
  setUp(() => amb = Ambiente());

  group('EntrarController', () {
    test('valida antes de chamar a API', () async {
      final vm = EntrarController(amb.conta)..mudarEmail('nao-e-email');
      expect(await vm.entrar(), isFalse);
      expect(vm.erroEmail, isNotNull);
      expect(vm.erroSenha, isNotNull);
      expect(amb.conta.logado, isFalse);
    });

    test('mostra a mensagem da API quando a senha está errada', () async {
      final vm = EntrarController(amb.conta)
        ..mudarEmail(EntrarController.emailDemo)
        ..mudarSenha('errada');
      expect(await vm.entrar(), isFalse);
      expect(vm.falha, 'E-mail ou senha não conferem.');
    });

    test('entra com a conta de demonstração', () async {
      final vm = EntrarController(amb.conta)
        ..mudarEmail(EntrarController.emailDemo)
        ..mudarSenha(EntrarController.senhaDemo);
      expect(await vm.entrar(), isTrue);
      expect(amb.conta.paciente!.primeiroNome, 'Lucas');
    });
  });

  group('CadastroController', () {
    CadastroController preenchido() => CadastroController(amb.conta, () => agoraFixo)
      ..mudar('nome', 'Beatriz Lima')
      ..mudar('email', 'bia@email.com')
      ..mudar('celular', '(62) 99876-5432')
      ..mudar('nascimento', DateTime(1995, 3, 2))
      ..mudar('senha', 'segura123')
      ..mudar('confirmacao', 'segura123')
      ..mudar('termos', true);

    test('senhas diferentes e termos não aceitos bloqueiam o envio', () async {
      final vm = preenchido()
        ..mudar('confirmacao', 'outra')
        ..mudar('termos', false);
      expect(await vm.enviar(), isFalse);
      expect(vm.erros.keys, containsAll(['confirmacao', 'termos']));
    });

    test('cadastro válido já deixa o paciente logado', () async {
      expect(await preenchido().enviar(), isTrue);
      expect(amb.conta.paciente!.email, 'bia@email.com');
    });

    test('e-mail já usado aparece no campo', () async {
      final vm = preenchido()..mudar('email', 'lucas@medagenda.app');
      expect(await vm.enviar(), isFalse);
      expect(vm.erros['email'], 'E-mail já cadastrado.');
    });
  });

  test('força da senha', () {
    expect(Validacao.forcaSenha('abc'), 0);
    expect(Validacao.forcaSenha('abcdefg1'), 2);
    expect(Validacao.forcaSenha('Abcdefgh123!'), 4);
  });

  group('com login', () {
    setUp(() => amb.logar());

    test('InicioController traz a próxima consulta e os destaques', () async {
      final vm = InicioController(amb.agenda);
      await esperar();
      final p = (vm.estado as Pronto<PainelInicio>).dado;
      expect(p.proxima!.medicoNome, 'Dra. Patrícia Nunes');
      expect(p.totalAgendadas, 2);
      expect(p.destaques, hasLength(5));
      expect(p.especialidades, hasLength(8));
    });

    test('BuscarController filtra por especialidade e por texto', () async {
      final vm = BuscarController(amb.agenda, espera: Duration.zero);
      await esperar();
      vm.filtrarEspecialidade('cardio');
      await esperar();
      expect((vm.resultado as Pronto<List<Medico>>).dado.map((m) => m.id), ['m-02', 'm-09']);

      vm.filtrarEspecialidade(null);
      vm.mudarTexto('bianca');
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect((vm.resultado as Pronto<List<Medico>>).dado.single.id, 'm-07');
      vm.dispose();
    });

    test('MedicoController escolhe o primeiro dia com vaga e agenda', () async {
      final vm = MedicoController(amb.agenda, 'm-01', () => agoraFixo);
      await esperar();
      expect(vm.dia, isNotNull);
      expect(vm.podeVoltarSemana, isFalse);

      final livre = vm.diaSelecionado!.horarios.firstWhere((h) => h.livre);
      vm.escolherHora(livre.hora);
      expect(vm.podeAgendar, isTrue);
      final r = await vm.agendar();
      expect(r, isA<Agendou>());
    });

    test('MedicoController recarrega a agenda quando o horário é tomado', () async {
      final vm = MedicoController(amb.agenda, 'm-01', () => agoraFixo);
      await esperar();
      final livre = vm.diaSelecionado!.horarios.firstWhere((h) => h.livre);
      vm.escolherHora(livre.hora);

      // outro paciente pega o mesmo horário antes da confirmação
      final outro = amb.servidor.atender('POST', '/v1/pacientes', corpo: {
        'nome': 'Outra Pessoa', 'email': 'o@x.com', 'celular': '62911112222', 'nascimento': '1990-01-01', 'senha': 'abc12345',
      });
      amb.servidor.atender('POST', '/v1/consultas',
          corpo: {'medicoId': 'm-01', 'inicio': vm.inicioEscolhido!.toIso8601String().substring(0, 16)},
          token: (outro.corpo as Map)['token'] as String);

      final r = await vm.agendar();
      expect(r, isA<NaoAgendou>());
      expect(vm.hora, isNull);
      final mesmo = vm.diaSelecionado!.horarios.firstWhere((h) => h.hora == livre.hora);
      expect(mesmo.livre, isFalse);
    });

    test('ConsultasController alterna abas e atualiza após cancelar', () async {
      final vm = ConsultasController(amb.agenda);
      await esperar();
      expect((vm.lista as Pronto<List<Consulta>>).dado, hasLength(2));

      expect(await vm.cancelar('c-001'), isNull);
      await esperar();
      expect((vm.lista as Pronto<List<Consulta>>).dado, hasLength(1));

      vm.trocarAba(Aba.anteriores);
      await esperar();
      expect((vm.lista as Pronto<List<Consulta>>).dado.first.situacao, Situacao.cancelada);
      vm.dispose();
    });
  });
}
