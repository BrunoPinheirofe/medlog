import 'package:equatable/equatable.dart';
import 'package:material_ui/material_ui.dart';

enum FormaMedicamento {
  comprimido,
  capsula,
  gota,
  liquido,
  injetavel,
  pomada,
  spray,
  outro,
}

extension FormaMedicamentoX on FormaMedicamento {
  String get label {
    switch (this) {
      case FormaMedicamento.comprimido:
        return 'Comprimido';
      case FormaMedicamento.capsula:
        return 'Cápsula';
      case FormaMedicamento.gota:
        return 'Gotas';
      case FormaMedicamento.liquido:
        return 'Líquido / Xarope';
      case FormaMedicamento.injetavel:
        return 'Injetável';
      case FormaMedicamento.pomada:
        return 'Pomada / Creme';
      case FormaMedicamento.spray:
        return 'Spray / Inalador';
      case FormaMedicamento.outro:
        return 'Outro';
    }
  }

  IconData get icon {
    switch (this) {
      case FormaMedicamento.comprimido:
        return Icons.medication;
      case FormaMedicamento.capsula:
        return Icons.medication_liquid;
      case FormaMedicamento.gota:
        return Icons.water_drop_outlined;
      case FormaMedicamento.liquido:
        return Icons.local_drink_outlined;
      case FormaMedicamento.injetavel:
        return Icons.vaccines_outlined;
      case FormaMedicamento.pomada:
        return Icons.sanitizer_outlined;
      case FormaMedicamento.spray:
        return Icons.air;
      case FormaMedicamento.outro:
        return Icons.healing_outlined;
    }
  }
}

enum Frequencia {
  umaVez,
  duasVezes,
  tresVezes,
  quatroVezes,
  intervaloHoras,
  quandoNecessario,
  personalizado,
}

extension FrequenciaX on Frequencia {
  String get label {
    switch (this) {
      case Frequencia.umaVez:
        return '1 vez ao dia';
      case Frequencia.duasVezes:
        return '2 vezes ao dia';
      case Frequencia.tresVezes:
        return '3 vezes ao dia';
      case Frequencia.quatroVezes:
        return '4 vezes ao dia';
      case Frequencia.intervaloHoras:
        return 'Intervalo fixo em horas';
      case Frequencia.quandoNecessario:
        return 'Quando necessário (SOS)';
      case Frequencia.personalizado:
        return 'Personalizado';
    }
  }

  String get subtitulo {
    switch (this) {
      case Frequencia.umaVez:
        return '1 dose por dia';
      case Frequencia.duasVezes:
        return 'A cada 12 horas aproximadamente';
      case Frequencia.tresVezes:
        return 'A cada 8 horas aproximadamente';
      case Frequencia.quatroVezes:
        return 'A cada 6 horas aproximadamente';
      case Frequencia.intervaloHoras:
        return 'Ex: de 8 em 8 horas';
      case Frequencia.quandoNecessario:
        return 'Sem horário fixo (para dor ou crise)';
      case Frequencia.personalizado:
        return 'Horários definidos livremente';
    }
  }
}

class Medicamento extends Equatable {
  final String id;
  final String nome;
  final FormaMedicamento forma;
  final double? doseValor;
  final String? doseUnidade;
  final int? corHex;
  final bool usoContinuo;
  final int? duracaoDias;
  final DateTime? dataInicio;
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
    this.doseValor,
    this.doseUnidade,
    this.corHex,
    this.usoContinuo = true,
    this.duracaoDias,
    this.dataInicio,
    this.instrucoes,
    required this.frequencia,
    this.horarios = const [],
    this.intervaloHoras,
    this.estoqueAtual = 0,
    this.estoqueMinimo = 5,
    this.fotoUrl,
  });

  /// Verifica se o tratamento está ativo na [data] (ignorando horas/minutos).
  bool estaAtivoNaData(DateTime data) {
    if (dataInicio == null) return true;
    final alvo = DateTime(data.year, data.month, data.day);
    final inicio = DateTime(dataInicio!.year, dataInicio!.month, dataInicio!.day);
    if (alvo.isBefore(inicio)) return false;
    if (!usoContinuo && duracaoDias != null && duracaoDias! > 0) {
      final fim = DateTime(inicio.year, inicio.month, inicio.day + duracaoDias! - 1);
      if (alvo.isAfter(fim)) return false;
    }
    return true;
  }

  String get descricaoDose {
    if (doseValor == null || doseValor == 0) {
      return '';
    }
    final valorFormatado = (doseValor! % 1 == 0)
        ? doseValor!.toInt().toString()
        : doseValor!.toString();
    final unidade = (doseUnidade != null && doseUnidade!.trim().isNotEmpty)
        ? ' ${doseUnidade!.trim()}'
        : '';
    return '$valorFormatado$unidade';
  }

  Medicamento copyWith({
    String? id,
    String? nome,
    FormaMedicamento? forma,
    double? doseValor,
    String? doseUnidade,
    int? corHex,
    bool? usoContinuo,
    int? duracaoDias,
    DateTime? dataInicio,
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
      doseValor: doseValor ?? this.doseValor,
      doseUnidade: doseUnidade ?? this.doseUnidade,
      corHex: corHex ?? this.corHex,
      usoContinuo: usoContinuo ?? this.usoContinuo,
      duracaoDias: duracaoDias ?? this.duracaoDias,
      dataInicio: dataInicio ?? this.dataInicio,
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
        doseValor,
        doseUnidade,
        corHex,
        usoContinuo,
        duracaoDias,
        dataInicio,
        instrucoes,
        frequencia,
        horarios,
        intervaloHoras,
        estoqueAtual,
        estoqueMinimo,
        fotoUrl,
      ];
}
