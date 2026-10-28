# Contracts: Alerta de Estoque Baixo

**Feature**: `/specs/001-low-stock-alert/spec.md`

Aplicação móvel 100% local (sem API HTTP) — os contratos abaixo definem as assinaturas públicas de domínio, estado do BLoC e semântica de UI/chaves de teste.

## 1. Domain — Calculadora de Alertas de Estoque

Arquivo: `lib/features/medicamentos/domain/estoque_dose_calculator.dart`

```dart
enum MotivoAlertaEstoque {
  abaixoDoMinimo,
  insuficienteAteFimTratamento,
}

class AlertaEstoqueBaixo extends Equatable {
  final Medicamento medicamento;
  final MotivoAlertaEstoque motivo;
  final double estoqueNecessario;
  final double folga;
  final String mensagem;

  const AlertaEstoqueBaixo({
    required this.medicamento,
    required this.motivo,
    required this.estoqueNecessario,
    required this.folga,
    required this.mensagem,
  });
}

/// Retorna a unidade textual correspondente à [forma] farmacêutica no singular ou plural.
String unidadeFormaEstoque(
  FormaMedicamento forma, {
  required bool singular,
  String? doseUnidade,
});

/// Formata a mensagem padrão do banner de estoque baixo (FR-002):
/// - Singular (estoqueAtual == 1): "Atenção: Resta apenas 1 <unidade>. Hora de comprar!"
/// - Plural (demais valores):      "Atenção: Restam apenas <X> <unidades>. Hora de comprar!"
String formatarMensagemEstoqueBaixo(Medicamento medicamento);

/// Avalia todos os [medicamentos] na [dataReferencia] e retorna os alertas de estoque
/// baixo ordenados pelo mais urgente (menor `folga`).
///
/// [dosesConcluidasNoDiaPorMedicamento] informa quantas doses agendadas na
/// [dataReferencia] já foram marcadas como tomadas ou puladas para cada `medicamento.id`.
List<AlertaEstoqueBaixo> calcularAlertasEstoqueBaixo({
  required List<Medicamento> medicamentos,
  required DateTime dataReferencia,
  Map<String, int> dosesConcluidasNoDiaPorMedicamento = const {},
});
```

## 2. State — `DosesState`

Arquivo: `lib/features/doses/bloc/doses_state.dart`

```dart
class DosesState extends Equatable {
  final DosesStatus status;
  final DateTime dataSelecionada;
  final List<GrupoHorarioDoses> gruposHorario;
  final List<ItemDoseDia> dosesExtras;
  final List<Medicamento> medicamentosDisponiveis;
  final List<AlertaEstoqueBaixo> alertasEstoque;
  final String? errorMessage;
  // ...
}
```

## 3. UI — Banner na Tela Hoje (`DosesPage`)

Arquivo: `lib/features/doses/doses_page.dart`

- **Posição**: No topo do `ListView` da tela **Hoje**, imediatamente antes dos cards `_CardGrupoHorario` (ou `_EstadoSemDosesCard`).
- **Key por item**: `ValueKey('banner_estoque_baixo_${alerta.medicamento.id}')`.
- **Conteúdo obrigatório**:
  - Nome do medicamento (`Text(alerta.medicamento.nome)`).
  - Mensagem de reposição (`Text(alerta.mensagem)`).
  - Ícone de aviso (`Icons.warning_amber_rounded`).
- **Interação**: Toque no card abre `DetalheMedicamentoPage` para o `alerta.medicamento` e, ao retornar, dispara `LoadDosesDia()` no `DosesBloc`. Nunca bloqueia o registro de doses.
