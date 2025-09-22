# Guia Prático de Implementação de Módulos

**Data:** 22 de setembro de 2025  
**Autor:** Manus AI  
**Projeto:** ManusPsiqueia

## 1. Introdução

Este guia fornece instruções práticas para trabalhar com a arquitetura modular do ManusPsiqueia. Você aprenderá como usar os módulos existentes, criar novos módulos e manter a integridade da arquitetura.

## 2. Usando Módulos Existentes

### ManusPsiqueiaUI

O módulo de UI fornece componentes reutilizáveis e um sistema de temas.

#### Importação e Configuração

```swift
import SwiftUI
import ManusPsiqueiaUI

@main
struct ManusPsiqueiaApp: App {
    
    init() {
        // Configurar tema personalizado
        let customTheme = Theme(
            colors: Theme.Colors(
                primary: Color.blue,
                secondary: Color.gray,
                accent: Color.orange,
                background: Color(UIColor.systemBackground),
                surface: Color(UIColor.secondarySystemBackground),
                error: Color.red,
                warning: Color.yellow,
                success: Color.green,
                text: Theme.Colors.TextColors(
                    primary: Color(UIColor.label),
                    secondary: Color(UIColor.secondaryLabel),
                    disabled: Color(UIColor.tertiaryLabel),
                    onPrimary: Color.white,
                    onSecondary: Color.white
                )
            )
        )
        
        ManusPsiqueiaUI.configure(with: customTheme)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .manusPsiqueiaTheme() // Aplicar tema
        }
    }
}
```

#### Usando Componentes

```swift
import SwiftUI
import ManusPsiqueiaUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @Environment(\.theme) var theme
    
    var body: some View {
        VStack(spacing: theme.spacing.md) {
            // Usar componentes do módulo UI
            Text("Login")
                .font(theme.typography.title1)
                .foregroundColor(theme.colors.text.primary)
            
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            SecureField("Senha", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button("Entrar") {
                // Ação de login
            }
            .buttonStyle(.borderedProminent)
            .tint(theme.colors.primary)
        }
        .padding(theme.spacing.lg)
    }
}
```

### ManusPsiqueiaServices

O módulo de serviços encapsula todas as integrações externas.

#### Configuração

```swift
import ManusPsiqueiaServices

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Configurar serviços
        let serviceConfig = ServiceConfiguration(
            network: ServiceConfiguration.NetworkConfiguration(
                baseURL: "https://api.manuspsiqueia.com/v1",
                timeout: 30.0,
                retryCount: 3,
                enableLogging: true
            ),
            payment: ServiceConfiguration.PaymentConfiguration(
                stripePublishableKey: ConfigurationManager.shared.stripePublishableKey,
                environment: .development
            ),
            ai: ServiceConfiguration.AIConfiguration(
                openAIAPIKey: ConfigurationManager.shared.openAIAPIKey,
                model: "gpt-4",
                maxTokens: 1000,
                temperature: 0.7
            ),
            database: ServiceConfiguration.DatabaseConfiguration(
                supabaseURL: ConfigurationManager.shared.supabaseURL,
                supabaseAnonKey: ConfigurationManager.shared.supabaseAnonKey,
                enableRealtime: true
            ),
            security: ServiceConfiguration.SecurityConfiguration(
                enableCertificatePinning: true,
                enableEncryption: true,
                securityLevel: .high
            )
        )
        
        ManusPsiqueiaServices.configure(with: serviceConfig)
        
        return true
    }
}
```

#### Usando Serviços

```swift
import Combine
import ManusPsiqueiaServices

class PaymentViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var paymentResult: PaymentResult?
    @Published var errorMessage: String?
    
    private let paymentService: PaymentServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(paymentService: PaymentServiceProtocol = ManusPsiqueiaServices.makePaymentService()) {
        self.paymentService = paymentService
    }
    
    func createPayment(amount: Int, currency: String = "BRL") {
        isLoading = true
        
        paymentService.createPaymentIntent(amount: amount, currency: currency)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] paymentIntent in
                    // Processar payment intent
                    print("Payment Intent criado: \(paymentIntent.id)")
                }
            )
            .store(in: &cancellables)
    }
}
```

## 3. Criando Novos Módulos

### Passo 1: Estrutura Básica

Para criar um novo módulo (exemplo: `ManusPsiqueiaCore`):

```bash
# Criar estrutura de diretórios
mkdir -p Modules/ManusPsiqueiaCore/Sources/ManusPsiqueiaCore
mkdir -p Modules/ManusPsiqueiaCore/Tests/ManusPsiqueiaCore
```

### Passo 2: Package.swift

Crie o arquivo `Modules/ManusPsiqueiaCore/Package.swift`:

```swift
// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ManusPsiqueiaCore",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "ManusPsiqueiaCore",
            targets: ["ManusPsiqueiaCore"]
        ),
    ],
    dependencies: [
        // Adicionar dependências se necessário
        .package(path: "../ManusPsiqueiaServices")
    ],
    targets: [
        .target(
            name: "ManusPsiqueiaCore",
            dependencies: [
                "ManusPsiqueiaServices"
            ],
            path: "Sources/ManusPsiqueiaCore"
        ),
        .testTarget(
            name: "ManusPsiqueiaCore",
            dependencies: ["ManusPsiqueiaCore"],
            path: "Tests/ManusPsiqueiaCore"
        ),
    ]
)
```

### Passo 3: Arquivo Principal

Crie `Modules/ManusPsiqueiaCore/Sources/ManusPsiqueiaCore/ManusPsiqueiaCore.swift`:

```swift
//
//  ManusPsiqueiaCore.swift
//  ManusPsiqueiaCore
//
//  Módulo central com modelos e lógica de negócio
//

import Foundation

public struct ManusPsiqueiaCore {
    public static let version = "1.0.0"
    
    public static func configure() {
        // Configuração inicial do módulo
    }
}

// MARK: - Public API

public protocol UserRepositoryProtocol {
    func fetchUser(id: String) async throws -> User
    func saveUser(_ user: User) async throws
}

public protocol DiaryRepositoryProtocol {
    func fetchEntries(for userId: String) async throws -> [DiaryEntry]
    func saveEntry(_ entry: DiaryEntry) async throws
}
```

### Passo 4: Modelos de Dados

Crie `Modules/ManusPsiqueiaCore/Sources/ManusPsiqueiaCore/Models/User.swift`:

```swift
import Foundation

public struct User: Codable, Identifiable {
    public let id: String
    public let email: String
    public let name: String
    public let userType: UserType
    public let createdAt: Date
    public let updatedAt: Date
    
    public enum UserType: String, Codable, CaseIterable {
        case patient = "patient"
        case psychologist = "psychologist"
        
        public var displayName: String {
            switch self {
            case .patient:
                return "Paciente"
            case .psychologist:
                return "Psicólogo"
            }
        }
    }
    
    public init(
        id: String,
        email: String,
        name: String,
        userType: UserType,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.userType = userType
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
```

### Passo 5: Testes

Crie `Modules/ManusPsiqueiaCore/Tests/ManusPsiqueiaCore/UserTests.swift`:

```swift
import XCTest
@testable import ManusPsiqueiaCore

final class UserTests: XCTestCase {
    
    func testUserCreation() {
        // Given
        let id = "user_123"
        let email = "test@example.com"
        let name = "João Silva"
        let userType = User.UserType.patient
        
        // When
        let user = User(
            id: id,
            email: email,
            name: name,
            userType: userType
        )
        
        // Then
        XCTAssertEqual(user.id, id)
        XCTAssertEqual(user.email, email)
        XCTAssertEqual(user.name, name)
        XCTAssertEqual(user.userType, userType)
    }
    
    func testUserTypeDisplayName() {
        // Given & When & Then
        XCTAssertEqual(User.UserType.patient.displayName, "Paciente")
        XCTAssertEqual(User.UserType.psychologist.displayName, "Psicólogo")
    }
}
```

## 4. Integrando Módulos no Projeto Principal

### Passo 1: Adicionar Dependência

No projeto principal, adicione o módulo como dependência local no Xcode:

1. Selecione o projeto no Navigator
2. Vá para a aba "Package Dependencies"
3. Clique em "+" e selecione "Add Local..."
4. Navegue até a pasta do módulo (ex: `Modules/ManusPsiqueiaCore`)

### Passo 2: Importar e Usar

```swift
import ManusPsiqueiaCore

class UserManager: ObservableObject {
    @Published var currentUser: User?
    
    private let userRepository: UserRepositoryProtocol
    
    init(userRepository: UserRepositoryProtocol) {
        self.userRepository = userRepository
    }
    
    func loadUser(id: String) async {
        do {
            let user = try await userRepository.fetchUser(id: id)
            await MainActor.run {
                self.currentUser = user
            }
        } catch {
            print("Erro ao carregar usuário: \(error)")
        }
    }
}
```

## 5. Boas Práticas

### Estrutura de Arquivos

Organize os arquivos dentro de cada módulo de forma consistente:

```
ManusPsiqueiaCore/
├── Sources/
│   └── ManusPsiqueiaCore/
│       ├── ManusPsiqueiaCore.swift      # Arquivo principal
│       ├── Models/                      # Modelos de dados
│       ├── Repositories/                # Interfaces de repositório
│       ├── Managers/                    # Lógica de negócio
│       └── Extensions/                  # Extensões úteis
└── Tests/
    └── ManusPsiqueiaCore/
        ├── Models/                      # Testes de modelos
        ├── Repositories/                # Testes de repositório
        └── Managers/                    # Testes de managers
```

### Versionamento

Mantenha versões consistentes entre os módulos:

```swift
public struct ManusPsiqueiaCore {
    public static let version = "1.0.0"
    public static let buildNumber = "1"
}
```

### Documentação

Documente todas as APIs públicas:

```swift
/// Repositório para gerenciar dados de usuários
public protocol UserRepositoryProtocol {
    
    /// Busca um usuário pelo ID
    /// - Parameter id: ID único do usuário
    /// - Returns: Usuário encontrado
    /// - Throws: `RepositoryError` se o usuário não for encontrado
    func fetchUser(id: String) async throws -> User
}
```

### Testes

Mantenha alta cobertura de testes em todos os módulos:

```swift
// Sempre teste as APIs públicas
// Use mocks para dependências externas
// Teste casos de erro além dos casos de sucesso
```

## 6. Comandos Úteis

### Compilar Módulo Específico

```bash
# Compilar apenas um módulo
cd Modules/ManusPsiqueiaCore
swift build

# Executar testes de um módulo
swift test
```

### Verificar Dependências

```bash
# Listar dependências do projeto
swift package show-dependencies

# Resolver dependências
swift package resolve
```

### Limpeza

```bash
# Limpar build cache
swift package clean

# Limpar DerivedData do Xcode
rm -rf ~/Library/Developer/Xcode/DerivedData
```

## 7. Solução de Problemas

### Erro: "No such module"

**Causa:** Módulo não foi adicionado como dependência.

**Solução:**
1. Verifique se o módulo está listado nas dependências do projeto
2. Limpe e recompile o projeto
3. Reinicie o Xcode se necessário

### Erro de Dependência Circular

**Causa:** Dois módulos dependem um do outro.

**Solução:**
1. Revise a arquitetura - dependências devem ser unidirecionais
2. Extraia código comum para um módulo de nível inferior
3. Use protocolos para quebrar dependências

### Compilação Lenta

**Causa:** Muitas dependências ou módulos muito grandes.

**Solução:**
1. Divida módulos grandes em módulos menores
2. Minimize dependências entre módulos
3. Use `@_implementationOnly import` quando possível

Seguindo este guia, você será capaz de trabalhar efetivamente com a arquitetura modular do ManusPsiqueia!
