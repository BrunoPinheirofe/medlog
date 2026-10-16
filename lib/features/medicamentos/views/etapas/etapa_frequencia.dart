import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../bloc/cadastro_medicamento_bloc.dart';
import '../../domain/schedule_calculator.dart';
import '../../models/medicamento.dart';

class EtapaFrequencia extends StatelessWidget {
  const EtapaFrequencia({super.key});

  static const List<Frequencia> _frequenciasExibidas = [
    Frequencia.umaVez,
    Frequencia.duasVezes,
    Frequencia.tresVezes,
    Frequencia.quatroVezes,
    Frequencia.intervaloHoras,
    Frequencia.quandoNecessario,
  ];

  static const List<int> _intervalosSugeridos = [4, 6, 8, 12];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CadastroMedicamentoBloc, CadastroMedicamentoState>(
      builder: (context, state) {
        final theme = Theme.of(context);
        final isIntervaloInvalido = state.tentouAvancar && !state.isFrequenciaValida;

        return ListView(
          children: [
            Text(
              'Frequência e Duração',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Escolha a periodicidade das doses e se é um tratamento contínuo ou temporário.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),

            // Opções de Frequência
            ..._frequenciasExibidas.map((freq) {
              final isSelected = state.frequencia == freq;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    context.read<CadastroMedicamentoBloc>().add(
                          UpdateFrequencia(
                            freq,
                            intervaloHoras: freq == Frequencia.intervaloHoras
                                ? (state.intervaloHoras ?? 8)
                                : null,
                          ),
                        );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                          : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                freq.label,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight:
                                      isSelected ? FontWeight.bold : FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                freq.subtitulo,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            // Campo de Intervalo se selecionado intervaloHoras
            if (state.frequencia == Frequencia.intervaloHoras) ...[
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'A cada quantas horas?',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: _intervalosSugeridos.map((intervalo) {
                          final isAtivo = state.intervaloHoras == intervalo;
                          return ChoiceChip(
                            label: Text('A cada ${intervalo}h'),
                            selected: isAtivo,
                            onSelected: (selected) {
                              if (selected) {
                                context.read<CadastroMedicamentoBloc>().add(
                                      UpdateFrequencia(
                                        Frequencia.intervaloHoras,
                                        intervaloHoras: intervalo,
                                      ),
                                    );
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: state.intervaloHoras?.toString() ?? '8',
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Ou digite outro intervalo',
                          suffixText: 'horas',
                          border: const OutlineInputBorder(),
                          errorText: isIntervaloInvalido
                              ? 'Informe um intervalo entre 1 e 24 horas'
                              : null,
                        ),
                        onChanged: (value) {
                          final horas = int.tryParse(value);
                          context.read<CadastroMedicamentoBloc>().add(
                                UpdateFrequencia(
                                  state.frequencia,
                                  intervaloHoras: horas,
                                ),
                              );
                        },
                      ),
                      if (state.intervaloHoras != null &&
                          state.intervaloHoras! > 0 &&
                          state.intervaloHoras! <= 24) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: theme.colorScheme.primary),
                            const SizedBox(width: 6),
                            Text(
                              'Equivale a ~${ScheduleCalculator.calcularDosesPorDia(Frequencia.intervaloHoras, state.intervaloHoras)} doses por dia',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),

            // Duração do Tratamento
            Text(
              'Duração do Tratamento',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(
                  value: true,
                  label: Text('Uso Contínuo'),
                  icon: Icon(Icons.all_inclusive),
                ),
                ButtonSegment<bool>(
                  value: false,
                  label: Text('Temporário'),
                  icon: Icon(Icons.date_range),
                ),
              ],
              selected: {state.usoContinuo},
              onSelectionChanged: (novaSelecao) {
                final usoContinuo = novaSelecao.first;
                context.read<CadastroMedicamentoBloc>().add(
                      UpdateTratamentoDuracao(
                        usoContinuo: usoContinuo,
                        duracaoDias: usoContinuo ? null : (state.duracaoDias ?? 7),
                      ),
                    );
              },
            ),

            if (!state.usoContinuo) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: state.duracaoDias?.toString() ?? '7',
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Quantidade de dias',
                        suffixText: 'dias',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.timer_outlined),
                      ),
                      onChanged: (value) {
                        final dias = int.tryParse(value);
                        context.read<CadastroMedicamentoBloc>().add(
                              UpdateTratamentoDuracao(
                                usoContinuo: false,
                                duracaoDias: dias,
                              ),
                            );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Wrap(
                    spacing: 6,
                    children: [7, 10, 14].map((dias) {
                      return ActionChip(
                        label: Text('+$dias d'),
                        onPressed: () {
                          context.read<CadastroMedicamentoBloc>().add(
                                UpdateTratamentoDuracao(
                                  usoContinuo: false,
                                  duracaoDias: dias,
                                ),
                              );
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
