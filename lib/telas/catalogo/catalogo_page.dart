import 'package:flutter/material.dart';

import '../../kit/kit.dart';
import '../../modelos/modelos.dart';

/// Vitrine do Kit MedAgenda: tokens e cada componente nos seus estados.
/// Abra pelo Perfil ou direto com `flutter run -t lib/main_catalogo.dart`.
class CatalogoPage extends StatefulWidget {
  const CatalogoPage({super.key});

  @override
  State<CatalogoPage> createState() => _CatalogoPageState();
}

class _CatalogoPageState extends State<CatalogoPage> {
  int _dia = 1;
  String? _hora = '09:30';
  bool _carregando = false;

  static final _hoje = DateTime(2026, 11, 23);

  static const _medico = Medico(
    id: 'x',
    nome: 'Dra. Exemplo Silva',
    especialidadeId: 'cardio',
    especialidadeNome: 'Cardiologia',
    registro: 'CRM-GO 00000',
    nota: 4.8,
    avaliacoes: 120,
    valor: 200,
    teleconsulta: true,
    sobre: '',
  );

  Consulta _consulta(Situacao s, Modalidade m) => Consulta(
        id: s.name,
        medicoId: 'x',
        medicoNome: 'Dra. Exemplo Silva',
        especialidadeNome: 'Cardiologia',
        inicio: DateTime(2026, 11, 26, 14, 30),
        modalidade: m,
        situacao: s,
        motivo: s == Situacao.agendada ? 'Retorno' : null,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kit MedAgenda')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Espaco.l, 0, Espaco.l, Espaco.xxl),
        children: [
          _Bloco('Cores', [
            Wrap(spacing: Espaco.s, runSpacing: Espaco.s, children: const [
              _Cor('indigo', Paleta.indigo),
              _Cor('indigoEscuro', Paleta.indigoEscuro),
              _Cor('indigoSuave', Paleta.indigoSuave),
              _Cor('coral', Paleta.coral),
              _Cor('coralSuave', Paleta.coralSuave),
              _Cor('tinta', Paleta.tinta),
              _Cor('tintaSuave', Paleta.tintaSuave),
              _Cor('borda', Paleta.borda),
              _Cor('fundo', Paleta.fundo),
              _Cor('verde', Paleta.verde),
              _Cor('vermelho', Paleta.vermelho),
              _Cor('ambar', Paleta.ambar),
            ]),
          ]),
          _Bloco('Tipografia', const [
            Text('Display 28', style: Tipo.display),
            Text('Título 20', style: Tipo.titulo),
            Text('Subtítulo 16', style: Tipo.subtitulo),
            Text('Corpo 15 — texto corrido das telas.', style: Tipo.corpo),
            Text('Apoio 13 — informações secundárias', style: Tipo.apoio),
            Text('RÓTULO 12', style: Tipo.rotulo),
          ]),
          _Bloco('Espaços e raios', [
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              for (final e in const [Espaco.xs, Espaco.s, Espaco.m, Espaco.l, Espaco.xl, Espaco.xxl])
                Padding(
                  padding: const EdgeInsets.only(right: Espaco.s),
                  child: Column(children: [
                    Container(width: e, height: e, color: Paleta.coral),
                    Text('${e.toInt()}', style: Tipo.apoio),
                  ]),
                ),
              const Spacer(),
              for (final r in const [Raio.pequeno, Raio.medio, Raio.grande])
                Container(
                  margin: const EdgeInsets.only(left: Espaco.s),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: Paleta.indigoSuave, borderRadius: BorderRadius.circular(r)),
                  alignment: Alignment.center,
                  child: Text('${r.toInt()}', style: Tipo.apoio),
                ),
            ]),
          ]),
          _Bloco('MaBotao', [
            MaBotao('Primário', aoTocar: () {}),
            MaBotao('Destaque', variante: VarianteBotao.destaque, icone: Icons.check, aoTocar: () {}),
            MaBotao('Contorno', variante: VarianteBotao.contorno, aoTocar: () {}),
            MaBotao('Fantasma', variante: VarianteBotao.fantasma, aoTocar: () {}),
            MaBotao('Perigo', variante: VarianteBotao.perigo, icone: Icons.delete_outline, aoTocar: () {}),
            const MaBotao('Desabilitado', aoTocar: null),
            MaBotao('Toque para carregar', carregando: _carregando, aoTocar: () async {
              setState(() => _carregando = true);
              await Future<void>.delayed(const Duration(seconds: 2));
              if (mounted) setState(() => _carregando = false);
            }),
          ]),
          _Bloco('MaCampo', const [
            MaCampo(rotulo: 'Normal', icone: Icons.person_outline, dica: 'Digite aqui'),
            MaCampo(rotulo: 'Com erro', icone: Icons.alternate_email, erro: 'E-mail em formato inválido.'),
            MaCampo(rotulo: 'Senha', icone: Icons.lock_outline, senha: true),
          ]),
          _Bloco('MaEtiqueta e MaNota', [
            Wrap(spacing: Espaco.s, runSpacing: Espaco.s, children: [
              for (final s in Situacao.values) MaEtiqueta.situacao(s),
              for (final m in Modalidade.values) MaEtiqueta.modalidade(m),
              const MaNota(4.8, avaliacoes: 120),
            ]),
          ]),
          _Bloco('MaAvatar', const [
            Row(children: [
              MaAvatar('Dra. Ana Souza', tamanho: 40),
              SizedBox(width: Espaco.m),
              MaAvatar('Lucas Andrade', tamanho: 56),
              SizedBox(width: Espaco.m),
              MaAvatar('Pedro', tamanho: 72),
            ]),
          ]),
          _Bloco('MaBlocoEspecialidade', [
            Row(children: [
              for (final (n, i, sel) in const [('Cardiologia', 'heart', true), ('Nutrição', 'food', false), ('Otorrino', 'ear', false), ('Clínico', 'stethoscope', false)])
                Expanded(child: MaBlocoEspecialidade(nome: n, icone: i, selecionado: sel, aoTocar: () {})),
            ]),
          ]),
          _Bloco('Cartões de profissional', [
            MaCartaoMedico(_medico, aoTocar: () {}),
            SizedBox(height: 186, child: Align(alignment: Alignment.centerLeft, child: MaCartaoMedicoVertical(_medico, aoTocar: () {}))),
          ]),
          _Bloco('MaCartaoConsulta', [
            MaCartaoConsulta(_consulta(Situacao.agendada, Modalidade.presencial)),
            MaCartaoConsulta(_consulta(Situacao.concluida, Modalidade.teleconsulta)),
            MaCartaoConsulta(_consulta(Situacao.cancelada, Modalidade.presencial)),
          ]),
          _Bloco('MaDiaSemana (toque para escolher)', [
            MaPainel(
              preenchimento: const EdgeInsets.all(Espaco.s),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                for (var i = 0; i < 7; i++)
                  MaDiaSemana(
                    data: _hoje.add(Duration(days: i)),
                    atende: i != 5 && i != 6,
                    temVaga: i != 3,
                    selecionado: _dia == i,
                    aoTocar: () => setState(() => _dia = i),
                  ),
              ]),
            ),
          ]),
          _Bloco('MaHorario', [
            Wrap(spacing: Espaco.s, runSpacing: Espaco.s, children: [
              for (final (h, livre) in const [('08:00', true), ('08:30', false), ('09:00', true), ('09:30', true), ('10:00', false)])
                MaHorario(h, livre: livre, selecionado: _hora == h, aoTocar: () => setState(() => _hora = h)),
            ]),
          ]),
          _Bloco('Estados de tela', [
            const MaAlerta('E-mail ou senha não conferem.'),
            const MaPainel(child: MaVazio(icone: Icons.event_available, titulo: 'Nada marcado por enquanto', texto: 'Texto de apoio do estado vazio.')),
            MaPainel(child: MaFalha('Sem conexão com o servidor.', aoTentar: () {})),
          ]),
          _Bloco('Diálogos', [
            MaBotao('Abrir confirmação', variante: VarianteBotao.contorno, aoTocar: () => perguntar(context, titulo: 'Confirmar consulta?', mensagem: 'Exemplo de folha de confirmação.', confirmar: 'Confirmar')),
            MaBotao('Abrir confirmação destrutiva', variante: VarianteBotao.perigo, aoTocar: () => perguntar(context, titulo: 'Cancelar consulta?', mensagem: 'Essa ação não pode ser desfeita.', confirmar: 'Sim, cancelar', perigoso: true, icone: Icons.event_busy)),
            MaBotao('Mostrar aviso', variante: VarianteBotao.fantasma, aoTocar: () => avisar(context, 'Consulta marcada!')),
          ]),
        ],
      ),
    );
  }
}

class _Bloco extends StatelessWidget {
  const _Bloco(this.titulo, this.filhos);
  final String titulo;
  final List<Widget> filhos;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Espaco.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(titulo, style: Tipo.subtitulo.copyWith(color: Paleta.indigo)),
          const SizedBox(height: Espaco.m),
          for (final f in filhos) Padding(padding: const EdgeInsets.only(bottom: Espaco.s), child: f),
        ],
      ),
    );
  }
}

class _Cor extends StatelessWidget {
  const _Cor(this.nome, this.cor);
  final String nome;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    final hex = '#${cor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
    return SizedBox(
      width: 100,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(height: 44, decoration: BoxDecoration(color: cor, borderRadius: Raio.p, border: Border.all(color: Paleta.borda))),
        const SizedBox(height: 4),
        Text(nome, style: Tipo.apoio.copyWith(color: Paleta.tinta, fontWeight: FontWeight.w700, fontSize: 12)),
        Text(hex, style: Tipo.apoio.copyWith(fontSize: 11)),
      ]),
    );
  }
}
