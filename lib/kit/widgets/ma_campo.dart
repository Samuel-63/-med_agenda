import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/tokens.dart';

/// Campo de texto do kit: rótulo acima, ícone, mensagem de erro e,
/// para senhas, botão de mostrar/ocultar.
class MaCampo extends StatefulWidget {
  const MaCampo({
    super.key,
    required this.rotulo,
    this.controller,
    this.icone,
    this.dica,
    this.erro,
    this.senha = false,
    this.teclado,
    this.formatadores,
    this.aoMudar,
    this.aoEnviar,
    this.acaoTeclado,
    this.somenteLeitura = false,
    this.aoTocar,
    this.linhas = 1,
    this.limite,
    this.autofill,
  });

  final String rotulo;
  final TextEditingController? controller;
  final IconData? icone;
  final String? dica;
  final String? erro;
  final bool senha;
  final TextInputType? teclado;
  final List<TextInputFormatter>? formatadores;
  final ValueChanged<String>? aoMudar;
  final ValueChanged<String>? aoEnviar;
  final TextInputAction? acaoTeclado;
  final bool somenteLeitura;
  final VoidCallback? aoTocar;
  final int linhas;
  final int? limite;
  final Iterable<String>? autofill;

  @override
  State<MaCampo> createState() => _MaCampoState();
}

class _MaCampoState extends State<MaCampo> {
  bool _oculto = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.rotulo.toUpperCase(), style: Tipo.rotulo),
        const SizedBox(height: Espaco.s - 2),
        TextField(
          controller: widget.controller,
          obscureText: widget.senha && _oculto,
          keyboardType: widget.teclado,
          inputFormatters: widget.formatadores,
          onChanged: widget.aoMudar,
          onSubmitted: widget.aoEnviar,
          textInputAction: widget.acaoTeclado,
          readOnly: widget.somenteLeitura,
          onTap: widget.aoTocar,
          minLines: widget.linhas,
          maxLines: widget.senha ? 1 : widget.linhas,
          maxLength: widget.limite,
          autofillHints: widget.autofill,
          style: Tipo.corpo,
          decoration: InputDecoration(
            hintText: widget.dica,
            hintStyle: Tipo.corpo.copyWith(color: Paleta.tintaApagada),
            errorText: widget.erro,
            prefixIcon: widget.icone == null ? null : Icon(widget.icone, size: 20),
            suffixIcon: widget.senha
                ? IconButton(
                    tooltip: _oculto ? 'Mostrar senha' : 'Ocultar senha',
                    icon: Icon(_oculto ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                    onPressed: () => setState(() => _oculto = !_oculto),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
