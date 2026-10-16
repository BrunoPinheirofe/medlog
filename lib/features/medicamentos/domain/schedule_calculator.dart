import 'package:material_ui/material_ui.dart';
import '../models/medicamento.dart';

/// Utilitário de domínio para cálculo, ordenação e formatação de horários de doses.
class ScheduleCalculator {
  const ScheduleCalculator._();

  /// Calcula a lista de horários diários a partir de um horário inicial, frequência e intervalo opcional.
  static List<TimeOfDay> gerarHorarios({
    required TimeOfDay inicial,
    required Frequencia frequencia,
    int? intervaloHoras,
  }) {
    if (frequencia == Frequencia.quandoNecessario) {
      return const [];
    }

    final List<TimeOfDay> lista = [inicial];

    switch (frequencia) {
      case Frequencia.umaVez:
        break;

      case Frequencia.duasVezes:
        lista.add(TimeOfDay(
          hour: (inicial.hour + 12) % 24,
          minute: inicial.minute,
        ));
        break;

      case Frequencia.tresVezes:
        lista.add(TimeOfDay(
          hour: (inicial.hour + 8) % 24,
          minute: inicial.minute,
        ));
        lista.add(TimeOfDay(
          hour: (inicial.hour + 16) % 24,
          minute: inicial.minute,
        ));
        break;

      case Frequencia.quatroVezes:
        lista.add(TimeOfDay(
          hour: (inicial.hour + 6) % 24,
          minute: inicial.minute,
        ));
        lista.add(TimeOfDay(
          hour: (inicial.hour + 12) % 24,
          minute: inicial.minute,
        ));
        lista.add(TimeOfDay(
          hour: (inicial.hour + 18) % 24,
          minute: inicial.minute,
        ));
        break;

      case Frequencia.intervaloHoras:
        if (intervaloHoras != null && intervaloHoras > 0 && intervaloHoras < 24) {
          int horasAdicionadas = intervaloHoras;
          while (horasAdicionadas < 24) {
            lista.add(TimeOfDay(
              hour: (inicial.hour + horasAdicionadas) % 24,
              minute: inicial.minute,
            ));
            horasAdicionadas += intervaloHoras;
          }
        }
        break;

      case Frequencia.quandoNecessario:
      case Frequencia.personalizado:
        break;
    }

    return normalizarEOrdenar(lista);
  }

  /// Remove duplicatas e ordena cronologicamente (00:00 até 23:59).
  static List<TimeOfDay> normalizarEOrdenar(List<TimeOfDay> horarios) {
    final Map<int, TimeOfDay> mapaMinutos = {};
    for (final h in horarios) {
      final minutosDoDia = h.hour * 60 + h.minute;
      mapaMinutos.putIfAbsent(minutosDoDia, () => h);
    }

    final ordenados = mapaMinutos.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return ordenados.map((e) => e.value).toList();
  }

  /// Retorna a quantidade estimada de doses por dia com base na frequência.
  static int? calcularDosesPorDia(Frequencia frequencia, int? intervaloHoras) {
    switch (frequencia) {
      case Frequencia.umaVez:
        return 1;
      case Frequencia.duasVezes:
        return 2;
      case Frequencia.tresVezes:
        return 3;
      case Frequencia.quatroVezes:
        return 4;
      case Frequencia.intervaloHoras:
        if (intervaloHoras != null && intervaloHoras > 0) {
          return (24 / intervaloHoras).floor();
        }
        return null;
      case Frequencia.quandoNecessario:
        return 0;
      case Frequencia.personalizado:
        return null;
    }
  }

  /// Formata um [TimeOfDay] no padrão brasileiro `HH:mm`.
  static String formatar(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Interpreta uma string `HH:mm` em [TimeOfDay].
  static TimeOfDay parse(String horario) {
    final partes = horario.split(':');
    return TimeOfDay(hour: int.parse(partes[0]), minute: int.parse(partes[1]));
  }
}
