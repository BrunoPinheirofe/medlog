# Quickstart: Edição Rápida de Medicamento por Modais

**Feature**: `/specs/002-edicao-rapida-medicamento/spec.md` | **Plano**: [plan.md](./plan.md)

Guia de validação fim-a-fim da funcionalidade de edição rápida por modais na tela de detalhes do medicamento. Veja também [data-model.md](./data-model.md) e [contracts/ui-modals-contract.md](./contracts/ui-modals-contract.md).

## Pré-requisitos

- Flutter/Dart SDK `^3.13.1` instalado.
- Executar comandos a partir da raiz do projeto (`/home/bruno/projetos/medlog`).

## Comandos de Validação Automatizada

```bash
# 1) Análise estática (deve retornar 0 erros/avisos)
flutter analyze

# 2) Testes unitários e de BLoC do cadastro/edição de medicamentos
flutter test test/features/medicamentos/bloc/cadastro_medicamento_bloc_test.dart

# 3) Testes de widget da tela de detalhes e modais de edição rápida
flutter test test/features/medicamentos/views/detalhe_medicamento_page_test.dart

# 4) Testes de integração/widget da listagem de medicamentos
flutter test test/features/medicamentos/views/medicamentos_page_test.dart

# 5) Suíte completa do projeto
flutter test
```

## Cenários de Validação Manual

1. **Edição Rápida de Estoque (US1)**:
   - Abra um medicamento com estoque baixo (ex.: `2 un.`, alerta em `5 un.`).
   - Na seção **Controle de Estoque**, toque no ícone **Editar estoque**.
   - No modal, toque no chip `+30 un.` (estoque vai para `32`) e toque em **Salvar**.
   - **Resultado esperado**: O modal fecha, o card exibe `32 un.` e o banner amarelo de estoque baixo desaparece imediatamente.

2. **Edição Rápida de Horários (US2)**:
   - Na seção **Horários das Doses**, toque no ícone **Editar horários**.
   - Adicione ou edite um horário (ou tente remover todos os horários e tocar em **Salvar** para verificar o bloqueio de validação).
   - Com pelo menos um horário válido, toque em **Salvar**.
   - **Resultado esperado**: Os chips de horário na seção são atualizados e exibidos em ordem cronológica.

3. **Edição Rápida de Dose (US3)**:
   - No card principal do topo da tela de detalhes, toque no ícone **Editar dose**.
   - Altere o valor da dose para `750` e a unidade para `mg` (ou `2,5` e `ml`) e toque em **Salvar**.
   - **Resultado esperado**: O cabeçalho passa a exibir `750 mg` (ou `2.5 ml`) imediatamente.

4. **Edição Rápida de Instruções (US4)**:
   - Na seção **Instruções e Informações Adicionais**, toque no ícone **Editar instruções**.
   - Toque no chip `Após refeições` e em `Com bastante água`, depois toque em **Salvar**.
   - **Resultado esperado**: A seção exibe `Após refeições, Com bastante água`.

5. **Cancelamento e Sincronização com a Lista**:
   - Abra qualquer modal de edição rápida, modifique o campo e toque em **Cancelar** (ou fora do modal). Verifique que o valor original permaneceu inalterado.
   - Volte para a tela de listagem de medicamentos e verifique que as alterações salvas nos passos 1 a 4 estão refletidas no card do medicamento.
