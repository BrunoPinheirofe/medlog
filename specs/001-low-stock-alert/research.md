# Phase 0 Research: Alerta de Estoque Baixo

**Feature**: `/specs/001-low-stock-alert/spec.md` | **Date**: 2026-10-19

Todas as decisões técnicas foram consolidadas com base no código existente (`001-baixa-automatica-estoque` e `002-edicao-rapida-medicamento`) e na Constituição do projeto (`.specify/memory/constitution.md`).

## R1 — Cálculo de cobertura até o fim do tratamento (`dataFim`) e prevenção de falsos positivos

**Decision**:
- Para medicamentos de uso temporário (`!medicamento.usoContinuo && medicamento.duracaoDias != null && medicamento.duracaoDias! > 0`) ativos na `dataReferencia` (`medicamento.estaAtivoNaData(dataReferencia) == true`):
  - A data de início base é `inicio = DateTime.utc(dataInicio.year, dataInicio.month, dataInicio.day)` (ou a própria `dataReferencia` normalizada em UTC caso `dataInicio == null` em fixtures legados).
  - A data final inclusiva do tratamento é `fim = DateTime.utc(inicio.year, inicio.month, inicio.day + medicamento.duracaoDias! - 1)`.
  - O número de dias futuros após `dataReferencia` é `diasFuturos = fim.difference(alvoUtc).inDays` (`>= 0`).
  - No próprio dia (`dataReferencia`), o número de doses agendadas ainda restantes é `dosesRestantesHoje = max(0, medicamento.horarios.length - dosesConcluidasNaData)`, onde `dosesConcluidasNaData` é a quantidade de horários agendados daquele medicamento na `dataReferencia` cujo status já é `StatusDose.tomada` ou `StatusDose.pulada`.
  - O total de doses agendadas restantes até `fim` é `dosesRestantes = dosesRestantesHoje + (diasFuturos * medicamento.horarios.length)`.
  - O estoque necessário até o fim do tratamento é `consumoRestante = dosesRestantes * quantidadeConsumidaPorDose(medicamento)`.
  - O gatilho por fim de tratamento dispara quando `medicamento.estoqueAtual < consumoRestante` (`FR-004`, `FR-009`).

**Rationale**:
- Usar datas em `DateTime.utc(y, m, d)` evita erros de arredondamento de 23h/25h em dias de mudança de horário de verão.
- Descontar as doses já tomadas/puladas no dia atual evita um falso positivo crítico (`SC-004`): se o paciente inicia o dia com estoque exato para cobrir as doses restantes (ex.: 6 comprimidos para 6 doses em 3 dias) e marca a 1ª dose como tomada, o estoque cai para `5` e restam `5` doses a tomar (`5 >= 5`). Se o cálculo ignorasse os registros do dia e mantivesse `6` doses necessárias durante todo o dia, o banner apareceria indevidamente logo após tomar a dose.
- Multiplicar por `quantidadeConsumidaPorDose(medicamento)` integra perfeitamente com o saldo fracionário (`double`) introduzido em `001-baixa-automatica-estoque`.

**Alternatives considered**:
- Multiplicar sempre `diasRestantesTotais * horarios.length` ignorando doses já tomadas no dia — rejeitado por causar falso alerta no dia em que o estoque era exato antes da tomada (`SC-004`).
- Assumir consumo fixo de `1` por dose — rejeitado porque `001-baixa-automatica-estoque` já introduziu doses em `ml`/`gotas`/frações (`docs/pendencias-mvp.md` item 1.3); para comprimidos unitários ou em `mg`, `quantidadeConsumidaPorDose` retorna `1.0`, mantendo 100% de compatibilidade com os cenários da especificação.

## R2 — Ordenação por urgência ("menor folga em relação à reposição")

**Decision**:
- Para cada medicamento em alerta, definir:
  - `limiarMinimo = medicamento.estoqueMinimo.toDouble()`
  - `limiarCobertura = (!medicamento.usoContinuo) ? consumoRestante : 0.0`
  - `estoqueNecessario = max(limiarMinimo, limiarCobertura)`
  - `folga = medicamento.estoqueAtual - estoqueNecessario`
- Ordenar a lista de `AlertaEstoqueBaixo` por:
  1. `folga` crescente (menor folga / mais negativo primeiro — mais urgente no topo);
  2. `medicamento.estoqueAtual` crescente (estoque zerado ou menor saldo absoluto primeiro em caso de empate de folga);
  3. `medicamento.nome.toLowerCase()` crescente e `medicamento.id` crescente (ordem determinística).

**Rationale**:
- Atende diretamente ao critério de aceitação `US3.1` ("ordenados pelo mais urgente (menor folga em relação à reposição)") e garante estabilidade visual na lista de banners.

**Alternatives considered**:
- Ordenar apenas por `estoqueAtual` absoluto — rejeitado porque um medicamento que precisa de 10 unidades para terminar o tratamento e tem 3 (`folga = -7`) é mais urgente que outro com mínimo 2 e estoque 2 (`folga = 0`).

## R3 — Formatação da mensagem e pluralização por forma farmacêutica (`FR-002`)

**Decision**:
- Formatar `X` via `formatarEstoque(medicamento.estoqueAtual)` (inteiros sem casas decimais, ex.: `"2"`, `"0"`; frações com vírgula pt-BR, ex.: `"2,5"`).
- Quando `medicamento.estoqueAtual == 1.0`, usar verbo e unidade no singular:
  `"Atenção: Resta apenas 1 <unidade_singular>. Hora de comprar!"`
- Para qualquer outro valor (`0`, `0,5`, `2`, `15`, etc.), usar verbo e unidade no plural:
  `"Atenção: Restam apenas <X> <unidade_plural>. Hora de comprar!"`
- Mapeamento de unidades por `FormaMedicamento`:
  - `comprimido`: `comprimido` / `comprimidos`
  - `capsula`: `cápsula` / `cápsulas`
  - `gota`: `gota` / `gotas`
  - `liquido`: `ml` / `ml`
  - `injetavel`: `ampola` / `ampolas`
  - `spray`: `dose` / `doses`
  - `pomada` e `outro`: `unidade` / `unidades`

**Rationale**:
- Cumpre literalmente `FR-002`, `US1.1`, o Edge Case 1 (`"Restam apenas 0 comprimidos..."`) e a seção `Assumptions` da spec (`"Resta apenas 1 comprimido"` no singular).

## R4 — Posicionamento na `DosesPage` e fluxo de recuperação de estoque

**Decision**:
- Renderizar os banners (`_BannerEstoqueBaixo`) no início do `ListView` da `DosesPage` (logo abaixo de `_CalendarioSemanalStrip` e acima dos cards de horário / `_EstadoSemDosesCard`).
- Cada card de banner possui `Key('banner_estoque_baixo_${alerta.medicamento.id}')`, exibe o nome do medicamento (`alerta.medicamento.nome`) em destaque e a frase completa (`alerta.mensagem`), utilizando paleta âmbar acolhedora (`Colors.amber.shade100` / `Colors.amber.shade900`, ícone `Icons.warning_amber_rounded`), consistente com o aviso já existente em `DetalheMedicamentoPage`.
- Ao tocar no banner, navegar para `DetalheMedicamentoPage(medicamento: alerta.medicamento, repository: medicamentoRepository)` e, no retorno (`await Navigator.push(...)`), disparar `context.read<DosesBloc>().add(const LoadDosesDia())`.

**Rationale**:
- Satisfaz `FR-003` (destaque acima da lista de doses), `FR-006` e `US3.2` (desaparecimento imediato ao atualizar o estoque sem reiniciar o app), além de oferecer um atalho ergonômico direto para o modal de edição rápida de estoque (`002-edicao-rapida-medicamento`).
