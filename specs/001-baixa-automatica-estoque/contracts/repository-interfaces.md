# Contracts: Baixa Automática de Estoque

**Feature**: `/specs/001-baixa-automatica-estoque/spec.md`

App móvel interno (sem API HTTP) — os contratos relevantes são as interfaces Dart públicas alteradas e a migração de schema. Formato: assinaturas Dart idiomáticas da casa (documentação em pt-BR conforme convenção do repositório).

## 1. Métrica migratória (obrigatória antes de qualquer comportamento)

`AppDatabase` (lib/core/database/app_database.dart):

```dart
static const int databaseVersion = 4;  // era 3

// dentro de migrate(): if (oldVersion < 4) _migrateV3ParaV4(db);
// - rebuild de `medicamentos` com estoque_atual REAL (mesmo nome de tabela)
// - ALTER TABLE registros_dose ADD COLUMN estoque_consumido REAL NOT NULL DEFAULT 0
```

Contrato: migração única, transacional, idempotente (roda só quando `oldVersion < 4`), sem perda de linhas — verificada em `test/core/database/app_database_migration_test.dart`.

## 2. Domain — calculadora pura

`lib/features/medicamentos/domain/estoque_dose_calculator.dart`:

```dart
/// Quantidade de unidades físicas do estoque consumida por UMA tomada.
/// doseValor direto (ml/gotas/unidades); 1.0 para dose nula/não positiva
/// ou unidades de concentração (mg/mcg/g/UI) em formas sólidas.
double quantidadeConsumidaPorDose(Medicamento medicamento);

/// Formata o saldo: "30" para inteiros, "12,5" para frações (pt-BR).
String formatarEstoque(double valor);
```

## 3. Repository — MedicamentoRepository

```dart
/// Ajuste manual/programático do estoque (retipado): saldo fracionário,
/// limiar mínimo continua inteiro.
Future<void> updateEstoque(String id, double estoqueAtual, int estoqueMinimo);
```

`save/getAll/getById/delete` ficam inalterados; o mapeamento linha↔modelo passa a ler/escrever `estoque_atual` como double.

## 4. Repository — DoseRepository (comportamento alterado, assinaturas idênticas)

```dart
/// Ao marcar TOMADA: baixa min(quantidadeConsumidaPorDose(med), estoqueAtual)
/// e persiste o valor EFETIVO em registros_dose.estoque_consumido (mesma txn).
/// Ao sair de TOMADA (pendente/pulada): estorna registros_dose.estoque_consumido
/// daquele registro; fallback dose padrão para registros tomados herdados (v3).
/// Avaliação idempotente: status igual ⇒ nenhuma alteração de estoque.
Future<void> registrarStatusDose({...});

/// Dose extra "Tomada": baixa idêntica à agendada (quantidade real, piso 0).
Future<void> registrarDoseExtra({...});

/// Remoção da extra: estorna o que foi efetivamente deduzido no registro.
Future<void> removerDoseExtra({...});

/// registrarSilenciarDose NÃO toca estoque (contrato explícito).
Future<void> registrarSilenciarDose({...});
```

Riscos de compatibilidade aceitáveis: `estoque_consumido` default 0 é retrocompatível; chamadores existentes do Dart mantêm as mesmas assinaturas.
