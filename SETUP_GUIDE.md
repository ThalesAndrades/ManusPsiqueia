# 🛠️ Guia de Configuração - ManusPsiqueia

Este guia fornece instruções detalhadas para configurar o ambiente de desenvolvimento do ManusPsiqueia.

## 📋 Pré-requisitos

### **Ferramentas Necessárias**
- **Xcode 15.0+** - IDE principal para desenvolvimento iOS
- **iOS 16.0+ Simulator** - Para testes em simulador
- **Apple Developer Account** - Para certificados e provisioning profiles
- **Git** - Controle de versão
- **CocoaPods ou Swift Package Manager** - Gerenciamento de dependências

### **Contas de Serviços**
- **Stripe Account** - Para processamento de pagamentos
- **OpenAI Account** - Para funcionalidades de IA
- **Apple Developer Program** - Para distribuição na App Store

## 🚀 Configuração Inicial

### **1. Clone do Repositório**
```bash
# Clone o repositório
git clone https://github.com/ThalesAndrades/ManusPsiqueia.git

# Navegue para o diretório
cd ManusPsiqueia

# Verifique as branches disponíveis
git branch -a
```

### **2. Configuração do Xcode**
```bash
# Abra o projeto no Xcode
open ManusPsiqueia.xcodeproj

# Ou use o comando xed se estiver no diretório
xed .
```

### **3. Configuração de Certificados**
1. **Apple Developer Account**:
   - Acesse [developer.apple.com](https://developer.apple.com)
   - Crie/configure App ID: `com.ailun.manuspsiqueia`
   - Gere certificados de desenvolvimento e distribuição
   - Crie provisioning profiles

2. **Xcode Signing**:
   ```
   Project Settings → Signing & Capabilities
   ├── Team: Selecione sua equipe de desenvolvimento
   ├── Bundle Identifier: com.ailun.manuspsiqueia
   └── Provisioning Profile: Automatic ou Manual
   ```

## 💳 Configuração do Stripe

### **1. Criar Conta Stripe**
1. Acesse [dashboard.stripe.com](https://dashboard.stripe.com)
2. Crie uma conta ou faça login
3. Ative o modo de teste para desenvolvimento

### **2. Configurar Stripe Connect**
```bash
# No dashboard Stripe
1. Vá para "Connect" → "Settings"
2. Ative "Express accounts"
3. Configure webhook endpoints
4. Obtenha as chaves de API
```

### **3. Configurar Chaves no Projeto**
```swift
// Em StripeManager.swift
private struct StripeConfig {
    static let publishableKey = "pk_test_YOUR_PUBLISHABLE_KEY_HERE"
    static let secretKey = "sk_test_YOUR_SECRET_KEY_HERE"
    static let connectClientId = "ca_YOUR_CONNECT_CLIENT_ID_HERE"
}
```

### **4. Webhooks Configuration**
```json
{
  "url": "https://your-backend.com/stripe/webhooks",
  "events": [
    "payment_intent.succeeded",
    "payment_intent.payment_failed",
    "customer.subscription.created",
    "customer.subscription.updated",
    "customer.subscription.deleted",
    "account.updated",
    "transfer.created"
  ]
}
```

## 🤖 Configuração da OpenAI

### **1. Obter API Key**
1. Acesse [platform.openai.com](https://platform.openai.com)
2. Crie uma conta ou faça login
3. Vá para "API Keys" e gere uma nova chave
4. Configure billing e limits

### **2. Configurar no Projeto**
```swift
// Em AIManager.swift
private struct OpenAIConfig {
    static let apiKey = "sk-YOUR_OPENAI_API_KEY_HERE"
    static let organization = "org-YOUR_ORGANIZATION_ID" // Opcional
    static let model = "gpt-4" // ou "gpt-3.5-turbo"
}
```

### **3. Configurar Prompts**
```swift
// Exemplos de prompts para diferentes funcionalidades
struct AIPrompts {
    static let sessionAnalysis = """
    Analise as seguintes notas de sessão terapêutica e forneça:
    1. Resumo dos principais tópicos discutidos
    2. Estado emocional do paciente
    3. Progresso observado
    4. Recomendações para próximas sessões
    
    Notas: {session_notes}
    """
    
    static let treatmentPlan = """
    Com base no histórico do paciente, crie um plano de tratamento que inclua:
    1. Objetivos terapêuticos específicos
    2. Intervenções recomendadas
    3. Timeline estimado
    4. Exercícios práticos
    
    Histórico: {patient_history}
    """
}
```

## 📱 Configuração de Push Notifications

### **1. Apple Push Notifications (APNs)**
1. **Certificado APNs**:
   ```
   Apple Developer Portal → Certificates, Identifiers & Profiles
   ├── Certificates → Create new
   ├── Type: Apple Push Notification service SSL
   └── App ID: com.ailun.manuspsiqueia
   ```

2. **Configuração no Xcode**:
   ```
   Project → Capabilities
   ├── Push Notifications: ON
   └── Background Modes: Background processing, Remote notifications
   ```

### **2. Configuração no Código**
```swift
// Em NotificationManager.swift
class NotificationManager: NSObject, ObservableObject {
    func requestPermission() async {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            if granted {
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        } catch {
            print("Erro ao solicitar permissão: \(error)")
        }
    }
}
```

## 🗄️ Configuração de Banco de Dados

### **1. Core Data Setup**
```swift
// Em PersistenceController.swift
import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ManusPsiqueia")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Core Data error: \(error), \(error.userInfo)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
```

### **2. CloudKit Integration**
```swift
// Configuração para sincronização com CloudKit
container.persistentStoreDescriptions.forEach { storeDescription in
    storeDescription.setOption(true as NSNumber, 
                              forKey: NSPersistentHistoryTrackingKey)
    storeDescription.setOption(true as NSNumber, 
                              forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
}
```

## 🔧 Configuração de Dependências

### **1. Swift Package Manager**
```swift
// Em Package.swift ou Xcode → File → Add Package Dependencies
dependencies: [
    .package(url: "https://github.com/stripe/stripe-ios", from: "23.0.0"),
    .package(url: "https://github.com/MacPaw/OpenAI", from: "0.2.0"),
    .package(url: "https://github.com/kishikawakatsumi/KeychainAccess", from: "4.2.2"),
    .package(url: "https://github.com/Alamofire/Alamofire", from: "5.8.0")
]
```

### **2. Configuração de Build Settings**
```
Build Settings:
├── Swift Language Version: Swift 5.9
├── iOS Deployment Target: 16.0
├── Enable Bitcode: No
├── Swift Compilation Mode: Whole Module Optimization
└── Optimization Level: Optimize for Speed [-O]
```

## 🧪 Configuração de Testes

### **1. Estrutura de Testes**
```bash
# Criar grupos de teste no Xcode
Tests/
├── UnitTests/
├── IntegrationTests/
└── UITests/
```

### **2. Configuração de Mock Data**
```swift
// Em MockData.swift
extension User {
    static let mockPsychologist = User(
        id: UUID(),
        email: "psicologo@teste.com",
        name: "Dr. João Silva",
        userType: .psychologist,
        subscriptionStatus: .active
    )
    
    static let mockPatient = User(
        id: UUID(),
        email: "paciente@teste.com",
        name: "Maria Santos",
        userType: .patient,
        linkedPsychologistId: mockPsychologist.id
    )
}
```

### **3. Configuração de Testes de UI**
```swift
// Em UITestBase.swift
class UITestBase: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }
}
```

## 🔒 Configuração de Segurança

### **1. Keychain Configuration**
```swift
// Em KeychainManager.swift
import KeychainAccess

class KeychainManager {
    private let keychain = Keychain(service: "com.ailun.manuspsiqueia")
        .accessibility(.whenUnlockedThisDeviceOnly)
    
    func store(key: String, value: String) throws {
        try keychain.set(value, key: key)
    }
    
    func retrieve(key: String) throws -> String? {
        return try keychain.get(key)
    }
}
```

### **2. Network Security**
```swift
// Em NetworkManager.swift
class NetworkManager {
    private let session: URLSession
    
    init() {
        let configuration = URLSessionConfiguration.default
        configuration.tlsMinimumSupportedProtocolVersion = .TLSv12
        configuration.tlsMaximumSupportedProtocolVersion = .TLSv13
        self.session = URLSession(configuration: configuration)
    }
}
```

## 📊 Configuração de Analytics

### **1. Firebase Analytics (Opcional)**
```swift
// Se usar Firebase
import FirebaseAnalytics

class AnalyticsManager {
    func trackEvent(name: String, parameters: [String: Any]?) {
        Analytics.logEvent(name, parameters: parameters)
    }
}
```

### **2. Custom Analytics**
```swift
// Analytics customizado
class CustomAnalytics {
    func trackUserAction(action: String, user: User) {
        let event = AnalyticsEvent(
            action: action,
            userId: user.id,
            timestamp: Date(),
            metadata: ["user_type": user.userType.rawValue]
        )
        // Enviar para seu backend
    }
}
```

## 🚀 Build e Deploy

### **1. Configuração de Schemes**
```
Schemes:
├── ManusPsiqueia-Debug
│   ├── Build Configuration: Debug
│   └── Preprocessor Macros: DEBUG=1
├── ManusPsiqueia-Release
│   ├── Build Configuration: Release
│   └── Optimization: Optimize for Speed
└── ManusPsiqueia-TestFlight
    ├── Build Configuration: Release
    └── Code Signing: Distribution Certificate
```

### **2. Archive e Upload**
```bash
# Via Xcode
Product → Archive → Distribute App → App Store Connect

# Via linha de comando
xcodebuild archive -project ManusPsiqueia.xcodeproj \
                  -scheme ManusPsiqueia \
                  -archivePath build/ManusPsiqueia.xcarchive

xcodebuild -exportArchive -archivePath build/ManusPsiqueia.xcarchive \
                         -exportPath build/ \
                         -exportOptionsPlist ExportOptions.plist
```

## 🔍 Debugging e Troubleshooting

### **1. Common Issues**
```swift
// Problema: Stripe não inicializa
// Solução: Verificar se as chaves estão corretas
#if DEBUG
print("Stripe Key: \(StripeConfig.publishableKey)")
#endif

// Problema: Core Data crash
// Solução: Verificar modelo de dados e migrações
container.loadPersistentStores { _, error in
    if let error = error {
        print("Core Data error: \(error)")
        // Implementar fallback ou migração
    }
}
```

### **2. Logging Configuration**
```swift
// Em Logger.swift
import os.log

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!
    
    static let authentication = Logger(subsystem: subsystem, category: "authentication")
    static let payments = Logger(subsystem: subsystem, category: "payments")
    static let ui = Logger(subsystem: subsystem, category: "ui")
}
```

## 📞 Suporte

### **Problemas Comuns**
- **Build Errors**: Verificar certificados e provisioning profiles
- **Stripe Integration**: Confirmar chaves de API e webhook configuration
- **OpenAI Errors**: Verificar API key e billing status
- **Push Notifications**: Confirmar certificados APNs

### **Recursos de Ajuda**
- **Documentação Stripe**: [stripe.com/docs](https://stripe.com/docs)
- **OpenAI Documentation**: [platform.openai.com/docs](https://platform.openai.com/docs)
- **Apple Developer**: [developer.apple.com](https://developer.apple.com)
- **Swift Documentation**: [swift.org/documentation](https://swift.org/documentation)

### **Contato**
- **Email**: contato@ailun.com.br
- **GitHub Issues**: Para bugs e features
- **Documentação**: Wiki do repositório

---

**Guia mantido pela [AiLun Tecnologia](mailto:contato@ailun.com.br)**

*Última atualização: Janeiro 2024*
