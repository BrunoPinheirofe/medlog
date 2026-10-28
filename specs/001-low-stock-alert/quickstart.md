# Quickstart: Alerta de Estoque Baixo

**Feature**: `/specs/001-low-stock-alert/spec.md` | **Plano**: [plan.md](./plan.md)

Guia de validação fim-a-fim dos banners de alerta de estoque baixo na tela **Hoje**. Detalhes do modelo e contratos em [data-model.md](./data-model.md) e [contracts/alerta-estoque-contract.md](./contracts/alerta-estoque-contract.md).

## Pré-requisitos

- Flutter/Dart SDK `^3.13.1` instalado.
- Executar os comandos a partir da raiz do repositório (`/home/bruno/projetos/medlog`).

## Comandos de Validação Automatizada

```bash
# 1) Análise estática (0 erros/avisos)
flutter analyze

# 2) Testes unitários da calculadora de domínio (gatilhos, cobertura até dataFim, pluralização, ordenação)
flutter test test/features/medicamentos/domain/estoque_dose_calculator_test.dart

# 3) Testes de widget da tela Hoje (banners acima da agenda, atualização ao tomar dose e ao editar estoque)
flutter test test/features/doses/views/doses_page_test.dart

# 4) Suíte completa do projeto
flutter test
```

## Cenários de Validação Manual

1. **Estoque abaixo ou igual ao mínimo (US1)**:
   - Cadastre um medicamento contínuo (ex.: "Losartana", Comprimido, estoque atual `2`, alerta mínimo `5`).
   - Abra a aba **Hoje**.
   - **Esperado**: Acima da agenda de horários aparece o banner de "Losartana" com o texto `"Atenção: Restam apenas 2 comprimidos. Hora de comprar!"`.
2. **Disparo dinâmico ao tomar dose (US1.4)**:
   - Com um medicamento ativo tendo `estoqueAtual = 5` e `estoqueMinimo = 5` (ou `estoqueAtual = 6`, `estoqueMinimo = 5`), marque uma dose como tomada na tela **Hoje**.
   - **Esperado**: O estoque cai e o banner passa a ser exibido (ou atualiza a quantidade restante) imediatamente, sem reiniciar o app.
3. **Cobertura insuficiente até o fim do tratamento (US2)**:
   - Cadastre um medicamento temporário com duração de `3 dias`, `2 vezes ao dia` (`6 doses` restantes), `estoqueAtual = 4` e `estoqueMinimo = 2`.
   - Abra a aba **Hoje**.
   - **Esperado**: Mesmo com `4 > 2` (acima do mínimo), o banner é exibido porque `4` comprimidos não cobrem as `6` doses agendadas até o fim do tratamento.
4. **Múltiplos alertas e recuperação ao repor estoque (US3)**:
   - Com dois medicamentos em alerta, verifique que ambos aparecem no topo da tela **Hoje**, com o mais urgente (menor folga) primeiro.
   - Toque no banner do medicamento, edite o estoque rapidamente para `+30 un.` e salve; volte para a tela **Hoje**.
   - **Esperado**: O banner daquele medicamento desaparece imediatamente.
