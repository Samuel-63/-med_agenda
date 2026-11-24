import 'package:flutter/material.dart';

import '../../app/app.dart';
import '../../app/dependencias.dart';
import '../../kit/kit.dart';
import 'entrar_controller.dart';

class EntrarPage extends StatefulWidget {
  const EntrarPage({super.key});

  @override
  State<EntrarPage> createState() => _EntrarPageState();
}

class _EntrarPageState extends State<EntrarPage> {
  late final EntrarController _vm = EntrarController(Dependencias.of(context).conta);
  final _email = TextEditingController();
  final _senha = TextEditingController();

  @override
  void dispose() {
    _vm.dispose();
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  void _usarDemo() {
    _email.text = EntrarController.emailDemo;
    _senha.text = EntrarController.senhaDemo;
    _vm
      ..mudarEmail(_email.text)
      ..mudarSenha(_senha.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Paleta.indigoEscuro,
      body: Container(
        decoration: const BoxDecoration(gradient: Paleta.gradienteTopo),
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, c) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: c.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _Marca(),
                      Expanded(child: _formulario()),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _formulario() {
    return Container(
      padding: const EdgeInsets.fromLTRB(Espaco.xl, Espaco.xxl, Espaco.xl, Espaco.xl),
      decoration: const BoxDecoration(
        color: Paleta.fundo,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) => AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Entrar na conta', style: Tipo.titulo),
              const SizedBox(height: Espaco.xs),
              const Text('Use o e-mail cadastrado para ver e marcar consultas.', style: Tipo.apoio),
              const SizedBox(height: Espaco.xl),
              if (_vm.falha != null) ...[MaAlerta(_vm.falha!), const SizedBox(height: Espaco.l)],
              MaCampo(
                key: const Key('campo-email'),
                rotulo: 'E-mail',
                controller: _email,
                icone: Icons.alternate_email,
                dica: 'voce@email.com',
                teclado: TextInputType.emailAddress,
                acaoTeclado: TextInputAction.next,
                erro: _vm.erroEmail,
                aoMudar: _vm.mudarEmail,
                autofill: const [AutofillHints.email],
              ),
              const SizedBox(height: Espaco.l),
              MaCampo(
                key: const Key('campo-senha'),
                rotulo: 'Senha',
                controller: _senha,
                icone: Icons.lock_outline,
                senha: true,
                erro: _vm.erroSenha,
                aoMudar: _vm.mudarSenha,
                aoEnviar: (_) => _vm.entrar(),
                autofill: const [AutofillHints.password],
              ),
              const SizedBox(height: Espaco.xl),
              MaBotao('Entrar', carregando: _vm.enviando, aoTocar: _vm.podeEnviar ? _vm.entrar : null),
              const SizedBox(height: Espaco.m),
              Center(
                child: ActionChip(
                  avatar: const Icon(Icons.bolt, size: 18, color: Paleta.coral),
                  label: const Text('Preencher conta de demonstração'),
                  backgroundColor: Paleta.coralSuave,
                  side: BorderSide.none,
                  onPressed: _usarDemo,
                ),
              ),
              const Spacer(),
              const SizedBox(height: Espaco.xl),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('Primeira vez aqui?', style: Tipo.apoio),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, Rotas.cadastro),
                    child: const Text('Criar conta', style: TextStyle(fontWeight: FontWeight.w800, color: Paleta.coral)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Marca extends StatelessWidget {
  const _Marca();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Espaco.xl, Espaco.xxl, Espaco.xl, Espaco.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(Espaco.m),
            decoration: BoxDecoration(color: Paleta.coral, borderRadius: Raio.m),
            child: const Icon(Icons.event_note_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(height: Espaco.l),
          Text('MedAgenda', style: Tipo.display.copyWith(color: Colors.white)),
          const SizedBox(height: Espaco.xs),
          Text(
            'Sua consulta marcada em poucos toques,\nsem fila e sem ligação.',
            style: Tipo.corpo.copyWith(color: Colors.white.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}
