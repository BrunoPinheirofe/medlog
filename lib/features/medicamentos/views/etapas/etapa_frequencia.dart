import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/cadastro_medicamento_bloc.dart';
import '../../models/medicamento.dart';

class EtapaFrequencia extends StatelessWidget {
  const EtapaFrequencia({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CadastroMedicamentoBloc, CadastroMedicamentoState>(
      builder: (context, state) {
        return ListView(
          children: [
            const Text(
              'Com que frequência você toma este medicamento?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildRadioOption(context, state, Frequencia.umaVez, 'Uma vez por dia'),
            _buildRadioOption(context, state, Frequencia.duasVezes, 'Duas vezes ao dia'),
            _buildRadioOption(context, state, Frequencia.intervaloHoras, 'Intervalo de horas (ex: de 8h em 8h)'),
            _buildRadioOption(context, state, Frequencia.quandoNecessario, 'Quando necessário (nenhum lembrete)'),
            
            if (state.frequencia == Frequencia.intervaloHoras) ...[
              const SizedBox(height: 16),
              TextFormField(
                initialValue: state.intervaloHoras?.toString() ?? '',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Intervalo em horas',
                  border: OutlineInputBorder(),
                  suffixText: 'horas',
                ),
                onChanged: (value) {
                  final horas = int.tryParse(value);
                  context.read<CadastroMedicamentoBloc>().add(
                    UpdateFrequencia(state.frequencia, intervaloHoras: horas),
                  );
                },
              ),
            ]
          ],
        );
      },
    );
  }

  Widget _buildRadioOption(BuildContext context, CadastroMedicamentoState state, Frequencia value, String label) {
    return RadioListTile<Frequencia>(
      title: Text(label),
      value: value,
      groupValue: state.frequencia,
      onChanged: (Frequencia? newValue) {
        if (newValue != null) {
          context.read<CadastroMedicamentoBloc>().add(UpdateFrequencia(newValue));
        }
      },
    );
  }
}
