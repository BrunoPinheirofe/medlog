# Tasks: Alerta de Estoque Baixo

**Input**: Design documents from `/specs/001-low-stock-alert/`  
**Prerequisites**: [plan.md](./plan.md) (required), [spec.md](./spec.md) (required), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/alerta-estoque-contract.md](./contracts/alerta-estoque-contract.md), [quickstart.md](./quickstart.md)

**Tests**: Inclusos — o Princípio IV da Constituição exige testes automatizados de unidade e widget para toda nova regra de domínio e fluxo de UI.

**Organization**: Tarefas agrupadas por User Story para permitir implementação e validação incremental.

---

## Phase 1: Setup

- [X] T001 Validar baseline do projeto com `flutter analyze` e `flutter test` na raiz do repositório

---

## Phase 2: Foundational (Domínio e Estado)

- [X] T002 Definir `MotivoAlertaEstoque`, `AlertaEstoqueBaixo`, `unidadeFormaEstoque`, `formatarMensagemEstoqueBaixo` e `calcularAlertasEstoqueBaixo` em `lib/features/medicamentos/domain/estoque_dose_calculator.dart`
- [X] T003 [P] Adicionar testes unitários de domínio em `test/features/medicamentos/domain/estoque_dose_calculator_test.dart` cobrindo limite mínimo (`<=`), cobertura até `dataFim` (incluindo desconto de doses já tomadas no dia), pluralização/singular por `FormaMedicamento`, filtro de tratamento ativo e ordenação por menor folga
- [X] T004 Adicionar campo `alertasEstoque` em `lib/features/doses/bloc/doses_state.dart` e computá-lo em `DosesBloc._carregarDia` (`lib/features/doses/bloc/doses_bloc.dart`) a partir dos medicamentos e registros do dia

---

## Phase 3: User Story 1 - Banner de Estoque Abaixo do Mínimo (Priority: P1) 🎯 MVP

- [X] T005 [US1] Implementar o widget `_BannerEstoqueBaixo` e renderizar a lista `state.alertasEstoque` no topo do `ListView` (acima dos grupos de horário) em `lib/features/doses/doses_page.dart`
- [X] T006 [P] [US1] Adicionar testes de widget para US1 em `test/features/doses/views/doses_page_test.dart` (exibição quando `estoqueAtual <= estoqueMinimo`, ocultação quando acima do mínimo, igualdade `5 == 5`, e aparição dinâmica ao marcar dose como tomada)

---

## Phase 4: User Story 2 - Aviso de Reposição Perto do Fim do Tratamento (Priority: P2)

- [X] T007 [P] [US2] Adicionar testes de widget para US2 em `test/features/doses/views/doses_page_test.dart` validando exibição do banner para tratamento temporário com estoque acima do mínimo mas insuficiente para as doses até `dataFim`, e ausência de banner quando o estoque cobre todas as doses até `dataFim`

---

## Phase 5: User Story 3 - Gestão de Múltiplos Avisos e Recuperação (Priority: P3)

- [X] T008 [P] [US3] Adicionar testes de widget para US3 em `test/features/doses/views/doses_page_test.dart` validando múltiplos banners ordenados pelo mais urgente, ausência de banner para tratamento encerrado e desaparecimento imediato do banner após repor o estoque tocando no banner e editando na `DetalheMedicamentoPage`

---

## Phase 6: Polish & Cross-Cutting Concerns

- [X] T009 [P] Atualizar `docs/pendencias-mvp.md` marcando o item `1.3 — Alerta de estoque baixo` como concluído (`001-low-stock-alert`)
- [X] T010 Executar validação final (`flutter analyze` e `flutter test`) conforme `specs/001-low-stock-alert/quickstart.md`
