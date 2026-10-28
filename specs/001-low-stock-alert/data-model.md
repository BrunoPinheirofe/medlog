# Data Model: Alerta de Estoque Baixo

**Feature**: `/specs/001-low-stock-alert/spec.md` | **Schema versão**: 4 (inalterado)

## Entidades

Nenhuma alteração no banco SQLite é necessária. O alerta é uma projeção de domínio imutável calculada sobre `Medicamento` e os `RegistroDose` da data selecionada.

### `MotivoAlertaEstoque` (novo enum de domínio)

Local: `lib/features/medicamentos/domain/estoque_dose_calculator.dart`

| Valor | Descrição |
|-------|-----------|
| `abaixoDoMinimo` | Disparado quando `medicamento.estoqueAtual <= medicamento.estoqueMinimo` (`FR-001`). |
| `insuficienteAteFimTratamento` | Disparado em tratamento temporário (`!medicamento.usoContinuo`) quando `medicamento.estoqueAtual > medicamento.estoqueMinimo`, mas `medicamento.estoqueAtual < consumoRestanteAteFim` (`FR-004`). |

### `AlertaEstoqueBaixo` (novo value object de domínio)

Local: `lib/features/medicamentos/domain/estoque_dose_calculator.dart`

| Campo | Tipo | Notas |
|-------|------|-------|
| `medicamento` | `Medicamento` | Referência ao medicamento ativo que originou o alerta (garante unicidade por `id`, inclusive para medicamentos homônimos). |
| `motivo` | `MotivoAlertaEstoque` | Razão principal do disparo do alerta. |
| `estoqueNecessario` | `double` | Maior valor entre `estoqueMinimo.toDouble()` e o consumo estimado para cobrir as doses agendadas restantes até `dataFim` (quando temporário). |
| `folga` | `double` | `estoqueAtual - estoqueNecessario` (usado para ordenar do mais urgente / menor folga para o menos urgente). |
| `mensagem` | `String` | Texto formatado conforme `FR-002`: `"Atenção: Restam apenas X [unidade]. Hora de comprar!"` (ou singular quando `X == 1`). |

### `DosesState` (alterada)

Local: `lib/features/doses/bloc/doses_state.dart`

| Campo | Tipo | Notas |
|-------|------|-------|
| `alertasEstoque` | `List<AlertaEstoqueBaixo>` | Lista de alertas ativos na `dataSelecionada`, ordenada por urgência crescente de `folga`. Default: `const []`. |

## Regras de Validação e Transições de Estado

1. **Filtro de Atividade (`FR-007`, `US3.3`)**:
   - Somente medicamentos com `medicamento.estaAtivoNaData(dataSelecionada) == true` são avaliados. Medicamentos cujo tratamento ainda não iniciou ou já terminou nunca geram `AlertaEstoqueBaixo`.
2. **Gatilho 1 — Limite Mínimo (`FR-001`)**:
   - `medicamento.estoqueMinimo >= 0 && medicamento.estoqueAtual <= medicamento.estoqueMinimo`.
   - Se `estoqueMinimo == 0`, só dispara quando `estoqueAtual == 0`.
3. **Gatilho 2 — Cobertura até `dataFim` (`FR-004`, `FR-005`, `FR-009`)**:
   - Avaliado apenas quando `!medicamento.usoContinuo && medicamento.duracaoDias != null && medicamento.duracaoDias! > 0`.
   - `dosesRestantes = max(0, horarios.length - dosesConcluidasNoDia) + (diasFuturosAteFim * horarios.length)`.
   - `consumoRestante = dosesRestantes * quantidadeConsumidaPorDose(medicamento)`.
   - Dispara quando `medicamento.estoqueAtual < consumoRestante`.
4. **Ciclo de Vida Reativo (`FR-006`, `US1.4`, `US3.2`)**:
   - Nenhum estado de alerta ou "dispensa manual" é salvo no banco.
   - Sempre que `DosesBloc._carregarDia` roda (abertura da tela Hoje, troca de data, tomada/estorno de dose agendada ou em grupo, adição/remoção de dose extra, retorno da edição de medicamento), `alertasEstoque` é recalculado e emitido em `DosesState`.
