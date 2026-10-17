# Feature Specification: Alerta de estoque baixo

**Feature Branch**: `001-low-stock-alert`

**Created**: 2026-10-17

**Status**: Draft

**Input**: User description: "1.3 — Alerta de estoque baixo — Banner na tela Hoje: 'Atenção: Restam apenas X comprimidos. Hora de comprar!' quando `estoqueAtual <= estoqueMinimo`. Considerar também `dataFim` do tratamento como gatilho de 'repor'."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Banner de estoque abaixo do mínimo (Priority: P1)

Marta toma um medicamento em tratamento e, ao abrir o app pela manhã, vê o aviso de que o estoque do remédio está acabando — antes de faltar comprimido no dia da dose. O aviso aparece na tela **Hoje**, em destaque acima da agenda de doses, com a mensagem "Atenção: Restam apenas X comprimidos. Hora de comprar!".

**Why this priority**: É o requisito central do item 1.3 do backlog; protege o paciente contra interrupção do tratamento por falta de medicamento, o cenário de maior risco.

**Independent Test**: Cadastrar um medicamento, ajustar seu estoque atual para um valor igual ou inferior ao seu estoque mínimo e abrir a tela Hoje. O banner deve estar visível. Implementável de forma independente das demais stories.

**Acceptance Scenarios**:

1. **Given** um medicamento ativo com estoque atual de 2 comprimidos e estoque mínimo de 5, **When** o usuário abre a tela Hoje, **Then** um banner exibido acima da agenda mostra "Atenção: Restam apenas 2 comprimidos. Hora de comprar!".
2. **Given** um medicamento ativo com estoque atual de 10 comprimidos e estoque mínimo de 5, **When** o usuário abre a tela Hoje, **Then** nenhum banner de estoque é exibido para esse medicamento.
3. **Given** um medicamento ativo em que o estoque atual equivale exatamente ao estoque mínimo (ex.: 5 e 5), **When** o usuário abre a tela Hoje, **Then** o banner é exibido (o limite é atingido no sinal de igual).
4. **Given** que o usuário registrou uma dose como tomada e o estoque caiu de 5 para 4 com mínimo de 5, **When** a tela Hoje é atualizada após o registro, **Then** o banner de estoque baixo passa a ser exibido sem que o aplicativo precise ser reiniciado.

---

### User Story 2 - Aviso de reposição perto do fim do tratamento (Priority: P2)

João usa um medicamento de uso temporário (tratamento com data de fim definida). Mesmo estando acima do mínimo, seu estoque não é suficiente para cobrir todas as doses agendadas até o fim do tratamento. O aviso de reposição aparece para que ele compre antes de terminar o estoque no meio do tratamento.

**Why this priority**: complementa o limite estático do estoque mínimo: um estoque "acima do mínimo" ainda pode ser insuficiente para concluir um tratamento que está acabando. Sem isso, o aviso falha justamente nos tratamentos por prazo definido.

**Independent Test**: Cadastrar um medicamento temporário com data de fim próxima e estoque insuficiente para as doses restantes, porém acima do estoque mínimo. Ao abrir a tela Hoje, o banner de reposição deve aparecer.

**Acceptance Scenarios**:

1. **Given** um tratamento temporário ativo com data de fim em 3 dias e 6 doses agendadas até o fim, com estoque atual de 4 comprimidos e mínimo de 2, **When** o usuário abre a tela Hoje, **Then** o banner de reposição é exibido (o estoque cobre apenas 4 das 6 doses).
2. **Given** um tratamento temporário com data de fim em 3 dias e estoque suficiente para todas as doses agendadas e acima do mínimo, **When** o usuário abre a tela Hoje, **Then** nenhum banner é exibido.
3. **Given** um medicamento de uso contínuo (sem data de fim) acima do estoque mínimo, **When** o usuário abre a tela Hoje, **Then** nenhum banner de reposição por fim de tratamento é exibido (o disparo por mínimo segue a regra da User Story 1).

---

### User Story 3 - Gestão de múltiplos avisos e recuperação (Priority: P3)

Carla cuida de rotina com mais de um medicamento e pode ter mais de um em situação de reposição ao mesmo tempo. Ela precisa saber quais estão baixos, e o aviso desaparece assim que ela atualiza o estoque após comprar o medicamento.

**Why this priority**: protege a clareza da tela em cenários de rotina com vários medicamentos; melhoria de UX que depende das regras centrais (P1/P2) já funcionarem.

**Independent Test**: Cadastrar dois medicamentos com estoque abaixo do mínimo e um acima; abrir a tela Hoje e verificar os avisos; atualizar o estoque de um deles e verificar que o respectivo aviso desaparece.

**Acceptance Scenarios**:

1. **Given** dois medicamentos ativos com estoque abaixo do mínimo, **When** o usuário abre a tela Hoje, **Then** um banner é exibido para cada medicamento, indicando o nome e a quantidade restante, ordenados pelo mais urgente (menor folga em relação à reposição).
2. **Given** um banner visível para um medicamento, **When** o usuário edita o medicamento e define o estoque atual acima do mínimo (com cobertura suficiente ao fim do tratamento, quando aplicável), **Then** o banner correspondente desaparece da tela Hoje na próxima atualização, sem reiniciar o app.
3. **Given** um medicamento cujo tratamento já terminou (data de fim anterior a hoje) com estoque baixo, **When** o usuário abre a tela Hoje, **Then** nenhum banner é exibido para ele.

### Edge Cases

- Estoque zerado: o aviso é exibido com "Restam apenas 0 ..." reforçando a urgência de compra; o usuário não é impedido de registrar doses (não há bloqueio punitivo, respeitando o princípio de UX não punitiva).
- Estoque mínimo igual a zero: só dispara banner quando o estoque atual também for zero (limiar de igualdade).
- Doses extras (SOS) reduzem o estoque e podem disparar o banner imediatamente após o registro de uma dose extra.
- Mais de um medicamento com o mesmo nome: cada aviso é vinculado ao cadastro individual, não ao nome.
- Estoque mínimo indefinido/cadastro antigo sem valor de mínimo: banner não é exibido por essa regra (sem limiar para comparar).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: A tela Hoje MUST exibir um aviso (banner) de estoque baixo para cada medicamento ativo cujo estoque atual seja menor ou igual ao seu estoque mínimo definido.
- **FR-002**: O banner MUST apresentar a mensagem "Atenção: Restam apenas X [unidade]. Hora de comprar!", em que X é o estoque atual e [unidade] corresponde à forma do medicamento (ex.: "comprimidos", "cápsulas", "gotas").
- **FR-003**: O banner MUST aparecer em posição de destaque na tela Hoje, acima da lista de doses do dia.
- **FR-004**: O sistema MUST considerar a data de fim do tratamento como gatilho de reposição: para tratamentos temporários ativos, o banner MUST ser exibido quando o estoque atual for insuficiente para cobrir todas as doses agendadas entre hoje e a data de fim do tratamento, mesmo que estoque atual > estoque mínimo.
- **FR-005**: Para tratamentos de uso contínuo (sem data de fim), o único gatilho de reposição é o limite do estoque mínimo (FR-001).
- **FR-006**: O aviso some automaticamente assim que o estoque for atualizado para um valor acima do mínimo (ou com cobertura suficiente para o fim do tratamento, quando aplicável), sem persistir reconhecimento/dispensa manual.
- **FR-007**: Nenhum banner MUST ser exibido para medicamentos sem tratamento ativo no dia (tratamento encerrado ou ainda não iniciado).
- **FR-008**: O aviso é apenas informativo e de tom acolhedor; ele NÃO DEVE bloquear registro de doses, emitir punição ou gerar ansiedade (linguagem não punitiva segundo a constituição).
- **FR-009**: A verificação do esgotamento por data de fim MUST computar as doses agendadas do cronograma do medicamento (quantas doses restam agendadas de hoje até a data de fim), não um número fixo arbitrário.

### Key Entities *(include if feature involves data)*

- **Medicamento**: cadastro de medicamento do usuário; atributos relevantes: nome, forma (unidade de contagem — ex. comprimido, cápsula, gota), estoque atual, estoque mínimo, tipo de uso (contínuo ou temporário), data de início e duração do tratamento (de onde se deriva a data de fim). É o medicamento que define o estado do banner.
- **Dose agendada**: dose prevista pelo cronograma de um medicamento em uma data; usada para estimar o consumo restante até o fim do tratamento (para tratamentos temporários).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Em todos os casos em que o estoque de um medicamento ativo esteja igual ou abaixo do mínimo, o aviso aparece na tela Hoje na primeira abertura após a condição existir, sem exigir qualquer ação do usuário (0% de omissão do aviso).
- **SC-002**: Nos tratamentos temporários em que o estoque não cobre as doses restantes até a data de fim, o aviso aparece na tela Hoje (verificável em menos de 5 segundos após abrir a tela).
- **SC-003**: Após o usuário atualizar o estoque para valor satisfatório, o aviso desaparece da tela Hoje na próxima atualização, sem reiniciar o aplicativo.
- **SC-004**: Em uma rotina simulada de 30 dias com 5 medicamentos mantendo estoque acima do mínimo e com cobertura suficiente, o resultado é 0 avisos falsos exibidos. em uma rotina simulada de 30 dias com 5 medicamentos em que todos mantenham estoque acima do mínimo e com cobertura suficiente: 0 banners indevidos.
- **SC-005**: Em teste de usabilidade simples, 9 em 10 usuários de teste compreendem, somente lendo o banner, qual ação tomar (comprar/repor o medicamento).

## Assumptions

- Cada dose consumida subtrai 1 unidade do estoque atual (comportamento já adotado na baixa automática do item 1.2 do backlog), então "cobrir as doses restantes" equivale a comparar o estoque atual com o número de doses agendadas restantes até a data de fim.
- A data de fim de um tratamento temporário é derivada dos dados existentes no cadastro (data de início + duração em dias); tratamentos de uso contínuo não possuem data de fim.
- O texto do banner ajusta a unidade plural conforme a forma do medicamento; quando há apenas um comprimido restante, a frase no singular ("Resta apenas 1 comprimido") é preferível, mantendo a mesma estrutura do texto-base.
- Não há reconhecimento ("dispensar por hoje"): o banner segue a regra matemática e some quando a condição deixa de valer — comportamento mais simples e sem risco de silenciar um alerta crítico esquecido.
- Com mais de um medicamento em baixo estoque, um banner por medicamento é exibido (ordenado pelo mais urgente); uma mensagem única combinada não é necessária nesta versão.
- O banner se aplica apenas à tela Hoje; notificações de sistema ou avisos em outras telas estão fora do escopo deste item.
