import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/cadastro_medicamento_bloc.dart';

class EtapaEstoqueInstrucoes extends StatelessWidget {
  const EtapaEstoqueInstrucoes({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CadastroMedicamentoBloc, CadastroMedicamentoState>(
      builder: (context, state) {
        return ListView(
          children: [
            const Text(
              'Estoque e Instruções',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: state.estoqueAtual > 0 ? state.estoqueAtual.toString() : '',
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantidade atual em estoque (opcional)',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                final estoque = int.tryParse(value) ?? 0;
                context.read<CadastroMedicamentoBloc>().add(
                  UpdateEstoqueInstrucoes(estoque, state.instrucoes),
                );
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: state.instrucoes,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Instruções especiais (ex: tomar após o almoço)',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                context.read<CadastroMedicamentoBloc>().add(
                  UpdateEstoqueInstrucoes(state.estoqueAtual, value),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Foto da Caixa/Comprimido (Opcional)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () {
                // Aqui entraria a chamada para image_picker
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Acesso à câmera/galeria será implementado aqui')),
                );
              },
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Tirar Foto ou Escolher da Galeria', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
