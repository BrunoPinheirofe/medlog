import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../medicamentos/domain/schedule_calculator.dart';
import '../medicamentos/models/medicamento.dart';
import '../medicamentos/repositories/medicamento_repository.dart';
import '../medicamentos/views/detalhe_medicamento_page.dart';
import 'bloc/doses_bloc.dart';
import 'models/registro_dose.dart';
import 'repositories/dose_repository.dart';

class DosesPage extends StatelessWidget {
  const DosesPage({
    super.key,
    this.medicamentoRepository,
    this.doseRepository,
    this.dataInicial,
  });

  final MedicamentoRepository? medicamentoRepository;
  final DoseRepository? doseRepository;
  final DateTime? dataInicial;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DosesBloc(
        medicamentoRepository: medicamentoRepository,
        doseRepository: doseRepository,
        dataInicial: dataInicial,
      )..add(const LoadDosesDia()),
      child: _DosesView(medicamentoRepository: medicamentoRepository),
    );
  }
}

class _DosesView extends StatelessWidget {
  const _DosesView({this.medicamentoRepository});

  final MedicamentoRepository? medicamentoRepository;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DosesBloc, DosesState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
      },
      builder: (context, state) {
        return Column(
          children: [
            _CalendarioSemanalStrip(
              dataSelecionada: state.dataSelecionada,
              onSelectData: (data) {
                context.read<DosesBloc>().add(SelectDataDoses(data));
              },
            ),
            Expanded(
              child: state.status == DosesStatus.loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      children: [
                        if (state.semDosesAgendadas)
                          const _EstadoSemDosesCard()
                        else
                          for (final grupo in state.gruposHorario)
                            _CardGrupoHorario(
                              grupo: grupo,
                              medicamentoRepository: medicamentoRepository,
                            ),
                        const SizedBox(height: 12),
                        _SecaoQuandoNecessario(
                          dosesExtras: state.dosesExtras,
                          medicamentosDisponiveis:
                              state.medicamentosDisponiveis,
                        ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _CalendarioSemanalStrip extends StatelessWidget {
  const _CalendarioSemanalStrip({
    required this.dataSelecionada,
    required this.onSelectData,
  });

  final DateTime dataSelecionada;
  final ValueChanged<DateTime> onSelectData;

  static const List<String> _letrasDias = ['d', 's', 't', 'q', 'q', 's', 's'];

  List<DateTime> _diasDaSemana(DateTime base) {
    // Domingo como primeiro dia da semana (weekday % 7 == 0 para domingo)
    final offsetDomingo = base.weekday % 7;
    final domingo = DateTime(base.year, base.month, base.day - offsetDomingo);
    return List.generate(
      7,
      (i) => DateTime(domingo.year, domingo.month, domingo.day + i),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dias = _diasDaSemana(dataSelecionada);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(7, (index) {
          final dia = dias[index];
          final selecionado =
              dia.year == dataSelecionada.year &&
              dia.month == dataSelecionada.month &&
              dia.day == dataSelecionada.day;

          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => onSelectData(dia),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selecionado
                      ? theme.colorScheme.surfaceContainerHighest
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selecionado
                            ? theme.colorScheme.onSurface
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        _letrasDias[index].toUpperCase(),
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: selecionado
                              ? theme.colorScheme.surface
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${dia.day}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: selecionado
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: selecionado
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _CardGrupoHorario extends StatelessWidget {
  const _CardGrupoHorario({required this.grupo, this.medicamentoRepository});

  final GrupoHorarioDoses grupo;
  final MedicamentoRepository? medicamentoRepository;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final horarioTexto = ScheduleCalculator.formatar(grupo.horario);
    final todasTomadas = grupo.todasTomadas;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho do Card de Horário
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    horarioTexto,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      context.read<DosesBloc>().add(
                        MarcarGrupoHorarioTomado(grupo),
                      );
                    },
                    child: Container(
                      width: 42,
                      height: 36,
                      decoration: BoxDecoration(
                        color: todasTomadas
                            ? Colors.green.withValues(alpha: 0.15)
                            : theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        todasTomadas ? Icons.done_all : Icons.check,
                        size: 20,
                        color: todasTomadas
                            ? Colors.green.shade700
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Divider(
              height: 1,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
            for (var i = 0; i < grupo.itens.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  indent: 76,
                  endIndent: 16,
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.3,
                  ),
                ),
              _LinhaMedicamentoDose(
                item: grupo.itens[i],
                medicamentoRepository: medicamentoRepository,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LinhaMedicamentoDose extends StatelessWidget {
  const _LinhaMedicamentoDose({required this.item, this.medicamentoRepository});

  final ItemDoseDia item;
  final MedicamentoRepository? medicamentoRepository;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final med = item.medicamento;
    final cor = med.corHex != null
        ? Color(med.corHex!)
        : theme.colorScheme.primary;
    final subtituloPartes = [
      med.descricaoDose.isNotEmpty ? med.descricaoDose : med.forma.label,
      med.frequencia.label,
      if (item.isPulada) 'Dose pulada',
      if (item.silenciada) 'Dose silenciada',
    ];

    return InkWell(
      onTap: () {
        context.read<DosesBloc>().add(ToggleDoseTomada(item));
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 8, 12),
        child: Row(
          children: [
            // Ícone/Avatar quadrado arredondado estilo referência
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: item.isTomada
                    ? Colors.green.withValues(alpha: 0.15)
                    : cor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                item.isTomada
                    ? Icons.check_circle
                    : item.isPulada
                    ? Icons.remove_circle_outline
                    : med.forma.icon,
                color: item.isTomada
                    ? Colors.green.shade700
                    : item.isPulada
                    ? theme.colorScheme.outline
                    : cor,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    med.nome,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      decoration: item.isTomada
                          ? TextDecoration.lineThrough
                          : null,
                      color: item.isTomada || item.isPulada
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtituloPartes.join('  |  '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // Botão para silenciar/reativar apenas esta dose específica
            IconButton(
              icon: Icon(
                item.silenciada
                    ? Icons.volume_off_outlined
                    : Icons.volume_up_outlined,
                size: 20,
                color: item.silenciada
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurfaceVariant,
              ),
              tooltip: item.silenciada
                  ? 'Ativar alarme da dose'
                  : 'Silenciar esta dose',
              onPressed: () {
                context.read<DosesBloc>().add(ToggleSilenciarDose(item));
              },
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              tooltip: 'Opções da dose',
              onSelected: (acao) async {
                final bloc = context.read<DosesBloc>();
                switch (acao) {
                  case 'tomar':
                    bloc.add(
                      AlterarStatusDose(
                        item,
                        item.isTomada ? StatusDose.pendente : StatusDose.tomada,
                      ),
                    );
                  case 'pular':
                    bloc.add(
                      AlterarStatusDose(
                        item,
                        item.isPulada ? StatusDose.pendente : StatusDose.pulada,
                      ),
                    );
                  case 'silenciar':
                    bloc.add(ToggleSilenciarDose(item));
                  case 'detalhes':
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DetalheMedicamentoPage(
                          medicamento: med,
                          repository: medicamentoRepository,
                        ),
                      ),
                    );
                    if (context.mounted) {
                      bloc.add(const LoadDosesDia());
                    }
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'tomar',
                  child: Text(
                    item.isTomada ? 'Desmarcar dose' : 'Marcar como tomada',
                  ),
                ),
                PopupMenuItem(
                  value: 'pular',
                  child: Text(item.isPulada ? 'Desfazer pular' : 'Pular dose'),
                ),
                PopupMenuItem(
                  value: 'silenciar',
                  child: Text(
                    item.silenciada
                        ? 'Ativar alarme da dose'
                        : 'Silenciar esta dose',
                  ),
                ),
                const PopupMenuItem(
                  value: 'detalhes',
                  child: Text('Ver medicamento'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SecaoQuandoNecessario extends StatelessWidget {
  const _SecaoQuandoNecessario({
    required this.dosesExtras,
    required this.medicamentosDisponiveis,
  });

  final List<ItemDoseDia> dosesExtras;
  final List<Medicamento> medicamentosDisponiveis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'Quando necessário',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        for (final extra in dosesExtras)
          Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green.withValues(alpha: 0.15),
                foregroundColor: Colors.green.shade700,
                child: const Icon(Icons.check),
              ),
              title: Text(
                extra.medicamento.nome,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Dose extra registrada às ${ScheduleCalculator.formatar(extra.horario)}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Remover dose extra',
                onPressed: () {
                  if (extra.registroId != null) {
                    context.read<DosesBloc>().add(
                      RemoverDoseExtraEvent(
                        extra.registroId!,
                        extra.medicamento.id,
                      ),
                    );
                  }
                },
              ),
            ),
          ),
        Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _abrirSeletorDoseExtra(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Registrar dose extra',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _abrirSeletorDoseExtra(BuildContext context) {
    final bloc = context.read<DosesBloc>();
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        if (medicamentosDisponiveis.isEmpty) {
          return const SafeArea(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Nenhum medicamento cadastrado para registrar dose extra.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  child: Text(
                    'Registrar dose extra',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: medicamentosDisponiveis.length,
                    itemBuilder: (_, index) {
                      final med = medicamentosDisponiveis[index];
                      final isSos =
                          med.frequencia == Frequencia.quandoNecessario;
                      return ListTile(
                        leading: Icon(
                          med.forma.icon,
                          color: theme.colorScheme.primary,
                        ),
                        title: Text(med.nome),
                        subtitle: Text(
                          isSos
                              ? 'Quando necessário (SOS)'
                              : med.frequencia.label,
                        ),
                        trailing: const Icon(Icons.add_circle_outline),
                        onTap: () {
                          bloc.add(RegistrarDoseExtraEvent(med));
                          Navigator.of(sheetContext).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EstadoSemDosesCard extends StatelessWidget {
  const _EstadoSemDosesCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.event_note_outlined,
              size: 44,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Nenhuma dose agendada para este dia',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Adicione medicamentos com horários fixos ou registre uma dose extra abaixo.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
