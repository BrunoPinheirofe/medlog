import 'dart:async';

import 'package:medlog/features/medicamentos/models/medicamento.dart';
import 'package:medlog/features/medicamentos/repositories/medicamento_repository.dart';

/// Repositório in-memory para testes de bloc e de página.
/// Itens ficam num mapa por id; campos `erro*` forçam falhas por operação.
class FakeMedicamentoRepository implements MedicamentoRepository {
  final Map<String, Medicamento> store = {};

  Object? erroAoCarregar;
  Object? erroAoSalvar;
  Object? erroAoRemover;
  Object? erroAoAtualizarEstoque;

  /// Quando definida, bloqueia o save até ser completada (testes de UI).
  Completer<void>? travaNoSave;

  @override
  Future<List<Medicamento>> getAll() async {
    if (erroAoCarregar != null) throw erroAoCarregar!;
    return store.values.toList();
  }

  @override
  Future<Medicamento?> getById(String id) async => store[id];

  @override
  Future<void> save(Medicamento medicamento) async {
    if (erroAoSalvar != null) throw erroAoSalvar!;
    if (travaNoSave != null) await travaNoSave!.future;
    store[medicamento.id] = medicamento;
  }

  @override
  Future<void> delete(String id) async {
    if (erroAoRemover != null) throw erroAoRemover!;
    store.remove(id);
  }

  @override
  Future<void> updateEstoque(String id, double estoqueAtual, int estoqueMinimo) async {
    if (erroAoAtualizarEstoque != null) throw erroAoAtualizarEstoque!;
    final atual = store[id];
    if (atual != null) {
      store[id] = atual.copyWith(estoqueAtual: estoqueAtual, estoqueMinimo: estoqueMinimo);
    }
  }
}
