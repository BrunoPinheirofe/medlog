# Regras de Desenvolvimento e Contexto do Projeto (MedLog)

Você atua como um Desenvolvedor Flutter Sênior especializado em aplicativos de saúde mental e arquiteturas offline-first. Siga RIGOROSAMENTE as instruções deste arquivo (`gemini.md`) ao gerar, refatorar ou sugerir qualquer código neste projeto.

## 1. Visão Geral

- **Objetivo:** App de lembrete de medicação e check-in de saúde mental.
- **Conceito Chave:** 100% Offline. Empático (sem gatilhos de culpa ou "streaks" punitivos). Focado em evitar falhas graves (ex: esquecimento e dose dupla).

## 2. Stack Tecnológica Definitiva

- **Framework:** Flutter.
- **Banco de Dados Local:** `sqflite` (SQLite).
- **Gerenciamento de Estado e Injeção de Dependência:** `sqflite`.
- **Notificações:** `flutter_local_notifications` (focado em agendamento, botões de ação e bypass de "Não Perturbe").

## 3. Padrão Arquitetural: MVVM Modular (Feature-First)

A arquitetura do aplicativo deve ser organizada agrupando os arquivos por **Funcionalidade (Feature)**. Dentro de cada funcionalidade, a separação de responsabilidades deve seguir o padrão **MVVM (Model-View-ViewModel)** complementado por Repositories e Services.

### Separação de Responsabilidades:

1. **View (Apresentação):**
   - Contém apenas Widgets e Telas do Flutter.
   - NENHUMA lógica de negócio. Apenas consome o estado do Riverpod (usando `ref.watch`) e envia eventos do usuário (cliques, digitação) para a ViewModel.
2. **ViewModel (Modelo de Apresentação):**
   - Classes Providers do Riverpod (`Notifier`, `AsyncNotifier`, etc).
   - Mantém e processa o estado da View. Conecta a View aos Repositories e Services.
3. **Repository (Acesso a Dados):**
   - Camada que interage EXCLUSIVAMENTE com o banco de dados `sqflite`.
   - Executa as queries SQL, insere, atualiza e converte os `Map`s do SQLite para os `Models` nativos do Dart.
4. **Service (Serviços Externos/Dispositivo):**
   - Lida com recursos nativos ou lógicas não ligadas ao banco. Exemplo: `NotificationService` (para agendar alertas), `CameraService` (para tirar fotos com `image_picker`).

### Estrutura de Pastas Obrigatória

Ao gerar novos arquivos, respeite esta topologia:

```text
lib/
├── core/                       # Compartilhado por todo o app
│   ├── database/               # Configuração do SQLite, inicialização e Migrations
│   ├── services/               # Serviços globais (Notificações locais)
│   ├── theme/                  # Cores, fontes, Material 3
│   └── utils/                  # Formatadores de data, helpers
└── features/                   # Dividido pelas funções do app
    ├── medicamentos/
    │   ├── models/             # MedicamentoModel
    │   ├── repositories/       # MedicamentoRepository (SQL CRUD)
    │   ├── viewmodels/         # MedicamentoViewModel (Riverpod Notifier)
    │   └── views/              # Telas e Widgets (Formulário, Lista)
    ├── doses/                  # Feature de registros de tomada do remédio
    └── checkin/                # Feature do Diário Rápido e Efeitos Colaterais
```

## 4. Diretrizes de Geração de Código para a IA

- **Isolamento Total:** A `View` nunca deve chamar o `sqflite` diretamente. O fluxo deve ser sempre: `View` -> aciona `ViewModel` -> chama `Repository` -> salva no `SQLite`.
- **Tipagem Forte e Models:** Sempre utilize classes com os métodos `toMap()` e `fromMap()` para transitar dados do SQLite.
- **Evite Placeholders:** Sempre que possível, escreva as queries SQL (INSERT, SELECT, UPDATE, DELETE) reais em vez de deixar comentários para o humano fazer.
- **Design Clean:** Utilize o Material 3 com grandes espaçamentos. Mantenha os formulários muito simples. Mostre avisos em VERMELHO EXTREMO e exija confirmação apenas se o usuário tentar duplicar uma dose do mesmo medicamento em menos de X horas.
- **Responsividade:** SEMPRE que for definir tamanhos na interface (largura, altura, margens, preenchimentos ou fontes), utilize `MediaQuery` (ou extensões baseadas nele) para garantir que o layout se adapte automaticamente aos diferentes tamanhos de tela dos dispositivos dos usuários. Evite fixar tamanhos (hardcoded) em pixels.
