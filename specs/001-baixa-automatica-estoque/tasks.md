# Tasks: Baixa Automática de Estoque

**Input**: Design documents from `/specs/001-baixa-automatica-estoque/`

**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/repository-interfaces.md, quickstart.md

**Tests**: inclusos — a constituição (Princípio IV) exige suíte automatizada como gate de qualidade e o plan.md define os arquivos de teste.

**Organization**: agrupados por user story para implementação e teste independentes.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: pode rodar em paralelo (arquivos diferentes, sem dependência pendente)
- **[Story]**: user story dona da tarefa (US1, US2, US3)
- Caminhos exatos incluídos nas descrições

## Path Conventions

- Projeto único Flutter: `lib/features/<feature>/...`, `test/features/<feature>/...`, `test/core/database/...`

**Task Generation Rules**: Tasks MUST be organized by user story to enable independent implementation and testing.
**User Stories (spec.md)**: US1 — Desconto automático fracionário (P1); US2 — Estorno consistente (P1); US3 — Visualização fracionária do saldo e baixo estoque (P2).

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Baseline verde antes de qualquer código (projeto já inicializado)

- [X] T001 Rodar suíte atual na raiz do repo e registrar baseline (`flutter test` + `flutter analyze`) — se houver falha pré-existente, documentá-la antes de começar

**Checkpoint**: baseline conhecido; nada a inicializar (estrutura feature-first já existe).

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: tipagem fracionária do estoque + schema v4 + calculadora de domínio — pré-requisitos de TODAS as stories

**⚠️ CRITICAL**: Nenhuma story começa antes deste checkpoint.

- [X] T002 Migração v3→v4: em `lib/core/database/app_database.dart` subir `databaseVersion` para 4; atualizar `createSchema` (`estoque_atual REAL NOT NULL DEFAULT 0` em `medicamentos`; coluna nova `estoque_consumido REAL NOT NULL DEFAULT 0` em `registros_dose`); implementar `migrate` com `oldVersion < 4`: rebuild transacional da tabela `medicamentos` preservando nome/ids/FKs (PRAGMA foreign_keys OFF → criar tabela nova com colunas existentes + `estoque_atual REAL` → `INSERT ... SELECT` → drop → rename → ON → `foreign_key_check`) e `ALTER TABLE registros_dose ADD COLUMN estoque_consumido REAL NOT NULL DEFAULT 0` (decisões R2/R3 de research.md)
- [X] T003 [P] Teste de migração em `test/core/database/app_database_migration_test.dart`: fixture cria schema e dados v3 (medicamento com estoque 30 + registros tomadas legados), roda `migrate` até v4 e valida: valores preservados (limpo lido como double: 30.0), `estoque_consumido=0` em doses legadas, tabela `medicamento_horarios` intacta, idempotência (migrar de novo não duplica) — escrever ANTES de T002 correr; deve FAIL no baseline
- [X] T004 Retipar modelo: `estoqueAtual` de `int` para `double` (default `0.0`) em `lib/features/medicamentos/models/medicamento.dart` (e `cadastro_medicamento_state.dart`, `cadastro_medicamento_event.dart`, `etapa_estoque_instrucoes.dart`, `registro_dose.dart`) — `copyWith`, construtor const e `props` acompanham; `estoqueMinimo` permanece `int` (R2)
- [X] T005 [P] Mapper: em `lib/features/medicamentos/data/medicamento_mappers.dart` ler/escrever `estoque_atual` como `double` (coerção segura de `num` vindo do SQLite)
- [X] T006 [P] Retipar updateEstoque(id, double estoqueAtual, int estoqueMinimo) em `lib/features/medicamentos/repositories/medicamento_repository.dart` e implementação SQLite em `medicamento_repository_sqflite.dart` (contrato em contracts/repository-interfaces.md §3)
- [X] T007 [P] Retipar fakes e fixtures de teste para double (`estoqueAtual: 30` → `30.0` etc.): `test/features/medicamentos/repositories/fake_repository.dart`, fake de doses em `test/features/doses/views/doses_page_test.dart`, `test/features/medicamentos/bloc/cadastro_medicamento_bloc_test.dart` (fixture `estoqueAtual: 20, estoqueMinimo: 5`) — suíte retorna ao verde tipando
- [X] T008 Calculadora de domínio pura `lib/features/medicamentos/domain/estoque_dose_calculator.dart` (decisões R1/R6): `double quantidadeConsumidaPorDose(Medicamento m)` (dose direta `doseValor` > 0 para consumo direto — gotas, ml, contagens físicas; default `1.0` quando doseValor nula/<= 0 OU unidade de concentração `mg/mcg/g/UI` em forma sólida) e `String formatarEstoque(double v)` (inteiro sem decimais: "30"; fracionário pt-BR: "12,5")
- [X] T009 [P] Testes unitários `test/features/medicamentos/domain/estoque_dose_calculator_test.dart`: 15 gotas→15.0; 2.5 ml→2.5; comprimido 500 mg→1.0; dose nula/0→1.0; 0.5 comprimido→0.5; formatação 30.0→"30", 12.5→"12,5" — deve FAIL antes de T008 valer

**Checkpoint**: suíte verde tipada; schema v4 verificado; calculadora coberta — stories podem começar.

---

## Phase 3: User Story 1 - Desconto Automático Fracionário ao Tomar Dose (Priority: P1) 🎯 MVP

**Goal**: ao marcar dose (agendada, grupo ou extra/SOS), descontar a quantidade real configurada do saldo fracionário, com piso em 0, dentro da transação já existente.

**Independent Test**: cadastrar medicamentos com doses diferentes (1 comprimido, 0.5 comprimido, 2.5 ml, 15 gotas) e estoque conhecido; marcar "Tomada"; verificar que o saldo reflete min(dose, estoque) e que repetir "Tomada" não desconta de novo (quickstart.md cenários 1, 2, 4, 5).

### Tests for User Story 1 ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [X] T010 [P] [US1] Testes FFI em `test/features/doses/repositories/dose_repository_sqflite_test.dart`: registrar tomada deduz `doseValor` (2.5 ml de estoque 100 → 97.5); extra SOS deduz 15 gotas de 200 → 185; comprimido dose "500 mg" desconta 1.0 (29 → 28); estoque 1 com dose 2.5 → piso 0.0 (nunca negativo, FR-006); idempotência (segunda "Tomada" não altera estoque); coluna `estoque_consumido` grava `min(dose, estoque disponível)`; nunca bloqueia registro (FR/edge: estoque 0 + tomada permitida)

### Implementation for User Story 1

- [X] T011 [US1] Em `lib/features/doses/repositories/dose_repository_sqflite.dart`: computar consumo com `quantidadeConsumidaPorDose(medicamento)` (T008); efetivar baixa `min(consumo, estoqueAtual)` com piso 0; gravar estoque_consumido na mesma transação da baixa: agendada em `registrarStatusDose` (transição para tomada), extra em `registrarDoseExtra` (deps: T008, T010)
- [X] T012 [P] [US1] Paridade no fake: fake do DoseRepository em `test/features/doses/views/doses_page_test.dart` passa a usar a mesma calculadora (dedução real, piso 0) para que testes de bloc/widget sigam válidos
- [X] T013 [US1] Grupo de horário: garantir em `registrarStatusDose` que iteração item-a-item do `DosesBloc.MarcarGrupoHorarioTomado` deduza a dose específica de CADA medicamento (nada extra a codificar, mas validado por teste de grupo em dose_repository_sqflite_test.dart)

**Checkpoint**: US1 independente e verde — MVP demonstrável (marcar dose => saldo certo).

---

## Phase 4: User Story 2 - Estorno Consistente ao Desfazer (Priority: P1)

**Goal**: desfazer dose tomada (→ Pendente/Pulada, individual ou grupo) ou remover dose extra devolve EXATAMENTE o que foi efetivamente descontado (inclusive após estourar o piso 0).

**Independent Test**: tomar dose fracionada, desmarcar e conferir rollback exato; provocar piso 0 (estoque 1, dose 2.5), desfazer e conferir retorno a 1.0 (nunca criar estoque fantasma) — quickstart.md cenário 3.

### Tests for User Story 2 ⚠️

- [X] T014 [P] [US2] Testes FFI estorno em `test/features/doses/repositories/dose_repository_sqflite_test.dart`: desmarcar dose 2.5 ml devolve +2.5; estorno após piso (estoque 1 → tomada 2.5 → 0; desmarcar → volta 1.0, lendo `estoque_consumido`); registro tomado LEGADO v3 (`estoque_consumido=0`) desmarcado devolve `quantidadeConsumidaPorDose` corrente; remover extra devolve dedução daquele registro; transição tomada→pulada estorna e zera `estoque_consumido` da linha; `registrarSilenciarDose` NÃO toca estoque; desmarcar GRUPO estorna item-a-item

### Implementation for User Story 2

- [X] T015 [US2] Em `lib/features/doses/repositories/dose_repository_sqflite.dart`: no caminho que SAI da tomada (pendente/pulada/extra removida) ler `estoque_consumido` do registro em questão e somar de volta; fallback `quantidadeConsumidaPorDose(medicamento)` quando registro era tomada legada (consumido 0); na nova linha (pulada persistida) gravar `estoque_consumido = 0` — mesma transação do registro (data-model.md; deps T011, T014)
- [X] T016 [US2] Estorno no fake do DoseRepository em `test/features/doses/views/doses_page_test.dart` (mesma semântica do T015) para bloc/widget tests validarem rollback

**Checkpoint**: US1 + US2 verdes independentemente; ciclo tomar↔desfazer fecha com saldo consistente.

---

## Phase 5: User Story 3 - Visualização Fracionária do Saldo e Baixo Estoque (Priority: P2)

**Goal**: usuário vê o saldo atualizado com frações formatadas (10 vs 10,5 pt-BR) e identificação visual de estoque baixo nas telas que exibem o saldo.

**Independent Test**: registrar dose que leve o saldo a valor fracionário/inferior ao mínimo e conferir exibição formatada e indicador — quickstart.md cenário 6; dois dígitos: integer sem decimais (US3.2 da spec).

### Implementation for User Story 3

- [X] T017 [US3] Exibição: em `lib/features/medicamentos/views/` (detalhe e telas que mostram estoque — `detalhe_medicamento_page.dart`, página de listagem), renderizar saldo via `formatarEstoque(med.estoqueAtual)` (T008) e indicador de "estoque baixo" quando `estoqueAtual <= estoqueMinimo` (texto de apoio no layout existente, sem punição ou bloqueio)
- [X] T018 [P] [US3] Widget tests: ajustar fixtures double em `test/features/medicamentos/views/medicamentos_page_test.dart` (estoque 2/min 5 mostra indicador; 30/5 não) e `test/features/doses/views/doses_page_test.dart` (fixture `estoqueAtual: 10.0`); validar texto formatado "12,5" e "10" sem casas decimais desnecessárias

**Checkpoint**: histórias 1+2+3 independentes e verdes.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: validação fim-a-fim e documentação

- [X] T019 [P] Atualizar `docs/pendencias-mvp.md`: marcar item "1.2 — Baixa automática de estoque" como concluído e anotar que o banner do 1.3 (feature `001-low-stock-alert`) consumirá o saldo fracionário resultante
- [X] T020 Validação final por `specs/001-baixa-automatica-estoque/quickstart.md`: `flutter analyze` (zero erro/aviso — constituição gate 1), `flutter test` completo (gate 2), cenários manuais 1–6 registrados — feature fechada

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Fase 1)**: imediato; sem dependências
- **Foundational (Fase 2)**: após setup — BLOQUEIA todas as stories (tipagem + schema v4 + calculadora)
- **US1 (Fase 3)**: após Foundational — pode ser a única story entregue (MVP)
- **US2 (Fase 4)**: depende da baixa implementada (T011 escreve `estoque_consumido` que T015 lê); o RESTO do ciclo é o mesmo arquivo
- **US3 (Fase 5)**: depende de Foundational (tipagem + `formatarEstoque`); não depende de US1/US2 — pode paralelizar com elas (arquivos distintos)
- **Polish (Fase 6)**: após as stories escolhidas

### User Story Dependencies

- **US1**: após Foundational; sem dependência de outras stories
- **US2**: acoplada ao arquivo de T011 (`dose_repository_sqflite.dart`) — sequencial após US1; independente testável por fixtures próprios (T014)
- **US3**: paralela a US1/US2 (views + widget tests, arquivos separados); requer `formatarEstoque` (T008) e double (T004)

### Within Each User Story

- Testes escritos primeiro e falhando (T010/T014/T018) antes da implementação
- Repositório antes da UI: baixa antes de estorno; implementação antes de polir

### Parallel Opportunities

- Fase 2: T003 (teste migração) e T009 (teste calculadora) rodam enquanto T002/T008 são redigidos; T005–T007 paralelizáveis após T004
- Entre stories: US1+US2 (sequência no repo SQLite) vs US3 (views) em paralelo
- T010 e T014 são o MESMO arquivo — planejar por cima da mesma sessão de edição, não em duplicidade

---

## Parallel Example: US1 e US3

```text
Fila A (repo):  T010 → T011 → T014 → T015 (dose_repository_sqflite.dart)
Fila B (UI):    T008/T009 prontos → T017 → T018 (views + widget tests)
```

---

## Implementation Strategy

### MVP First (Somente US1)

1. Concluir Fase 1 + 2 (setup + foundational)
2. Concluir US1 → **STOP e validar**: tomadas fracionárias descontando certo
3. Demo: "marcar dose e ver saldo cair exatamente"

### Incremental Delivery

1. Foundational → 2. US1 (MVP) → 3. US2 (ciclo tomar/desfazer fecha) → 4. US3 (visualização) → 5. Polish
- Cada incremento mantém as anteriores verdes (nada é descartado)

### Suggested MVP Scope

Somente **US1**: usuário já obtém a baixa automática correta (desconto fracionário com piso 0); estorno consistente (US2) e visualização (US3) seguem como incrementos de segurança/UX do mesmo épico.

---

## Notes

- [P] = arquivos diferentes, sem dependência pendente
- Idempotência e "silenciar não toca estoque" já existem no código e são travados por teste (dignum de manter)
- Commit por tarefa ou grupo lógico; validar em cada checkpoint
- Evitar: tocar o mesmo arquivo em duas tasks [P] simultâneas
