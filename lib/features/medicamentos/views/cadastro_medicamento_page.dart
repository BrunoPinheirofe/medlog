import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/cadastro_medicamento_bloc.dart';
import 'etapas/etapa_nome_forma.dart';
import 'etapas/etapa_frequencia.dart';
import 'etapas/etapa_horarios.dart';
import 'etapas/etapa_estoque_instrucoes.dart';

class CadastroMedicamentoPage extends StatelessWidget {
  const CadastroMedicamentoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CadastroMedicamentoBloc(),
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
    'Detalhes'
  ];

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CadastroMedicamentoBloc, CadastroMedicamentoState>(
      listenWhen: (previous, current) => previous.isSuccess != current.isSuccess,
      listener: (context, state) {
        if (state.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Medicamento cadastrado com sucesso!')),
          );
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Novo Medicamento'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: Column(
            children: [
              _buildTopProgressBar(context, state.etapaAtual),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: _buildEtapa(state.etapaAtual),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (state.etapaAtual > 0)
                      TextButton(
                        onPressed: () {
                          context.read<CadastroMedicamentoBloc>().add(PreviousStep());
                        },
                        child: const Text('VOLTAR', style: TextStyle(fontSize: 16)),
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
                          : Text(
                              state.etapaAtual < 3 ? 'PRÓXIMO' : 'SALVAR',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopProgressBar(BuildContext context, int etapaAtual) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      child: Column(
        children: [
          Row(
            children: List.generate(_stepTitles.length * 2 - 1, (index) {
              if (index % 2 == 1) {
                // Linha conectora
                final stepIndex = index ~/ 2;
                final isCompleted = etapaAtual > stepIndex;
                return Expanded(
                  child: Container(
                    height: 4,
                    color: isCompleted 
                        ? Theme.of(context).colorScheme.primary 
                        : Theme.of(context).colorScheme.outlineVariant,
                  ),
                );
              } else {
                // Ponto (dot)
                final stepIndex = index ~/ 2;
                final isActive = stepIndex == etapaAtual;
                final isCompleted = stepIndex < etapaAtual;
                final color = isActive || isCompleted
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outlineVariant;
                
                return Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: isCompleted
                      ? Icon(Icons.check, size: 16, color: Theme.of(context).colorScheme.onPrimary)
                      : (isActive ? Center(child: Container(width: 8, height: 8, decoration: BoxDecoration(color: Theme.of(context).colorScheme.onPrimary, shape: BoxShape.circle))) : null),
                );
              }
            }),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_stepTitles.length, (index) {
              final isActive = index == etapaAtual;
              return Text(
                _stepTitles[index],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive 
                      ? Theme.of(context).colorScheme.primary 
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
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
