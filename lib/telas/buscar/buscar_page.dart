import 'package:flutter/material.dart';

import '../../app/app.dart';
import '../../kit/kit.dart';
import '../../util/estado.dart';
import 'buscar_controller.dart';

class BuscarPage extends StatefulWidget {
  const BuscarPage({super.key, required this.vm});
  final BuscarController vm;

  @override
  State<BuscarPage> createState() => _BuscarPageState();
}

class _BuscarPageState extends State<BuscarPage> {
  final _texto = TextEditingController();

  BuscarController get _vm => widget.vm;

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Encontrar profissional')),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Espaco.l),
              child: TextField(
                key: const Key('campo-busca'),
                controller: _texto,
                onChanged: _vm.mudarTexto,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Nome ou especialidade',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _vm.texto.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Limpar',
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _texto.clear();
                            _vm.mudarTexto('');
                            _vm.buscar();
                          },
                        ),
                ),
              ),
            ),
            const SizedBox(height: Espaco.m),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: Espaco.l),
                children: [
                  _Filtro(
                    rotulo: 'Teleconsulta',
                    icone: Icons.videocam_outlined,
                    ativo: _vm.soTeleconsulta,
                    aoTocar: _vm.alternarTeleconsulta,
                  ),
                  for (final e in _vm.especialidades)
                    _Filtro(
                      rotulo: e.nome,
                      ativo: _vm.especialidadeId == e.id,
                      aoTocar: () => _vm.filtrarEspecialidade(_vm.especialidadeId == e.id ? null : e.id),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Espaco.l, Espaco.s, Espaco.s, 0),
              child: Row(
                children: [
                  Expanded(child: Text(_resumo(), style: Tipo.apoio)),
                  PopupMenuButton<Ordem>(
                    initialValue: _vm.ordem,
                    onSelected: _vm.ordenarPor,
                    itemBuilder: (_) => [for (final o in Ordem.values) PopupMenuItem(value: o, child: Text(o.rotulo))],
                    child: Padding(
                      padding: const EdgeInsets.all(Espaco.s),
                      child: Row(children: [
                        const Icon(Icons.swap_vert, size: 18, color: Paleta.indigo),
                        const SizedBox(width: 4),
                        Text(_vm.ordem.rotulo, style: Tipo.apoio.copyWith(color: Paleta.indigo, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _lista()),
          ],
        ),
      ),
    );
  }

  String _resumo() => switch (_vm.resultado) {
        Pronto(:final dado) => '${dado.length} profissiona${dado.length == 1 ? 'l' : 'is'}',
        _ => 'Buscando…',
      };

  Widget _lista() => switch (_vm.resultado) {
        Carregando() => const MaCarregando(),
        ComFalha(:final mensagem) => MaFalha(mensagem, aoTentar: _vm.buscar),
        Pronto(:final dado) when dado.isEmpty => MaVazio(
            icone: Icons.person_search_outlined,
            titulo: 'Ninguém encontrado',
            texto: 'Tente outro nome ou remova alguns filtros.',
            acao: _vm.temFiltros ? TextButton(onPressed: () {
              _texto.clear();
              _vm.limpar();
            }, child: const Text('Limpar filtros')) : null,
          ),
        Pronto(:final dado) => ListView.separated(
            padding: const EdgeInsets.fromLTRB(Espaco.l, Espaco.s, Espaco.l, Espaco.xl),
            itemCount: dado.length,
            separatorBuilder: (_, _) => const SizedBox(height: Espaco.m),
            itemBuilder: (_, i) => MaCartaoMedico(
              dado[i],
              aoTocar: () => Navigator.pushNamed(context, Rotas.medico, arguments: dado[i].id),
            ),
          ),
      };
}

class _Filtro extends StatelessWidget {
  const _Filtro({required this.rotulo, required this.ativo, required this.aoTocar, this.icone});
  final String rotulo;
  final bool ativo;
  final VoidCallback aoTocar;
  final IconData? icone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: Espaco.s),
      child: FilterChip(
        label: Text(rotulo),
        avatar: icone == null ? null : Icon(icone, size: 18, color: ativo ? Colors.white : Paleta.coral),
        selected: ativo,
        showCheckmark: false,
        onSelected: (_) => aoTocar(),
        selectedColor: Paleta.indigo,
        backgroundColor: Paleta.superficie,
        labelStyle: TextStyle(color: ativo ? Colors.white : Paleta.tinta, fontWeight: FontWeight.w600),
        side: BorderSide(color: ativo ? Paleta.indigo : Paleta.borda),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Raio.pilula)),
      ),
    );
  }
}
