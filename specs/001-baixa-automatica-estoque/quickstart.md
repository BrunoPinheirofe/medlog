# Quickstart: Baixa Automática de Estoque

**Feature**: `/specs/001-baixa-automatica-estoque/spec.md` | Plano: [plan.md](./plan.md)

Guia de validação fim-a-fim do comportamento. Detalhes de assinaturas: [contracts/repository-interfaces.md](./contracts/repository-interfaces.md); diagrama de dados: [data-model.md](./data-model.md).

## Pré-requisitos

- Flutter/Dart SDK ^3.13.1 instalado.
- Testes de banco rodam com `sqflite_common_ffi` já presente no projeto.
- Rodar da raiz do repositório `/home/bruno/projetos/medlog`.

## Comandos de validação

```bash
# 0) Estático zerado
flutter analyze

# 1) Migração v3 → v4 preserva dados e tipa o saldo em REAL (constituição V)
flutter test test/core/database/app_database_migration_test.dart

# 2) Regra de quantidade consumida (R1) e formatação (R6)
flutter test test/features/medicamentos/domain/estoque_dose_calculator_test.dart

# 3) Baixa/estorno fracionário, piso 0, idempotência, extras (E2E via repository FFI)
flutter test test/features/doses/repositories/dose_repository_sqflite_test.dart

# 4) Suíte completa (bloc/lista/detalhe com double — fakes retipados)
flutter test
```

## Cenários manuais (prova de aceitação)

Pré-requisito: app aberto na tela **Hoje** (emulador/dispositivo).

1. **Desconto fracionário**: cadastre "Xarope A" (Líquido, dose 2.5 ml) com estoque 100 ml; toque na dose e marque "Tomada". **Esperado**: saldo no detalhe = 97,5 ml; nenhuma dose bloqueada.
2. **Concentração não desconta massa**: cadastre "Comprimido B" (dose 500 mg) com estoque 30; marque a dose. **Esperado**: saldo −1 (29), pois mg é concentração da forma sólida.
3. **Estorno consistente com piso**: com estoque 1, marque a dose de 2.5 ml (saldo vira 0, consumo efetivo 1); desmarque a dose. **Esperado**: saldo volta a 1 (não 2.5/3.5).
4. **Dose extra**: registre dose extra SOS de 15 gotas com estoque 200. **Esperado**: saldo 185; remover a extra devolve para 200.
5. **Idempotência**: toque duas vezes em "Tomada" na mesma dose (menu "Marcar como tomada" já tomada). **Esperado**: saldo permanece o mesmo.
6. **Formatação**: detalhe do "Xarope A" mostra `97,5 ml`; após duas doses `95 ml` (sem decimais).

## Falhas comuns

- `Mismatched types: int → double` nos fakes/testes existentes → retipar os fixtures (fake_repository.dart, dados de testes).
- Migração falha com FK: verifique que o rebuild foi executado com `PRAGMA foreign_keys = OFF` e revalidado (`foreign_key_check`), conforme [data-model.md](./data-model.md).
