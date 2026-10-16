import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:medlog/features/medicamentos/domain/schedule_calculator.dart';
import 'package:medlog/features/medicamentos/models/medicamento.dart';

void main() {
  group('ScheduleCalculator', () {
    test('gerarHorarios para umaVez deve conter apenas o horário inicial', () {
      const inicial = TimeOfDay(hour: 8, minute: 0);
      final resultado = ScheduleCalculator.gerarHorarios(
        inicial: inicial,
        frequencia: Frequencia.umaVez,
      );

      expect(resultado.length, 1);
      expect(resultado.first, inicial);
    });

    test('gerarHorarios para duasVezes deve adicionar +12h e ordenar', () {
      const inicial = TimeOfDay(hour: 8, minute: 30);
      final resultado = ScheduleCalculator.gerarHorarios(
        inicial: inicial,
        frequencia: Frequencia.duasVezes,
      );

      expect(resultado.length, 2);
      expect(resultado[0], const TimeOfDay(hour: 8, minute: 30));
      expect(resultado[1], const TimeOfDay(hour: 20, minute: 30));
    });

    test('gerarHorarios para tresVezes deve adicionar +8h e +16h ordenados', () {
      const inicial = TimeOfDay(hour: 7, minute: 0);
      final resultado = ScheduleCalculator.gerarHorarios(
        inicial: inicial,
        frequencia: Frequencia.tresVezes,
      );

      expect(resultado.length, 3);
      expect(resultado[0], const TimeOfDay(hour: 7, minute: 0));
      expect(resultado[1], const TimeOfDay(hour: 15, minute: 0));
      expect(resultado[2], const TimeOfDay(hour: 23, minute: 0));
    });

    test('gerarHorarios para intervalo de 8 horas', () {
      const inicial = TimeOfDay(hour: 6, minute: 0);
      final resultado = ScheduleCalculator.gerarHorarios(
        inicial: inicial,
        frequencia: Frequencia.intervaloHoras,
        intervaloHoras: 8,
      );

      expect(resultado.length, 3);
      expect(resultado[0], const TimeOfDay(hour: 6, minute: 0));
      expect(resultado[1], const TimeOfDay(hour: 14, minute: 0));
      expect(resultado[2], const TimeOfDay(hour: 22, minute: 0));
    });

    test('gerarHorarios para quandoNecessario deve ser lista vazia', () {
      const inicial = TimeOfDay(hour: 10, minute: 0);
      final resultado = ScheduleCalculator.gerarHorarios(
        inicial: inicial,
        frequencia: Frequencia.quandoNecessario,
      );

      expect(resultado, isEmpty);
    });

    test('calcularDosesPorDia retorna valores esperados', () {
      expect(ScheduleCalculator.calcularDosesPorDia(Frequencia.umaVez, null), 1);
      expect(ScheduleCalculator.calcularDosesPorDia(Frequencia.duasVezes, null), 2);
      expect(ScheduleCalculator.calcularDosesPorDia(Frequencia.tresVezes, null), 3);
      expect(ScheduleCalculator.calcularDosesPorDia(Frequencia.quatroVezes, null), 4);
      expect(ScheduleCalculator.calcularDosesPorDia(Frequencia.intervaloHoras, 6), 4);
      expect(ScheduleCalculator.calcularDosesPorDia(Frequencia.quandoNecessario, null), 0);
    });

    test('formatar formata hora com zero à esquerda', () {
      expect(ScheduleCalculator.formatar(const TimeOfDay(hour: 9, minute: 5)), '09:05');
      expect(ScheduleCalculator.formatar(const TimeOfDay(hour: 21, minute: 30)), '21:30');
    });
  });
}
