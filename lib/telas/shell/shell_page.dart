import 'package:flutter/material.dart';

import '../../app/dependencias.dart';
import '../buscar/buscar_controller.dart';
import '../buscar/buscar_page.dart';
import '../consultas/consultas_page.dart';
import '../inicio/inicio_page.dart';
import '../perfil/perfil_page.dart';

/// Estrutura do app logado: quatro abas na barra inferior.
///
/// O controller da Busca mora aqui para que o Início consiga abrir
/// a busca já filtrada por uma especialidade.
class ShellPage extends StatefulWidget {
  const ShellPage({super.key});

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  int _aba = 0;
  late final BuscarController _busca = BuscarController(Dependencias.of(context).agenda);

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  void _irPara(int aba) => setState(() => _aba = aba);

  void _buscarPor({String? especialidadeId, bool focarTexto = false}) {
    _busca.filtrarEspecialidade(especialidadeId);
    _irPara(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _aba,
        children: [
          InicioPage(aoBuscar: _buscarPor, aoVerConsultas: () => _irPara(2)),
          BuscarPage(vm: _busca),
          const ConsultasPage(),
          const PerfilPage(),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE1E3EE)))),
        child: NavigationBar(
          selectedIndex: _aba,
          onDestinationSelected: _irPara,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.space_dashboard_outlined), selectedIcon: Icon(Icons.space_dashboard), label: 'Início'),
            NavigationDestination(icon: Icon(Icons.search), selectedIcon: Icon(Icons.manage_search), label: 'Buscar'),
            NavigationDestination(icon: Icon(Icons.event_note_outlined), selectedIcon: Icon(Icons.event_note), label: 'Consultas'),
            NavigationDestination(icon: Icon(Icons.account_circle_outlined), selectedIcon: Icon(Icons.account_circle), label: 'Perfil'),
          ],
        ),
      ),
    );
  }
}
