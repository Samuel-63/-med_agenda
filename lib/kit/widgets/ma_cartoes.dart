import 'package:flutter/material.dart';

import '../../modelos/modelos.dart';
import '../../util/datas.dart';
import '../tokens/tokens.dart';
import 'ma_basicos.dart';

String formatarValor(double v) => 'R\$ ${v.toStringAsFixed(0)}';

/// Profissional em formato de linha (busca).
class MaCartaoMedico extends StatelessWidget {
  const MaCartaoMedico(this.medico, {super.key, this.aoTocar});
  final Medico medico;
  final VoidCallback? aoTocar;

  @override
  Widget build(BuildContext context) {
    return MaPainel(
      aoTocar: aoTocar,
      preenchimento: const EdgeInsets.all(Espaco.m),
      child: Row(
        children: [
          MaAvatar(medico.nome, tamanho: 56),
          const SizedBox(width: Espaco.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(medico.nome, style: Tipo.subtitulo, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(medico.especialidadeNome, style: Tipo.apoio),
                const SizedBox(height: Espaco.s),
                Wrap(
                  spacing: Espaco.s,
                  runSpacing: Espaco.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    MaNota(medico.nota, avaliacoes: medico.avaliacoes),
                    if (medico.teleconsulta) const Icon(Icons.videocam_outlined, size: 18, color: Paleta.coral),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatarValor(medico.valor), style: Tipo.subtitulo.copyWith(color: Paleta.indigo)),
              const Text('consulta', style: Tipo.apoio),
            ],
          ),
        ],
      ),
    );
  }
}

/// Profissional em formato de cartão vertical (carrossel do Início).
class MaCartaoMedicoVertical extends StatelessWidget {
  const MaCartaoMedicoVertical(this.medico, {super.key, this.aoTocar});
  final Medico medico;
  final VoidCallback? aoTocar;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 168,
      child: MaPainel(
        aoTocar: aoTocar,
        preenchimento: const EdgeInsets.all(Espaco.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MaAvatar(medico.nome, tamanho: 44),
                const Spacer(),
                MaNota(medico.nota),
              ],
            ),
            const SizedBox(height: Espaco.m),
            Text(medico.nome, style: Tipo.subtitulo.copyWith(fontSize: 15), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(medico.especialidadeNome, style: Tipo.apoio),
            const Spacer(),
            Text('a partir de ${formatarValor(medico.valor)}', style: Tipo.apoio.copyWith(color: Paleta.indigo, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

/// Bloco de especialidade (grade 4 colunas do Início).
class MaBlocoEspecialidade extends StatelessWidget {
  const MaBlocoEspecialidade({super.key, required this.nome, required this.icone, this.aoTocar, this.selecionado = false});
  final String nome;
  final String icone;
  final VoidCallback? aoTocar;
  final bool selecionado;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: aoTocar,
      borderRadius: Raio.m,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Espaco.xs),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: selecionado ? Paleta.indigo : Paleta.superficie,
                borderRadius: Raio.m,
                border: Border.all(color: selecionado ? Paleta.indigo : Paleta.borda),
              ),
              child: Icon(iconeEspecialidade(icone), color: selecionado ? Colors.white : Paleta.indigo),
            ),
            const SizedBox(height: Espaco.s - 2),
            Text(
              nome,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Tipo.apoio.copyWith(fontSize: 12, color: Paleta.tinta, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

/// Consulta com "bloco de calendário" à esquerda.
class MaCartaoConsulta extends StatelessWidget {
  const MaCartaoConsulta(this.consulta, {super.key, this.rodape, this.aoTocar});
  final Consulta consulta;
  final Widget? rodape;
  final VoidCallback? aoTocar;

  @override
  Widget build(BuildContext context) {
    final c = consulta;
    final apagada = c.situacao != Situacao.agendada;
    return MaPainel(
      aoTocar: aoTocar,
      preenchimento: const EdgeInsets.all(Espaco.m),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                padding: const EdgeInsets.symmetric(vertical: Espaco.s),
                decoration: BoxDecoration(
                  color: apagada ? Paleta.fundo : Paleta.indigoSuave,
                  borderRadius: Raio.p,
                ),
                child: Column(
                  children: [
                    Text(Datas.siglaSemana(c.inicio), style: Tipo.rotulo.copyWith(fontSize: 10, color: apagada ? Paleta.tintaSuave : Paleta.indigo)),
                    Text('${c.inicio.day}', style: Tipo.titulo.copyWith(fontSize: 22, color: apagada ? Paleta.tintaSuave : Paleta.indigo)),
                    Text(Datas.siglaMes(c.inicio), style: Tipo.apoio.copyWith(fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(width: Espaco.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.medicoNome, style: Tipo.subtitulo, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(c.especialidadeNome, style: Tipo.apoio),
                    const SizedBox(height: Espaco.s),
                    Wrap(
                      spacing: Espaco.s,
                      runSpacing: Espaco.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.schedule, size: 16, color: Paleta.tintaSuave),
                          const SizedBox(width: 4),
                          Text(Datas.hora(c.inicio), style: Tipo.apoio.copyWith(color: Paleta.tinta, fontWeight: FontWeight.w700)),
                        ]),
                        MaEtiqueta.modalidade(c.modalidade),
                        if (c.situacao != Situacao.agendada) MaEtiqueta.situacao(c.situacao),
                      ],
                    ),
                    if (c.motivo != null) ...[
                      const SizedBox(height: Espaco.s),
                      Text('“${c.motivo}”', style: Tipo.apoio.copyWith(fontStyle: FontStyle.italic)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (rodape != null) ...[
            const SizedBox(height: Espaco.m),
            const Divider(),
            const SizedBox(height: Espaco.s),
            rodape!,
          ],
        ],
      ),
    );
  }
}
