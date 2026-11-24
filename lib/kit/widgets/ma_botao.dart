import 'package:flutter/material.dart';

import '../tokens/tokens.dart';

enum VarianteBotao { primario, destaque, contorno, fantasma, perigo }

/// Botão do kit. Mostra um spinner quando [carregando] e fica
/// desabilitado quando [aoTocar] é nulo.
class MaBotao extends StatelessWidget {
  const MaBotao(
    this.rotulo, {
    super.key,
    required this.aoTocar,
    this.variante = VarianteBotao.primario,
    this.icone,
    this.carregando = false,
    this.largo = true,
  });

  final String rotulo;
  final VoidCallback? aoTocar;
  final VarianteBotao variante;
  final IconData? icone;
  final bool carregando;
  final bool largo;

  @override
  Widget build(BuildContext context) {
    final (fundo, frente, borda) = switch (variante) {
      VarianteBotao.primario => (Paleta.indigo, Colors.white, Colors.transparent),
      VarianteBotao.destaque => (Paleta.coral, Colors.white, Colors.transparent),
      VarianteBotao.contorno => (Paleta.superficie, Paleta.indigo, Paleta.indigo),
      VarianteBotao.fantasma => (Colors.transparent, Paleta.indigo, Colors.transparent),
      VarianteBotao.perigo => (Paleta.vermelhoSuave, Paleta.vermelho, Colors.transparent),
    };
    final ativo = aoTocar != null && !carregando;

    final conteudo = carregando
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: frente),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icone != null) ...[Icon(icone, size: 20), const SizedBox(width: Espaco.s)],
              Flexible(child: Text(rotulo, overflow: TextOverflow.ellipsis)),
            ],
          );

    final botao = TextButton(
      onPressed: ativo ? aoTocar : null,
      style: TextButton.styleFrom(
        backgroundColor: ativo || carregando ? fundo : Paleta.borda,
        foregroundColor: frente,
        disabledForegroundColor: carregando ? frente : Paleta.tintaApagada,
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: Espaco.xl),
        textStyle: Tipo.botao,
        shape: RoundedRectangleBorder(
          borderRadius: Raio.m,
          side: BorderSide(color: ativo ? borda : Colors.transparent, width: 1.4),
        ),
      ),
      child: conteudo,
    );
    return largo ? SizedBox(width: double.infinity, child: botao) : botao;
  }
}
