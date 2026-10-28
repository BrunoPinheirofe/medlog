# Implementation Plan: Alerta de Estoque Baixo

**Branch**: `001-low-stock-alert` | **Date**: 2026-10-19 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-low-stock-alert/spec.md`

## Summary

Exibir banners de aviso de reposição no topo da tela **Hoje** (`lib/features/doses/doses_page.dart`), acima da agenda de doses, para cada medicamento ativo na data selecionada cujo estoque atual seja menor ou igual ao limite mínimo (`estoqueAtual <= estoqueMinimo`) ou, em tratamentos temporários (`!usoContinuo`), insuficiente para cobrir as doses agendadas restantes até a data de fim do tratamento (`estoqueAtual < dosesRestantes * quantidadeConsumidaPorDose(med)`). A lógica de avaliação, pluralização de unidades por forma farmacêutica e ordenação por urgência (menor folga em relação à reposição) vive como função pura em `lib/features/medicamentos/domain/estoque_dose_calculator.dart`, sendo orquestrada por `DosesBloc` e refletida em `DosesState.alertasEstoque`.

## Technical Context

**Language/Version**: Dart SDK ^3.13.1 / Flutter (MVP mobile)

**Primary Dependencies**: `flutter_bloc` + `equatable` (`DosesBloc` / `DosesState`), `sqflite` / `sqflite_common_ffi` (persistência local já existente), `material_ui` (Material 3 UI), `flutter_test` (testes). Nenhuma dependência externa nova necessária.

**Storage**: SQLite local (`AppDatabase`, `lib/core/database/app_database.dart`) na versão atual (v4). Nenhuma migração de schema necessária — os alertas são derivados dinamicamente de `Medicamento` e dos `RegistroDose` do dia.

**Testing**: `flutter test` — testes unitários de domínio (`test/features/medicamentos/domain/estoque_dose_calculator_test.dart`) e testes de widget da tela Hoje (`test/features/doses/views/doses_page_test.dart`).

**Target Platform**: Android / iOS / Linux desktop (Flutter 100% offline, single-user local).

**Project Type**: mobile-app (Flutter, arquitetura modular feature-first).

**Performance Goals**: Cálculo em memória O(N) para dezenas de medicamentos (<1 ms) dentro de `DosesBloc._carregarDia`, mantendo transições de 60 fps e atualização imediata após marcar/desmarcar doses ou editar estoque.

**Constraints**: 100% offline; linguagem acolhedora e não punitiva em pt-BR; nenhum bloqueio ao registro de doses quando o estoque estiver baixo ou zerado; sem persistência de dispensa manual (o banner desaparece automaticamente quando o estoque é reposto).

**Scale/Scope**: 1 usuário local, dezenas de medicamentos; escopo restrito à calculadora de domínio (`AlertaEstoqueBaixo` + `calcularAlertasEstoqueBaixo`), estado do `DosesBloc` e componente visual `_BannerEstoqueBaixo` na `DosesPage`.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Avaliação | Pass |
|-----------|-----------|------|
| I. Offline-First & Privacy (NON-NEGOTIABLE) | Avaliação 100% em memória sobre dados locais do SQLite; zero chamadas de rede ou telemetria. | ✅ |
| II. Empathetic UX & Patient Safety | Aviso informativo e gentil (`"Atenção: Restam apenas X [unidade]. Hora de comprar!"`), sem bloquear tomadas nem induzir culpa; toque no banner facilita abrir os detalhes para repor estoque. | ✅ |
| III. Feature-First Modular Architecture (BLoC + Repository) | Regra de cálculo e formatação pura em `lib/features/medicamentos/domain/estoque_dose_calculator.dart`; orquestração em `DosesBloc`; `DosesPage` apenas renderiza `state.alertasEstoque`. | ✅ |
| IV. Comprehensive Automated Testing | Cobertura automatizada com testes unitários da calculadora (limites, cobertura até `dataFim`, pluralização, ordenação por urgência) e testes de widget em `DosesPage` (exibição, gatilho ao tomar dose, múltiplos avisos e recuperação). | ✅ |
| V. Safe Schema Migrations & Data Integrity | Nenhuma alteração de schema SQLite necessária (permanece na v4); consome o saldo fracionário (`double`) já migrado pela feature `001-baixa-automatica-estoque`. | ✅ |

Nenhuma violação da Constituição identificada (pré e pós-design da Fase 1).

## Project Structure

### Documentation (this feature)

```text
specs/001-low-stock-alert/
├── plan.md              # Este arquivo (/speckit-plan)
├── research.md          # Fase 0 — decisões técnicas
├── data-model.md        # Fase 1 — entidades derivadas e regras de validação
├── quickstart.md        # Fase 1 — guia de validação
├── contracts/           # Fase 1 — contratos Dart e de UI
│   └── alerta-estoque-contract.md
└── tasks.md             # Fase 2 (/speckit-tasks)
```

### Source Code (repository root)

```text
lib/
└── features/
    ├── medicamentos/
    │   └── domain/
    │       └── estoque_dose_calculator.dart  # AlertaEstoqueBaixo, calcularAlertasEstoqueBaixo, formatarMensagemEstoqueBaixo
    └── doses/
        ├── bloc/
        │   ├── doses_bloc.dart               # Computa alertasEstoque em _carregarDia
        │   └── doses_state.dart              # Campo alertasEstoque em DosesState
        └── doses_page.dart                   # Renderiza _BannerEstoqueBaixo acima da agenda

test/
└── features/
    ├── medicamentos/
    │   └── domain/
    │       └── estoque_dose_calculator_test.dart  # Testes unitários dos gatilhos, cobertura dataFim, pluralização e ordenação
    └── doses/
        └── views/
            └── doses_page_test.dart               # Testes de widget dos banners na tela Hoje
```

**Structure Decision**: Reaproveita a estrutura modular feature-first existente sem criar novos pacotes ou BLoCs. As funções puras de cálculo de alerta e formatação da mensagem de estoque baixo convivem em `lib/features/medicamentos/domain/estoque_dose_calculator.dart` junto a `quantidadeConsumidaPorDose` e `formatarEstoque`, pois compartilham as mesmas regras de unidade e saldo fracionário.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

Nenhuma violação — tabela não aplicável.
