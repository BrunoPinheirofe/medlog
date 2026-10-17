# UI & Component Contracts: Modais de Edição Rápida

**Feature**: `/specs/002-edicao-rapida-medicamento/spec.md`

## 1. Pontos de Entrada em `DetalheMedicamentoPage`

Arquivo: `lib/features/medicamentos/views/detalhe_medicamento_page.dart`

| Seção na Tela | Elemento de Acionamento (Key / Tooltip) | Modal Acionado |
|---------------|-----------------------------------------|----------------|
| Cabeçalho Principal (Dose) | `IconButton` com `key: Key('btn_editar_rapido_dose')`, `tooltip: 'Editar dose'` | `mostrarModalEditarDose` |
| Seção: Horários das Doses | `IconButton` no cabeçalho do card com `key: Key('btn_editar_rapido_horarios')`, `tooltip: 'Editar horários'` | `mostrarModalEditarHorarios` |
| Seção: Controle de Estoque | `IconButton` no cabeçalho do card com `key: Key('btn_editar_rapido_estoque')`, `tooltip: 'Editar estoque'` | `mostrarModalEditarEstoque` |
| Seção: Instruções e Informações Adicionais | `IconButton` no cabeçalho do card com `key: Key('btn_editar_rapido_instrucoes')`, `tooltip: 'Editar instruções'` | `mostrarModalEditarInstrucoes` |
| AppBar (Ação existente mantida) | `IconButton` com `tooltip: 'Editar medicamento'` | `CadastroMedicamentoPage` (fluxo completo em 4 etapas) |

## 2. Assinaturas dos Modais de Edição Rápida

Arquivo: `lib/features/medicamentos/views/modals/edicao_rapida_modals.dart`

Cada função exibe um `ModalBottomSheet<Medicamento>` provendo um `CadastroMedicamentoBloc` isolado e retorna o `Medicamento` persistido em caso de confirmação, ou `null` caso o usuário cancele/feche o modal.

```dart
Future<Medicamento?> mostrarModalEditarDose(
  BuildContext context, {
  required Medicamento medicamento,
  MedicamentoRepository? repository,
});

Future<Medicamento?> mostrarModalEditarHorarios(
  BuildContext context, {
  required Medicamento medicamento,
  MedicamentoRepository? repository,
});

Future<Medicamento?> mostrarModalEditarEstoque(
  BuildContext context, {
  required Medicamento medicamento,
  MedicamentoRepository? repository,
});

Future<Medicamento?> mostrarModalEditarInstrucoes(
  BuildContext context, {
  required Medicamento medicamento,
  MedicamentoRepository? repository,
});
```

## 3. Comportamento Comum dos Modais

- **Cabeçalho do Modal**: Título claro da seção (ex.: `'Editar Dose'`, `'Editar Horários'`, `'Editar Estoque'`, `'Editar Instruções'`) e botão de fechar (`Icons.close`).
- **Rodapé de Ações**:
  - `TextButton` com rótulo `'Cancelar'` → fecha o modal retornando `null`.
  - `FilledButton` com rótulo `'Salvar'` → valida entradas e envia `SaveMedicamento()` ao `CadastroMedicamentoBloc`.
- **Feedback pós-salvamento**:
  - Na confirmação bem-sucedida, a `DetalheMedicamentoPage` atualiza seu estado `_medicamento` imediatamente e apresenta `SnackBar` com `'Medicamento atualizado com sucesso!'`.
