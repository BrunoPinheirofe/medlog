part of 'cadastro_medicamento_bloc.dart';

abstract class CadastroMedicamentoEvent extends Equatable {
  const CadastroMedicamentoEvent();

  @override
  List<Object?> get props => [];
}

class NextStep extends CadastroMedicamentoEvent {}

class PreviousStep extends CadastroMedicamentoEvent {}

class GoToStep extends CadastroMedicamentoEvent {
  final int step;
  const GoToStep(this.step);

  @override
  List<Object?> get props => [step];
}

class UpdateNomeForma extends CadastroMedicamentoEvent {
  final String nome;
  final FormaMedicamento forma;

  const UpdateNomeForma(this.nome, this.forma);

  @override
  List<Object?> get props => [nome, forma];
}

class UpdateDosagem extends CadastroMedicamentoEvent {
  final double? doseValor;
  final String doseUnidade;

  const UpdateDosagem(this.doseValor, this.doseUnidade);

  @override
  List<Object?> get props => [doseValor, doseUnidade];
}

class UpdateCor extends CadastroMedicamentoEvent {
  final int? corHex;

  const UpdateCor(this.corHex);

  @override
  List<Object?> get props => [corHex];
}

class UpdateFrequencia extends CadastroMedicamentoEvent {
  final Frequencia frequencia;
  final int? intervaloHoras;

  const UpdateFrequencia(this.frequencia, {this.intervaloHoras});

  @override
  List<Object?> get props => [frequencia, intervaloHoras];
}

class UpdateTratamentoDuracao extends CadastroMedicamentoEvent {
  final bool usoContinuo;
  final int? duracaoDias;
  final DateTime? dataInicio;

  const UpdateTratamentoDuracao({
    required this.usoContinuo,
    this.duracaoDias,
    this.dataInicio,
  });

  @override
  List<Object?> get props => [usoContinuo, duracaoDias, dataInicio];
}

class UpdateHorarios extends CadastroMedicamentoEvent {
  final List<TimeOfDay> horarios;

  const UpdateHorarios(this.horarios);

  @override
  List<Object?> get props => [horarios];
}

class GerarHorariosAutomaticos extends CadastroMedicamentoEvent {
  final TimeOfDay inicial;

  const GerarHorariosAutomaticos(this.inicial);

  @override
  List<Object?> get props => [inicial];
}

class EditarHorario extends CadastroMedicamentoEvent {
  final int index;
  final TimeOfDay novoHorario;

  const EditarHorario(this.index, this.novoHorario);

  @override
  List<Object?> get props => [index, novoHorario];
}

class RemoverHorario extends CadastroMedicamentoEvent {
  final int index;

  const RemoverHorario(this.index);

  @override
  List<Object?> get props => [index];
}

class AdicionarHorario extends CadastroMedicamentoEvent {
  final TimeOfDay horario;

  const AdicionarHorario(this.horario);

  @override
  List<Object?> get props => [horario];
}

class UpdateEstoqueInstrucoes extends CadastroMedicamentoEvent {
  final double estoqueAtual;
  final int? estoqueMinimo;
  final String instrucoes;

  const UpdateEstoqueInstrucoes(
    this.estoqueAtual,
    this.instrucoes, {
    this.estoqueMinimo,
  });

  @override
  List<Object?> get props => [estoqueAtual, estoqueMinimo, instrucoes];
}

class UpdateFoto extends CadastroMedicamentoEvent {
  final String fotoUrl;

  const UpdateFoto(this.fotoUrl);

  @override
  List<Object?> get props => [fotoUrl];
}

class SaveMedicamento extends CadastroMedicamentoEvent {}
