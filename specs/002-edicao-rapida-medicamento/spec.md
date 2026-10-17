# Feature Specification: Edição Rápida de Medicamento por Modais

**Feature Branch**: `002-edicao-rapida-medicamento`  
**Created**: 2026-10-17  
**Status**: Draft  
**Input**: User description: "formularios de edicao rapida em medicamentos, para editar doses, horarios estoques e instrucoes com modals na tela @[lib/features/medicamentos/views/detalhe_medicamento_page.dart]"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Edição Rápida de Estoque e Alerta Mínimo (Priority: P1)

Na tela de detalhes de um medicamento, o usuário deseja atualizar rapidamente a quantidade em estoque (por exemplo, ao comprar uma nova caixa) ou ajustar o limite de alerta mínimo diretamente a partir da seção "Controle de Estoque", através de uma janela modal focada, sem precisar percorrer todas as etapas do formulário completo de cadastro.

**Why this priority**: Reposição e ajuste de estoque são as alterações mais frequentes no ciclo de vida de um medicamento já cadastrado. Permitir essa edição em poucos toques reduz o atrito e mantém os alertas de estoque sempre confiáveis.

**Independent Test**: Pode ser testado abrindo a tela de detalhes de um medicamento existente, acionando a edição rápida na seção de estoque, adicionando ou alterando a quantidade atual e o alerta mínimo no modal, salvando e verificando se a tela de detalhes e o indicador de estoque baixo refletem os novos valores imediatamente.

**Acceptance Scenarios**:

1. **Given** que o usuário está na tela de detalhes de um medicamento com estoque atual de 3 unidades (com alerta de estoque baixo visível para limite de 5 unidades), **When** o usuário abre o modal de edição rápida de estoque, utiliza um atalho de adição rápida (ex: `+30 un.`) ou digita `33` e confirma, **Then** o modal se fecha, o estoque exibido passa a ser `33 un.` e o aviso de estoque baixo desaparece imediatamente.
2. **Given** que o usuário abre o modal de edição rápida de estoque, **When** ele altera o limite de alerta mínimo de `5` para `10` unidades e confirma, **Then** o novo limite é persistido e exibido na seção "Controle de Estoque".
3. **Given** que o usuário alterou valores no modal de estoque, **When** ele cancela ou fecha o modal sem salvar, **Then** nenhuma alteração é aplicada ao medicamento.

---

### User Story 2 - Edição Rápida de Horários das Doses (Priority: P1)

Na tela de detalhes de um medicamento, o usuário deseja ajustar os horários das tomadas (editar um horário existente, adicionar um novo horário, remover um horário ou recalcular a rotina a partir da primeira dose) diretamente na seção "Horários das Doses" por meio de um modal dedicado.

**Why this priority**: Mudanças na rotina diária do paciente exigem ajustes rápidos nos horários das doses. Ir até a 3ª etapa do assistente completo apenas para mudar um horário de `08:00` para `09:00` gera carga cognitiva desnecessária.

**Independent Test**: Pode ser testado abrindo a tela de detalhes de um medicamento, acionando a edição na seção de horários, alterando/adicionando/removendo horários no modal, salvando e verificando a lista de horários ordenada na tela de detalhes.

**Acceptance Scenarios**:

1. **Given** um medicamento com horários configurados às `08:00` e `20:00`, **When** o usuário abre o modal de edição rápida de horários, altera o horário das `08:00` para `09:00` e salva, **Then** a seção "Horários das Doses" na tela de detalhes passa a exibir `09:00` e `20:00`.
2. **Given** um medicamento de uso programado (não SOS) no modal de edição rápida de horários, **When** o usuário remove todos os horários e tenta salvar, **Then** o sistema exibe uma mensagem informando que ao menos um horário é obrigatório e impede o salvamento inválido.
3. **Given** um medicamento configurado como "Quando necessário (SOS)", **When** o usuário abre a edição rápida de horários ou frequência/posologia, **Then** o modal informa claramente que medicamentos sob demanda não exigem horários fixos (ou permite ajustar a frequência/posologia para habilitar horários).

---

### User Story 3 - Edição Rápida de Dose e Identificação (Priority: P2)

Na tela de detalhes de um medicamento, o usuário deseja ajustar rapidamente a dosagem/concentração (valor e unidade) ou dados básicos de apresentação no cabeçalho/seção de dose do medicamento através de um modal compacto, como quando o médico altera a dose prescrita de `25 mg` para `50 mg`.

**Why this priority**: Ajustes de dosagem prescrita ocorrem ao longo do tratamento e precisam ser simples de realizar diretamente a partir do cartão principal ou seção correspondente na tela de detalhes.

**Independent Test**: Pode ser testado abrindo a tela de detalhes, acionando a edição rápida de dose/identificação, alterando o valor e a unidade da dose (ex: de `500 mg` para `750 mg`), salvando e verificando a atualização imediata no cabeçalho da tela de detalhes.

**Acceptance Scenarios**:

1. **Given** um medicamento com dose de `500 mg`, **When** o usuário abre o modal de edição rápida de dose, altera o valor para `1000` (mantendo `mg`) e salva, **Then** o cabeçalho da tela de detalhes exibe imediatamente `1000 mg`.
2. **Given** um medicamento com dose em gotas ou líquido, **When** o usuário informa um valor decimal (ex: `2,5` com unidade `ml`) no modal de edição rápida de dose e salva, **Then** o valor fracionado e a unidade são salvos e formatados corretamente na tela de detalhes.

---

### User Story 4 - Edição Rápida de Instruções e Orientações Adicionais (Priority: P3)

Na tela de detalhes de um medicamento, o usuário deseja adicionar ou editar orientações de uso (ex: "Tomar com alimentos", "Em jejum") diretamente na seção "Instruções e Informações Adicionais" por meio de um modal com sugestões rápidas e campo de texto livre.

**Why this priority**: Facilita anotar recomendações médicas esquecidas durante o cadastro inicial sem abrir o fluxo completo de 4 etapas.

**Independent Test**: Pode ser testado acionando a edição na seção de instruções, selecionando chips de sugestões rápidas ou digitando uma orientação personalizada, salvando e verificando o texto atualizado na seção correspondente.

**Acceptance Scenarios**:

1. **Given** um medicamento sem instruções cadastradas, **When** o usuário abre o modal de edição rápida de instruções, seleciona a sugestão `"Após refeições"`, complementa o texto e salva, **Then** a seção "Instruções e Informações Adicionais" passa a exibir o novo texto imediatamente.
2. **Given** um medicamento com instruções preenchidas, **When** o usuário limpa todo o texto no modal de instruções e salva, **Then** a seção volta a exibir o estado vazio padrão (`"Nenhuma instrução especial cadastrada."`).

---

### Edge Cases

- **Cancelamento ou fechamento por gesto/toque externo**: Se o usuário fechar o modal (botão cancelar, botão voltar ou toque fora da área do modal), qualquer edição não confirmada deve ser descartada, mantendo os dados originais do medicamento intactos.
- **Validação de entradas inválidas nos modais**:
  - Valor de dose negativo ou texto não numérico no campo de dose não deve corromper o cadastro (deve ser validado ou tratado com segurança).
  - Horários duplicados adicionados manualmente no modal de horários devem ser normalizados (sem duplicatas) e ordenados cronologicamente ao salvar.
  - Medicamentos que não sejam de uso "Quando necessário (SOS)" não podem ser salvos no modal de horários com a lista de horários vazia.
  - Valores de estoque atual ou mínimo negativos não devem ser permitidos (piso mínimo de `0`).
- **Sincronização ao voltar para a listagem**: Após realizar uma ou mais edições rápidas na tela de detalhes e retornar para a lista de medicamentos, a listagem principal deve refletir todos os dados atualizados (dose, horários, estoque e alertas).
- **Preservação do fluxo completo de edição**: O botão de edição completa no topo da tela de detalhes deve continuar disponível para usuários que desejarem revisar ou alterar todo o cadastro passo a passo (incluindo nome, forma, cor, frequência e duração).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: A tela de detalhes do medicamento DEVE oferecer pontos de acionamento claros em suas seções (Cabeçalho/Dose, Horários das Doses, Controle de Estoque e Instruções Adicionais) para abrir formulários modais de edição rápida focados apenas no respectivo grupo de informações.
- **FR-002**: O modal de edição rápida de **Dose** DEVE permitir alterar o valor numérico da dose (suportando inteiros e decimais com vírgula ou ponto) e a unidade de medida (dentre as unidades padrão: `mg`, `ml`, `gotas`, `comprimido`, `g`, `mcg`, `UI`).
- **FR-003**: O modal de edição rápida de **Horários** DEVE permitir adicionar novos horários, editar horários existentes, remover horários individuais e recalcular horários automaticamente a partir de um horário inicial conforme a frequência do medicamento, garantindo ordenação cronológica e impedindo lista vazia para medicamentos com frequência fixa.
- **FR-004**: O modal de edição rápida de **Estoque** DEVE permitir editar o estoque atual, o limite de alerta mínimo e oferecer atalhos de adição rápida (`+10`, `+20`, `+30` unidades), exibindo aviso contextual caso o estoque configurado esteja abaixo ou igual ao alerta mínimo.
- **FR-005**: O modal de edição rápida de **Instruções** DEVE permitir editar o texto livre de orientações especiais e oferecer chips de sugestões rápidas (como `"Em jejum"`, `"Com alimentos"`, `"Após refeições"`, `"Antes de dormir"`, `"Com bastante água"`, `"Não mastigar"`, `"Evitar álcool"`).
- **FR-006**: Ao confirmar a edição em qualquer modal rápido, o sistema DEVE persistir imediatamente o medicamento atualizado no armazenamento local, atualizar os dados exibidos na tela de detalhes sem recarregar a página inteira e exibir uma confirmação visual discreta de sucesso.
- **FR-007**: Ao fechar qualquer modal rápido sem salvar (cancelar), o sistema DEVE descartar as alterações temporárias sem modificar o registro persistido.
- **FR-008**: A ação de edição completa já existente na barra superior da tela de detalhes DEVE ser mantida funcional para edições gerais (como nome, forma farmacêutica, cor, frequência e duração do tratamento), podendo também a seção de Frequência e Duração acionar edição rápida ou direcionar adequadamente sem perda de funcionalidade.

### Key Entities

- **Medicamento**: Entidade central cujos atributos são atualizados parcialmente por seção (dosagem: `doseValor` e `doseUnidade`; rotina: `horarios`; estoque: `estoqueAtual` e `estoqueMinimo`; orientações: `instrucoes`), mantendo os demais campos inalterados durante cada edição rápida.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: O usuário consegue atualizar o estoque, um horário de dose, a dosagem ou as instruções de um medicamento diretamente na tela de detalhes em no máximo 3 interações (abrir modal, ajustar valor, salvar), sem precisar navegar pelas 4 etapas do formulário completo.
- **SC-002**: 100% das alterações confirmadas nos modais de edição rápida são refletidas instantaneamente na tela de detalhes e permanecem salvas após fechar o aplicativo ou retornar para a listagem de medicamentos.
- **SC-003**: 100% das tentativas de salvar um estado inválido nos modais (como zero horários em um medicamento de uso programado) são bloqueadas com feedback claro ao usuário antes da persistência.
- **SC-004**: Nenhuma informação de outras seções do medicamento é perdida ou sobrescrita indevidamente ao salvar uma edição rápida em uma seção específica.

## Assumptions

- Os modais de edição rápida seguem o padrão visual e de linguagem empática do aplicativo (português brasileiro, mensagens claras e não punitivas).
- Para medicamentos configurados como "Quando necessário (SOS)", a seção de horários continua informando que não há horários fixos; caso o usuário queira definir horários fixos, assume-se que ele pode alterar a frequência ou utilizar a edição do medicamento.
- O funcionamento permanece 100% local e offline, gravando as alterações no banco de dados local do dispositivo por meio do repositório de medicamentos existente.
