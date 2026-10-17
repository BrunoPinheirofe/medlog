# Implementation Plan: Edição Rápida de Medicamento por Modais

**Branch**: `002-edicao-rapida-medicamento` | **Date**: 2026-10-17 | **Spec**: [spec.md](./spec.md)  
**Input**: Feature specification from `/specs/002-edicao-rapida-medicamento/spec.md`

## Summary

Adicionar formulários de edição rápida em modais (`ModalBottomSheet`) diretamente na tela de detalhes do medicamento (`lib/features/medicamentos/views/detalhe_medicamento_page.dart`) para permitir a edição pontual de **Dose** (valor e unidade), **Horários das Doses** (adicionar, editar, remover e recalcular), **Estoque** (estoque atual, alerta mínimo e atalhos `+10`/`+20`/`+30`) e **Instruções** (chips de sugestões rápidas e texto livre), reutilizando o `CadastroMedicamentoBloc` e o `MedicamentoRepository` existentes para validação e persistência local atômica no SQLite.

## Technical Context

**Language/Version**: Dart SDK ^3.13.1 / Flutter  
**Primary Dependencies**: `flutter_bloc` + `equatable` (`CadastroMedicamentoBloc`), `sqflite` / `sqflite_common_ffi` (`MedicamentoRepository`), `material_ui` (Material 3 UI). Nenhuma nova dependência externa necessária.  
**Storage**: SQLite local (`AppDatabase`, `lib/core/database/app_database.dart`) na versão atual (v3), sem necessidade de migração de schema (`medicamentos` e `medicamento_horarios` já contemplam todos os campos).  
**Testing**: `flutter test` e `bloc_test` — testes de BLoC (`cadastro_medicamento_bloc_test.dart`) e testes de widget (`detalhe_medicamento_page_test.dart` e `medicamentos_page_test.dart`) usando `FakeMedicamentoRepository`.  
**Target Platform**: Android / iOS / Linux desktop (Flutter 100% offline).  
**Project Type**: Mobile app (Flutter, arquitetura modular feature-first).  
**Performance Goals**: Abertura instantânea dos modais (60 fps) e persistência local imediata (<50 ms em transação SQLite local) com atualização reativa da tela de detalhes sem recarregar a rota inteira.  
**Constraints**: 100% offline; linguagem empática em pt-BR; preservação do fluxo completo de edição (`CadastroMedicamentoPage`) no botão da `AppBar`; descarte seguro de alterações ao fechar/cancelar o modal.  
**Scale/Scope**: 4 modais de edição rápida acionados a partir das seções de `DetalheMedicamentoPage`, ajuste em `CadastroMedicamentoState.copyWith` para suportar limpeza de `doseValor`, e suíte de testes automatizados de widget e BLoC.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Avaliação | Pass |
|-----------|-----------|------|
| I. Offline-First & Privacy (NON-NEGOTIABLE) | Persistência 100% local via `MedicamentoRepository` (SQLite); sem uso de rede ou telemetria. | ✅ |
| II. Empathetic UX & Patient Safety | Reduz a carga cognitiva ao permitir ajustes rápidos por seção com validações claras (ex.: impedir medicamento de rotina fixa sem horários) e confirmações discretas, sem linguagem punitiva. | ✅ |
| III. Feature-First Modular Architecture (BLoC + Repository) | Tudo permanece dentro de `lib/features/medicamentos/`; os modais usam `CadastroMedicamentoBloc` + `MedicamentoRepository` e `ScheduleCalculator`, sem queries SQLite ou regras de negócio acopladas aos widgets. | ✅ |
| IV. Comprehensive Automated Testing | Cobertura planejada com testes de BLoC para atualização/limpeza de dose e testes de widget para os 4 modais na `DetalheMedicamentoPage` (salvar, validar erro e cancelar). | ✅ |
| V. Safe Schema Migrations & Data Integrity | Nenhuma mudança de schema SQLite necessária; a escrita reutiliza a transação atômica existente em `MedicamentoRepositorySqflite.save()`. | ✅ |

Nenhuma violação da Constituição identificada (pré e pós-design da Fase 1).

## Project Structure

### Documentation (this feature)

```text
specs/002-edicao-rapida-medicamento/
├── plan.md              # Este arquivo (/speckit-plan)
├── research.md          # Fase 0 — decisões técnicas e alternativas
├── data-model.md        # Fase 1 — subconjuntos de dados, validações e estados
├── quickstart.md        # Fase 1 — guia de execução e validação
├── contracts/           # Fase 1 — contratos de UI e assinaturas dos modais
│   └── ui-modals-contract.md
└── tasks.md             # Fase 2 (/speckit-tasks — gerado na próxima etapa)
```

### Source Code (repository root)

```text
lib/
└── features/
    └── medicamentos/
        ├── bloc/
        │   ├── cadastro_medicamento_bloc.dart       # Suporte a limpeza/atualização de doseValor
        │   └── cadastro_medicamento_state.dart      # Parametrização clearDoseValor em copyWith
        └── views/
            ├── detalhe_medicamento_page.dart        # Botões de edição rápida nas seções + integração com modais
            └── modals/
                └── edicao_rapida_modals.dart        # NOVO: Modais de Dose, Horários, Estoque e Instruções

test/
└── features/
    └── medicamentos/
        ├── bloc/
        │   └── cadastro_medicamento_bloc_test.dart  # Casos de teste adicionais para edição rápida/limpeza de dose
        └── views/
            ├── detalhe_medicamento_page_test.dart   # NOVO: Testes de widget dos 4 modais de edição rápida
            └── medicamentos_page_test.dart          # Testes de regressão da listagem e detalhes
```

**Structure Decision**: Segue estritamente a estrutura modular `lib/features/medicamentos/` existente. Os 4 modais coesos de edição rápida ficam organizados em `lib/features/medicamentos/views/modals/edicao_rapida_modals.dart`, mantendo `detalhe_medicamento_page.dart` enxuto e legível.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

Nenhuma violação — tabela não aplicável.
