import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/cadastro_medicamento_bloc.dart';
import '../../models/medicamento.dart';

class EtapaNomeForma extends StatelessWidget {
  const EtapaNomeForma({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CadastroMedicamentoBloc, CadastroMedicamentoState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Qual o nome do medicamento?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: state.nome,
              decoration: const InputDecoration(
                labelText: 'Nome do medicamento',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                context.read<CadastroMedicamentoBloc>().add(UpdateNomeForma(value, state.forma));
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Qual a forma do medicamento?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8.0,
              children: FormaMedicamento.values.map((forma) {
                return ChoiceChip(
                  label: Text(forma.name),
                  selected: state.forma == forma,
                  onSelected: (selected) {
                    if (selected) {
                      context.read<CadastroMedicamentoBloc>().add(UpdateNomeForma(state.nome, forma));
                    }
                  },
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}
