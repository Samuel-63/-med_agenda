import 'package:flutter/material.dart';

import '../../app/dependencias.dart';
import '../../kit/kit.dart';
import '../../modelos/modelos.dart';
import '../../util/datas.dart';
import '../../util/estado.dart';
import 'medico_controller.dart';

class MedicoPage extends StatefulWidget {
  const MedicoPage({super.key, required this.medicoId});
  final String medicoId;

  @override
  State<MedicoPage> createState() => _MedicoPageState();
}

class _MedicoPageState extends State<MedicoPage> {
  late final _deps = Dependencias.of(context);
  late final MedicoController _vm = MedicoController(_deps.agenda, widget.medicoId, _deps.relogio);

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _confirmar(Medico m) async {
    final inicio = _vm.inicioEscolhido!;
    final ok = await perguntar(
      context,
      titulo: 'Confirmar consulta?',
      mensagem: '${m.nome}\n${Datas.porExtenso(inicio)} às ${Datas.hora(inicio)}\n'
          '${_vm.modalidade.rotulo} · ${formatarValor(m.valor)}',
      confirmar: 'Confirmar',
      icone: Icons.event_available,
    );
    if (!ok || !mounted) return;
    final r = await _vm.agendar();
    if (!mounted) return;
    switch (r) {
      case Agendou():
        avisar(context, 'Consulta marcada! Você encontra os detalhes em Consultas.');
        Navigator.pop(context);
      case NaoAgendou(:final mensagem):
        avisar(context, mensagem, erro: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) => switch (_vm.medico) {
        Carregando() => Scaffold(appBar: AppBar(), body: const MaCarregando()),
        ComFalha(:final mensagem) => Scaffold(appBar: AppBar(), body: Center(child: MaFalha(mensagem, aoTentar: _vm.tentarDeNovo))),
        Pronto(dado: final m) => Scaffold(
            body: CustomScrollView(
              slivers: [
                _Topo(m),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(Espaco.l, Espaco.xl, Espaco.l, Espaco.xl),
                  sliver: SliverList.list(children: [
                    const MaSecao('Sobre'),
                    Text(m.sobre, style: Tipo.corpo.copyWith(color: Paleta.tintaSuave)),
                    const SizedBox(height: Espaco.xl),
                    _Agenda(vm: _vm),
                    const SizedBox(height: Espaco.xl),
                    const MaSecao('Como prefere ser atendido?'),
                    _EscolhaModalidade(vm: _vm, permiteTele: m.teleconsulta),
                    const SizedBox(height: Espaco.xl),
                    MaCampo(
                      rotulo: 'Motivo (opcional)',
                      dica: 'Ex.: dor de cabeça há 3 dias',
                      linhas: 2,
                      limite: 140,
                      aoMudar: _vm.mudarMotivo,
                    ),
                  ]),
                ),
              ],
            ),
            bottomNavigationBar: _Rodape(vm: _vm, medico: m, aoAgendar: () => _confirmar(m)),
          ),
      },
    );
  }
}

class _Topo extends StatelessWidget {
  const _Topo(this.m);
  final Medico m;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 250,
      backgroundColor: Paleta.indigoEscuro,
      foregroundColor: Colors.white,
      title: Text(m.nome, style: Tipo.subtitulo.copyWith(color: Colors.white)),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: Paleta.gradienteTopo),
          padding: EdgeInsets.fromLTRB(Espaco.l, MediaQuery.paddingOf(context).top + 64, Espaco.l, Espaco.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                MaAvatar(m.nome, tamanho: 64, claro: true),
                const SizedBox(width: Espaco.l),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(m.especialidadeNome, style: Tipo.titulo.copyWith(color: Colors.white)),
                    Text(m.registro, style: Tipo.apoio.copyWith(color: Colors.white70)),
                  ]),
                ),
              ]),
              const Spacer(),
              Row(children: [
                _Numero(m.nota.toStringAsFixed(1).replaceAll('.', ','), 'nota', Icons.star_rounded),
                _Numero('${m.avaliacoes}', 'avaliações', Icons.forum_outlined),
                _Numero(formatarValor(m.valor), 'consulta', Icons.payments_outlined),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _Numero extends StatelessWidget {
  const _Numero(this.valor, this.rotulo, this.icone);
  final String valor;
  final String rotulo;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: Espaco.s),
        padding: const EdgeInsets.symmetric(vertical: Espaco.s, horizontal: Espaco.m),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: Raio.p),
        child: Row(children: [
          Icon(icone, size: 18, color: Paleta.coral),
          const SizedBox(width: 6),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(valor, style: Tipo.subtitulo.copyWith(color: Colors.white, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(rotulo, style: Tipo.apoio.copyWith(color: Colors.white70, fontSize: 11)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Agenda extends StatelessWidget {
  const _Agenda({required this.vm});
  final MedicoController vm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Agenda', style: Tipo.subtitulo),
              Text(Datas.mesAno(vm.inicioSemana), style: Tipo.apoio),
            ]),
          ),
          IconButton.outlined(
            tooltip: 'Semana anterior',
            onPressed: vm.podeVoltarSemana ? () => vm.mudarSemana(-1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          const SizedBox(width: Espaco.xs),
          IconButton.outlined(
            tooltip: 'Próxima semana',
            onPressed: vm.podeAvancarSemana ? () => vm.mudarSemana(1) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ]),
        const SizedBox(height: Espaco.m),
        MaPainel(
          preenchimento: const EdgeInsets.all(Espaco.s),
          child: switch (vm.semana) {
            Carregando() => const SizedBox(height: 86, child: Center(child: CircularProgressIndicator())),
            ComFalha(:final mensagem) => MaFalha(mensagem, aoTentar: vm.carregarSemana),
            Pronto(:final dado) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final d in dado)
                    MaDiaSemana(
                      data: d.data,
                      atende: d.atende,
                      temVaga: d.temVaga,
                      selecionado: vm.dia != null && Datas.mesmoDia(d.data, vm.dia!),
                      aoTocar: () => vm.escolherDia(d.data),
                    ),
                ],
              ),
          },
        ),
        const SizedBox(height: Espaco.l),
        _Horarios(vm: vm),
      ],
    );
  }
}

class _Horarios extends StatelessWidget {
  const _Horarios({required this.vm});
  final MedicoController vm;

  @override
  Widget build(BuildContext context) {
    if (vm.semana is! Pronto) return const SizedBox.shrink();
    final d = vm.diaSelecionado;
    if (d == null) {
      return const MaVazio(
        icone: Icons.event_busy,
        titulo: 'Sem vagas nesta semana',
        texto: 'Avance para a próxima semana para ver mais horários.',
      );
    }
    final manha = d.horarios.where((h) => h.manha).toList();
    final tarde = d.horarios.where((h) => !h.manha).toList();
    Widget grupo(String titulo, IconData icone, List<Horario> hs) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icone, size: 18, color: Paleta.tintaSuave),
              const SizedBox(width: 6),
              Text(titulo, style: Tipo.rotulo),
            ]),
            const SizedBox(height: Espaco.s),
            Wrap(
              spacing: Espaco.s,
              runSpacing: Espaco.s,
              children: [
                for (final h in hs)
                  MaHorario(h.hora, livre: h.livre, selecionado: vm.hora == h.hora, aoTocar: () => vm.escolherHora(h.hora)),
              ],
            ),
            const SizedBox(height: Espaco.l),
          ],
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(Datas.porExtenso(d.data), style: Tipo.subtitulo.copyWith(fontSize: 15)),
        const SizedBox(height: Espaco.m),
        if (manha.isNotEmpty) grupo('MANHÃ', Icons.wb_twilight, manha),
        if (tarde.isNotEmpty) grupo('TARDE E NOITE', Icons.wb_sunny_outlined, tarde),
      ],
    );
  }
}

class _EscolhaModalidade extends StatelessWidget {
  const _EscolhaModalidade({required this.vm, required this.permiteTele});
  final MedicoController vm;
  final bool permiteTele;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<Modalidade>(
            segments: [
              const ButtonSegment(value: Modalidade.presencial, label: Text('Presencial'), icon: Icon(Icons.place_outlined)),
              ButtonSegment(
                value: Modalidade.teleconsulta,
                label: const Text('Teleconsulta'),
                icon: const Icon(Icons.videocam_outlined),
                enabled: permiteTele,
              ),
            ],
            selected: {vm.modalidade},
            onSelectionChanged: (s) => vm.escolherModalidade(s.first),
          ),
        ),
        if (!permiteTele) ...[
          const SizedBox(height: Espaco.s),
          const Text('Este profissional atende apenas presencialmente.', style: Tipo.apoio),
        ],
      ],
    );
  }
}

class _Rodape extends StatelessWidget {
  const _Rodape({required this.vm, required this.medico, required this.aoAgendar});
  final MedicoController vm;
  final Medico medico;
  final VoidCallback aoAgendar;

  @override
  Widget build(BuildContext context) {
    final inicio = vm.inicioEscolhido;
    return Container(
      padding: EdgeInsets.fromLTRB(Espaco.l, Espaco.m, Espaco.l, Espaco.m + MediaQuery.paddingOf(context).bottom),
      decoration: const BoxDecoration(color: Paleta.superficie, border: Border(top: BorderSide(color: Paleta.borda))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(inicio == null ? 'Escolha um horário' : '${Datas.curta(inicio)} · ${Datas.hora(inicio)}', style: Tipo.subtitulo.copyWith(fontSize: 15)),
                Text(formatarValor(medico.valor), style: Tipo.apoio),
              ],
            ),
          ),
          MaBotao(
            'Agendar',
            largo: false,
            variante: VarianteBotao.destaque,
            icone: Icons.check,
            carregando: vm.agendando,
            aoTocar: vm.podeAgendar ? aoAgendar : null,
          ),
        ],
      ),
    );
  }
}
