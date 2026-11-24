import 'package:flutter/material.dart';

import '../../app/app.dart';
import '../../app/dependencias.dart';
import '../../kit/kit.dart';
import '../../util/datas.dart';
import '../../util/validacao.dart';

/// Perfil: só exibe dados da sessão, por isso não precisa de controller.
class PerfilPage extends StatelessWidget {
  const PerfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    final deps = Dependencias.of(context);
    final p = deps.conta.paciente;
    if (p == null) return const SizedBox.shrink();
    final idade = _idade(p.nascimento, deps.relogio());

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(Espaco.l),
        children: [
          MaPainel(
            child: Row(children: [
              MaAvatar(p.nome, tamanho: 64),
              const SizedBox(width: Espaco.l),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.nome, style: Tipo.titulo),
                  Text('$idade anos', style: Tipo.apoio),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: Espaco.l),
          MaPainel(
            preenchimento: EdgeInsets.zero,
            child: Column(children: [
              _Linha(Icons.alternate_email, 'E-mail', p.email),
              const Divider(indent: 56),
              _Linha(Icons.phone_iphone, 'Celular', MascaraCelular.formatar(p.celular)),
              const Divider(indent: 56),
              _Linha(Icons.cake_outlined, 'Nascimento', Datas.curta(p.nascimento)),
            ]),
          ),
          const SizedBox(height: Espaco.l),
          MaPainel(
            preenchimento: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.palette_outlined, color: Paleta.indigo),
              title: const Text('Catálogo de componentes', style: Tipo.subtitulo),
              subtitle: const Text('Tokens e componentes do Kit MedAgenda', style: Tipo.apoio),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, Rotas.catalogo),
            ),
          ),
          const SizedBox(height: Espaco.xl),
          MaBotao(
            'Sair da conta',
            icone: Icons.logout,
            variante: VarianteBotao.perigo,
            aoTocar: () async {
              final ok = await perguntar(
                context,
                titulo: 'Sair do MedAgenda?',
                mensagem: 'Você precisará entrar de novo para ver suas consultas.',
                confirmar: 'Sair',
                perigoso: true,
                icone: Icons.logout,
              );
              if (ok) deps.conta.sair();
            },
          ),
          const SizedBox(height: Espaco.l),
          const Center(child: Text('MedAgenda 1.0 · dados de demonstração', style: Tipo.apoio)),
        ],
      ),
    );
  }

  static int _idade(DateTime nasc, DateTime hoje) {
    var anos = hoje.year - nasc.year;
    if (hoje.month < nasc.month || (hoje.month == nasc.month && hoje.day < nasc.day)) anos--;
    return anos;
  }
}

class _Linha extends StatelessWidget {
  const _Linha(this.icone, this.rotulo, this.valor);
  final IconData icone;
  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icone, color: Paleta.indigo),
        title: Text(rotulo, style: Tipo.apoio),
        subtitle: Text(valor, style: Tipo.corpo),
      );
}
