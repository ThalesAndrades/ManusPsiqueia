# Módulos do ManusPsiqueia

Esta pasta contém os módulos Swift Package Manager que compõem a arquitetura modular do ManusPsiqueia. A modularização traz diversos benefícios para o projeto, incluindo melhor organização, compilação mais rápida e reutilização de código.

## Estrutura dos Módulos

### 🎨 ManusPsiqueiaUI

Módulo responsável por todos os componentes de interface do usuário reutilizáveis.

**Características:**
- Componentes UI padronizados e reutilizáveis
- Sistema de temas configurável
- Animações e efeitos visuais
- Compatibilidade com SwiftUI

**Conteúdo:**
- `Components/` - Botões, campos de entrada, scrollviews avançados
- `Views/` - Views complexas como loading, particles, splash screen
- `Styles/` - Definições de estilo e tema
- `Extensions/` - Extensões úteis para SwiftUI

**Dependências:**
- Apenas SwiftUI (nativo)

### 🔧 ManusPsiqueiaServices

Módulo que encapsula todos os serviços e integrações externas.

**Características:**
- Serviços de rede e API
- Integração com Stripe para pagamentos
- Serviços de IA com OpenAI
- Gerenciamento de banco de dados com Supabase
- Serviços de segurança e criptografia

**Conteúdo:**
- `Network/` - Serviços de rede e comunicação HTTP
- `Payment/` - Integração com Stripe e processamento de pagamentos
- `AI/` - Serviços de inteligência artificial
- `Database/` - Operações de banco de dados
- `Security/` - Serviços de segurança e criptografia

**Dependências:**
- Stripe iOS SDK
- Supabase Swift SDK
- OpenAI Swift SDK
- SwiftKeychainWrapper

## Benefícios da Modularização

### 🚀 Performance de Compilação

A modularização permite que o Xcode compile apenas os módulos que foram modificados, resultando em builds incrementais muito mais rápidos. Isso é especialmente importante durante o desenvolvimento ativo.

### 🔄 Reutilização de Código

Os módulos podem ser facilmente reutilizados em outros projetos da AiLun Tecnologia, como o PsiqueGarden ou futuras aplicações da plataforma.

### 🧪 Testabilidade

Cada módulo pode ser testado independentemente, facilitando a criação de testes unitários focados e a manutenção da qualidade do código.

### 📦 Gerenciamento de Dependências

As dependências ficam isoladas por módulo, evitando conflitos e facilitando atualizações. Por exemplo, apenas o módulo `ManusPsiqueiaServices` depende do Stripe SDK.

### 👥 Desenvolvimento em Equipe

Diferentes desenvolvedores podem trabalhar em módulos diferentes sem conflitos, melhorando a produtividade da equipe.

## Como Usar os Módulos

### Importação

```swift
import ManusPsiqueiaUI
import ManusPsiqueiaServices
```

### Configuração do Tema (UI)

```swift
// Configurar tema personalizado
let customTheme = Theme(
    colors: Theme.Colors(
        primary: .blue,
        secondary: .gray,
        // ... outras cores
    )
)

ManusPsiqueiaUI.configure(with: customTheme)

// Aplicar tema em uma view
ContentView()
    .manusPsiqueiaTheme(customTheme)
```

### Configuração dos Serviços

```swift
// Configurar serviços
let serviceConfig = ServiceConfiguration(
    network: .init(baseURL: "https://api.manuspsiqueia.com"),
    payment: .init(stripePublishableKey: "pk_live_..."),
    ai: .init(openAIAPIKey: "sk-..."),
    database: .init(supabaseURL: "https://...", supabaseAnonKey: "..."),
    security: .init(securityLevel: .high)
)

ManusPsiqueiaServices.configure(with: serviceConfig)

// Usar serviços
let networkService = ManusPsiqueiaServices.makeNetworkService()
let paymentService = ManusPsiqueiaServices.makePaymentService()
```

## Desenvolvimento dos Módulos

### Adicionando Novos Componentes

Para adicionar um novo componente UI:

1. Crie o arquivo Swift em `ManusPsiqueiaUI/Sources/ManusPsiqueiaUI/Components/`
2. Implemente o componente seguindo o padrão do tema
3. Adicione testes em `ManusPsiqueiaUI/Tests/`
4. Documente o componente

### Adicionando Novos Serviços

Para adicionar um novo serviço:

1. Defina o protocolo do serviço em `ManusPsiqueiaServices.swift`
2. Implemente o serviço em uma pasta apropriada
3. Adicione o factory method no `ManusPsiqueiaServices`
4. Crie testes abrangentes

## Roadmap

### Próximos Módulos Planejados

- **ManusPsiqueiaCore** - Modelos de dados e lógica de negócio central
- **ManusPsiqueiaAnalytics** - Serviços de analytics e métricas
- **ManusPsiqueiaNotifications** - Gerenciamento de notificações push
- **ManusPsiqueiaOffline** - Funcionalidades offline e sincronização

### Melhorias Futuras

- Documentação automática com DocC
- Integração com Swift Package Index
- Versionamento semântico independente por módulo
- Distribuição via Swift Package Registry

## Contribuindo

Ao contribuir com os módulos, siga estas diretrizes:

1. **Mantenha a compatibilidade** - Mudanças breaking devem ser evitadas
2. **Documente as APIs públicas** - Use comentários de documentação Swift
3. **Escreva testes** - Mantenha alta cobertura de testes
4. **Siga o padrão** - Use as convenções estabelecidas nos módulos existentes

## Suporte

Para dúvidas sobre a arquitetura modular ou problemas específicos dos módulos, consulte a documentação técnica ou entre em contato com a equipe de desenvolvimento.
