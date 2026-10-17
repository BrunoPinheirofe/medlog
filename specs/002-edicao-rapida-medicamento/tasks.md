# Tasks: Edição Rápida de Medicamento por Modais

**Input**: Design documents from `/specs/002-edicao-rapida-medicamento/`  
**Prerequisites**: [plan.md](./plan.md) (required), [spec.md](./spec.md) (required), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/ui-modals-contract.md](./contracts/ui-modals-contract.md), [quickstart.md](./quickstart.md)

**Tests**: Inclusos — o Princípio IV da Constituição do MedLog exige testes automatizados (BLoC e Widget) para toda nova funcionalidade e regra de domínio.

**Organization**: As tarefas estão agrupadas por User Story para permitir implementação, teste e validação independentes de cada incremento.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode ser executada em paralelo (arquivos diferentes, sem dependências incompletas)
- **[Story]**: Rótulo da User Story correspondente (`[US1]`, `[US2]`, `[US3]`, `[US4]`)
- Caminhos exatos dos arquivos incluídos em todas as tarefas

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Verificação do baseline do projeto antes de iniciar as modificações.

- [ ] T001 Executar `flutter analyze` e `flutter test` a partir da raiz do projeto para validar o baseline de compilação e testes em `lib/features/medicamentos/` e `test/features/medicamentos/`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Ajustes no estado do BLoC para limpeza de dose, estrutura base compartilhada dos modais de edição rápida e suporte a ações de edição nos cards de seção da tela de detalhes.

**⚠️ CRITICAL**: Nenhuma User Story deve ser iniciada antes da conclusão desta fase.

- [ ] T002 Atualizar `CadastroMedicamentoState.copyWith` em `lib/features/medicamentos/bloc/cadastro_medicamento_state.dart` adicionando o parâmetro `bool clearDoseValor = false` e ajustar o handler `on<UpdateDosagem>` em `lib/features/medicamentos/bloc/cadastro_medicamento_bloc.dart` para permitir limpar `doseValor` para `null` quando `event.doseValor == null`
- [ ] T003 [P] Adicionar teste unitário de BLoC em `test/features/medicamentos/bloc/cadastro_medicamento_bloc_test.dart` verificando que `UpdateDosagem(null, 'mg')` limpa `doseValor` para `null` em um medicamento existente e que `SaveMedicamento` preserva todos os demais atributos intactos
- [ ] T004 Criar o arquivo `lib/features/medicamentos/views/modals/edicao_rapida_modals.dart` com o container/shell compartilhado de `ModalBottomSheet<Medicamento>` (`isScrollControlled: true`, `useSafeArea: true`, padding para `MediaQuery.viewInsetsOf(context).bottom`, cabeçalho com título e botão fechar, rodapé com botões `'Cancelar'` e `'Salvar'`, e integração com `BlocProvider<CadastroMedicamentoBloc>`)
- [ ] T005 Atualizar `_SecaoInfoCard` e `_DetalheMedicamentoPageState` em `lib/features/medicamentos/views/detalhe_medicamento_page.dart` para aceitar `onEdit` (`VoidCallback?`), `editTooltip` (`String?`) e `editButtonKey` (`Key?`) no cabeçalho do card e implementar o método auxiliar `_aplicarResultadoModal(Medicamento? atualizado)` que atualiza `_medicamento` via `setState` e exibe `SnackBar` com `'Medicamento atualizado com sucesso!'`

**Checkpoint**: Fundação pronta — `CadastroMedicamentoBloc`, o shell base de modal e `_SecaoInfoCard` estão prontos para receber cada modal de User Story.

---

## Phase 3: User Story 1 - Edição Rápida de Estoque e Alerta Mínimo (Priority: P1) 🎯 MVP

**Goal**: Permitir que o usuário atualize rapidamente o estoque atual e o limite de alerta mínimo (incluindo atalhos `+10`, `+20`, `+30` unidades) em um modal dedicado acionado diretamente na seção "Controle de Estoque".

**Independent Test**: Abrir `DetalheMedicamentoPage` para um medicamento com estoque baixo (ex.: `3 un.`, alerta `5 un.`), tocar no botão `Key('btn_editar_rapido_estoque')`, clicar no chip `+30 un.` (ou digitar um novo estoque/alerta mínimo) e tocar em `Salvar`; verificar que o modal fecha, o card exibe `33 un.` e o alerta de estoque baixo desaparece imediatamente.

### Tests for User Story 1 ⚠️

> **NOTE: Escreva estes testes PRIMEIRO e confirme que falham antes de implementar a funcionalidade**

- [ ] T006 [P] [US1] Criar arquivo de testes de widget `test/features/medicamentos/views/detalhe_medicamento_page_test.dart` com os cenários da US1: abrir modal pelo botão `Key('btn_editar_rapido_estoque')`, somar estoque via `ActionChip` `+30 un.`, alterar limite mínimo, salvar persistindo no `FakeMedicamentoRepository`, ocultar aviso de estoque baixo e descartar alterações ao tocar em `'Cancelar'`

### Implementation for User Story 1

- [ ] T007 [US1] Implementar `mostrarModalEditarEstoque` em `lib/features/medicamentos/views/modals/edicao_rapida_modals.dart` respeitando as restrições de `data-model.md` (`estoqueAtual >= 0` inteiro não-negativo onde vazio assume `0`; `estoqueMinimo >= 0` inteiro não-negativo onde vazio assume `5` ou `0`; `ActionChip`s `+10 un.`, `+20 un.`, `+30 un.`; e aviso visual quando `estoqueAtual <= estoqueMinimo`)
- [ ] T008 [US1] Conectar a seção `Controle de Estoque` em `lib/features/medicamentos/views/detalhe_medicamento_page.dart` passando `editButtonKey: const Key('btn_editar_rapido_estoque')`, `editTooltip: 'Editar estoque'` e `onEdit` acionando `mostrarModalEditarEstoque`

**Checkpoint**: User Story 1 (MVP) 100% funcional e testável de forma independente.

---

## Phase 4: User Story 2 - Edição Rápida de Horários das Doses (Priority: P1)

**Goal**: Permitir que o usuário adicione, edite, remova ou recalcule os horários das doses diretamente na seção "Horários das Doses" através de um modal dedicado, mantendo ordenação cronológica e validação de obrigatoriedade para medicamentos de uso programado.

**Independent Test**: Abrir `DetalheMedicamentoPage`, tocar em `Key('btn_editar_rapido_horarios')`, adicionar/editar/remover horários no modal e salvar; verificar que os chips de horário são atualizados em ordem cronológica e que tentar salvar com zero horários (para medicamento não-SOS) bloqueia a ação com mensagem de erro.

### Tests for User Story 2 ⚠️

- [ ] T009 [P] [US2] Adicionar testes de widget para a US2 em `test/features/medicamentos/views/detalhe_medicamento_page_test.dart` cobrindo: abertura via `Key('btn_editar_rapido_horarios')`, remoção de horário, bloqueio de salvamento com mensagem de erro quando todos os horários são removidos em frequência fixa (`frequencia != Frequencia.quandoNecessario`), exibição de mensagem informativa para medicamento SOS (`Frequencia.quandoNecessario`) e persistência ao salvar horários válidos

### Implementation for User Story 2

- [ ] T010 [US2] Implementar `mostrarModalEditarHorarios` em `lib/features/medicamentos/views/modals/edicao_rapida_modals.dart` permitindo adicionar horário (`AdicionarHorario`), editar horário (`EditarHorario`), remover horário (`RemoverHorario`) e recalcular horários a partir da 1ª dose (`GerarHorariosAutomaticos`), garantindo as restrições de `data-model.md` (`frequencia != Frequencia.quandoNecessario` exige `horarios.isNotEmpty`; normalização sem duplicatas e ordenação cronológica via `ScheduleCalculator.normalizarEOrdenar`; mensagem informativa quando `frequencia == Frequencia.quandoNecessario`)
- [ ] T011 [US2] Conectar a seção `Horários das Doses` em `lib/features/medicamentos/views/detalhe_medicamento_page.dart` passando `editButtonKey: const Key('btn_editar_rapido_horarios')`, `editTooltip: 'Editar horários'` e `onEdit` acionando `mostrarModalEditarHorarios`

**Checkpoint**: User Stories 1 e 2 funcionais e testadas independentemente.

---

## Phase 5: User Story 3 - Edição Rápida de Dose e Identificação (Priority: P2)

**Goal**: Permitir ajustar rapidamente o valor numérico da dose (inteiro ou decimal) e sua unidade farmacêutica em um modal compacto acionado a partir do card de cabeçalho na tela de detalhes.

**Independent Test**: Abrir `DetalheMedicamentoPage`, tocar em `Key('btn_editar_rapido_dose')` no card principal, alterar o valor da dose para `750` (ou `2,5` com unidade `ml`) e salvar; verificar que o cabeçalho exibe imediatamente a nova descrição de dose.

### Tests for User Story 3 ⚠️

- [ ] T012 [P] [US3] Adicionar testes de widget para a US3 em `test/features/medicamentos/views/detalhe_medicamento_page_test.dart` cobrindo: abertura via `Key('btn_editar_rapido_dose')`, edição de dose inteira (`1000 mg`) e decimal com vírgula (`2,5 ml`), validação bloqueando valor numérico inválido (`<= 0` ou texto não numérico quando preenchido) e limpeza da dose quando o campo é esvaziado

### Implementation for User Story 3

- [ ] T013 [US3] Implementar `mostrarModalEditarDose` em `lib/features/medicamentos/views/modals/edicao_rapida_modals.dart` respeitando as restrições de `data-model.md` (`doseValor` opcional: se vazio → `null`, se preenchido deve ser numérico `> 0` aceitando `,` ou `.` como separador decimal; `doseUnidade` restrita às unidades padrão `mg`, `ml`, `gotas`, `comprimido`, `g`, `mcg`, `UI`)
- [ ] T014 [US3] Adicionar `IconButton` de edição rápida (`key: const Key('btn_editar_rapido_dose')`, `tooltip: 'Editar dose'`) no card de cabeçalho principal em `lib/features/medicamentos/views/detalhe_medicamento_page.dart` acionando `mostrarModalEditarDose`

**Checkpoint**: User Stories 1, 2 e 3 funcionais e testadas independentemente.

---

## Phase 6: User Story 4 - Edição Rápida de Instruções e Orientações Adicionais (Priority: P3)

**Goal**: Permitir adicionar, complementar ou limpar orientações de uso diretamente na seção "Instruções e Informações Adicionais" usando um modal com chips de sugestões rápidas e campo de texto livre.

**Independent Test**: Abrir `DetalheMedicamentoPage`, tocar em `Key('btn_editar_rapido_instrucoes')`, selecionar um chip de sugestão rápida (ex.: `'Após refeições'`) ou digitar uma instrução, salvar e verificar que o texto é atualizado imediatamente na seção de instruções.

### Tests for User Story 4 ⚠️

- [ ] T015 [P] [US4] Adicionar testes de widget para a US4 em `test/features/medicamentos/views/detalhe_medicamento_page_test.dart` cobrindo: abertura via `Key('btn_editar_rapido_instrucoes')`, adição de chips de sugestão rápida (`'Após refeições'`, `'Com bastante água'`) sem duplicar termos, limpeza do texto voltando a exibir `'Nenhuma instrução especial cadastrada.'` e persistência no repositório

### Implementation for User Story 4

- [ ] T016 [US4] Implementar `mostrarModalEditarInstrucoes` em `lib/features/medicamentos/views/modals/edicao_rapida_modals.dart` respeitando as restrições de `data-model.md` (texto livre após `trim()`, se vazio persistido como `null`; chips de sugestão rápida `'Em jejum'`, `'Com alimentos'`, `'Após refeições'`, `'Antes de dormir'`, `'Com bastante água'`, `'Não mastigar'`, `'Evitar álcool'` concatenando com `, ` sem duplicar termos já presentes)
- [ ] T017 [US4] Conectar a seção `Instruções e Informações Adicionais` em `lib/features/medicamentos/views/detalhe_medicamento_page.dart` passando `editButtonKey: const Key('btn_editar_rapido_instrucoes')`, `editTooltip: 'Editar instruções'` e `onEdit` acionando `mostrarModalEditarInstrucoes`

**Checkpoint**: Todas as 4 User Stories estão completas e testadas independentemente.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Garantir sincronização fim-a-fim com a listagem de medicamentos e validar todos os gates de qualidade da Constituição.

- [ ] T018 [P] Adicionar teste de widget em `test/features/medicamentos/views/medicamentos_page_test.dart` validando que uma edição rápida feita em `DetalheMedicamentoPage` (ex.: atualizar estoque e dose via modal) atualiza o card correspondente ao retornar para `MedicamentosPage`, mantendo o botão de edição completa na `AppBar` funcional
- [ ] T019 Executar validação completa do `specs/002-edicao-rapida-medicamento/quickstart.md` rodando `flutter analyze` (zero erros/warnings) e `flutter test` em toda a suíte do repositório

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Sem dependências — início imediato.
- **Foundational (Phase 2)**: Depende da Phase 1 — **BLOQUEIA** todas as User Stories (`T002`–`T005`).
- **User Stories (Phase 3 a Phase 6)**: Todas dependem da conclusão da Phase 2 (Foundational).
  - Podem ser implementadas em ordem de prioridade: US1 (P1) → US2 (P1) → US3 (P2) → US4 (P3).
- **Polish (Phase 7)**: Depende da conclusão das User Stories desejadas.

### User Story Dependencies

- **User Story 1 (P1 - Estoque)**: Depende apenas da Phase 2; totalmente independente das demais stories.
- **User Story 2 (P1 - Horários)**: Depende apenas da Phase 2; independente de US1, US3 e US4.
- **User Story 3 (P2 - Dose)**: Depende apenas da Phase 2 (especificamente `T002` para limpeza de `doseValor`); independente de US1, US2 e US4.
- **User Story 4 (P3 - Instruções)**: Depende apenas da Phase 2; independente de US1, US2 e US3.

### Parallel Opportunities

- Na **Phase 2**: `T003` (teste unitário do BLoC em `test/features/medicamentos/bloc/cadastro_medicamento_bloc_test.dart`) pode ser desenvolvido em paralelo com `T004` e `T005` (arquivos de view em `lib/features/medicamentos/views/`).
- Em cada **User Story (Phases 3–6)**: a escrita dos testes de widget em `test/features/medicamentos/views/detalhe_medicamento_page_test.dart` (`T006`, `T009`, `T012`, `T015`) pode ocorrer de forma isolada antes da respectiva implementação nos arquivos de view (`lib/features/medicamentos/views/modals/edicao_rapida_modals.dart` e `lib/features/medicamentos/views/detalhe_medicamento_page.dart`).
- Na **Phase 7**: `T018` (`test/features/medicamentos/views/medicamentos_page_test.dart`) é independente de `detalhe_medicamento_page_test.dart`.

---

## Parallel Example: Foundational & User Story 1

```bash
# Após T002 (ajuste no estado/BLoC), rodar em paralelo:
Task T003: "Adicionar teste unitário de BLoC em test/features/medicamentos/bloc/cadastro_medicamento_bloc_test.dart"
Task T004: "Criar shell compartilhado de ModalBottomSheet em lib/features/medicamentos/views/modals/edicao_rapida_modals.dart"
Task T005: "Atualizar _SecaoInfoCard em lib/features/medicamentos/views/detalhe_medicamento_page.dart"

# Ao iniciar a User Story 1 (MVP):
Task T006: "Criar testes de widget para o modal de estoque em test/features/medicamentos/views/detalhe_medicamento_page_test.dart"
Task T007: "Implementar mostrarModalEditarEstoque em lib/features/medicamentos/views/modals/edicao_rapida_modals.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Concluir Phase 1: Setup (`T001`)
2. Concluir Phase 2: Foundational (`T002`–`T005`)
3. Concluir Phase 3: User Story 1 — Edição Rápida de Estoque (`T006`–`T008`)
4. **STOP and VALIDATE**: Executar `flutter test test/features/medicamentos/views/detalhe_medicamento_page_test.dart` para validar o MVP de edição rápida de estoque funcionando de ponta a ponta.

### Incremental Delivery

1. Setup + Foundational → Base pronta (`T001`–`T005`)
2. Adicionar **US1 (Estoque)** → Testar independentemente → Incremento 1 (MVP)
3. Adicionar **US2 (Horários)** → Testar independentemente → Incremento 2
4. Adicionar **US3 (Dose)** → Testar independentemente → Incremento 3
5. Adicionar **US4 (Instruções)** + **Polish** → Validar suíte completa (`T015`–`T019`)
