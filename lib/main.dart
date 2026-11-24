import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/dependencias.dart';
import 'repositorios/repositorios.dart';
import 'servicos/api_med_agenda.dart';
import 'servicos/transporte.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Para usar um backend real, troque apenas esta linha por um TransporteHttp.
  final Transporte transporte = await TransporteFake.doAsset();

  final api = ApiMedAgenda(transporte);
  runApp(Dependencias(
    conta: ContaRepositorio(api),
    agenda: AgendaRepositorio(api),
    relogio: DateTime.now,
    child: const MedAgendaApp(),
  ));
}
