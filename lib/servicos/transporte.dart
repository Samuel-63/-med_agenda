import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'fake/servidor_fake.dart';

/// Resposta já decodificada de uma chamada HTTP.
class RespostaHttp {
  const RespostaHttp(this.status, this.corpo);
  final int status;
  final Object? corpo;
}

/// Camada mais baixa: sabe "enviar uma requisição" e nada mais.
///
/// O [ApiMedAgenda] só conversa com esta interface. Hoje existe o
/// [TransporteFake]; para um servidor de verdade basta escrever um
/// `TransporteHttp` (com o pacote `http`, por exemplo) e trocar no main.
abstract interface class Transporte {
  Future<RespostaHttp> enviar(
    String metodo,
    String caminho, {
    Map<String, String> query,
    Object? corpo,
    String? token,
  });
}

/// Transporte que entrega a requisição ao [ServidorFake] em memória,
/// passando o corpo por JSON (ida e volta) para se comportar como a rede.
class TransporteFake implements Transporte {
  TransporteFake(this.servidor, {this.atraso = const Duration(milliseconds: 450)});

  final ServidorFake servidor;
  final Duration atraso;

  /// Carrega `assets/dados/base.json` e monta o servidor.
  static Future<TransporteFake> doAsset({Duration? atraso}) async {
    final texto = await rootBundle.loadString('assets/dados/base.json');
    final base = jsonDecode(texto) as Map<String, dynamic>;
    return TransporteFake(ServidorFake(base), atraso: atraso ?? const Duration(milliseconds: 450));
  }

  @override
  Future<RespostaHttp> enviar(
    String metodo,
    String caminho, {
    Map<String, String> query = const {},
    Object? corpo,
    String? token,
  }) async {
    if (atraso > Duration.zero) await Future<void>.delayed(atraso);
    final ida = corpo == null ? null : jsonDecode(jsonEncode(corpo));
    final r = servidor.atender(metodo, caminho, query: query, corpo: ida, token: token);
    return RespostaHttp(r.status, r.corpo == null ? null : jsonDecode(jsonEncode(r.corpo)));
  }
}
