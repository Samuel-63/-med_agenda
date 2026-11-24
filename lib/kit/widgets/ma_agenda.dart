import 'package:flutter/material.dart';

import '../../util/datas.dart';
import '../tokens/tokens.dart';

/// Um dia na faixa semanal da agenda.
///
/// Dias em que o profissional não atende aparecem apagados e não clicáveis;
/// dias lotados mostram um ponto cinza em vez do ponto coral.
class MaDiaSemana extends StatelessWidget {
  const MaDiaSemana({
    super.key,
    required this.data,
    required this.selecionado,
    required this.atende,
    required this.temVaga,
    this.aoTocar,
  });

  final DateTime data;
  final bool selecionado;
  final bool atende;
  final bool temVaga;
  final VoidCallback? aoTocar;

  @override
  Widget build(BuildContext context) {
    final cor = !atende
        ? Paleta.tintaApagada
        : selecionado
            ? Colors.white
            : Paleta.tinta;
    return Semantics(
      button: atende,
      selected: selecionado,
      label: '${Datas.porExtenso(data)}${atende ? '' : ', sem atendimento'}',
      child: GestureDetector(
        onTap: atende ? aoTocar : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 46,
          padding: const EdgeInsets.symmetric(vertical: Espaco.s + 2),
          decoration: BoxDecoration(
            color: selecionado ? Paleta.indigo : Colors.transparent,
            borderRadius: BorderRadius.circular(Raio.pilula),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(Datas.siglaSemana(data), style: Tipo.rotulo.copyWith(fontSize: 10, color: selecionado ? Colors.white70 : Paleta.tintaSuave)),
              const SizedBox(height: Espaco.xs),
              Text(
                '${data.day}',
                style: Tipo.subtitulo.copyWith(
                  color: cor,
                  decoration: atende ? null : TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(height: Espaco.xs),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: !atende
                      ? Colors.transparent
                      : temVaga
                          ? (selecionado ? Colors.white : Paleta.coral)
                          : Paleta.tintaApagada,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horário clicável. Ocupado = tracejado e sem toque.
class MaHorario extends StatelessWidget {
  const MaHorario(this.hora, {super.key, required this.livre, required this.selecionado, this.aoTocar});

  final String hora;
  final bool livre;
  final bool selecionado;
  final VoidCallback? aoTocar;

  @override
  Widget build(BuildContext context) {
    final fundo = selecionado ? Paleta.coral : (livre ? Paleta.superficie : Paleta.fundo);
    final frente = selecionado ? Colors.white : (livre ? Paleta.tinta : Paleta.tintaApagada);
    return Semantics(
      button: livre,
      selected: selecionado,
      label: livre ? 'Horário $hora' : 'Horário $hora ocupado',
      excludeSemantics: true,
      child: Material(
        color: fundo,
        shape: RoundedRectangleBorder(
          borderRadius: Raio.p,
          side: BorderSide(color: selecionado ? Paleta.coral : Paleta.borda),
        ),
        child: InkWell(
          borderRadius: Raio.p,
          onTap: livre ? aoTocar : null,
          child: SizedBox(
            width: 78,
            height: 42,
            child: Center(
              child: Text(
                hora,
                style: Tipo.corpo.copyWith(
                  fontWeight: FontWeight.w700,
                  color: frente,
                  decoration: livre ? null : TextDecoration.lineThrough,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
