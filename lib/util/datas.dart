/// Formatação de datas em pt-BR sem depender do pacote intl.
class Datas {
  Datas._();

  static const _meses = [
    'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
    'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
  ];
  static const _semana = [
    'segunda', 'terça', 'quarta', 'quinta', 'sexta', 'sábado', 'domingo',
  ];

  static String _dd(int n) => n.toString().padLeft(2, '0');

  /// 2026-11-24
  static String iso(DateTime d) => '${d.year}-${_dd(d.month)}-${_dd(d.day)}';

  /// 2026-11-24T09:30
  static String isoComHora(DateTime d) => '${iso(d)}T${hora(d)}';

  /// 09:30
  static String hora(DateTime d) => '${_dd(d.hour)}:${_dd(d.minute)}';

  /// 24/11/2026
  static String curta(DateTime d) => '${_dd(d.day)}/${_dd(d.month)}/${d.year}';

  /// quinta-feira, 26 de novembro
  static String porExtenso(DateTime d) {
    final dia = _semana[d.weekday - 1];
    final sufixo = d.weekday <= 5 ? '-feira' : '';
    return '$dia$sufixo, ${d.day} de ${_meses[d.month - 1]}';
  }

  /// "QUI"
  static String siglaSemana(DateTime d) =>
      _semana[d.weekday - 1].substring(0, 3).toUpperCase();

  /// "nov"
  static String siglaMes(DateTime d) => _meses[d.month - 1].substring(0, 3);

  /// "novembro de 2026"
  static String mesAno(DateTime d) => '${_meses[d.month - 1]} de ${d.year}';

  static DateTime soData(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool mesmoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// "Hoje", "Amanhã", "Em 5 dias", "Há 3 dias"
  static String relativo(DateTime alvo, DateTime agora) {
    final dias = soData(alvo).difference(soData(agora)).inDays;
    if (dias == 0) return 'Hoje';
    if (dias == 1) return 'Amanhã';
    if (dias == -1) return 'Ontem';
    return dias > 0 ? 'Em $dias dias' : 'Há ${-dias} dias';
  }
}
