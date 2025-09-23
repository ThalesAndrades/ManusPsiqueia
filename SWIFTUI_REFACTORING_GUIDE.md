# 🛠️ Guia de Refatoração para Otimização da Estrutura de Arquivos SwiftUI no ManusPsiqueia

**Status:** ✅ **GUIA DE REFATURAÇÃO CRIADO**

Este guia detalha um plano de refatoração para otimizar a estrutura de arquivos SwiftUI no projeto ManusPsiqueia. Uma estrutura de projeto bem organizada é fundamental para a manutenibilidade, escalabilidade e colaboração em equipes, especialmente em projetos complexos como o ManusPsiqueia.

## 🎯 **Princípios de Organização**

Antes de mergulharmos na estrutura, é importante entender os princípios que guiam esta refatoração:

1.  **Modularidade:** Dividir o projeto em unidades independentes e reutilizáveis (módulos ou grupos lógicos).
2.  **Separação de Responsabilidades (SoC):** Cada arquivo ou grupo deve ter uma única responsabilidade bem definida.
3.  **Clareza e Consistência:** Nomes de arquivos e diretórios devem ser intuitivos e seguir um padrão consistente.
4.  **Escalabilidade:** A estrutura deve suportar o crescimento do projeto sem se tornar caótica.
5.  **Facilidade de Navegação:** Desenvolvedores devem encontrar arquivos rapidamente.

## 📂 **Estrutura de Diretórios Recomendada**

A estrutura proposta visa organizar o código por funcionalidade e tipo, facilitando a localização e o gerenciamento.

```
ManusPsiqueia/
├── .github/                     # Configurações de GitHub Actions, templates de issues/PRs
├── ci_scripts/                  # Scripts para Xcode Cloud (ci_post_clone, ci_pre_xcodebuild, etc.)
├── Configuration/               # Arquivos .xcconfig para diferentes ambientes
├── docs/                        # Toda a documentação do projeto
│   ├── development/
│   ├── features/
│   ├── integrations/
│   ├── security/
│   ├── setup/
│   └── technical/
├── Modules/                     # Swift Packages locais (ManusPsiqueiaUI, ManusPsiqueiaServices)
│   ├── ManusPsiqueiaUI/
│   │   ├── Sources/
│   │   │   └── ManusPsiqueiaUI/
│   │   │       ├── Components/  # Componentes UI reutilizáveis (botões, cards, etc.)
│   │   │       ├── Extensions/  # Extensões de View, Color, Font, etc.
│   │   │       └── Styles/      # ViewModifiers para estilos globais
│   │   └── Package.swift
│   └── ManusPsiqueiaServices/
│       ├── Sources/
│       │   └── ManusPsiqueiaServices/
│       │       ├── API/
│       │       ├── Managers/
│       │       └── Models/
│       └── Package.swift
├── ManusPsiqueia/               # Target principal do aplicativo iOS
│   ├── App/                     # Arquivo principal do App (ManusPsiqueiaApp.swift)
│   ├── Assets.xcassets/         # Imagens, cores, ícones
│   ├── Preview Content/         # Assets para previews do Xcode
│   ├── Resources/               # Outros recursos (Info.plist, arquivos de dados, etc.)
│   ├── Features/                # Organização por funcionalidade (aqui é o foco da refatoração)
│   │   ├── Authentication/      # Telas de Login, Cadastro, Recuperação de Senha
│   │   │   ├── Views/
│   │   │   ├── ViewModels/
│   │   │   └── Models/
│   │   ├── Journal/             # Telas do Diário, Criação, Edição, Visualização
│   │   │   ├── Views/
│   │   │   ├── ViewModels/
│   │   │   ├── Models/
│   │   │   └── Services/        # Serviços específicos do diário
│   │   ├── Insights/            # Telas de Insights, Gráficos, Análises
│   │   │   ├── Views/
│   │   │   ├── ViewModels/
│   │   │   └── Models/
│   │   ├── Goals/               # Telas de Metas, Criação, Acompanhamento
│   │   │   ├── Views/
│   │   │   ├── ViewModels/
│   │   │   └── Models/
│   │   └── Profile/             # Telas de Perfil, Configurações, Assinatura
│   │       ├── Views/
│   │       ├── ViewModels/
│   │       └── Models/
│   ├── Core/                    # Componentes e lógicas globais do app principal
│   │   ├── Managers/            # ConfigurationManager, NetworkManager, etc.
│   │   ├── Services/            # APIService, PushNotificationService, etc.
│   │   ├── Models/              # Modelos de dados globais (User, Session, etc.)
│   │   ├── Utils/               # Extensões, Helpers, Constantes
│   │   └── Security/            # Lógica de segurança específica do app
│   └── Supporting Files/        # Arquivos de suporte (Info.plist, Entitlements, etc.)
├── ManusPsiqueiaTests/          # Testes unitários para o app principal
│   ├── Features/
│   │   ├── AuthenticationTests/
│   │   └── JournalTests/
│   └── CoreTests/
├── scripts/                     # Scripts de automação (setup, deploy, health check)
└── .swiftlint.yml               # Configurações do SwiftLint
```

## 📋 **Passos da Refatoração**

### **Fase 1: Preparação**

1.  **Backup:** Faça um backup completo do seu projeto ou certifique-se de que todas as mudanças estão commitadas e enviadas para o repositório remoto.
2.  **SwiftLint:** Certifique-se de que o SwiftLint está configurado e rodando. Ele ajudará a manter a consistência durante a refatoração.
3.  **Testes:** Garanta que todos os testes existentes estão passando. Isso é crucial para detectar regressões durante a refatoração.

### **Fase 2: Reorganização por Funcionalidade (`Features/`)**

Esta é a parte mais significativa da refatoração. O objetivo é mover todas as `Views`, `ViewModels`, `Models` e `Services` relacionados a uma funcionalidade específica para seu próprio diretório.

1.  **Crie o diretório `Features/`** dentro de `ManusPsiqueia/`.
2.  **Para cada funcionalidade principal (ex: Autenticação, Diário, Insights, Metas, Perfil):**
    *   Crie um subdiretório correspondente dentro de `Features/` (ex: `Features/Authentication/`).
    *   Dentro de cada subdiretório de funcionalidade, crie os grupos `Views/`, `ViewModels/`, `Models/` e, se necessário, `Services/`.
    *   **Mova os arquivos:** Arraste e solte os arquivos `.swift` relevantes do seu projeto para esses novos grupos no Xcode. O Xcode geralmente lida com as referências de arquivo automaticamente, mas verifique se não há erros.
    *   **Ajuste os `imports`:** Se você moveu arquivos para um módulo Swift Package (como `ManusPsiqueiaUI`), certifique-se de que os `import`s estão corretos (ex: `import ManusPsiqueiaUI`).

### **Fase 3: Refinamento dos Componentes Globais (`Core/`)**

O diretório `Core/` deve conter lógicas e componentes que são verdadeiramente globais e compartilhados por múltiplas funcionalidades.

1.  **Revise `Managers/`, `Services/`, `Models/`, `Utils/` e `Security/`:** Certifique-se de que apenas arquivos que são usados por *múltiplas* funcionalidades ou que representam a infraestrutura central do aplicativo residem aqui.
2.  **Mova para `Features/`:** Se um Manager, Service ou Model é usado *apenas* por uma funcionalidade específica, mova-o para o diretório `Services/` ou `Models/` dentro daquela funcionalidade em `Features/`.
3.  **Mova para `Modules/`:** Se um componente UI é genérico e reutilizável em *qualquer* projeto iOS, considere movê-lo para `Modules/ManusPsiqueiaUI/Components/`. Se um serviço é genérico e pode ser usado em *qualquer* projeto, mova-o para `Modules/ManusPsiqueiaServices/Services/`.

### **Fase 4: Otimização dos Módulos Swift Package (`Modules/`)**

Os módulos `ManusPsiqueiaUI` e `ManusPsiqueiaServices` já foram criados. Agora é a hora de popular e refinar.

1.  **`ManusPsiqueiaUI`:**
    *   Mova todos os `ViewModifier`s de estilo (como `PrimaryButtonStyleModifier`), `Views` genéricas (como `MaterialCardView` se for genérica o suficiente) e extensões de UI (`Color`, `Font`, `View`) para `Modules/ManusPsiqueiaUI/Sources/ManusPsiqueiaUI/`.
    *   Certifique-se de que o `Package.swift` do `ManusPsiqueiaUI` exporta os símbolos corretos (`.product(name: 
