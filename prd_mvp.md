# 📄 PRD - MVP: App de Lembretes de Medicação (MedLog)

## 👤 1. Perfil do Usuário (Persona)
*   **Quem são:** Pessoas jovens e adultas em tratamento de condições de saúde mental (TDAH, ansiedade, depressão).
*   **Principais Dores:** Esquecem de tomar a medicação por distração e sentem culpa por isso. Têm dificuldade de lembrar e relatar ao médico como se sentiram ao longo do mês. Correm o risco de tomar dose dupla por esquecimento momentâneo.
*   **Comportamento Tecnológico:** Precisam de interfaces muito limpas (sem sobrecarga de cores e textos). Ficam ansiosos com apps que os "punem" por quebrar sequências (streaks) perfeitas.
*   **Necessidade de Privacidade:** Querem ter certeza de que seus dados médicos não estão vazando na internet.

---

## 📖 2. Histórias de Usuário e Critérios de Aceite

### Épico 1: Cadastro e Gestão de Medicamentos
**História 1.1:** *Como usuário, quero cadastrar meu remédio com foto da caixa e do comprimido para não tomar o remédio errado.*
*   **Critérios de Aceite:**
    *   O usuário deve poder inserir nome do remédio, dosagem e forma de uso.
    *   O app deve permitir tirar ou anexar até 2 fotos (uma da caixa, outra do comprimido).
    *   Todos os dados devem ser salvos apenas localmente no aparelho (Offline).

**História 1.2:** *Como usuário, quero informar a quantidade de comprimidos que tenho, para o app me avisar quando eu precisar comprar mais.*
*   **Critérios de Aceite:**
    *   O usuário insere o estoque inicial (ex: 30 comprimidos).
    *   Cada vez que marcar o remédio como "Tomei", o app subtrai 1 do estoque automaticamente.
    *   Quando o estoque chegar a um limite crítico (ex: 5 comprimidos), o app deve emitir um alerta claro na tela inicial: *"Atenção: Restam apenas X comprimidos. Hora de comprar!"*.

### Épico 2: Alertas Gentis e Seguros
**História 2.1:** *Como usuário, quero receber lembretes na tela do celular com botões rápidos para que eu não precise abrir o app só para avisar que já tomei.*
*   **Critérios de Aceite:**
    *   A notificação Push deve ter 3 botões de ação direta: "Tomei", "Adiar 15 min" e "Pular".
    *   O app não deve usar linguagem de cobrança ou culpa se o usuário pular ou atrasar.

**História 2.2:** *Como usuário, quero ser bloqueado/avisado se eu tentar registrar a mesma dose duas vezes, para evitar uma superdosagem perigosa.*
*   **Critérios de Aceite:**
    *   Se o usuário marcar "Tomei" e, no mesmo turno/horário, tentar marcar de novo, a tela deve ficar vermelha com o aviso em destaque: *"Você já registrou esta dose hoje às HH:mm! Tem certeza?"*.
    *   O usuário deve confirmar explicitamente para prosseguir.

**História 2.3:** *Como usuário, quero configurar se os alarmes do app podem furar o modo "Não Perturbe" do meu celular.*
*   **Critérios de Aceite:**
    *   Deve existir uma opção nas configurações do app para ativar/desativar "Alertas Críticos" (que tocam mesmo no silencioso).

**História 2.4:** *Como usuário, quero ser avisado se eu for tomar um remédio estimulante muito tarde da noite, para não perder meu sono.*
*   **Critérios de Aceite:**
    *   No cadastro, deve haver uma opção: "Este remédio é estimulante?".
    *   Se marcado como sim, e o usuário apertar "Tomei" após um horário de corte (ex: 17h), o app deve perguntar: *"Tomar este medicamento agora pode atrapalhar seu sono. Tem certeza?"*.

### Épico 3: Acompanhamento (Diário Rápido)
**História 3.1:** *Como usuário, quero registrar como estou me sentindo em menos de 10 segundos, para ter um histórico sem ter preguiça de preencher.*
*   **Critérios de Aceite:**
    *   A tela de check-in deve ter medidores visuais simples (cores ou emojis) para: Ansiedade, Foco, Energia, Qualidade do Sono e Humor.
    *   Não deve exigir texto obrigatório.

**História 3.2:** *Como usuário, quero marcar quais efeitos colaterais estou sentindo hoje, para contar ao meu médico depois.*
*   **Critérios de Aceite:**
    *   A tela deve listar efeitos comuns (Náusea, insônia, boca seca, palpitação, tontura, apatia).
    *   O usuário deve poder escolher a intensidade (Leve, Médio, Forte).

---

## 📱 3. Telas Necessárias no MVP

Para este MVP em Flutter, precisaremos desenhar apenas as seguintes telas (foco no minimalismo):

1. **Tela Inicial (Home / Hoje):** 
   * Mostra os remédios do dia. 
   * Se já tomou, fica "apagadinho" com um check verde. 
   * Avisos de estoque baixo no topo da tela.
2. **Tela de Cadastro/Edição de Remédio:**
   * Formulário limpo com campos de texto, botão de tirar foto, definição de horários e botão de marcar como "Estimulante".
3. **Tela de Check-in (Diário):**
   * A tela de 10 segundos. Mostra os 5 emojis de humor/foco e, logo abaixo, os botões de efeitos colaterais com as intensidades.
4. **Tela de Histórico Simples:**
   * Uma lista simples em formato de linha do tempo mostrando os dias passados, se tomou o remédio e quais foram os registros de humor (sem gráficos complexos ainda).
5. **Tela de Configurações:**
   * Botão para ativar/desativar notificações furarem o "Não Perturbe".
   * Aviso de privacidade (texto confirmando que os dados não saem do aparelho).

---

## 🚫 4. O que fica FORA do escopo (Para V2 e V3)

* **Backend e Login em Nuvem:** O app não terá banco de dados na nuvem. Será 100% offline.
* **Escalonamento de Contatos:** Enviar SMS ou aviso para um "contato de segurança".
* **Botão SOS (Crise):** Botão de emergência de pânico com registro de hora exata.
* **Gráficos Complexos e Correlações:** Telas analisando se o remédio fez efeito no humor ao longo do tempo.
* **Geração de PDF:** Exportação de relatório formatado para o psiquiatra.
* **Biometria/Face ID:** Trava de segurança para abrir o aplicativo.
* **Modo Cuidador:** Vinculação de contas de pais/filhos.
