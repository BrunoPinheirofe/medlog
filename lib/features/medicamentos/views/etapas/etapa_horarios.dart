import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/cadastro_medicamento_bloc.dart';
import '../../models/medicamento.dart';

class EtapaHorarios extends StatelessWidget {
  const EtapaHorarios({super.key});

  List<TimeOfDay> _gerarHorarios(TimeOfDay inicial, Frequencia frequencia, int? intervalo) {
    List<TimeOfDay> lista = [inicial];

    if (frequencia == Frequencia.umaVez) {
      // apenas um
    } else if (frequencia == Frequencia.duasVezes) {
      lista.add(TimeOfDay(hour: (inicial.hour + 12) % 24, minute: inicial.minute));
    } else if (frequencia == Frequencia.intervaloHoras && intervalo != null && intervalo > 0) {
      int horasAdicionadas = intervalo;
      while (horasAdicionadas < 24) {
        lista.add(TimeOfDay(hour: (inicial.hour + horasAdicionadas) % 24, minute: inicial.minute));
        horasAdicionadas += intervalo;
      }
    }

    lista.sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
    // Remove duplicates just in case
    return lista.toSet().toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CadastroMedicamentoBloc, CadastroMedicamentoState>(
      builder: (context, state) {
        if (state.frequencia == Frequencia.quandoNecessario) {
          return const Center(
            child: Text(
              'Não é necessário definir horários para medicamentos tomados quando necessário.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Em quais horários você toma?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Defina o horário da primeira dose, e nós calculamos o restante para você.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            if (state.horarios.isEmpty)
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.access_time),
                  label: const Text('Definir Primeira Dose'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null && context.mounted) {
                      final novosHorarios = _gerarHorarios(time, state.frequencia, state.intervaloHoras);
                      context.read<CadastroMedicamentoBloc>().add(UpdateHorarios(novosHorarios));
                    }
                  },
                ),
              )
            else ...[
              Expanded(
                child: ListView.builder(
                  itemCount: state.horarios.length,
                  itemBuilder: (context, index) {
                    final time = state.horarios[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.access_time_filled, color: Colors.indigo),
                        title: Text(
                          time.format(context),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () {
                            final novosHorarios = List<TimeOfDay>.from(state.horarios)..removeAt(index);
                            context.read<CadastroMedicamentoBloc>().add(UpdateHorarios(novosHorarios));
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar Horário Manualmente'),
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null && context.mounted) {
                      final novosHorarios = List<TimeOfDay>.from(state.horarios)..add(time);
                      novosHorarios.sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
                      context.read<CadastroMedicamentoBloc>().add(UpdateHorarios(novosHorarios));
                    }
                  },
                ),
              )
            ]
          ],
        );
      },
    );
  }
}
