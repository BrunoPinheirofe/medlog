# 💊 MedLog

**MedLog** é um aplicativo de lembrete de medicação e check-in de saúde mental. Ele foi projetado para ser **100% offline**, empático (sem sistema de "ofensivas" punitivas ou gatilhos de culpa) e focado em evitar erros graves, como esquecimentos ou doses duplas.

---

## ✨ Principais Funcionalidades

- **⏰ Lembretes Confiáveis:** Notificações locais que ajudam o usuário a tomar a medicação na hora certa.
- **🛡️ Prevenção de Dose Dupla:** Avisos e confirmações de segurança caso o usuário tente registrar o mesmo medicamento em um curto espaço de tempo.
- **🧠 Check-in de Saúde Mental:** Diário rápido e registro de efeitos colaterais para acompanhamento diário.
- **📴 100% Offline e Privado:** Todos os dados (remédios, horários, diários) ficam salvos **apenas** no seu dispositivo. Nenhuma informação de saúde vai para a nuvem.
- **🎨 Interface Limpa e Responsiva:** Design baseado em Material 3, com suporte a múltiplos temas (como Dracula e Tokyo Night) e interface totalmente adaptável a qualquer tamanho de tela.

---

## 🛠️ Stack Tecnológica

- **Framework:** [Flutter](https://flutter.dev/)
- **Gerenciamento de Estado:** [`flutter_riverpod`](https://riverpod.dev/)
- **Banco de Dados Local:** [`sqflite`](https://pub.dev/packages/sqflite) (SQLite)
- **Notificações:** [`flutter_local_notifications`](https://pub.dev/packages/flutter_local_notifications)
- **Temas:** [`flex_color_scheme`](https://pub.dev/packages/flex_color_scheme)

---

## 🏛️ Arquitetura do Projeto

O aplicativo segue o padrão **MVVM Modular (Feature-First)**, separando o código de acordo com a funcionalidade e dividindo as responsabilidades de forma clara:

1. **View (Apresentação):** Widgets e Telas. Não contém lógica de negócios.
2. **ViewModel (Gerenciamento de Estado):** Utiliza Riverpod (`Notifier`, `AsyncNotifier`) para processar a lógica e conectar a View aos Repositories e Services.
3. **Repository (Acesso a Dados):** Camada de acesso ao banco de dados SQLite (`sqflite`). Realiza as operações de CRUD.
4. **Service:** Lida com recursos nativos do dispositivo (ex: Notificações, Câmera).

### Estrutura de Pastas

```text
lib/
├── core/                       # Código compartilhado por todo o app
│   ├── database/               # Configuração e inicialização do SQLite
│   ├── services/               # Serviços do dispositivo (ex: notificações)
│   ├── theme/                  # Gerenciamento de cores e temas
│   └── utils/                  # Formatadores e helpers gerais
└── features/                   # Módulos do app baseados em funcionalidades
    ├── checkin/                # Diário rápido e acompanhamento
    ├── doses/                  # Registros de tomada dos medicamentos
    └── medicamentos/           # Gerenciamento (CRUD) de medicamentos
```

---

## 🚀 Como Rodar o Projeto

### Pré-requisitos
- [Flutter SDK](https://docs.flutter.dev/get-started/install) instalado (versão mais recente recomendada).
- Um dispositivo físico ou emulador (Android/iOS) configurado.

### Passos

1. Clone o repositório:
   ```bash
   git clone <URL_DO_SEU_REPOSITORIO>
   cd medlog
   ```

2. Instale as dependências:
   ```bash
   flutter pub get
   ```

3. Execute o aplicativo:
   ```bash
   flutter run
   ```

---

*Desenvolvido com Flutter 💙*
