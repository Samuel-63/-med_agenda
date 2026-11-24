import 'package:flutter/material.dart';

import '../../app/dependencias.dart';
import '../../kit/kit.dart';
import '../../util/datas.dart';
import '../../util/validacao.dart';
import 'cadastro_controller.dart';

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  late final _deps = Dependencias.of(context);
  late final CadastroController _vm = CadastroController(_deps.conta, _deps.relogio);
  final _nascimento = TextEditingController();

  @override
  void dispose() {
    _vm.dispose();
    _nascimento.dispose();
    super.dispose();
  }

  Future<void> _escolherNascimento() async {
    final hoje = _deps.relogio();
    final d = await showDatePicker(
      context: context,
      initialDate: _vm.nascimento ?? DateTime(hoje.year - 25),
      firstDate: DateTime(1900),
      lastDate: hoje,
      helpText: 'Data de nascimento',
      initialEntryMode: DatePickerEntryMode.input,
    );
    if (d != null) {
      _nascimento.text = Datas.curta(d);
      _vm.mudar('nascimento', d);
    }
  }

  Future<void> _enviar() async {
    final ok = await _vm.enviar();
    if (ok && mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta')),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          final e = _vm.erros;
          return ListView(
            padding: const EdgeInsets.fromLTRB(Espaco.xl, Espaco.s, Espaco.xl, Espaco.xxl),
            children: [
              const Text('Leva menos de um minuto. Seus dados ficam só com a clínica.', style: Tipo.apoio),
              const SizedBox(height: Espaco.xl),
              if (_vm.falha != null) ...[MaAlerta(_vm.falha!), const SizedBox(height: Espaco.l)],
              _Grupo('Sobre você', [
                MaCampo(rotulo: 'Nome completo', icone: Icons.person_outline, erro: e['nome'], aoMudar: (v) => _vm.mudar('nome', v)),
                MaCampo(
                  rotulo: 'Data de nascimento',
                  icone: Icons.cake_outlined,
                  controller: _nascimento,
                  somenteLeitura: true,
                  dica: 'dd/mm/aaaa',
                  erro: e['nascimento'],
                  aoTocar: _escolherNascimento,
                ),
              ]),
              _Grupo('Contato', [
                MaCampo(
                  rotulo: 'E-mail',
                  icone: Icons.alternate_email,
                  teclado: TextInputType.emailAddress,
                  erro: e['email'],
                  aoMudar: (v) => _vm.mudar('email', v),
                ),
                MaCampo(
                  rotulo: 'Celular',
                  icone: Icons.phone_iphone,
                  dica: '(62) 99999-0000',
                  teclado: TextInputType.phone,
                  formatadores: [MascaraCelular()],
                  erro: e['celular'],
                  aoMudar: (v) => _vm.mudar('celular', v),
                ),
              ]),
              _Grupo('Segurança', [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MaCampo(rotulo: 'Senha', icone: Icons.lock_outline, senha: true, erro: e['senha'], aoMudar: (v) => _vm.mudar('senha', v)),
                    const SizedBox(height: Espaco.s),
                    _BarraForca(_vm.forcaSenha, visivel: _vm.senha.isNotEmpty),
                  ],
                ),
                MaCampo(
                  rotulo: 'Repita a senha',
                  icone: Icons.lock_reset,
                  senha: true,
                  erro: e['confirmacao'],
                  aoMudar: (v) => _vm.mudar('confirmacao', v),
                ),
              ]),
              CheckboxListTile(
                value: _vm.aceitouTermos,
                onChanged: (v) => _vm.mudar('termos', v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                activeColor: Paleta.indigo,
                title: const Text('Li e aceito os termos de uso e a política de privacidade.', style: Tipo.apoio),
                subtitle: e['termos'] == null ? null : Text(e['termos']!, style: const TextStyle(color: Paleta.vermelho, fontSize: 12)),
              ),
              const SizedBox(height: Espaco.l),
              MaBotao('Criar minha conta', variante: VarianteBotao.destaque, carregando: _vm.enviando, aoTocar: _enviar),
            ],
          );
        },
      ),
    );
  }
}

class _Grupo extends StatelessWidget {
  const _Grupo(this.titulo, this.campos);
  final String titulo;
  final List<Widget> campos;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Espaco.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(titulo, style: Tipo.subtitulo.copyWith(color: Paleta.indigo)),
          const SizedBox(height: Espaco.m),
          for (final c in campos) Padding(padding: const EdgeInsets.only(bottom: Espaco.l), child: c),
        ],
      ),
    );
  }
}

class _BarraForca extends StatelessWidget {
  const _BarraForca(this.forca, {required this.visivel});
  final int forca;
  final bool visivel;

  static const _rotulos = ['Muito fraca', 'Fraca', 'Razoável', 'Boa', 'Forte'];
  static const _cores = [Paleta.vermelho, Paleta.vermelho, Paleta.ambar, Paleta.verde, Paleta.verde];

  @override
  Widget build(BuildContext context) {
    if (!visivel) return const SizedBox.shrink();
    return Row(
      children: [
        for (var i = 0; i < 4; i++)
          Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: i < forca ? _cores[forca] : Paleta.borda,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        const SizedBox(width: Espaco.s),
        Text(_rotulos[forca], style: Tipo.apoio.copyWith(fontSize: 12, color: _cores[forca])),
      ],
    );
  }
}
