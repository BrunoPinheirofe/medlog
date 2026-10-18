import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../bloc/cadastro_medicamento_bloc.dart';
import '../../domain/estoque_dose_calculator.dart';
import '../../domain/schedule_calculator.dart';
import '../../models/medicamento.dart';

class EtapaEstoqueInstrucoes extends StatefulWidget {
  const EtapaEstoqueInstrucoes({super.key});

  @override
  State<EtapaEstoqueInstrucoes> createState() => _EtapaEstoqueInstrucoesState();
}

class _EtapaEstoqueInstrucoesState extends State<EtapaEstoqueInstrucoes> {
  late final TextEditingController _estoqueAtualController;
  late final TextEditingController _estoqueMinimoController;
  late final TextEditingController _instrucoesController;

  static const List<String> _instrucoesSugeridas = [
    'Em jejum',
    'Com alimentos',
    'Após refeições',
    'Antes de dormir',
    'Com bastante água',
    'Não mastigar',
    'Evitar álcool',
  ];

  @override
  void initState() {
    super.initState();
    final state = context.read<CadastroMedicamentoBloc>().state;
    _estoqueAtualController = TextEditingController(
      text: state.estoqueAtual > 0 ? formatarEstoque(state.estoqueAtual) : '',
    );
    _estoqueMinimoController = TextEditingController(
      text: state.estoqueMinimo.toString(),
    );
    _instrucoesController = TextEditingController(text: state.instrucoes);
  }

  @override
  void dispose() {
    _estoqueAtualController.dispose();
    _estoqueMinimoController.dispose();
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
    final state = context.read<CadastroMedicamentoBloc>().state;
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
    return BlocBuilder<CadastroMedicamentoBloc, CadastroMedicamentoState>(
      builder: (context, state) {
        final theme = Theme.of(context);
        final estoqueBaixo =
            state.estoqueAtual > 0 && state.estoqueAtual <= state.estoqueMinimo;

        return ListView(
          children: [
            Text(
              'Estoque, Instruções & Revisão',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Controle a quantidade restante para lembretes de reposição e revise os dados.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),

            // Seção de Estoque
            Text(
              'Gerenciamento de Estoque',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _estoqueAtualController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Estoque atual',
                      hintText: 'Ex: 30',
                      suffixText: 'un.',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                    ),
                    onChanged: (value) {
                      final atual = double.tryParse(value.replaceAll(',', '.')) ?? 0;
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
                      final minimo = int.tryParse(value) ?? 5;
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
            const SizedBox(height: 8),

            // Botões de adição rápida de estoque
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

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),

            // Instruções Especiais
            Text(
              'Instruções de Uso',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
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
              maxLines: 2,
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

            const SizedBox(height: 28),

            // Card Consolidado de Resumo
            Card(
              elevation: 0,
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          state.forma.icon,
                          color: state.corHex != null
                              ? Color(state.corHex!)
                              : theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Resumo da Prescrição',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    _buildLinhaResumo(
                      'Medicamento:',
                      '${state.nome.isEmpty ? "(Não informado)" : state.nome} '
                          '${state.descricaoDose.isNotEmpty ? "• ${state.descricaoDose} " : ""}'
                          '(${state.forma.label})',
                      theme,
                    ),
                    _buildLinhaResumo(
                      'Frequência:',
                      '${state.frequencia.label} • ${state.usoContinuo ? "Uso contínuo" : "${state.duracaoDias ?? 7} dias"}',
                      theme,
                    ),
                    if (state.frequencia != Frequencia.quandoNecessario) ...[
                      _buildLinhaResumo(
                        'Horários:',
                        state.horarios.isEmpty
                            ? 'Nenhum horário definido'
                            : state.horarios.map((h) => ScheduleCalculator.formatar(h)).join(', '),
                        theme,
                      ),
                    ],
                    if (state.estoqueAtual > 0) ...[
                      _buildLinhaResumo(
                        'Estoque:',
                        '${formatarEstoque(state.estoqueAtual)} un. (Alerta em ${state.estoqueMinimo} un.)',
                        theme,
                      ),
                    ],
                    if (state.instrucoes.trim().isNotEmpty) ...[
                      _buildLinhaResumo(
                        'Instruções:',
                        state.instrucoes.trim(),
                        theme,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _buildLinhaResumo(String rotulo, String valor, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              rotulo,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
