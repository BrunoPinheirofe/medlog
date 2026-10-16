import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'bloc/medicamentos_bloc.dart';
import 'models/medicamento.dart';
import 'repositories/medicamento_repository.dart';
import 'views/detalhe_medicamento_page.dart';

/// Listagem de medicamentos persistidos no SQLite local, via [MedicamentosBloc].
class MedicamentosPage extends StatelessWidget {
  const MedicamentosPage({super.key, this.repository});

  /// Injetável para testes; em produção usa a implementação SQLite.
  final MedicamentoRepository? repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MedicamentosBloc(repository: repository)..add(LoadMedicamentos()),
      child: _MedicamentosView(repository: repository),
    );
  }
}

class _MedicamentosView extends StatelessWidget {
  const _MedicamentosView({this.repository});

  final MedicamentoRepository? repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              return Dismissible(
                key: ValueKey(medicamento.id),
                direction: DismissDirection.horizontal,
                background: const _SwipeDeleteBackground(alignment: Alignment.centerLeft),
                secondaryBackground: const _SwipeDeleteBackground(alignment: Alignment.centerRight),
                confirmDismiss: (_) => confirmarExclusaoMedicamento(context, medicamento),
                onDismissed: (_) => _executarExclusaoComDesfazer(context, medicamento),
                child: _MedicamentoCard(
                  medicamento: medicamento,
                  onTap: () => _abrirDetalhes(context, medicamento),
                  onExcluir: () => _confirmarEExcluir(context, medicamento),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _abrirDetalhes(BuildContext context, Medicamento medicamento) async {
    final Medicamento? excluido = await Navigator.of(context).push<Medicamento>(
      MaterialPageRoute(
        builder: (_) => DetalheMedicamentoPage(
          medicamento: medicamento,
          repository: repository,
        ),
      ),
    );
    if (!context.mounted) return;
    if (excluido != null) {
      _executarExclusaoComDesfazer(context, excluido);
    } else {
      context.read<MedicamentosBloc>().add(LoadMedicamentos());
    }
  }

  Future<void> _confirmarEExcluir(BuildContext context, Medicamento medicamento) async {
    final bool confirmado = await confirmarExclusaoMedicamento(context, medicamento);
    if (confirmado && context.mounted) {
      _executarExclusaoComDesfazer(context, medicamento);
    }
  }

  void _executarExclusaoComDesfazer(BuildContext context, Medicamento medicamento) {
    final bloc = context.read<MedicamentosBloc>();
    bloc.add(DeleteMedicamento(medicamento.id));

    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    final controller = messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        content: Text('${medicamento.nome} foi removido'),
        action: SnackBarAction(
          label: 'Desfazer',
          onPressed: () => bloc.add(RestoreMedicamento(medicamento)),
        ),
      ),
    );
    final timer = Timer(const Duration(seconds: 2), controller.close);
    controller.closed.whenComplete(timer.cancel);
  }
}

class _SwipeDeleteBackground extends StatelessWidget {
  const _SwipeDeleteBackground({required this.alignment});

  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: alignment,
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.delete_outline,
        color: colorScheme.onErrorContainer,
      ),
    );
  }
}

class _MedicamentoCard extends StatelessWidget {
  const _MedicamentoCard({
    required this.medicamento,
    required this.onTap,
    required this.onExcluir,
  });

  final Medicamento medicamento;
  final VoidCallback onTap;
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
        onTap: onTap,
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
