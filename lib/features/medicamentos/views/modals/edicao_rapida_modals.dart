import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../bloc/cadastro_medicamento_bloc.dart';
import '../../domain/estoque_dose_calculator.dart';
import '../../domain/schedule_calculator.dart';
import '../../models/medicamento.dart';
import '../../repositories/medicamento_repository.dart';

/// Exibe um container base de ModalBottomSheet para edição rápida de uma seção
/// específica de um [Medicamento], utilizando [CadastroMedicamentoBloc].
Future<Medicamento?> mostrarModalEdicaoRapidaBase(
  BuildContext context, {
  required Medicamento medicamento,
  required String titulo,
  required Widget Function(BuildContext context, CadastroMedicamentoState state)
      builder,
  bool Function(CadastroMedicamentoState state)? onValidateBeforeSave,
  MedicamentoRepository? repository,
}) {
  return showModalBottomSheet<Medicamento>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return BlocProvider(
        create: (_) => CadastroMedicamentoBloc(
          repository: repository,
          medicamentoInicial: medicamento,
        ),
        child: _ModalEdicaoRapidaContainer(
          titulo: titulo,
          builder: builder,
          onValidateBeforeSave: onValidateBeforeSave,
        ),
      );
    },
  );
}

class _ModalEdicaoRapidaContainer extends StatelessWidget {
  const _ModalEdicaoRapidaContainer({
    required this.titulo,
    required this.builder,
    this.onValidateBeforeSave,
  });

  final String titulo;
  final Widget Function(BuildContext context, CadastroMedicamentoState state)
      builder;
  final bool Function(CadastroMedicamentoState state)? onValidateBeforeSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return BlocConsumer<CadastroMedicamentoBloc, CadastroMedicamentoState>(
      listenWhen: (previous, current) => previous.isSuccess != current.isSuccess,
      listener: (context, state) {
        if (state.isSuccess) {
          Navigator.of(context).pop(state.toMedicamento());
        }
      },
      builder: (context, state) {
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        titulo,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Fechar',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(height: 20),
                builder(context, state),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 20,
                          color: theme.colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            state.errorMessage!,
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
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: state.isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: state.isSubmitting
                          ? null
                          : () {
                              final podeSalvar =
                                  onValidateBeforeSave?.call(state) ?? true;
                              if (!podeSalvar) return;
                              context
                                  .read<CadastroMedicamentoBloc>()
                                  .add(SaveMedicamento());
                            },
                      child: state.isSubmitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Salvar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Modal de edição rápida de Estoque e Alerta Mínimo (US1).
Future<Medicamento?> mostrarModalEditarEstoque(
  BuildContext context, {
  required Medicamento medicamento,
  MedicamentoRepository? repository,
}) {
  return mostrarModalEdicaoRapidaBase(
    context,
    medicamento: medicamento,
    repository: repository,
    titulo: 'Editar Estoque',
    builder: (context, state) => _ConteudoModalEstoque(state: state),
  );
}

class _ConteudoModalEstoque extends StatefulWidget {
  const _ConteudoModalEstoque({required this.state});

  final CadastroMedicamentoState state;

  @override
  State<_ConteudoModalEstoque> createState() => _ConteudoModalEstoqueState();
}

class _ConteudoModalEstoqueState extends State<_ConteudoModalEstoque> {
  late final TextEditingController _estoqueAtualController;
  late final TextEditingController _estoqueMinimoController;

  @override
  void initState() {
    super.initState();
    _estoqueAtualController = TextEditingController(
      text: formatarEstoque(widget.state.estoqueAtual),
    );
    _estoqueMinimoController = TextEditingController(
      text: widget.state.estoqueMinimo.toString(),
    );
  }

  @override
  void dispose() {
    _estoqueAtualController.dispose();
    _estoqueMinimoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final estoqueBaixo = state.estoqueAtual <= state.estoqueMinimo;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _estoqueAtualController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Estoque atual',
                  hintText: 'Ex: 30',
                  suffixText: 'un.',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                onChanged: (value) {
                  final parsed =
                      double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;
                  final atual = math.max<double>(0, parsed);
                  context.read<CadastroMedicamentoBloc>().add(
                        UpdateEstoqueInstrucoes(
                          atual,
                          state.instrucoes,
                          estoqueMinimo: state.estoqueMinimo,
                        ),
                      );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _estoqueMinimoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Alerta em',
                  hintText: 'Ex: 5',
                  suffixText: 'un.',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notification_important_outlined),
                ),
                onChanged: (value) {
                  final parsed = int.tryParse(value.trim()) ?? 0;
                  final minimo = math.max(0, parsed);
                  context.read<CadastroMedicamentoBloc>().add(
                        UpdateEstoqueInstrucoes(
                          state.estoqueAtual,
                          state.instrucoes,
                          estoqueMinimo: minimo,
                        ),
                      );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [10, 20, 30].map((qtd) {
            return ActionChip(
              avatar: const Icon(Icons.add, size: 16),
              label: Text('+$qtd un.'),
              onPressed: () {
                final novoTotal = state.estoqueAtual + qtd;
                _estoqueAtualController.text = formatarEstoque(novoTotal);
                context.read<CadastroMedicamentoBloc>().add(
                      UpdateEstoqueInstrucoes(
                        novoTotal,
                        state.instrucoes,
                        estoqueMinimo: state.estoqueMinimo,
                      ),
                    );
              },
            );
          }).toList(),
        ),
        if (estoqueBaixo) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade400),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'O estoque atual atingiu ou está abaixo da quantidade mínima de alerta (${state.estoqueMinimo} un.).',
                    style: TextStyle(
                      color: Colors.amber.shade900,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Modal de edição rápida de Horários das Doses (US2).
Future<Medicamento?> mostrarModalEditarHorarios(
  BuildContext context, {
  required Medicamento medicamento,
  MedicamentoRepository? repository,
}) {
  return mostrarModalEdicaoRapidaBase(
    context,
    medicamento: medicamento,
    repository: repository,
    titulo: 'Editar Horários',
    builder: (context, state) => _ConteudoModalHorarios(state: state),
  );
}

class _ConteudoModalHorarios extends StatelessWidget {
  const _ConteudoModalHorarios({required this.state});

  final CadastroMedicamentoState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (state.frequencia == Frequencia.quandoNecessario) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info_outline,
              size: 40,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Medicamento de Uso Sob Demanda (SOS)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Medicamentos de uso quando necessário não possuem horários fixos.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.horarios.isEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Text(
                  'Nenhum horário cadastrado.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: const [
                    TimeOfDay(hour: 7, minute: 0),
                    TimeOfDay(hour: 8, minute: 0),
                    TimeOfDay(hour: 9, minute: 0),
                  ].map((hora) {
                    return ActionChip(
                      label: Text(
                        'Iniciar às ${ScheduleCalculator.formatar(hora)}',
                      ),
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
        ] else ...[
          Row(
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
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: state.horarios.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final time = state.horarios[index];
                return Card(
                  elevation: 0,
                  margin: EdgeInsets.zero,
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
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                          icon: Icon(
                            Icons.delete_outline,
                            color: theme.colorScheme.error,
                          ),
                          tooltip: 'Excluir dose',
                          onPressed: () {
                            context.read<CadastroMedicamentoBloc>().add(
                                  RemoverHorario(index),
                                );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 12),
        Center(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Adicionar Horário Manualmente'),
            onPressed: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: const TimeOfDay(hour: 8, minute: 0),
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
    );
  }
}

/// Modal de edição rápida de Dose e Unidade (US3).
Future<Medicamento?> mostrarModalEditarDose(
  BuildContext context, {
  required Medicamento medicamento,
  MedicamentoRepository? repository,
}) {
  final formKey = GlobalKey<_ConteudoModalDoseState>();
  return mostrarModalEdicaoRapidaBase(
    context,
    medicamento: medicamento,
    repository: repository,
    titulo: 'Editar Dose',
    onValidateBeforeSave: (_) => formKey.currentState?.validar() ?? true,
    builder: (context, state) => _ConteudoModalDose(
      key: formKey,
      state: state,
    ),
  );
}

class _ConteudoModalDose extends StatefulWidget {
  const _ConteudoModalDose({super.key, required this.state});

  final CadastroMedicamentoState state;

  @override
  State<_ConteudoModalDose> createState() => _ConteudoModalDoseState();
}

class _ConteudoModalDoseState extends State<_ConteudoModalDose> {
  static const List<String> _unidadesComuns = [
    'mg',
    'ml',
    'gotas',
    'comprimido',
    'g',
    'mcg',
    'UI',
  ];

  late final TextEditingController _doseController;
  String? _erroDose;

  @override
  void initState() {
    super.initState();
    final doseValor = widget.state.doseValor;
    _doseController = TextEditingController(
      text: doseValor != null
          ? (doseValor % 1 == 0
              ? doseValor.toInt().toString()
              : doseValor.toString())
          : '',
    );
  }

  @override
  void dispose() {
    _doseController.dispose();
    super.dispose();
  }

  bool validar() {
    final texto = _doseController.text.trim();
    if (texto.isEmpty) {
      setState(() => _erroDose = null);
      return true;
    }
    final parsed = double.tryParse(texto.replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) {
      setState(() {
        _erroDose = 'Informe um valor numérico maior que zero';
      });
      return false;
    }
    setState(() => _erroDose = null);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: TextFormField(
            controller: _doseController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Dose / Concentração',
              hintText: 'Ex: 500',
              prefixIcon: const Icon(Icons.scale_outlined),
              border: const OutlineInputBorder(),
              errorText: _erroDose,
            ),
            onChanged: (value) {
              final trimmed = value.trim();
              if (trimmed.isEmpty) {
                setState(() => _erroDose = null);
                context.read<CadastroMedicamentoBloc>().add(
                      UpdateDosagem(null, state.doseUnidade),
                    );
                return;
              }
              final parsed = double.tryParse(trimmed.replaceAll(',', '.'));
              if (parsed == null || parsed <= 0) {
                setState(() {
                  _erroDose = 'Informe um valor numérico maior que zero';
                });
              } else {
                setState(() => _erroDose = null);
                context.read<CadastroMedicamentoBloc>().add(
                      UpdateDosagem(parsed, state.doseUnidade),
                    );
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String>(
            initialValue: _unidadesComuns.contains(state.doseUnidade)
                ? state.doseUnidade
                : _unidadesComuns.first,
            decoration: const InputDecoration(
              labelText: 'Unidade',
              border: OutlineInputBorder(),
            ),
            items: _unidadesComuns.map((u) {
              return DropdownMenuItem(
                value: u,
                child: Text(u),
              );
            }).toList(),
            onChanged: (novaUnidade) {
              if (novaUnidade != null) {
                context.read<CadastroMedicamentoBloc>().add(
                      UpdateDosagem(state.doseValor, novaUnidade),
                    );
              }
            },
          ),
        ),
      ],
    );
  }
}

/// Modal de edição rápida de Instruções e Orientações Adicionais (US4).
Future<Medicamento?> mostrarModalEditarInstrucoes(
  BuildContext context, {
  required Medicamento medicamento,
  MedicamentoRepository? repository,
}) {
  return mostrarModalEdicaoRapidaBase(
    context,
    medicamento: medicamento,
    repository: repository,
    titulo: 'Editar Instruções',
    builder: (context, state) => _ConteudoModalInstrucoes(state: state),
  );
}

class _ConteudoModalInstrucoes extends StatefulWidget {
  const _ConteudoModalInstrucoes({required this.state});

  final CadastroMedicamentoState state;

  @override
  State<_ConteudoModalInstrucoes> createState() =>
      _ConteudoModalInstrucoesState();
}

class _ConteudoModalInstrucoesState extends State<_ConteudoModalInstrucoes> {
  static const List<String> _instrucoesSugeridas = [
    'Em jejum',
    'Com alimentos',
    'Após refeições',
    'Antes de dormir',
    'Com bastante água',
    'Não mastigar',
    'Evitar álcool',
  ];

  late final TextEditingController _instrucoesController;

  @override
  void initState() {
    super.initState();
    _instrucoesController =
        TextEditingController(text: widget.state.instrucoes);
  }

  @override
  void dispose() {
    _instrucoesController.dispose();
    super.dispose();
  }

  void _adicionarInstrucaoRapida(String instrucao) {
    final textoAtual = _instrucoesController.text.trim();
    if (textoAtual.isEmpty) {
      _instrucoesController.text = instrucao;
    } else if (!textoAtual.contains(instrucao)) {
      _instrucoesController.text = '$textoAtual, $instrucao';
    }
    final state = widget.state;
    context.read<CadastroMedicamentoBloc>().add(
          UpdateEstoqueInstrucoes(
            state.estoqueAtual,
            _instrucoesController.text,
            estoqueMinimo: state.estoqueMinimo,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _instrucoesSugeridas.map((instrucao) {
            return ActionChip(
              label: Text(instrucao),
              onPressed: () => _adicionarInstrucaoRapida(instrucao),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _instrucoesController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Orientações especiais',
            hintText: 'Ex: Tomar com água, evitar o sol',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.notes_outlined),
          ),
          onChanged: (value) {
            context.read<CadastroMedicamentoBloc>().add(
                  UpdateEstoqueInstrucoes(
                    state.estoqueAtual,
                    value,
                    estoqueMinimo: state.estoqueMinimo,
                  ),
                );
          },
        ),
      ],
    );
  }
}
