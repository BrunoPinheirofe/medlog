import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../bloc/cadastro_medicamento_bloc.dart';
import '../models/medicamento.dart';
import '../repositories/medicamento_repository.dart';
import 'etapas/etapa_estoque_instrucoes.dart';
import 'etapas/etapa_frequencia.dart';
import 'etapas/etapa_horarios.dart';
import 'etapas/etapa_nome_forma.dart';

class CadastroMedicamentoPage extends StatelessWidget {
  const CadastroMedicamentoPage({
    super.key,
    this.repository,
    this.medicamentoInicial,
  });

  /// Injetável para testes; em produção usa a implementação SQLite.
  final MedicamentoRepository? repository;

  /// Quando preenchido, abre o formulário em modo de edição.
  final Medicamento? medicamentoInicial;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CadastroMedicamentoBloc(
        repository: repository,
        medicamentoInicial: medicamentoInicial,
      ),
      child: const _CadastroMedicamentoView(),
    );
  }
}

class _CadastroMedicamentoView extends StatelessWidget {
  const _CadastroMedicamentoView();

  final List<String> _stepTitles = const [
    'Identificação',
    'Frequência',
    'Horários',
    'Detalhes & Estoque',
  ];

  Future<bool> _confirmarDescarte(BuildContext context, CadastroMedicamentoState state) async {
    if (!state.temDadosPreenchidos) {
      return true;
    }

    final deveSair = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Descartar alterações?'),
          content: const Text(
            'Você já preencheu dados deste medicamento. Deseja realmente sair sem salvar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Continuar editando'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Descartar'),
            ),
          ],
        );
      },
    );

    return deveSair ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CadastroMedicamentoBloc, CadastroMedicamentoState>(
      listenWhen: (previous, current) =>
          previous.isSuccess != current.isSuccess ||
          (previous.errorMessage != current.errorMessage && current.errorMessage != null),
      listener: (context, state) {
        if (state.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.isEdicao
                    ? 'Medicamento atualizado com sucesso!'
                    : 'Medicamento cadastrado com sucesso!',
              ),
            ),
          );
          Navigator.of(context).pop(state.toMedicamento());
        } else if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        return PopScope(
          canPop: !state.temDadosPreenchidos,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            final deveSair = await _confirmarDescarte(context, state);
            if (deveSair && context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(state.isEdicao ? 'Editar Medicamento' : 'Novo Medicamento'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () async {
                  final deveSair = await _confirmarDescarte(context, state);
                  if (deveSair && context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),
            body: SafeArea(
              child: Column(
                children: [
                  _buildTopProgressBar(context, state.etapaAtual),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: KeyedSubtree(
                          key: ValueKey<int>(state.etapaAtual),
                          child: _buildEtapa(state.etapaAtual),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border(
                        top: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (state.etapaAtual > 0)
                          OutlinedButton.icon(
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('VOLTAR'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            onPressed: () {
                              context.read<CadastroMedicamentoBloc>().add(PreviousStep());
                            },
                          )
                        else
                          const SizedBox.shrink(),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          ),
                          onPressed: state.isSubmitting
                              ? null
                              : () {
                                  if (state.etapaAtual < 3) {
                                    context.read<CadastroMedicamentoBloc>().add(NextStep());
                                  } else {
                                    context.read<CadastroMedicamentoBloc>().add(SaveMedicamento());
                                  }
                                },
                          child: state.isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      state.etapaAtual < 3 ? 'PRÓXIMO' : 'SALVAR',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      state.etapaAtual < 3 ? Icons.arrow_forward : Icons.check,
                                      size: 18,
                                    ),
                                  ],
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
      },
    );
  }

  Widget _buildTopProgressBar(BuildContext context, int etapaAtual) {
    const animationDuration = Duration(milliseconds: 300);
    const animationCurve = Curves.easeInOut;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 20.0),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      child: Column(
        children: [
          Row(
            children: List.generate(_stepTitles.length * 2 - 1, (index) {
              if (index % 2 == 1) {
                final stepIndex = index ~/ 2;
                final isCompleted = etapaAtual > stepIndex;
                return Expanded(
                  child: AnimatedContainer(
                    duration: animationDuration,
                    curve: animationCurve,
                    height: 4,
                    color: isCompleted
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                  ),
                );
              } else {
                final stepIndex = index ~/ 2;
                final isActive = stepIndex == etapaAtual;
                final isCompleted = stepIndex < etapaAtual;
                final color = isActive || isCompleted
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant;

                Widget childWidget;
                if (isCompleted) {
                  childWidget = Icon(
                    Icons.check,
                    key: const ValueKey('check_icon'),
                    size: 16,
                    color: theme.colorScheme.onPrimary,
                  );
                } else if (isActive) {
                  childWidget = Center(
                    key: const ValueKey('active_dot'),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onPrimary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                } else {
                  childWidget = Center(
                    key: const ValueKey('number_dot'),
                    child: Text(
                      '${stepIndex + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }

                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: isCompleted
                      ? () {
                          context.read<CadastroMedicamentoBloc>().add(GoToStep(stepIndex));
                        }
                      : null,
                  child: AnimatedContainer(
                    duration: animationDuration,
                    curve: animationCurve,
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: AnimatedSwitcher(
                      duration: animationDuration,
                      child: childWidget,
                    ),
                  ),
                );
              }
            }),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_stepTitles.length, (index) {
              final isActive = index == etapaAtual;
              return AnimatedDefaultTextStyle(
                duration: animationDuration,
                curve: animationCurve,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                child: Text(_stepTitles[index]),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildEtapa(int etapa) {
    switch (etapa) {
      case 0:
        return const EtapaNomeForma();
      case 1:
        return const EtapaFrequencia();
      case 2:
        return const EtapaHorarios();
      case 3:
        return const EtapaEstoqueInstrucoes();
      default:
        return const Center(child: Text('Etapa desconhecida'));
    }
  }
}
