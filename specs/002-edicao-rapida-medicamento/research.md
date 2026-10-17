# Phase 0 Research: Edição Rápida de Medicamento por Modais

**Feature**: `/specs/002-edicao-rapida-medicamento/spec.md` | **Date**: 2026-10-17

Todos os pontos de contexto técnico foram pesquisados e decididos com base na arquitetura existente do repositório e na constituição do projeto (`.specify/memory/constitution.md`).

## R1 — Gerenciamento de estado e persistência nos modais de edição rápida

**Decision**: Reutilizar o `CadastroMedicamentoBloc` (inicializado com `medicamentoInicial` e `repository`) dentro de cada `ModalBottomSheet` de edição rápida.

**Rationale**:
- `CadastroMedicamentoBloc` já implementa todos os eventos necessários (`UpdateDosagem`, `AdicionarHorario`, `EditarHorario`, `RemoverHorario`, `GerarHorariosAutomaticos`, `UpdateEstoqueInstrucoes`, `SaveMedicamento`), utiliza `ScheduleCalculator` para normalizar/ordenar horários e persiste de forma atômica via `MedicamentoRepository.save()`.
- Atende integralmente ao Princípio III (Feature-First Modular Architecture — BLoC + Repository, sem lógica de negócio ou acesso direto ao banco em widgets) e à diretriz de Simplicidade & YAGNI (evita criar um segundo BLoC redundante para fazer o mesmo upsert de `Medicamento`).
- Como cada modal instancia seu próprio `BlocProvider<CadastroMedicamentoBloc>` a partir do `_medicamento` atual da tela de detalhes, fechar/cancelar o modal descarta automaticamente o estado temporário sem efeitos colaterais (FR-007).

**Alternatives considered**:
- Criar um novo `EdicaoRapidaMedicamentoCubit`/`Bloc` — rejeitado por duplicar eventos, validações de horários e chamadas ao `MedicamentoRepository.save` já existentes em `CadastroMedicamentoBloc`.
- Chamar `repository.save()` diretamente de `StatefulWidget` nos modais — rejeitado por violar o Princípio III da Constituição (widgets não devem conter regras de domínio nem executar persistência diretamente sem BLoC).

## R2 — Limpeza e validação do valor de dose (`doseValor`) no estado

**Decision**: Ajustar `CadastroMedicamentoState.copyWith` para suportar a limpeza explícita de `doseValor` (quando o usuário apaga o valor da dose ou insere valor inválido/vazio) e garantir no modal de dose que textos não numéricos ou valores `<= 0` quando preenchidos sejam validados antes de disparar `SaveMedicamento`.

**Rationale**:
- Atualmente, `CadastroMedicamentoState.copyWith` faz `doseValor: doseValor ?? this.doseValor`, o que impede limpar `doseValor` para `null` ao editar um medicamento que já possuía dose cadastrada. Usar um parâmetro sentinela (ou `clearDoseValor: bool`) em `copyWith` e tratar no handler `UpdateDosagem` resolve esse caso de borda sem quebrar os testes existentes.

**Alternatives considered**:
- Gravar `0.0` em vez de `null` — rejeitado porque `doseValor: null` é a representação canônica de dose não informada no modelo e no banco SQLite.

## R3 — Padrão de componente de UI para os modais e gatilhos na tela de detalhes

**Decision**:
- Usar `showModalBottomSheet<Medicamento>` com `isScrollControlled: true`, `useSafeArea: true` e padding adaptativo ao teclado (`MediaQuery.viewInsetsOf(context).bottom`).
- Em `DetalheMedicamentoPage`:
  - Adicionar botão de ação de edição rápida no card de cabeçalho (para editar **Dose** — valor e unidade) e parâmetro opcional `onEdit` em `_SecaoInfoCard` (exibindo um `IconButton` de edição no cabeçalho de cada card de seção: **Horários das Doses**, **Controle de Estoque** e **Instruções e Informações Adicionais**).
  - Quando o modal salva com sucesso (`state.isSuccess`), ele fecha retornando o `Medicamento` atualizado (`Navigator.of(modalContext).pop(state.toMedicamento())`), a `DetalheMedicamentoPage` atualiza seu estado local (`_medicamento`) e exibe um `SnackBar` discreto (`'Medicamento atualizado com sucesso!'`).
- Manter o botão `Editar medicamento` na `AppBar` apontando para `CadastroMedicamentoPage` (fluxo completo de 4 etapas).

**Rationale**:
- `ModalBottomSheet` com ajuste de `viewInsets` é o padrão ergonômico do Material 3 em dispositivos móveis para formulários curtos com teclado numérico ou de texto.
- Retornar o `Medicamento` salvo pelo `pop` do modal mantém exatamente o mesmo contrato já utilizado por `_editarMedicamento()` em `DetalheMedicamentoPage`.
- Ao retornar da `DetalheMedicamentoPage` para a `MedicamentosPage`, o código atual já executa `context.read<MedicamentosBloc>().add(LoadMedicamentos())` (linha 92 de `medicamentos_page.dart`), garantindo sincronização automática com a listagem principal sem mudanças extras.

**Alternatives considered**:
- `AlertDialog` centralizado — rejeitado porque a lista de horários e os chips de instruções/estoque ficam comprimidos quando o teclado virtual abre em telas menores.
- Navegar para `CadastroMedicamentoPage` posicionado na etapa `N` — rejeitado porque a especificação pede explicitamente modais de edição rápida na própria tela de detalhes sem obrigar o usuário a passar pelo fluxo de etapas.
