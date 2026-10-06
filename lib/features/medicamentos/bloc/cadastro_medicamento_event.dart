part of 'cadastro_medicamento_bloc.dart';

abstract class CadastroMedicamentoEvent extends Equatable {
  const CadastroMedicamentoEvent();

  @override
  List<Object?> get props => [];
}

class NextStep extends CadastroMedicamentoEvent {}

class PreviousStep extends CadastroMedicamentoEvent {}

class UpdateNomeForma extends CadastroMedicamentoEvent {
  final String nome;
  final FormaMedicamento forma;

  const UpdateNomeForma(this.nome, this.forma);

  @override
  List<Object?> get props => [nome, forma];
}

class UpdateFrequencia extends CadastroMedicamentoEvent {
  final Frequencia frequencia;
  final int? intervaloHoras;

  const UpdateFrequencia(this.frequencia, {this.intervaloHoras});

  @override
  List<Object?> get props => [frequencia, intervaloHoras];
}

class UpdateHorarios extends CadastroMedicamentoEvent {
  final List<TimeOfDay> horarios;

  const UpdateHorarios(this.horarios);

  @override
  List<Object?> get props => [horarios];
}

class UpdateEstoqueInstrucoes extends CadastroMedicamentoEvent {
  final int estoqueAtual;
  final String instrucoes;

  const UpdateEstoqueInstrucoes(this.estoqueAtual, this.instrucoes);

  @override
  List<Object?> get props => [estoqueAtual, instrucoes];
}

class UpdateFoto extends CadastroMedicamentoEvent {
  final String fotoUrl;

  const UpdateFoto(this.fotoUrl);

  @override
  List<Object?> get props => [fotoUrl];
}

class SaveMedicamento extends CadastroMedicamentoEvent {}
