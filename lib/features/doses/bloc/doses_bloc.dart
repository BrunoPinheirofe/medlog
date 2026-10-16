import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:material_ui/material_ui.dart';

import '../../medicamentos/models/medicamento.dart';
import '../../medicamentos/repositories/medicamento_repository.dart';
import '../../medicamentos/repositories/medicamento_repository_sqflite.dart';
import '../models/registro_dose.dart';
import '../repositories/dose_repository.dart';
import '../repositories/dose_repository_sqflite.dart';

part 'doses_event.dart';
part 'doses_state.dart';

class DosesBloc extends Bloc<DosesEvent, DosesState> {
  DosesBloc({
    MedicamentoRepository? medicamentoRepository,
    DoseRepository? doseRepository,
    DateTime? dataInicial,
  })  : _medicamentoRepository = medicamentoRepository ?? MedicamentoRepositorySqflite(),
        _doseRepository = doseRepository ?? DoseRepositorySqflite(),
        super(DosesState(dataSelecionada: _normalizarData(dataInicial ?? DateTime.now()))) {
    on<LoadDosesDia>((event, emit) async {
      final dataAlvo = _normalizarData(event.data ?? state.dataSelecionada);
      await _carregarDia(dataAlvo, emit);
    });

    on<SelectDataDoses>((event, emit) async {
      final dataAlvo = _normalizarData(event.data);
      await _carregarDia(dataAlvo, emit);
    });

    on<ToggleDoseTomada>((event, emit) async {
      final novoStatus = event.item.status == StatusDose.tomada
          ? StatusDose.pendente
          : StatusDose.tomada;
      await _atualizarDose(event.item, novoStatus, emit);
    });

    on<AlterarStatusDose>((event, emit) async {
      await _atualizarDose(event.item, event.status, emit);
    });

    on<ToggleSilenciarDose>((event, emit) async {
      try {
        final dataIso = formatarDataIso(state.dataSelecionada);
        await _doseRepository.registrarSilenciarDose(
          medicamento: event.item.medicamento,
          dataIso: dataIso,
          horario: event.item.horario,
          silenciada: !event.item.silenciada,
        );
        await _carregarDia(state.dataSelecionada, emit);
      } catch (e) {
        emit(state.copyWith(
          status: DosesStatus.failure,
          errorMessage: 'Erro ao atualizar alarme da dose.',
        ));
      }
    });

    on<MarcarGrupoHorarioTomado>((event, emit) async {
      try {
        final dataIso = formatarDataIso(state.dataSelecionada);
        final novoStatus = grupoInteiroTomado(event.grupo)
            ? StatusDose.pendente
            : StatusDose.tomada;
        for (final item in event.grupo.itens) {
          await _doseRepository.registrarStatusDose(
            medicamento: item.medicamento,
            dataIso: dataIso,
            horario: item.horario,
            novoStatus: novoStatus,
          );
        }
        await _carregarDia(state.dataSelecionada, emit);
      } catch (e) {
        emit(state.copyWith(
          status: DosesStatus.failure,
          errorMessage: 'Erro ao atualizar doses do horário.',
        ));
      }
    });

    on<RegistrarDoseExtraEvent>((event, emit) async {
      try {
        final dataIso = formatarDataIso(state.dataSelecionada);
        final horario = event.horario ?? TimeOfDay.now();
        await _doseRepository.registrarDoseExtra(
          medicamento: event.medicamento,
          dataIso: dataIso,
          horario: horario,
        );
        await _carregarDia(state.dataSelecionada, emit);
      } catch (e) {
        emit(state.copyWith(
          status: DosesStatus.failure,
          errorMessage: 'Erro ao registrar dose extra.',
        ));
      }
    });

    on<RemoverDoseExtraEvent>((event, emit) async {
      try {
        await _doseRepository.removerDoseExtra(
          registroId: event.registroId,
          medicamentoId: event.medicamentoId,
        );
        await _carregarDia(state.dataSelecionada, emit);
      } catch (e) {
        emit(state.copyWith(
          status: DosesStatus.failure,
          errorMessage: 'Erro ao remover dose extra.',
        ));
      }
    });
  }

  final MedicamentoRepository _medicamentoRepository;
  final DoseRepository _doseRepository;

  static DateTime _normalizarData(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool grupoInteiroTomado(GrupoHorarioDoses grupo) => grupo.todasTomadas;

  Future<void> _atualizarDose(
    ItemDoseDia item,
    StatusDose novoStatus,
    Emitter<DosesState> emit,
  ) async {
    try {
      final dataIso = formatarDataIso(state.dataSelecionada);
      await _doseRepository.registrarStatusDose(
        medicamento: item.medicamento,
        dataIso: dataIso,
        horario: item.horario,
        novoStatus: novoStatus,
      );
      await _carregarDia(state.dataSelecionada, emit);
    } catch (e) {
      emit(state.copyWith(
        status: DosesStatus.failure,
        errorMessage: 'Erro ao registrar status da dose.',
      ));
    }
  }

  Future<void> _carregarDia(DateTime data, Emitter<DosesState> emit) async {
    try {
      final dataIso = formatarDataIso(data);
      final medicamentos = await _medicamentoRepository.getAll();
      final registros = await _doseRepository.getByData(dataIso);

      final Map<String, Medicamento> medPorId = {
        for (final m in medicamentos) m.id: m,
      };

      final Map<String, RegistroDose> agendadosPorId = {
        for (final r in registros)
          if (!r.extra) r.id: r,
      };

      // Agrupa todas as doses agendadas por horário (minutos desde 00:00).
      final Map<int, List<ItemDoseDia>> mapaHorarios = {};
      for (final med in medicamentos) {
        for (final horario in med.horarios) {
          final minutos = horario.hour * 60 + horario.minute;
          final chaveAgendado = RegistroDose.gerarIdAgendado(dataIso, med.id, horario);
          final registro = agendadosPorId[chaveAgendado];
          (mapaHorarios[minutos] ??= []).add(
            ItemDoseDia(
              medicamento: med,
              horario: horario,
              status: registro?.status ?? StatusDose.pendente,
              silenciada: registro?.silenciada ?? false,
              registroId: registro?.id,
              extra: false,
            ),
          );
        }
      }

      final chavesOrdenadas = mapaHorarios.keys.toList()..sort();
      final grupos = [
        for (final minutos in chavesOrdenadas)
          GrupoHorarioDoses(
            horario: TimeOfDay(hour: minutos ~/ 60, minute: minutos % 60),
            itens: mapaHorarios[minutos]!,
          ),
      ];

      final extras = <ItemDoseDia>[];
      for (final r in registros) {
        if (r.extra) {
          final med = medPorId[r.medicamentoId];
          if (med != null) {
            extras.add(
              ItemDoseDia(
                medicamento: med,
                horario: r.horario,
                status: r.status,
                registroId: r.id,
                extra: true,
              ),
            );
          }
        }
      }

      // Ordena medicamentos disponíveis priorizando os de uso SOS (quandoNecessario).
      final disponiveis = List<Medicamento>.from(medicamentos)
        ..sort((a, b) {
          final aSos = a.frequencia == Frequencia.quandoNecessario ? 0 : 1;
          final bSos = b.frequencia == Frequencia.quandoNecessario ? 0 : 1;
          if (aSos != bSos) return aSos.compareTo(bSos);
          return a.nome.compareTo(b.nome);
        });

      emit(state.copyWith(
        status: DosesStatus.success,
        dataSelecionada: data,
        gruposHorario: grupos,
        dosesExtras: extras,
        medicamentosDisponiveis: disponiveis,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DosesStatus.failure,
        dataSelecionada: data,
        errorMessage: 'Erro ao carregar doses do dia.',
      ));
    }
  }
}
