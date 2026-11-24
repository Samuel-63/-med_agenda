import 'package:flutter/material.dart';

import '../../modelos/modelos.dart';
import '../tokens/tokens.dart';

/// Ícone de cada especialidade (o backend manda um apelido, o app traduz).
IconData iconeEspecialidade(String apelido) => switch (apelido) {
      'stethoscope' => Icons.medical_services_outlined,
      'heart' => Icons.monitor_heart_outlined,
      'female' => Icons.pregnant_woman_outlined,
      'mind' => Icons.self_improvement_outlined,
      'drop' => Icons.water_drop_outlined,
      'ear' => Icons.hearing_outlined,
      'skin' => Icons.spa_outlined,
      'food' => Icons.restaurant_outlined,
      _ => Icons.local_hospital_outlined,
    };

/// Superfície branca com borda fina: base de todos os cartões.
class MaPainel extends StatelessWidget {
  const MaPainel({super.key, required this.child, this.aoTocar, this.preenchimento = const EdgeInsets.all(Espaco.l), this.cor});

  final Widget child;
  final VoidCallback? aoTocar;
  final EdgeInsets preenchimento;
  final Color? cor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cor ?? Paleta.superficie,
      shape: RoundedRectangleBorder(borderRadius: Raio.g, side: const BorderSide(color: Paleta.borda)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: aoTocar, child: Padding(padding: preenchimento, child: child)),
    );
  }
}

/// Círculo com as iniciais do nome (ignora "Dr." e "Dra.").
class MaAvatar extends StatelessWidget {
  const MaAvatar(this.nome, {super.key, this.tamanho = 48, this.claro = false});

  final String nome;
  final double tamanho;
  final bool claro;

  static String iniciais(String nome) {
    final partes = nome.split(' ').where((p) => p.isNotEmpty && !p.endsWith('.')).toList();
    if (partes.isEmpty) return '?';
    final a = partes.first[0];
    final b = partes.length > 1 ? partes.last[0] : '';
    return (a + b).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamanho,
      height: tamanho,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: claro ? Colors.white.withValues(alpha: 0.18) : Paleta.indigoSuave,
        borderRadius: BorderRadius.circular(tamanho * 0.32),
      ),
      child: Text(
        iniciais(nome),
        style: TextStyle(
          fontSize: tamanho * 0.36,
          fontWeight: FontWeight.w800,
          color: claro ? Colors.white : Paleta.indigo,
        ),
      ),
    );
  }
}

/// Etiqueta em formato de pílula.
class MaEtiqueta extends StatelessWidget {
  const MaEtiqueta(this.texto, {super.key, this.frente = Paleta.indigo, this.fundo = Paleta.indigoSuave, this.icone});

  factory MaEtiqueta.situacao(Situacao s) => switch (s) {
        Situacao.agendada => MaEtiqueta(s.rotulo, frente: Paleta.verde, fundo: Paleta.verdeSuave, icone: Icons.event_available),
        Situacao.concluida => MaEtiqueta(s.rotulo, frente: Paleta.tintaSuave, fundo: Paleta.fundo, icone: Icons.check),
        Situacao.cancelada => MaEtiqueta(s.rotulo, frente: Paleta.vermelho, fundo: Paleta.vermelhoSuave, icone: Icons.close),
      };

  factory MaEtiqueta.modalidade(Modalidade m) => m == Modalidade.teleconsulta
      ? MaEtiqueta(m.rotulo, frente: Paleta.coral, fundo: Paleta.coralSuave, icone: Icons.videocam_outlined)
      : MaEtiqueta(m.rotulo, icone: Icons.place_outlined);

  final String texto;
  final Color frente;
  final Color fundo;
  final IconData? icone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: fundo, borderRadius: BorderRadius.circular(Raio.pilula)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icone != null) ...[Icon(icone, size: 14, color: frente), const SizedBox(width: 4)],
          Text(texto, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: frente)),
        ],
      ),
    );
  }
}

/// Nota com estrela e quantidade de avaliações.
class MaNota extends StatelessWidget {
  const MaNota(this.nota, {super.key, this.avaliacoes});
  final double nota;
  final int? avaliacoes;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, size: 18, color: Paleta.ambar),
        const SizedBox(width: 2),
        Text(nota.toStringAsFixed(1).replaceAll('.', ','), style: Tipo.apoio.copyWith(color: Paleta.tinta, fontWeight: FontWeight.w700)),
        if (avaliacoes != null) Text(' ($avaliacoes)', style: Tipo.apoio),
      ],
    );
  }
}

/// Cabeçalho de seção, com ação opcional à direita.
class MaSecao extends StatelessWidget {
  const MaSecao(this.titulo, {super.key, this.acao, this.aoTocarAcao});
  final String titulo;
  final String? acao;
  final VoidCallback? aoTocarAcao;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Espaco.m),
      child: Row(
        children: [
          Expanded(child: Text(titulo, style: Tipo.subtitulo.copyWith(fontSize: 17))),
          if (acao != null)
            GestureDetector(
              onTap: aoTocarAcao,
              child: Text(acao!, style: Tipo.apoio.copyWith(color: Paleta.coral, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}

/// Mensagem amigável para listas vazias.
class MaVazio extends StatelessWidget {
  const MaVazio({super.key, required this.icone, required this.titulo, this.texto, this.acao});
  final IconData icone;
  final String titulo;
  final String? texto;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Espaco.xl, vertical: Espaco.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(Espaco.l),
            decoration: const BoxDecoration(color: Paleta.coralSuave, shape: BoxShape.circle),
            child: Icon(icone, size: 32, color: Paleta.coral),
          ),
          const SizedBox(height: Espaco.l),
          Text(titulo, style: Tipo.subtitulo, textAlign: TextAlign.center),
          if (texto != null) ...[
            const SizedBox(height: Espaco.xs),
            Text(texto!, style: Tipo.apoio, textAlign: TextAlign.center),
          ],
          if (acao != null) ...[const SizedBox(height: Espaco.l), acao!],
        ],
      ),
    );
  }
}

/// Erro de carregamento com botão "Tentar de novo".
class MaFalha extends StatelessWidget {
  const MaFalha(this.mensagem, {super.key, required this.aoTentar});
  final String mensagem;
  final VoidCallback aoTentar;

  @override
  Widget build(BuildContext context) {
    return MaVazio(
      icone: Icons.wifi_off_rounded,
      titulo: 'Não foi possível carregar',
      texto: mensagem,
      acao: TextButton.icon(onPressed: aoTentar, icon: const Icon(Icons.refresh), label: const Text('Tentar de novo')),
    );
  }
}

/// Faixa vermelha de erro usada em formulários.
class MaAlerta extends StatelessWidget {
  const MaAlerta(this.mensagem, {super.key});
  final String mensagem;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Espaco.m),
      decoration: BoxDecoration(color: Paleta.vermelhoSuave, borderRadius: Raio.p),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Paleta.vermelho, size: 20),
          const SizedBox(width: Espaco.s),
          Expanded(child: Text(mensagem, style: Tipo.apoio.copyWith(color: Paleta.vermelho))),
        ],
      ),
    );
  }
}

class MaCarregando extends StatelessWidget {
  const MaCarregando({super.key});
  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(padding: EdgeInsets.all(Espaco.xxl), child: CircularProgressIndicator(color: Paleta.indigo)),
      );
}
