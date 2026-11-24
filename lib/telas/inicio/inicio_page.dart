import 'package:flutter/material.dart';

import '../../app/app.dart';
import '../../app/dependencias.dart';
import '../../kit/kit.dart';
import '../../modelos/modelos.dart';
import '../../util/datas.dart';
import '../../util/estado.dart';
import 'inicio_controller.dart';

class InicioPage extends StatefulWidget {
  const InicioPage({super.key, required this.aoBuscar, required this.aoVerConsultas});

  final void Function({String? especialidadeId, bool focarTexto}) aoBuscar;
  final VoidCallback aoVerConsultas;

  @override
  State<InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends State<InicioPage> {
  late final _deps = Dependencias.of(context);
  late final InicioController _vm = InicioController(_deps.agenda);

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  void _abrirMedico(String id) => Navigator.pushNamed(context, Rotas.medico, arguments: id);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) => switch (_vm.estado) {
        Carregando() => const Scaffold(body: MaCarregando()),
        ComFalha(:final mensagem) => Scaffold(body: Center(child: MaFalha(mensagem, aoTentar: _vm.carregar))),
        Pronto(:final dado) => RefreshIndicator(onRefresh: _vm.carregar, child: _conteudo(dado)),
      },
    );
  }

  Widget _conteudo(PainelInicio p) {
    final paciente = _deps.conta.paciente;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _Cabecalho(nome: paciente?.primeiroNome ?? '', painel: p, agora: _deps.relogio(), aoVerConsultas: widget.aoVerConsultas, aoBuscar: () => widget.aoBuscar(focarTexto: true))),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(Espaco.l, Espaco.xl, Espaco.l, 0),
          sliver: SliverToBoxAdapter(
            child: MaSecao('Especialidades', acao: 'Ver todas', aoTocarAcao: () => widget.aoBuscar()),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: Espaco.s),
          sliver: SliverGrid.count(
            crossAxisCount: 4,
            childAspectRatio: 0.82,
            children: [
              for (final e in p.especialidades)
                MaBlocoEspecialidade(nome: e.nome, icone: e.icone, aoTocar: () => widget.aoBuscar(especialidadeId: e.id)),
            ],
          ),
        ),
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(Espaco.l, Espaco.l, Espaco.l, 0),
          sliver: SliverToBoxAdapter(child: MaSecao('Mais bem avaliados')),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 196,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Espaco.l),
              itemCount: p.destaques.length,
              separatorBuilder: (_, _) => const SizedBox(width: Espaco.m),
              itemBuilder: (_, i) => MaCartaoMedicoVertical(p.destaques[i], aoTocar: () => _abrirMedico(p.destaques[i].id)),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: Espaco.xl)),
      ],
    );
  }
}

class _Cabecalho extends StatelessWidget {
  const _Cabecalho({required this.nome, required this.painel, required this.agora, required this.aoVerConsultas, required this.aoBuscar});
  final String nome;
  final PainelInicio painel;
  final DateTime agora;
  final VoidCallback aoVerConsultas;
  final VoidCallback aoBuscar;

  String get _saudacao => switch (agora.hour) {
        < 12 => 'Bom dia',
        < 18 => 'Boa tarde',
        _ => 'Boa noite',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: Paleta.gradienteTopo,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(Espaco.l, MediaQuery.paddingOf(context).top + Espaco.l, Espaco.l, Espaco.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$_saudacao,', style: Tipo.corpo.copyWith(color: Colors.white70)),
                    Text(nome, style: Tipo.display.copyWith(color: Colors.white)),
                  ],
                ),
              ),
              MaAvatar(nome, claro: true),
            ],
          ),
          const SizedBox(height: Espaco.l),
          Material(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: Raio.m,
            child: InkWell(
              borderRadius: Raio.m,
              onTap: aoBuscar,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: Espaco.l, vertical: 14),
                child: Row(children: [
                  Icon(Icons.search, color: Colors.white70),
                  SizedBox(width: Espaco.m),
                  Expanded(
                    child: Text(
                      'Profissional ou especialidade',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white70, fontSize: 15),
                    ),
                  ),
                ]),
              ),
            ),
          ),
          const SizedBox(height: Espaco.l),
          _ProximaConsulta(painel.proxima, total: painel.totalAgendadas, agora: agora, aoVerConsultas: aoVerConsultas),
        ],
      ),
    );
  }
}

class _ProximaConsulta extends StatelessWidget {
  const _ProximaConsulta(this.consulta, {required this.total, required this.agora, required this.aoVerConsultas});
  final Consulta? consulta;
  final int total;
  final DateTime agora;
  final VoidCallback aoVerConsultas;

  @override
  Widget build(BuildContext context) {
    final c = consulta;
    return Container(
      padding: const EdgeInsets.all(Espaco.l),
      decoration: BoxDecoration(color: Paleta.superficie, borderRadius: Raio.g, boxShadow: Sombra.leve),
      child: c == null
          ? const Row(children: [
              Icon(Icons.event_available, color: Paleta.indigo),
              SizedBox(width: Espaco.m),
              Expanded(child: Text('Nenhuma consulta marcada. Que tal agendar um check-up?', style: Tipo.apoio)),
            ])
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  MaEtiqueta(Datas.relativo(c.inicio, agora), frente: Paleta.coral, fundo: Paleta.coralSuave, icone: Icons.notifications_active_outlined),
                  const Spacer(),
                  if (total > 1)
                    GestureDetector(
                      onTap: aoVerConsultas,
                      child: Text('+${total - 1} agendada${total > 2 ? 's' : ''}', style: Tipo.apoio.copyWith(color: Paleta.indigo, fontWeight: FontWeight.w700)),
                    ),
                ]),
                const SizedBox(height: Espaco.m),
                Text(c.medicoNome, style: Tipo.subtitulo),
                Text(c.especialidadeNome, style: Tipo.apoio),
                const SizedBox(height: Espaco.m),
                Row(children: [
                  const Icon(Icons.calendar_today_outlined, size: 16, color: Paleta.indigo),
                  const SizedBox(width: 6),
                  Flexible(child: Text(Datas.porExtenso(c.inicio), style: Tipo.apoio.copyWith(color: Paleta.tinta))),
                  const SizedBox(width: Espaco.m),
                  const Icon(Icons.schedule, size: 16, color: Paleta.indigo),
                  const SizedBox(width: 6),
                  Text(Datas.hora(c.inicio), style: Tipo.apoio.copyWith(color: Paleta.tinta, fontWeight: FontWeight.w700)),
                ]),
              ],
            ),
    );
  }
}
