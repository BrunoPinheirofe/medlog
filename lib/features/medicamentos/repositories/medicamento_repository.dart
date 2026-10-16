import '../models/medicamento.dart';

/// Contrato de acesso a dados de medicamentos. Isola telas e blocs do
/// mecanismo de persistência, permitindo trocar a implementação ou
/// testar com fakes em memória.
abstract class MedicamentoRepository {
  /// Salva o medicamento e todos os seus horários (upsert atômico: transação).
  Future<void> save(Medicamento medicamento);

  /// Lista todos os medicamentos, do mais recente para o mais antigo.
  Future<List<Medicamento>> getAll();

  /// Busca um medicamento por id, ou null quando não existe.
  Future<Medicamento?> getById(String id);

  /// Remove o medicamento; os horários são removidos em cascata.
  Future<void> delete(String id);

  /// Atualiza o estoque atual e o mínimo de um medicamento.
  Future<void> updateEstoque(String id, int estoqueAtual, int estoqueMinimo);
}
