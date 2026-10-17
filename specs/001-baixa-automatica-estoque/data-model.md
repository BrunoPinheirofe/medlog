# Data Model: Baixa Automática de Estoque

**Feature**: `/specs/001-baixa-automatica-estoque/spec.md` | **Schema versão**: 3 → 4

## Entidades

### Medicamento (alterada)

Representa o item terapêutico; a tabela `medicamentos` é reconstruída na v4 com tipo alterado.

| Campo | Tipo (v3) | Tipo (v4) | Notas |
|-------|-----------|-----------|-------|
| `id` | TEXT PK | TEXT PK | inalterado; mantém referências das FKs |
| `nome` | TEXT | TEXT | inalterado |
| `forma` | TEXT | TEXT | enum `FormaMedicamento`; inalterado |
| `dose_valor` | REAL | REAL | já decimal desde v1; entrada principal da regra de consumo |
| `dose_unidade` | TEXT | TEXT | ex.: `mg`, `ml`, `gotas`, `comprimido` |
| `estoque_atual` | INTEGER | **REAL** | saldo fracionário; leitura legada preservada (int copiado como REAL) |
| `estoque_minimo` | INTEGER | INTEGER | limiar permanece inteiro (R2) |
| demais colunas | — | — | inalteradas (v4 rebuild copia todos os campos) |

**Model Dart**: `Medicamento.estoqueAtual: int` → `estoqueAtual: double` (default `0.0`). `estoqueMinimo` permanece `int`. `copyWith` e `props` acompanham.

**Transições de estado do saldo**: apenas duas operações atingem `estoque_atual`:
1. **Baixa** (dose tomada): `novo = max(0, atual − consumo)` — consumo via R1, piso 0 (FR-006).
2. **Estorno** (tomada → pendente/pulada; remoção de extra): `novo = atual + estoque_consumido(registro)` — restaura exatamente o que foi deduzido (R4). Edições manuais continuam via `updateEstoque`/`save`.

### RegistroDose / registros_dose (alterada)

Evento de tomada agendada ou extra/SOS. Nova coluna:

| Campo | Tipo | Notas |
|-------|------|-------|
| `id` | TEXT PK | inalterado |
| `status` | TEXT | governa baixa/estorno; inalterado |
| `extra` | INTEGER | dose SOS; inalterado |
| **`estoque_consumido`** | **REAL NOT NULL DEFAULT 0** | quantidade efetivamente descontada na transação da baixa; `0` para doses não tomadas/silenciadas/puladas e para registros legados v3 |

**Idempotência**: quando `statusAnterior == novoStatus` o registro não é gravado e o estoque não é tocado (comportamento já existente, mantido).

**Migração de dados legados**: registros v3 marcados como "tomada" têm `estoque_consumido = 0`; na v4 nenhum dado é reescrito. Estornos futuros sobre esses registros tomados herdados devolvem `quantidadeConsumidaPorDose(medicamento)` (fallback quando o valor persistido é 0 em um registro tomado), compatível com a baixa herdada; detalhe no quickstart.

## Relações

- `registros_dose.medicamento_id` → `medicamentos.id` (`ON DELETE CASCADE`) — preservada pelo rebuild com nome de tabela constante.
- `medicamento_horarios.medicamento_id` → `medicamentos.id` — idem.

## Regras de validação (FRs → dados)

- `estoque_atual ≥ 0` sempre (clampa na escrita, FR-006).
- `estoque_consumido ≥ 0` e escrito apenas nas transações de baixa (FR-003/FR-004).
- `dose_valor` nulo/negativo ⇒ consumo 1.0 (FR-001).
