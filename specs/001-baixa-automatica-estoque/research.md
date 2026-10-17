# Phase 0 Research: Baixa Automática de Estoque

**Feature**: `/specs/001-baixa-automatica-estoque/spec.md` | **Date**: 2026-10-17

Todos os "NEEDS CLARIFICATION" do contexto técnico foram resolvidos; as decisões abaixo foram tomadas com base no código existente e na constituição (`.specify/memory/constitution.md`).

## R1 — Quanto descontar por dose? (regra de domínio)

**Decision**: Nova calculadora pura em `lib/features/medicamentos/domain/estoque_dose_calculator.dart`:

- `double quantidadeConsumidaPorDose(Medicamento m)` — retorna:
  - `m.doseValor` (> 0) quando o consumo é **direto** do saldo: forma `gota`, `liquido`, ou doseUnidade que representa volume/contagem consumida (`ml`, `gotas`, `comprimido`, `cápsula`, `doses` de spray);
  - `1.0` (unidade física) como padrão quando `doseValor` é `null`/`<= 0`, e também quando a unidade da dose é apenas **concentração farmacológica** de forma sólida (`mg`, `mcg`, `g`, `UI`) — ex.: comprimido de 500 mg desconta 1 comprimido, não 500.

**Rationale**: É exatamente o FR-001/FR-002 da spec; a base de código já centraliza regras de cronograma em `medicamentos/domain/schedule_calculator.dart` (mesmo padrão casa bem). Pura ⇒ testável sem banco.

**Alternatives considered**:
- Calcular inline em `_ajustarEstoque` (repository) — rejeitado: regra de domínio acoplada à persistência, viola o espírito do princípio III.
- Calcular no `DosesBloc` — rejeitado: bloc é orquestrador, não calculador (princípio III).

## R2 — Tipo do estoque fracionário

**Decision**: `estoqueAtual` (e coluna `estoque_atual`) passa a `double`/`REAL`. `estoqueMinimo` **permanece inteiro** (`int`/`INTEGER`): o limiar de alerta já é cadastrado como inteiro na etapa de estoque e a comparação `double <= int` funciona tanto em SQLite quanto em Dart.

**Rationale**: Menor difusão possível: só o saldo precisa de frações (ml, meio comprimido). Alterar o mínimo geraria mudança em 3 telas de cadastro/validação sem exigência da spec.

**Alternatives considered**:
- Converter ambos para `double` — rejeitado por YAGNI (Princípio V da constituição: simplicidade); rever só quando o cadastro passar a aceitar mínimo fracionário.
- Inteiro escalado (`estoque*100`) — rejeitado: contamina toda a UI e cadastro existentes.

## R3 — Migração do schema (v3 → v4)

**Decision**: Incrementar `databaseVersion` 3 → 4; no `migrate`, `oldVersion < 4` executa, dentro de uma transação, o rebuild canônico de `medicamentos` (12 passos SQLite): criar tabela temporária com novo schema (`estoque_atual REAL NOT NULL DEFAULT 0`), copiar `INSERT INTO ... SELECT`, `DROP` original, `RENAME`. A nova tabela mantém o **mesmo nome** `medicamentos` para que `registros_dose` e `medicamento_horarios` continuem referenciando o mesmo id (FK preservada). Coluna `estoque_minimo` mantida como está. Além disso: `ALTER TABLE registros_dose ADD COLUMN estoque_consumido REAL NOT NULL DEFAULT 0` (ver R4). `createSchema` atualizado para já criar o schema novo (instalações frescas).

**Rationale**: SQLite não permite `ALTER COLUMN` de tipo; o rebuild é o caminho canônico, não destrutivo (perdurança dos dados é princípio V — dados locais sem backup). `estoque_consumido` é `ADD COLUMN` trivial. Migração idempotente por versionamento (`oldVersion < 4`) e transacional (`sqflite` reverterá se qualquer passo falhar).

**Alternatives considered**:
- Não migrar e confiar na afinidade dinâmica do SQLite (guardar `97.5` em coluna INTEGER) — rejeitado: quebra o contrato do mapper Dart (`int`) e deixa o schema mentindo; princípio V exige versão explícita.
- Tabela paralela de movimentação de estoque (ledger) — rejeitado: ledger completo é over-engineering para o MVP; a dedução efetiva por registro (R4) dá o mesmo resultado de correção.

## R4 — Estorno consistente após estourar o piso 0

**Decision**: Persistir **a dedução efetiva** em `registros_dose.estoque_consumido REAL NOT NULL DEFAULT 0`, escrita na mesma transação da baixa: `efetiva = min(quantidadeConsumidaPorDose(med), estoqueAtual disponível)`. No estorno (tomada → pendente/pulada, exclusão de dose extra), o repository soma de volta exatamente o valor persistido naquele registro, em vez do delta fixo atual.

**Rationale**: Resolve o edge case da spec ("desfazer quando o estoque bateu no piso"): hoje o estorno soma `+1` cego e pode fabricar estoque que nunca existiu. Com `estoque_consumido` o histórico é auditável dentro da própria linha — atomicidade grátis (mesma transação), sem novas tabelas.

**Alternatives considered**:
- Recalcular na hora do estorno ("estoque final − estoque anterior") — rejeitado: exige ler dois estados que o usuário pode ter alterado manualmente entre as ações (edição manual de estoque); a coisa persistida é a verdade da transação.
- Sempre somar a dose cheia no estorno — rejeitado pela spec (Assumptions): inconsistente.

## R5 — Idempotência e fluxos de grupo

**Decision**: Nenhuma mudança estrutural: `registrarStatusDose` já retorna cedo quando o status anterior é igual ao novo (idempotência, edge case da spec já coberto); `MarcarGrupoHorarioTomado` itera item a item chamando o mesmo método do repository — cada item desconta/devolve sua própria quantidade (ex.: grupo com 2 medicamentos de doses diferentes). A assinatura `MedicamentoRepository.updateEstoque(id, estoqueAtual, estoqueMinimo)` é apenas retipada (`double`, `int`) — continua sendo o caminho de escrita manual.

**Rationale**: Menor diff possível; o comportamento de grupo já é composição do caso unitário.

**Alternatives considered**: API de "grupo atômico" no repository — rejeitado: cada item é um registro independente; transação por item já garante consistência individual.

## R6 — Exibição do saldo (User Story 3)

**Decision**: Uma extensão/formatação simples (`String formatarEstoque(double)`) vive junto da calculadora em `medicamentos/domain/`: inteiro sem decimais (`"30"`), fracionário com decimal ("`12,5`", pt-BR). O indicador de baixo estoque é exibido nos pontos onde o saldo já aparece (detalhe do medicamento), comparando `estoqueAtual <= estoqueMinimo`.

**Rationale**: Formatação é decisão de apresentação, mas de domínio compartilhado; uma função pura evita reimplementação em cada tela.

**Alternatives considered**: `intl`/`NumberFormat` — rejeitado: seria a primeira dependência de i18n do app para uma vírgula; dependência desnecessária (constituição, simplicidade).

## R7 — Bloqueio de dose sem estoque

**Decision**: Nunca bloquear: registrar dose "Tomada" com estoque 0 funciona e apenas mantém o piso em 0 (comportamento atual de `_ajustarEstoque` já clampa; slots nem emitem erro).

**Rationale**: Exigência da spec (edge case) + princípio II (sem punitividade, sem estados de erro falsos).

**Alternatives considered**: Diálogo "estoque insuficiente?" antes de confirmar — rejeitado para este item: atrito extra em rotina crítica; constaría como novo requisito de UX fora do escopo declarado.
