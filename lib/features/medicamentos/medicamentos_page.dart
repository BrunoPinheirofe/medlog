import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'bloc/medicamentos_bloc.dart';
import 'models/medicamento.dart';
import 'repositories/medicamento_repository.dart';
import 'views/cadastro_medicamento_page.dart';

/// Listagem de medicamentos persistidos no SQLite local, via [MedicamentosBloc].
class MedicamentosPage extends StatelessWidget {
  const MedicamentosPage({super.key, this.repository});

  /// Injetável para testes; em produção usa a implementação SQLite.
  final MedicamentoRepository? repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MedicamentosBloc(repository: repository)..add(LoadMedicamentos()),
      child: const _MedicamentosView(),
    );
  }
}

class _MedicamentosView extends StatelessWidget {
  const _MedicamentosView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const CadastroMedicamentoPage(),
              fullscreenDialog: true,
            ),
          );
          // Recarrega a lista ao voltar do cadastro.
          if (context.mounted) {
            context.read<MedicamentosBloc>().add(LoadMedicamentos());
          }
        },
        child: const Icon(Icons.add),
      ),
      body: BlocConsumer<MedicamentosBloc, MedicamentosState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
        },
        builder: (context, state) {
          if (state.status == MedicamentosStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.estaVazia) {
            return const Center(
              child: Text(
                'Nenhum medicamento cadastrado.\nUse o botão + para adicionar.',
                textAlign: TextAlign.center,
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.medicamentos.length,
            itemBuilder: (context, index) {
              final medicamento = state.medicamentos[index];
              return _MedicamentoCard(
                medicamento: medicamento,
                onExcluir: () => _confirmarExclusao(context, medicamento),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmarExclusao(BuildContext context, Medicamento medicamento) async {
    final bool? confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Remover ${medicamento.nome}?'),
        content: const Text(
          'O medicamento e seus horários serão removidos. '
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmado == true && context.mounted) {
      context.read<MedicamentosBloc>().add(DeleteMedicamento(medicamento.id));
    }
  }
}

class _MedicamentoCard extends StatelessWidget {
  const _MedicamentoCard({required this.medicamento, required this.onExcluir});

  final Medicamento medicamento;
  final VoidCallback onExcluir;

  @override
  Widget build(BuildContext context) {
    final bool estoqueBaixo = medicamento.estoqueAtual <= medicamento.estoqueMinimo;
    final String detalhes = [
      if (medicamento.doseValor != null) medicamento.descricaoDose,
      medicamento.frequencia.label,
      if (estoqueBaixo) 'Estoque baixo (atual: ${medicamento.estoqueAtual})',
    ].join(' • ');

    final Color cor = medicamento.corHex != null
        ? Color(medicamento.corHex!)
        : Theme.of(context).colorScheme.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cor.withValues(alpha: 0.12),
          foregroundColor: cor,
          child: Icon(medicamento.forma.icon),
        ),
        title: Text(medicamento.nome, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(detalhes, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Remover',
          onPressed: onExcluir,
        ),
      ),
    );
  }
}
