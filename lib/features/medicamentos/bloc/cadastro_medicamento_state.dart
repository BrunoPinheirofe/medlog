part of 'cadastro_medicamento_bloc.dart';

class CadastroMedicamentoState extends Equatable {
  final String? id;
  final int etapaAtual;
  final String nome;
  final FormaMedicamento forma;
  final double? doseValor;
  final String doseUnidade;
  final int? corHex;
  final bool usoContinuo;
  final int? duracaoDias;
  final DateTime? dataInicio;
  final Frequencia frequencia;
  final List<TimeOfDay> horarios;
  final int? intervaloHoras;
  final int estoqueAtual;
  final int estoqueMinimo;
  final String instrucoes;
  final String? fotoUrl;
  final bool isSubmitting;
  final bool isSuccess;
  final String? errorMessage;
  final bool tentouAvancar;

  const CadastroMedicamentoState({
    this.id,
    this.etapaAtual = 0,
    this.nome = '',
    this.forma = FormaMedicamento.comprimido,
    this.doseValor,
    this.doseUnidade = 'mg',
    this.corHex,
    this.usoContinuo = true,
    this.duracaoDias,
    this.dataInicio,
    this.frequencia = Frequencia.umaVez,
    this.horarios = const [],
    this.intervaloHoras,
    this.estoqueAtual = 0,
    this.estoqueMinimo = 5,
    this.instrucoes = '',
    this.fotoUrl,
    this.isSubmitting = false,
    this.isSuccess = false,
    this.errorMessage,
    this.tentouAvancar = false,
  });

  factory CadastroMedicamentoState.fromMedicamento(Medicamento m) {
    return CadastroMedicamentoState(
      id: m.id,
      nome: m.nome,
      forma: m.forma,
      doseValor: m.doseValor,
      doseUnidade: m.doseUnidade ?? 'mg',
      corHex: m.corHex,
      usoContinuo: m.usoContinuo,
      duracaoDias: m.duracaoDias,
      dataInicio: m.dataInicio,
      frequencia: m.frequencia,
      horarios: m.horarios,
      intervaloHoras: m.intervaloHoras,
      estoqueAtual: m.estoqueAtual,
      estoqueMinimo: m.estoqueMinimo,
      instrucoes: m.instrucoes ?? '',
      fotoUrl: m.fotoUrl,
    );
  }

  bool get isEdicao => id != null;

  bool get isNomeValido => nome.trim().length >= 2;

  bool get isFrequenciaValida {
    if (frequencia == Frequencia.intervaloHoras) {
      return intervaloHoras != null && intervaloHoras! > 0 && intervaloHoras! <= 24;
    }
    return true;
  }

  bool get isHorariosValidos {
    if (frequencia == Frequencia.quandoNecessario) return true;
    return horarios.isNotEmpty;
  }

  bool get isEtapaAtualValida {
    switch (etapaAtual) {
      case 0:
        return isNomeValido;
      case 1:
        return isFrequenciaValida;
      case 2:
        return isHorariosValidos;
      case 3:
      default:
        return true;
    }
  }

  bool get temDadosPreenchidos {
    return nome.trim().isNotEmpty ||
        instrucoes.trim().isNotEmpty ||
        estoqueAtual > 0 ||
        horarios.isNotEmpty ||
        doseValor != null;
  }

  String get descricaoDose {
    if (doseValor == null || doseValor == 0) return '';
    final valorFormatado = (doseValor! % 1 == 0)
        ? doseValor!.toInt().toString()
        : doseValor!.toString();
    final unidade = doseUnidade.trim().isNotEmpty ? ' ${doseUnidade.trim()}' : '';
    return '$valorFormatado$unidade';
  }

  Medicamento toMedicamento({String? id}) {
    final agora = DateTime.now();
    final inicioPadrao = DateTime(agora.year, agora.month, agora.day);
    return Medicamento(
      id: id ?? this.id ?? agora.millisecondsSinceEpoch.toString(),
      nome: nome.trim(),
      forma: forma,
      doseValor: doseValor,
      doseUnidade: doseUnidade,
      corHex: corHex,
      usoContinuo: usoContinuo,
      duracaoDias: duracaoDias,
      dataInicio: dataInicio ?? inicioPadrao,
      instrucoes: instrucoes.trim().isEmpty ? null : instrucoes.trim(),
      frequencia: frequencia,
      horarios: horarios,
      intervaloHoras: intervaloHoras,
      estoqueAtual: estoqueAtual,
      estoqueMinimo: estoqueMinimo,
      fotoUrl: fotoUrl,
    );
  }

  CadastroMedicamentoState copyWith({
    String? id,
    int? etapaAtual,
    String? nome,
    FormaMedicamento? forma,
    double? doseValor,
    String? doseUnidade,
    int? corHex,
    bool? usoContinuo,
    int? duracaoDias,
    DateTime? dataInicio,
    Frequencia? frequencia,
    List<TimeOfDay>? horarios,
    int? intervaloHoras,
    int? estoqueAtual,
    int? estoqueMinimo,
    String? instrucoes,
    String? fotoUrl,
    bool? isSubmitting,
    bool? isSuccess,
    String? errorMessage,
    bool? tentouAvancar,
  }) {
    return CadastroMedicamentoState(
      id: id ?? this.id,
      etapaAtual: etapaAtual ?? this.etapaAtual,
      nome: nome ?? this.nome,
      forma: forma ?? this.forma,
      doseValor: doseValor ?? this.doseValor,
      doseUnidade: doseUnidade ?? this.doseUnidade,
      corHex: corHex ?? this.corHex,
      usoContinuo: usoContinuo ?? this.usoContinuo,
      duracaoDias: duracaoDias ?? this.duracaoDias,
      dataInicio: dataInicio ?? this.dataInicio,
      frequencia: frequencia ?? this.frequencia,
      horarios: horarios ?? this.horarios,
      intervaloHoras: intervaloHoras ?? this.intervaloHoras,
      estoqueAtual: estoqueAtual ?? this.estoqueAtual,
      estoqueMinimo: estoqueMinimo ?? this.estoqueMinimo,
      instrucoes: instrucoes ?? this.instrucoes,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage,
      tentouAvancar: tentouAvancar ?? this.tentouAvancar,
    );
  }

  @override
  List<Object?> get props => [
        id,
        etapaAtual,
        nome,
        forma,
        doseValor,
        doseUnidade,
        corHex,
        usoContinuo,
        duracaoDias,
        dataInicio,
        frequencia,
        horarios,
        intervaloHoras,
        estoqueAtual,
        estoqueMinimo,
        instrucoes,
        fotoUrl,
        isSubmitting,
        isSuccess,
        errorMessage,
        tentouAvancar,
      ];
}
