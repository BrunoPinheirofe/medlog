# Feature Specification: Baixa Automática de Estoque

**Feature Branch**: `001-baixa-automatica-estoque`

**Created**: 2026-10-17

**Status**: Draft

**Input**: User description: "### 1.2 — Baixa automática de estoque
- **Status:** repository já tem `updateEstoque` (`medicamento_repository_sqflite.dart:102`), porém **nenhum chamador usa**.
- **Falta:**
  - Ao registrar dose como "Tomei", subtrair a dose consumida do `estoqueAtual` do medicamento (e tratar frações: gotas/ml).
  - Desfazer a baixa se o usuário desfizer o registro da dose."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Desconto Automático de Estoque ao Tomar Dose (Priority: P1)

Quando o usuário registra que tomou uma dose (agendada, em grupo de horário ou dose extra/SOS), o aplicativo deve descontar automaticamente a quantidade consumida do estoque disponível daquele medicamento, considerando tanto unidades inteiras quanto doses fracionadas (como ml, gotas ou meio comprimido).

**Why this priority**: É o fluxo central da funcionalidade; sem a dedução proporcional à dose consumida, o saldo de estoque fica incorreto sempre que uma dose diferente de 1 unidade inteira é registrada, comprometendo os alertas de reposição.

**Independent Test**: Pode ser testado de forma independente cadastrando medicamentos com diferentes quantidades por dose (ex: 1 comprimido, 0,5 comprimido, 2,5 ml, 15 gotas) e estoque inicial conhecido, registrando a dose como "Tomada" e verificando se o saldo atualizado reflete exatamente a subtração da dose configurada.

**Acceptance Scenarios**:

1. **Given** um medicamento com estoque atual de 30 unidades e dose de 2 unidades por tomada, **When** o usuário marca uma dose agendada como "Tomada", **Then** o estoque atual do medicamento passa a ser 28 unidades.
2. **Given** um medicamento líquido com estoque atual de 100 ml e dose de 2,5 ml por tomada, **When** o usuário marca uma dose como "Tomada", **Then** o estoque atual do medicamento passa a ser 97,5 ml.
3. **Given** um medicamento em gotas com estoque atual de 200 gotas (ou equivalente configurado) e dose de 15 gotas por tomada, **When** o usuário registra uma dose extra ("Quando necessário / SOS"), **Then** o estoque atual do medicamento é reduzido em 15 unidades (passando para 185).
4. **Given** um medicamento sem valor de dose específico preenchido (ou quando a unidade representa a concentração do princípio ativo, como `mg`, `mcg`, `g` ou `UI` em comprimidos/cápsulas), **When** o usuário marca uma dose como "Tomada", **Then** o sistema desconta o padrão de 1 unidade física por tomada.

---

### User Story 2 - Estorno de Estoque ao Desfazer ou Alterar Status da Dose (Priority: P1)

Quando o usuário desfaz o registro de uma dose anteriormente marcada como "Tomada" (voltando para "Pendente", alterando para "Pulada/Esquecida" ou excluindo uma dose extra registrada por engano), o aplicativo deve restituir exatamente a quantidade consumida ao estoque atual do medicamento.

**Why this priority**: Essencial para a segurança do paciente e empatia da interface (evitando penalidades por toques acidentais). O usuário precisa poder corrigir um clique equivocado sem descalibrar o saldo real do seu medicamento.

**Independent Test**: Pode ser testado marcando uma dose (inteira ou fracionada) como "Tomada", verificando a redução do estoque e, em seguida, desmarcando a dose (ou removendo a dose extra) e confirmando que o estoque retornou exatamente ao valor original.

**Acceptance Scenarios**:

1. **Given** uma dose agendada de 2,5 ml que já está marcada como "Tomada" e cujo estoque atual é 97,5 ml, **When** o usuário desmarca a dose (voltando para "Pendente") ou altera seu status para não tomada, **Then** o estoque atual retorna para 100 ml.
2. **Given** um grupo de horário onde todas as doses estão marcadas como "Tomadas", **When** o usuário aciona a opção de desmarcar o grupo inteiro, **Then** o estoque de cada medicamento do grupo é acrescido de suas respectivas quantidades por dose.
3. **Given** uma dose extra previamente registrada para um medicamento com dose de 15 gotas e estoque atual de 85 gotas, **When** o usuário remove o registro dessa dose extra, **Then** o estoque atual do medicamento volta para 100 gotas.
4. **Given** uma dose que está "Pendente" e é alterada apenas para "Silenciada" (ou não tomada), **When** essa alteração ocorre sem passar pelo estado "Tomada", **Then** o estoque do medicamento permanece inalterado.

---

### User Story 3 - Visualização e Atualização de Estoque com Suporte a Frações (Priority: P2)

O usuário deve visualizar o saldo de estoque atualizado (incluindo valores decimais quando houver consumo fracionado, como `12,5 ml` ou `4,5 un.`) e receber indicação visual de estoque baixo assim que a baixa automática fizer o saldo atingir ou ficar abaixo do limite mínimo de alerta.

**Why this priority**: Garante transparência imediata ao usuário após a baixa automática, permitindo planejar a reposição do medicamento antes que ele acabe.

**Independent Test**: Pode ser testado registrando uma dose que reduza o estoque até o limite mínimo configurado e navegando para a tela de listagem ou detalhes do medicamento para verificar a exibição formatada do saldo e do alerta de estoque baixo.

**Acceptance Scenarios**:

1. **Given** um medicamento com estoque atual de 6 unidades, alerta mínimo de 5 unidades e dose de 2 unidades, **When** o usuário marca uma dose como "Tomada", **Then** o estoque cai para 4 unidades e o indicador de alerta de estoque baixo passa a ser exibido para esse medicamento.
2. **Given** um medicamento cujo estoque resultante após uma dose seja um número inteiro (ex: `10.0`), **When** o saldo é exibido na interface, **Then** ele é apresentado sem casas decimais desnecessárias (ex: `10`), enquanto saldos fracionados são exibidos com a parte decimal (ex: `10,5` ou `10.5`).

---

### Edge Cases

- **Estoque insuficiente ou zerado no momento da dose**: Se o `estoqueAtual` for menor que a quantidade da dose consumida (ex: estoque = `1`, dose = `2,5`, ou estoque = `0`), o registro da dose "Tomada" NUNCA deve ser bloqueado e o estoque deve ser limitado ao piso `0` (nunca ficando negativo).
- **Desfazer dose quando o estoque bateu no piso zero**: Se o estoque anterior era `0` (ou menor que a dose) quando a dose foi tomada e o usuário desfaz a ação logo em seguida, o sistema deve restaurar o saldo de forma consistente (evitando criar estoque inexistente se o medicamento já estava em `0` antes da tomada, ou restituindo a quantidade efetivamente deduzida).
- **Unidades de concentração vs. unidades de volume/quantidade**: Quando um medicamento sólido (ex: Comprimido ou Cápsula) tem a dose expressa em massa/concentração (ex: `500 mg`, `100 mcg`, `1 g`, `1000 UI`), o estoque é controlado em unidades físicas (comprimidos/cápsulas); portanto, cada tomada deve deduzir `1` unidade do estoque (e não `500` unidades). Já quando a unidade de dose ou forma representa volume/contagem direta consumida do estoque (`ml`, `gotas`, `comprimido`), deduz-se o próprio valor numérico da dose (`doseValor`).
- **Múltiplos cliques ou repetição do mesmo status**: Se uma dose já marcada como "Tomada" receber novamente o comando de "Tomada", nenhuma nova dedução deve ocorrer (operação idempotente).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema DEVE calcular a quantidade de estoque consumida por dose de acordo com a configuração do medicamento:
  - Quando a unidade/forma indicar consumo direto do saldo (`gotas`, `ml`, `comprimido`, ou formas líquidas/gotas com valor numérico definido), a quantidade consumida DEVE ser igual ao valor da dose (`doseValor`, suportando números decimais/fracionados).
  - Quando o medicamento não possuir `doseValor` definido (`null` ou `<= 0`), ou quando a unidade informada referir-se apenas à concentração farmacológica de uma forma sólida (`mg`, `mcg`, `g`, `UI`), a quantidade consumida DEVE assumir o padrão de `1` unidade por tomada.
- **FR-002**: O sistema DEVE suportar valores numéricos fracionados (decimais) para o estoque atual e para os ajustes de estoque, preservando a precisão ao descontar doses em `ml`, `gotas` ou frações de comprimido.
- **FR-003**: Ao alterar o status de uma dose agendada de não-tomada para "Tomada" (individualmente ou via ação de grupo de horário), o sistema DEVE subtrair a quantidade da dose consumida do `estoqueAtual` do medicamento de forma atômica junto ao registro da dose.
- **FR-004**: Ao registrar uma dose extra ("Quando necessário / SOS"), o sistema DEVE subtrair a quantidade da dose consumida do `estoqueAtual` do medicamento.
- **FR-005**: Ao desfazer uma dose agendada "Tomada" (retornando para "Pendente" ou outro status não-tomado, individualmente ou em grupo) ou ao remover uma dose extra registrada, o sistema DEVE estornar a quantidade deduzida ao `estoqueAtual` do medicamento.
- **FR-006**: O sistema DEVE garantir que o `estoqueAtual` nunca assuma um valor menor que zero (`0`), mesmo que o usuário registre doses quando o estoque estiver zerado ou abaixo do valor da dose.
- **FR-007**: A atualização manual ou programática de estoque disponibilizada pelo repositório de medicamentos (`updateEstoque`) DEVE estar integrada ao fluxo de persistência de estoque e suportar a representação numérica adotada para o saldo.
- **FR-008**: Qualquer alteração na estrutura de armazenamento local para suportar estoque fracionado DEVE preservar integralmente os dados de medicamentos e históricos de doses já cadastrados no dispositivo.

### Key Entities

- **Medicamento**: Representa o item terapêutico gerenciado pelo usuário, contendo forma farmacêutica, valor e unidade da dose (`doseValor`, `doseUnidade`), saldo de estoque disponível (`estoqueAtual`) e limite de alerta (`estoqueMinimo`).
- **Registro de Dose**: Representa um evento de tomada (agendada ou extra/SOS) vinculado a um medicamento em uma data e horário específicos, cujo status ("Tomada" vs. "Pendente") governa a baixa e o estorno de estoque.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% das doses marcadas como "Tomada" (individuais, em grupo ou extras) atualizam o saldo de estoque do respectivo medicamento imediatamente na mesma operação local, sem atraso perceptível ao usuário.
- **SC-002**: 100% das doses com valores fracionados ou múltiplos (ex: `0,5`, `2,5 ml`, `15 gotas`) descontam e estornam exatamente o valor configurado, com erro de arredondamento zero para até duas casas decimais.
- **SC-003**: 100% das operações de desfazer dose ("Tomada" → "Pendente" ou exclusão de dose extra) restauram o estoque ao estado pré-tomada sem perda ou duplicação de saldo.
- **SC-004**: Nenhum medicamento apresenta saldo de estoque negativo (`< 0`) após qualquer sequência de tomadas e estornos.

## Assumptions

- Para medicamentos em gotas ou líquidos, assume-se que o usuário informa o `estoqueAtual` na mesma grandeza de consumo da dose (ex: total de gotas ou total de ml no frasco) ou utiliza valores numéricos diretos compatíveis com `doseValor`.
- Caso um medicamento tinha estoque `0` antes de a dose ser marcada como "Tomada", a baixa efetiva foi `0`; ao desfazer essa dose, o sistema pode restaurar apenas a quantidade efetivamente descontada ou somar a dose padrão conforme o histórico local, priorizando a simplicidade e consistência transacional.
- O aplicativo permanece 100% offline, executando a atualização de status da dose e o ajuste de estoque dentro da mesma transação local.
