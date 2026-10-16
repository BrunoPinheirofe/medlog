import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../bloc/cadastro_medicamento_bloc.dart';
import '../../domain/schedule_calculator.dart';
import '../../models/medicamento.dart';

class EtapaHorarios extends StatelessWidget {
  const EtapaHorarios({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CadastroMedicamentoBloc, CadastroMedicamentoState>(
      builder: (context, state) {
        final theme = Theme.of(context);
        final isHorarioInvalido = state.tentouAvancar && !state.isHorariosValidos;

        if (state.frequencia == Frequencia.quandoNecessario) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.healing_outlined,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Medicamento de Uso Sob Demanda (SOS)',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Não é necessário configurar horários nem alarmes fixos. Você poderá registrar as doses tomadas diretamente na tela de doses diárias.',
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Horários das Doses',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Defina os horários em que você toma o medicamento ao longo do dia.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (isHorarioInvalido) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 20, color: theme.colorScheme.onErrorContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Defina pelo menos um horário de dose para continuar.',
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),

            if (state.horarios.isEmpty) ...[
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.access_time_outlined,
                          size: 56,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum horário cadastrado',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Defina o horário da 1ª dose e calcularemos a rotina completa.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.alarm_add),
                          label: const Text('Definir Primeira Dose'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          ),
                          onPressed: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: const TimeOfDay(hour: 8, minute: 0),
                            );
                            if (time != null && context.mounted) {
                              context.read<CadastroMedicamentoBloc>().add(
                                    GerarHorariosAutomaticos(time),
                                  );
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          children: [
                            const TimeOfDay(hour: 7, minute: 0),
                            const TimeOfDay(hour: 8, minute: 0),
                            const TimeOfDay(hour: 9, minute: 0),
                          ].map((hora) {
                            return ActionChip(
                              label: Text('Iniciar às ${ScheduleCalculator.formatar(hora)}'),
                              onPressed: () {
                                context.read<CadastroMedicamentoBloc>().add(
                                      GerarHorariosAutomaticos(hora),
                                    );
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${state.horarios.length} ${state.horarios.length == 1 ? "dose configurada" : "doses configuradas"}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Recalcular'),
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: state.horarios.first,
                        );
                        if (time != null && context.mounted) {
                          context.read<CadastroMedicamentoBloc>().add(
                                GerarHorariosAutomaticos(time),
                              );
                        }
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: state.horarios.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final time = state.horarios[index];
                    return Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: theme.colorScheme.outlineVariant),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text(
                            '${index + 1}ª',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        title: Text(
                          ScheduleCalculator.formatar(time),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text('Toque para editar o horário'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: 'Editar horário',
                              onPressed: () async {
                                final novoHorario = await showTimePicker(
                                  context: context,
                                  initialTime: time,
                                );
                                if (novoHorario != null && context.mounted) {
                                  context.read<CadastroMedicamentoBloc>().add(
                                        EditarHorario(index, novoHorario),
                                      );
                                }
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                              tooltip: 'Excluir dose',
                              onPressed: () {
                                context.read<CadastroMedicamentoBloc>().add(
                                      RemoverHorario(index),
                                    );
                              },
                            ),
                          ],
                        ),
                        onTap: () async {
                          final novoHorario = await showTimePicker(
                            context: context,
                            initialTime: time,
                          );
                          if (novoHorario != null && context.mounted) {
                            context.read<CadastroMedicamentoBloc>().add(
                                  EditarHorario(index, novoHorario),
                                );
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar Horário Manualmente'),
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null && context.mounted) {
                      context.read<CadastroMedicamentoBloc>().add(
                            AdicionarHorario(time),
                          );
                    }
                  },
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
