# Data Model: Edição Rápida de Medicamento por Modais

**Feature**: `/specs/002-edicao-rapida-medicamento/spec.md` | **Schema versão**: 3 (inalterado)

## Entidades

### Medicamento (existente — sem alteração de schema SQLite)

A funcionalidade opera sobre a entidade `Medicamento` (`lib/features/medicamentos/models/medicamento.dart`) e sua persistência transacional existente em `MedicamentoRepository.save(Medicamento)` (`medicamentos` + `medicamento_horarios`). Nenhuma migração de banco de dados é necessária.

#### Subconjuntos de Campos por Modal de Edição Rápida

| Modal | Campos Editados | Campos Preservados | Regras de Validação |
|-------|-----------------|--------------------|---------------------|
| **Edição Rápida de Dose** | `doseValor` (`double?`), `doseUnidade` (`String?`) | `id`, `nome`, `forma`, `corHex`, `frequencia`, `intervaloHoras`, `usoContinuo`, `duracaoDias`, `dataInicio`, `horarios`, `estoqueAtual`, `estoqueMinimo`, `instrucoes`, `fotoUrl` | - `doseValor`: opcional (se vazio → `null`); se preenchido, deve ser numérico `> 0` (aceita `,` ou `.` como separador decimal).<br>- `doseUnidade`: uma das unidades padrão (`mg`, `ml`, `gotas`, `comprimido`, `g`, `mcg`, `UI`). |
| **Edição Rápida de Horários** | `horarios` (`List<TimeOfDay>`) | Todos os demais campos do `Medicamento` | - Se `frequencia != Frequencia.quandoNecessario`, `horarios` **não pode ser vazio** (`horarios.isNotEmpty`).<br>- Horários são automaticamente normalizados (sem duplicatas) e ordenados cronologicamente via `ScheduleCalculator.normalizarEOrdenar`.<br>- Recálculo automático usa `ScheduleCalculator.gerarHorarios` com a `frequencia` e `intervaloHoras` atuais do medicamento. |
| **Edição Rápida de Estoque** | `estoqueAtual` (`int`), `estoqueMinimo` (`int`) | Todos os demais campos do `Medicamento` | - `estoqueAtual >= 0` (inteiro não-negativo; vazio assume `0`).<br>- `estoqueMinimo >= 0` (inteiro não-negativo; vazio assume `5` ou `0`).<br>- Exibe alerta visual informativo quando `estoqueAtual <= estoqueMinimo`. |
| **Edição Rápida de Instruções** | `instrucoes` (`String?`) | Todos os demais campos do `Medicamento` | - Texto livre após `trim()`; se vazio, persistido como `null`.<br>- Chips de sugestão rápida concatenam com `, ` sem duplicar termos já presentes no texto. |

## Transições de Estado (`CadastroMedicamentoBloc`)

1. **Abertura do Modal**:
   - `CadastroMedicamentoBloc` é instanciado com `medicamentoInicial: medicamentoAtual`.
   - Estado inicial: `CadastroMedicamentoState.fromMedicamento(medicamentoAtual)` com `isSubmitting: false`, `isSuccess: false`, `errorMessage: null`.
2. **Edição Local (dentro do Modal)**:
   - Modal de Dose dispara `UpdateDosagem(doseValor, doseUnidade)`.
   - Modal de Horários dispara `AdicionarHorario`, `EditarHorario`, `RemoverHorario` ou `GerarHorariosAutomaticos`.
   - Modal de Estoque dispara `UpdateEstoqueInstrucoes(novoEstoqueAtual, state.instrucoes, estoqueMinimo: novoEstoqueMinimo)`.
   - Modal de Instruções dispara `UpdateEstoqueInstrucoes(state.estoqueAtual, novasInstrucoes, estoqueMinimo: state.estoqueMinimo)`.
3. **Cancelamento / Fechamento**:
   - Modal é descartado (`Navigator.pop(context, null)`); o `BlocProvider` do modal é encerrado e nenhuma escrita ocorre no repositório.
4. **Confirmação (`SaveMedicamento`)**:
   - Valida `state.isNomeValido` e `state.isHorariosValidos`.
   - Se inválido: emite `errorMessage` e mantém o modal aberto exibindo o erro.
   - Se válido: emite `isSubmitting: true`, chama `_repository.save(state.toMedicamento())`, emite `isSubmitting: false, isSuccess: true`, fecha o modal retornando o `Medicamento` atualizado para `DetalheMedicamentoPage`.
