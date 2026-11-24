import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:med_agenda/app/app.dart';
import 'package:med_agenda/app/dependencias.dart';
import 'package:med_agenda/repositorios/repositorios.dart';
import 'package:med_agenda/servicos/api_med_agenda.dart';
import 'package:med_agenda/servicos/fake/servidor_fake.dart';
import 'package:med_agenda/servicos/transporte.dart';

/// "Agora" fixo de todos os testes: terça-feira, 24/11/2026, 10:00.
final agoraFixo = DateTime(2026, 11, 24, 10);

Map<String, dynamic> lerBase() =>
    jsonDecode(File('assets/dados/base.json').readAsStringSync()) as Map<String, dynamic>;

ServidorFake novoServidor({DateTime? agora}) {
  final t = agora ?? agoraFixo;
  return ServidorFake(lerBase(), relogio: () => t);
}

/// Tudo montado (sem atraso de rede) para testar controllers e telas.
class Ambiente {
  Ambiente() : servidor = novoServidor() {
    api = ApiMedAgenda(TransporteFake(servidor, atraso: Duration.zero));
    conta = ContaRepositorio(api);
    agenda = AgendaRepositorio(api);
  }

  final ServidorFake servidor;
  late final ApiMedAgenda api;
  late final ContaRepositorio conta;
  late final AgendaRepositorio agenda;

  Future<void> logar() => conta.entrar('lucas@medagenda.app', 'senha123');

  Widget app() => Dependencias(conta: conta, agenda: agenda, relogio: () => agoraFixo, child: const MedAgendaApp());
}
