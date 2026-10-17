# 📋 Pendências do MVP — MedLog

> Levantamento de funcionalidades pendentes comparando o PRD (`prd_mvp.md`) com o código atual.
> Atualizado em: 2026-10-17 — branch `feature/gerenciamento-doses` @ `3b61d9a`.

## ✅ O que já está implementado

- Cadastro/edição/exclusão de medicamentos (nome, dosagem, forma, horários, frequência, estoque, instruções).
- Tela **Hoje** com agenda de doses, silenciamento por dose, doses extras (SOS) e registro de tomada/pulada.
- Persistência SQLite com migrations (v3: `data_inicio` com backfill) e repositories.
- Filtro de doses por data de início/duração do tratamento (`Medicamento.estaAtivoNaData`).
- Tela de detalhes com swipe para excluir e desfazer.
- Temas light/dark (`core/theme`).

---

## 🔴 Épico 1 — Cadastro e Gestão de Medicamentos

### 1.1 — Fotos da caixa e do comprimido
- **Status:** campo `fotoUrl` existe no model (`Medicamento`), mas nada o preenche.
- **Falta:**
  - UI no cadastro para anexar até 2 fotos (caixa + comprimido), câmera ou galeria.
  - Service de armazenamento local (copiar arquivo para diretório do app e salvar o path).
  - Exibir a(s) foto(s) na tela de detalhes.
- **Dependência:** pacote `image_picker` (ou similar) — ainda não está no `pubspec.yaml`.

### 1.2 — Baixa automática de estoque
- **Status:** repository já tem `updateEstoque` (`medicamento_repository_sqflite.dart:102`), porém **nenhum chamador usa**.
- **Falta:**
  - Ao registrar dose como "Tomei", subtrair a dose consumida do `estoqueAtual` do medicamento (e tratar frações: gotas/ml).
  - Desfazer a baixa se o usuário desfizer o registro da dose.

### 1.3 — Alerta de estoque baixo
- **Falta:**
  - Banner na tela **Hoje**: *"Atenção: Restam apenas X comprimidos. Hora de comprar!"* quando `estoqueAtual <= estoqueMinimo`.
  - Considerar também `dataFim` do tratamento como gatilho de "repor".

---

## 🟠 Épico 2 — Alertas Gentis e Seguros

### 2.1 — Notificações locais com botões de ação
- **Status:** `flutter_local_notifications` está no `pubspec.yaml`, mas **não há nenhum código de notificação** (não existe `lib/core/services/`).
- **Falta:**
  - `NotificationService` em `lib/core/services/`: inicialização, permissões (Android 13+/iOS) e agendamento.
  - Agendar lembrete para cada horário de cada medicamento ativo (respeitando `estaAtivoNaData`).
  - Notificação com 3 ações: **"Tomei"**, **"Adiar 15 min"**, **"Pular"**.
  - Reprogramar lembretes ao criar/editar/excluir medicamento e ao reagendar/adiar/pular.
  - Linguagem gentil — sem tom de cobrança.
- **Extras necessários:** tratamento de `exactAlarm`/permissões no Android (SCHEDULE_EXACT_ALARM, battery optimization).

### 2.2 — Prevenção de dose dupla
- **Falta:**
  - Se o usuário tentar registrar "Tomei" para dose que já foi tomada no mesmo horário/turno, mostrar aviso em destaque (tela vermelha): *"Você já registrou esta dose hoje às HH:mm! Tem certeza?"*.
  - Exigir confirmação explícita antes de gravar o registro extra.
- **Ponto de encaixe:** fluxo de registro de dose em `doses_bloc.dart` / `doses_page.dart`.

### 2.3 — Alertas críticos (furar "Não Perturbe")
- **Falta:**
  - Opção de configuração "Alertas Críticos" (tocar mesmo em silencioso).
  - Pode depender da tela de Configurações (ver Telas) e de APIs nativas (canal de notificação com `IMPORTANCE_HIGH` / DND bypass no Android).

### 2.4 — Aviso de estimulante à noite
- **Falta:**
  - Flag "Este remédio é estimulante?" no cadastro (coluna no banco + model + etapa do formulário).
  - Ao marcar "Tomei" após horário de corte (ex: 17h), perguntar: *"Tomar este medicamento agora pode atrapalhar seu sono. Tem certeza?"*.

---

## 🟡 Épico 3 — Check-in (Diário Rápido)

- **Status:** `checkin_page.dart` é um **stub** (texto estático). Não existe model, tabela, repository nem bloc.
- **Falta:**
  - Migration nova (v4) com tabela de check-ins (data, notas) e efeitos colaterais.
  - **3.1 — Medidores visuais** (emojis/cores, < 10 segundos, sem texto obrigatório): Ansiedade, Foco, Energia, Qualidade do Sono, Humor.
  - **3.2 — Efeitos colaterais** com lista de comuns (náusea, insônia, boca seca, palpitação, tontura, apatia) e intensidade **Leve / Médio / Forte**.
  - Bloc + repository + testes.

---

## ⚪ Telas do MVP ainda não criadas

### 4. Tela de Histórico
- Linha do tempo simples dos dias passados: doses tomadas/puladas + registros de humor. Sem gráficos complexos.
- Depende do Check-in (Épico 3) para ter dados de humor.

### 5. Tela de Configurações
- Toggle "Alertas críticos fura o Não Perturbe" (2.3).
- Aviso de privacidade: texto confirmando que os dados não saem do aparelho.
- Adicionar aba no `main_layout.dart` (ou acesso via AppBar).

---

## 💡 Melhorias identificadas (fora do PRD)

- **Navegação de datas na tela Hoje** — o `DosesBloc` já recebe uma data, mas a UI só exibe hoje; adicionar setas/seletor para voltar/avançar dias.
- **README desatualizado** — menciona Riverpod, mas o projeto usa BLoC; arquitetura descrita difere da real (feature-first com bloc/repositories).

---

## 🚫 Fora do escopo (V2/V3 — confirmado no PRD)

Backend/nuvem, escalonamento de contatos, botão SOS, gráficos complexos/correlações, geração de PDF, biometria, modo cuidador.

---

## 🗺️ Ordem sugerida

1. **Notificações (2.1)** + **dose dupla (2.2)** — núcleo do produto: lembrete confiável e segurança.
2. **Baixa e alerta de estoque (1.2, 1.3)** — fecha o Épico 1.
3. **Check-in (Épico 3)** — desbloqueia o Histórico.
4. **Histórico + Configurações + estimulante/alertas críticos** — completa as telas do MVP.
