import 'package:flutter/material.dart';

import '../tokens/tokens.dart';
import 'ma_botao.dart';

/// Folha inferior de confirmação. Devolve `true` se o usuário confirmou.
Future<bool> perguntar(
  BuildContext context, {
  required String titulo,
  required String mensagem,
  required String confirmar,
  String voltar = 'Voltar',
  bool perigoso = false,
  IconData icone = Icons.help_outline,
}) async {
  final r = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Paleta.superficie,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Raio.grande))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Espaco.xl, 0, Espaco.xl, Espaco.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: perigoso ? Paleta.vermelhoSuave : Paleta.indigoSuave,
              child: Icon(icone, color: perigoso ? Paleta.vermelho : Paleta.indigo, size: 28),
            ),
            const SizedBox(height: Espaco.l),
            Text(titulo, style: Tipo.titulo, textAlign: TextAlign.center),
            const SizedBox(height: Espaco.s),
            Text(mensagem, style: Tipo.corpo.copyWith(color: Paleta.tintaSuave), textAlign: TextAlign.center),
            const SizedBox(height: Espaco.xl),
            MaBotao(
              confirmar,
              variante: perigoso ? VarianteBotao.perigo : VarianteBotao.primario,
              aoTocar: () => Navigator.pop(ctx, true),
            ),
            const SizedBox(height: Espaco.s),
            MaBotao(voltar, variante: VarianteBotao.fantasma, aoTocar: () => Navigator.pop(ctx, false)),
          ],
        ),
      ),
    ),
  );
  return r ?? false;
}

/// Aviso rápido no rodapé.
void avisar(BuildContext context, String mensagem, {bool erro = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Row(children: [
        Icon(erro ? Icons.error_outline : Icons.check_circle_outline, color: erro ? Paleta.coral : Colors.white),
        const SizedBox(width: Espaco.s),
        Expanded(child: Text(mensagem)),
      ]),
    ));
}
