import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../bloc/cadastro_medicamento_bloc.dart';
import '../../models/medicamento.dart';

class EtapaNomeForma extends StatefulWidget {
  const EtapaNomeForma({super.key});

  @override
  State<EtapaNomeForma> createState() => _EtapaNomeFormaState();
}

class _EtapaNomeFormaState extends State<EtapaNomeForma> {
  late final TextEditingController _nomeController;
  late final TextEditingController _doseController;

  static const List<String> _unidadesComuns = [
    'mg',
    'ml',
    'gotas',
    'comprimido',
    'g',
    'mcg',
    'UI',
  ];

  static const List<Color> _coresDisponiveis = [
    Colors.indigo,
    Colors.blue,
    Colors.teal,
    Colors.green,
    Colors.amber,
    Colors.deepOrange,
    Colors.purple,
    Colors.pink,
  ];

  @override
  void initState() {
    super.initState();
    final state = context.read<CadastroMedicamentoBloc>().state;
    _nomeController = TextEditingController(text: state.nome);
    _doseController = TextEditingController(
      text: state.doseValor != null
          ? (state.doseValor! % 1 == 0
              ? state.doseValor!.toInt().toString()
              : state.doseValor!.toString())
          : '',
    );
  }

  @override
  void dispose() {
    _nomeController.disposeDisposeSafely();
    _doseController.disposeDisposeSafely();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CadastroMedicamentoBloc, CadastroMedicamentoState>(
      listenWhen: (previous, current) =>
          previous.nome != current.nome || previous.doseValor != current.doseValor,
      listener: (context, state) {
        if (_nomeController.text != state.nome) {
          _nomeController.text = state.nome;
        }
      },
      builder: (context, state) {
        final theme = Theme.of(context);
        final isNomeInvalido = state.tentouAvancar && !state.isNomeValido;

        return ListView(
          children: [
            Text(
              'Identificação do Medicamento',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Informe o nome, dosagem e como o medicamento é administrado.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // Campo Nome
            TextFormField(
              controller: _nomeController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Nome do medicamento *',
                hintText: 'Ex: Paracetamol, Losartana, Amoxicilina',
                prefixIcon: Icon(
                  state.forma.icon,
                  color: state.corHex != null
                      ? Color(state.corHex!)
                      : theme.colorScheme.primary,
                ),
                border: const OutlineInputBorder(),
                errorText: isNomeInvalido
                    ? 'Informe um nome válido com ao menos 2 caracteres'
                    : null,
              ),
              onChanged: (value) {
                context.read<CadastroMedicamentoBloc>().add(
                      UpdateNomeForma(value, state.forma),
                    );
              },
            ),
            const SizedBox(height: 20),

            // Linha de Dosagem (Valor + Unidade)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _doseController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Dose / Concentração',
                      hintText: 'Ex: 500',
                      prefixIcon: Icon(Icons.scale_outlined),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      final parsed = double.tryParse(value.replaceAll(',', '.'));
                      context.read<CadastroMedicamentoBloc>().add(
                            UpdateDosagem(parsed, state.doseUnidade),
                          );
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
            ),
            const SizedBox(height: 24),

            // Forma Farmacêutica
            Text(
              'Forma Farmacêutica',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: FormaMedicamento.values.map((forma) {
                final isSelected = state.forma == forma;
                return ChoiceChip(
                  avatar: Icon(
                    forma.icon,
                    size: 18,
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.primary,
                  ),
                  label: Text(forma.label),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      context.read<CadastroMedicamentoBloc>().add(
                            UpdateNomeForma(state.nome, forma),
                          );
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            // Cor de Identificação (Opcional)
            Row(
              children: [
                Text(
                  'Cor do medicamento',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Text(
                  '(opcional)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _coresDisponiveis.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final cor = _coresDisponiveis[index];
                  final corValor = cor.toARGB32();
                  final isSelected = state.corHex == corValor;
                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      context.read<CadastroMedicamentoBloc>().add(
                            UpdateCor(isSelected ? null : corValor),
                          );
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: cor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: cor.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                  spreadRadius: 2,
                                )
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 20, color: Colors.white)
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

extension _TextEditingControllerExt on TextEditingController {
  void disposeDisposeSafely() {
    dispose();
  }
}
