# Implementation Plan: Baixa Automática de Estoque

**Branch**: `001-baixa-automatica-estoque` | **Date**: 2026-10-17 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-baixa-automatica-estoque/spec.md`

## Summary

Fracionalizar a baixa automática de estoque: hoje cada tomada desconta fixamente 1 unidade (`_ajustarEstoque` em `DoseRepositorySqflite`), ignorando a quantidade configurada do medicamento. O plano introduz uma regra de domínio pura (quantidade consumida por dose = `doseValor` para consumo direto em gotas/ml/unidades, senão 1), altera o estoque de `int` para `double` (model + schema SQLite), persiste a dedução efetiva por registro de dose (para estorno consistente quando o estoque bateu no piso 0) e aplica tudo atomicamente nas transações já existentes de registrar/estornar dose.

## Technical Context

**Language/Version**: Dart SDK ^3.13.1 / Flutter (MVP mobile)

**Primary Dependencies**: `flutter_bloc` + `equatable` (DosesBloc), `sqflite` / `sqflite_common_ffi` (persistência local), `flutter_test` (testes). Nenhuma dependência nova necessária.

**Storage**: SQLite local (`AppDatabase`, `lib/core/database/app_database.dart`), versão atual 3 → migra para 4.

**Testing**: `flutter test` — unit (calculadora de domínio), BLoC (transições de estado), repository/migration FFI (`sqflite_common_ffi`) e widget tests existentes.

**Target Platform**: Android/iOS (flutter app 100% offline, single-user local).

**Project Type**: mobile-app (Flutter, feature-first modular architecture).

**Performance Goals**: Atualização de estoque no mesmo evento local do toque na dose — imperceptível (<100 ms no fluxo já transacional; sem novas leituras em loop).

**Constraints**: 100% offline; nenhuma migração destrutiva; estoque jamais negativo (piso 0); registro de dose nunca bloqueado por falta de estoque.

**Scale/Scope**: 1 usuário local, dezenas de medicamentos; escopo: cálculo de quantidade consumida, tipagem fracionária do estoque, persistência da dedução efetiva e integração nos fluxos de tomar/estornar dose (agendada, grupo, extra/SOS). Exibição formatada do saldo (inteiro vs. decimal) na UI.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Avaliação | Pass |
|-----------|-----------|------|
| I. Offline-First & Privacy | Toda a baixa/estorno permanece em transações SQLite locais; sem qualquer rede | ✅ |
| II. Empathetic UX & Patient Safety | Dose nunca é bloqueada por estoque insuficiente (piso em 0, sem punição); estorno devolve exatamente o que foi descontado (corrige o bug atual de criar estoque fantasma ao desfazer) | ✅ |
| III. Feature-First Modular (BLoC + Repository) | Regra de quantidade consumida vive em `lib/features/medicamentos/domain/` como calculadora pura (padrão do `schedule_calculator.dart`); persistência no `DoseRepositorySqflite` (padrão já adotado); widgets e bloc sem regra de cálculo | ✅ |
| IV. Automated Testing | Testes unitários da calculadora, testes FFI do repository e migração v3→v4 no arquivo de migração obrigatório, bloc/widget tests atualizados | ✅ |
| V. Safe Schema Migrations | Mudança de `estoque_atual` (INTEGER→REAL) + nova coluna `estoque_consumido` em `registros_dose` exige `databaseVersion` 3→4 com caminho `onUpgrade` idempotente e não destrutivo (rebuild de tabela preservando dados) + teste de migração | ✅ |

Nenhuma violação: os pontos acima são exigências da própria constituição já contempladas no design (Sem necessidade de Complexity Tracking).

## Project Structure

### Documentation (this feature)

```text
specs/001-baixa-automatica-estoque/
├── plan.md              # Este arquivo
├── research.md          # Fase 0 — decisões técnicas
├── data-model.md        # Fase 1 — entidades e mudanças de schema
├── quickstart.md        # Fase 1 — guia de validação
├── contracts/           # Fase 1 — contratos Dart alterados
│   └── repository-interfaces.md
└── tasks.md             # Fase 2 (/speckit-tasks — não criado aqui)
```

### Source Code (repository root)

```text
lib/
├── core/
│   └── database/app_database.dart          # v4: estoque REAL + estoque_consumido, migrate()
└── features/
    ├── medicamentos/
    │   ├── domain/
    │   │   └── estoque_dose_calculator.dart # NOVO: quantidade consumida por dose (puro)
    │   ├── models/medicamento.dart          # estoqueAtual/estoqueMinimo → double
    │   ├── data/medicamento_mappers.dart    # mapear REAL ↔ double
    │   └── repositories/
    │       ├── medicamento_repository.dart  # updateEstoque(double, int)
    │       └── medicamento_repository_sqflite.dart
    └── doses/
        ├── repositories/
        │   ├── dose_repository.dart         # docs do contrato
        │   └── dose_repository_sqflite.dart # _ajustarEstoque usa calculadora + estoque_consumido
        └── (bloc/pages sem alteração de regra)

test/
├── core/database/app_database_migration_test.dart   # caso v3→v4
├── features/medicamentos/domain/estoque_dose_calculator_test.dart  # NOVO
├── features/doses/repositories/dose_repository_sqflite_test.dart   # frações, piso 0, estorno
└── (fakes com double: fake_repository.dart)
```

**Structure Decision**: Aproveita a estrutura feature-first existente sem novos módulos/blocs. A única peça nova de código é a calculadora de domínio pura (1 arquivo + teste), porque a dificuldade real da feature é a regra "quanto descontar por dose" — nada se justifica fora dela; o restante são mudanças de tipo e de transação já existentes.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

Nenhuma violação de constituição — tabela permanece vazia.
