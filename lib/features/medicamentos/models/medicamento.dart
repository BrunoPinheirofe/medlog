import 'package:equatable/equatable.dart';
import 'package:material_ui/material_ui.dart';

enum FormaMedicamento { comprimido, gota, liquido, injetavel, outro }
enum Frequencia { umaVez, duasVezes, intervaloHoras, quandoNecessario, personalizado }

class Medicamento extends Equatable {
  final String id;
  final String nome;
  final FormaMedicamento forma;
  final String? instrucoes;
  final Frequencia frequencia;
  final List<TimeOfDay> horarios;
  final int? intervaloHoras;
  final int estoqueAtual;
  final int estoqueMinimo;
  final String? fotoUrl;

  const Medicamento({
    required this.id,
    required this.nome,
    required this.forma,
    this.instrucoes,
    required this.frequencia,
    this.horarios = const [],
    this.intervaloHoras,
    this.estoqueAtual = 0,
    this.estoqueMinimo = 5,
    this.fotoUrl,
  });

  Medicamento copyWith({
    String? id,
    String? nome,
    FormaMedicamento? forma,
    String? instrucoes,
    Frequencia? frequencia,
    List<TimeOfDay>? horarios,
    int? intervaloHoras,
    int? estoqueAtual,
    int? estoqueMinimo,
    String? fotoUrl,
  }) {
    return Medicamento(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      forma: forma ?? this.forma,
      instrucoes: instrucoes ?? this.instrucoes,
      frequencia: frequencia ?? this.frequencia,
      horarios: horarios ?? this.horarios,
      intervaloHoras: intervaloHoras ?? this.intervaloHoras,
      estoqueAtual: estoqueAtual ?? this.estoqueAtual,
      estoqueMinimo: estoqueMinimo ?? this.estoqueMinimo,
      fotoUrl: fotoUrl ?? this.fotoUrl,
    );
  }

  @override
  List<Object?> get props => [
        id,
        nome,
        forma,
        instrucoes,
        frequencia,
        horarios,
        intervaloHoras,
        estoqueAtual,
        estoqueMinimo,
        fotoUrl,
      ];
}
