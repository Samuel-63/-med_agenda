import 'package:flutter/material.dart';

import '../../app/app.dart';
import '../../app/dependencias.dart';
import '../../kit/kit.dart';
import '../../modelos/modelos.dart';
import '../../util/datas.dart';
import '../../util/estado.dart';
import 'consultas_controller.dart';

class ConsultasPage extends StatefulWidget {
  const ConsultasPage({super.key});

  @override
  State<ConsultasPage> createState() => _ConsultasPageState();
}

class _ConsultasPageState extends State<ConsultasPage> {
  late final ConsultasController _vm = ConsultasController(Dependencias.of(context).agenda);

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _cancelar(Consulta c) async {
    final ok = await perguntar(
      context,
      titulo: 'Cancelar esta consulta?',
      mensagem: '${c.medicoNome} · ${Datas.porExtenso(c.inicio)} às ${Datas.hora(c.inicio)}.\n'
          'O horário será liberado para outros pacientes.',
      confirmar: 'Sim, cancelar',
      voltar: 'Manter consulta',
      perigoso: true,
      icone: Icons.event_busy,
    );
    if (!ok || !mounted) return;
    final erro = await _vm.cancelar(c.id);
    if (!mounted) return;
    avisar(context, erro ?? 'Consulta cancelada.', erro: erro != null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minhas consultas')),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Espaco.l),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<Aba>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: Aba.proximas, label: Text('Próximas'), icon: Icon(Icons.upcoming_outlined)),
                    ButtonSegment(value: Aba.anteriores, label: Text('Histórico'), icon: Icon(Icons.history)),
                  ],
                  selected: {_vm.aba},
                  onSelectionChanged: (s) => _vm.trocarAba(s.first),
                ),
              ),
            ),
            const SizedBox(height: Espaco.m),
            Expanded(child: RefreshIndicator(onRefresh: _vm.carregar, child: _corpo())),
          ],
        ),
      ),
    );
  }

  Widget _corpo() {
    Widget rolavel(Widget filho) => ListView(children: [filho]); // permite "puxar para atualizar"
    return switch (_vm.lista) {
      Carregando() => const MaCarregando(),
      ComFalha(:final mensagem) => rolavel(MaFalha(mensagem, aoTentar: _vm.carregar)),
      Pronto(:final dado) when dado.isEmpty => rolavel(
          _vm.aba == Aba.proximas
              ? const MaVazio(
                  icone: Icons.event_available,
                  titulo: 'Nada marcado por enquanto',
                  texto: 'Use a aba Buscar para encontrar um profissional e escolher um horário.',
                )
              : const MaVazio(icone: Icons.history, titulo: 'Sem histórico ainda'),
        ),
      Pronto(:final dado) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(Espaco.l, 0, Espaco.l, Espaco.xl),
          itemCount: dado.length,
          separatorBuilder: (_, _) => const SizedBox(height: Espaco.m),
          itemBuilder: (_, i) => _item(dado[i]),
        ),
    };
  }

  Widget _item(Consulta c) {
    if (c.situacao != Situacao.agendada) {
      return MaCartaoConsulta(
        c,
        rodape: Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, Rotas.medico, arguments: c.medicoId),
            icon: const Icon(Icons.replay, size: 18),
            label: const Text('Agendar de novo'),
          ),
        ),
      );
    }
    final cancelando = _vm.cancelando.contains(c.id);
    return MaCartaoConsulta(
      c,
      rodape: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: Paleta.tintaSuave),
          const SizedBox(width: 6),
          const Expanded(child: Text('Cancelamento até 2 h antes', style: Tipo.apoio)),
          MaBotao(
            'Cancelar',
            largo: false,
            variante: VarianteBotao.perigo,
            carregando: cancelando,
            aoTocar: () => _cancelar(c),
          ),
        ],
      ),
    );
  }
}
