part of 'cadastro_medicamento_bloc.dart';

class CadastroMedicamentoState extends Equatable {
  final int etapaAtual;
  final String nome;
  final FormaMedicamento forma;
  final Frequencia frequencia;
  final List<TimeOfDay> horarios;
  final int? intervaloHoras;
  final int estoqueAtual;
  final String instrucoes;
  final String? fotoUrl;
  final bool isSubmitting;
  final bool isSuccess;
  final String? errorMessage;

  const CadastroMedicamentoState({
    this.etapaAtual = 0,
    this.nome = '',
    this.forma = FormaMedicamento.comprimido,
    this.frequencia = Frequencia.umaVez,
    this.horarios = const [],
    this.intervaloHoras,
    this.estoqueAtual = 0,
    this.instrucoes = '',
    this.fotoUrl,
    this.isSubmitting = false,
    this.isSuccess = false,
    this.errorMessage,
  });

  CadastroMedicamentoState copyWith({
    int? etapaAtual,
    String? nome,
    FormaMedicamento? forma,
    Frequencia? frequencia,
    List<TimeOfDay>? horarios,
    int? intervaloHoras,
    int? estoqueAtual,
    String? instrucoes,
    String? fotoUrl,
    bool? isSubmitting,
    bool? isSuccess,
    String? errorMessage,
  }) {
    return CadastroMedicamentoState(
      etapaAtual: etapaAtual ?? this.etapaAtual,
      nome: nome ?? this.nome,
      forma: forma ?? this.forma,
      frequencia: frequencia ?? this.frequencia,
      horarios: horarios ?? this.horarios,
      intervaloHoras: intervaloHoras ?? this.intervaloHoras,
      estoqueAtual: estoqueAtual ?? this.estoqueAtual,
      instrucoes: instrucoes ?? this.instrucoes,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        etapaAtual,
        nome,
        forma,
        frequencia,
        horarios,
        intervaloHoras,
        estoqueAtual,
        instrucoes,
        fotoUrl,
        isSubmitting,
        isSuccess,
        errorMessage,
      ];
}
