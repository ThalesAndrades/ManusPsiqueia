# 📋 Documentação Técnica - ManusPsiqueia

## 🏗️ Arquitetura do Sistema

### **Visão Geral**
O ManusPsiqueia é construído com arquitetura MVVM (Model-View-ViewModel) utilizando SwiftUI e Combine, garantindo separação clara de responsabilidades e testabilidade.

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│     Views       │    │    Managers     │    │     Models      │
│   (SwiftUI)     │◄──►│   (Business)    │◄──►│    (Data)       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   UI Components │    │   API Services  │    │   Core Data     │
│   Animations    │    │   Stripe SDK    │    │   CloudKit      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🔧 Componentes Principais

### **1. Authentication System**

#### **AuthenticationManager.swift**
```swift
class AuthenticationManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var authenticationState: AuthenticationState = .unauthenticated
    
    // Métodos principais
    func signIn(email: String, password: String) async throws
    func signUp(userData: UserRegistrationData) async throws
    func signOut() async
    func refreshToken() async throws
}
```

**Funcionalidades:**
- Autenticação biométrica (Face ID/Touch ID)
- Gerenciamento de tokens JWT
- Refresh automático de sessões
- Integração com Keychain para segurança

### **2. Stripe Integration**

#### **StripeManager.swift**
```swift
class StripeManager: ObservableObject {
    @Published var subscriptionStatus: SubscriptionStatus = .inactive
    @Published var financialData: FinancialData?
    
    // Pagamentos e Assinaturas
    func createSubscription(for user: User) async throws -> Subscription
    func processPayment(amount: Decimal, customer: String) async throws -> PaymentIntent
    func processWithdrawal(amount: Decimal, bankAccount: BankAccount) async throws -> Withdrawal
    
    // Analytics Financeiros
    func getFinancialData(period: FinancialPeriod) async throws -> FinancialData
    func getTransactionHistory() async throws -> [Transaction]
}
```

**Configuração Stripe Connect:**
```swift
// Configuração para marketplace
private func setupStripeConnect() {
    // 1. Criar conta conectada para psicólogo
    // 2. Configurar split de pagamentos
    // 3. Gerenciar transferências automáticas
    // 4. Implementar webhooks para eventos
}
```

### **3. Invitation System**

#### **InvitationManager.swift**
```swift
class InvitationManager: ObservableObject {
    @Published var pendingInvitations: [Invitation] = []
    @Published var sentInvitations: [Invitation] = []
    
    // Gestão de Convites
    func sendInvitation(to email: String, from patient: User) async throws
    func acceptInvitation(invitation: Invitation) async throws
    func declineInvitation(invitation: Invitation) async throws
    
    // Vinculação Psicólogo-Paciente
    func linkPatientToPsychologist(patient: User, psychologist: User) async throws
    func unlinkPatient(patient: User) async throws
}
```

**Fluxo de Convites:**
```
1. Paciente envia convite por email
2. Sistema gera link único com token
3. Psicólogo clica no link e é direcionado para app
4. Psicólogo se cadastra/faz login
5. Sistema vincula automaticamente os usuários
6. Psicólogo pode começar a atender o paciente
```

## 💰 Sistema Financeiro

### **Modelo de Dados Financeiros**

#### **Financial.swift**
```swift
struct FinancialData: Codable {
    let availableBalance: Decimal
    let totalRevenue: Decimal
    let monthlyRevenue: Decimal
    let activePatients: Int
    let conversionRate: Double
    let platformFeePercentage: Double
    let revenueChartData: [RevenueChartPoint]
    let recentPayments: [PatientPayment]
    let recentWithdrawals: [Withdrawal]
    let recentTransactions: [Transaction]
}
```

### **Fluxo de Pagamentos**

#### **1. Assinatura de Psicólogos**
```swift
// Fluxo mensal automático
func processMonthlySubscription() async {
    // 1. Verificar psicólogos ativos
    // 2. Cobrar R$ 89,90 via Stripe
    // 3. Atualizar status de assinatura
    // 4. Enviar notificação de cobrança
    // 5. Suspender acesso se pagamento falhar
}
```

#### **2. Pagamentos de Pacientes**
```swift
// Fluxo de pagamento mensal do paciente para psicólogo
func processPatientPayment(patient: User, psychologist: User, amount: Decimal) async {
    // 1. Criar PaymentIntent no Stripe
    // 2. Processar pagamento do paciente
    // 3. Calcular taxa da plataforma (8.5%)
    // 4. Transferir valor líquido para psicólogo
    // 5. Registrar transação no sistema
    // 6. Enviar confirmação por email
}
```

#### **3. Sistema de Saques**
```swift
// Fluxo de saque para psicólogos
func processWithdrawal(amount: Decimal, bankAccount: BankAccount) async throws -> Withdrawal {
    // 1. Validar saldo disponível
    // 2. Calcular taxa de saque (2.5%)
    // 3. Criar transferência no Stripe
    // 4. Atualizar saldo do psicólogo
    // 5. Registrar transação
    // 6. Enviar confirmação
}
```

## 🎨 Interface e Animações

### **Design System**

#### **Cores Principais**
```swift
extension Color {
    static let primaryPurple = Color(red: 0.4, green: 0.2, blue: 0.8)
    static let secondaryBlue = Color(red: 0.2, green: 0.6, blue: 0.9)
    static let accentGreen = Color.green
    static let backgroundDark = Color.black
    static let surfaceLight = Color.white.opacity(0.1)
}
```

#### **Tipografia**
```swift
extension Font {
    static let headingLarge = Font.system(size: 32, weight: .bold, design: .rounded)
    static let headingMedium = Font.system(size: 24, weight: .bold, design: .rounded)
    static let bodyLarge = Font.system(size: 18, weight: .medium)
    static let bodyRegular = Font.system(size: 16, weight: .regular)
    static let caption = Font.system(size: 14, weight: .medium)
}
```

### **Animações Avançadas**

#### **Particle System**
```swift
struct ParticleView: View {
    @State private var particles: [Particle] = []
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(
                            x: particle.x + sin(animationOffset * particle.speed) * particle.amplitude,
                            y: particle.y + cos(animationOffset * particle.speed * 0.7) * particle.amplitude * 0.3
                        )
                        .opacity(particle.opacity)
                        .blur(radius: particle.blur)
                }
            }
        }
    }
}
```

#### **Gradient Animations**
```swift
struct AnimatedGradientBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.primaryPurple.opacity(0.1),
                Color.clear,
                Color.secondaryBlue.opacity(0.1)
            ]),
            startPoint: animateGradient ? .topTrailing : .bottomLeading,
            endPoint: animateGradient ? .bottomLeading : .topTrailing
        )
        .animation(
            Animation.easeInOut(duration: 4.0).repeatForever(autoreverses: true),
            value: animateGradient
        )
    }
}
```

## 🤖 Inteligência Artificial

### **AIManager.swift**
```swift
class AIManager: ObservableObject {
    private let openAIClient: OpenAIClient
    
    // Análise de Sessões
    func analyzeSessionNotes(notes: String) async throws -> SessionAnalysis
    func generateSessionSummary(transcript: String) async throws -> String
    func suggestTreatmentPlan(patientHistory: [Session]) async throws -> TreatmentPlan
    
    // Assistente para Psicólogos
    func getTherapeuticSuggestions(context: TherapyContext) async throws -> [Suggestion]
    func analyzeSentiment(text: String) async throws -> SentimentAnalysis
    func generateExercises(for condition: MentalHealthCondition) async throws -> [Exercise]
}
```

### **Modelos de IA**

#### **Session Analysis**
```swift
struct SessionAnalysis: Codable {
    let sentiment: SentimentScore
    let keyTopics: [String]
    let riskFactors: [RiskFactor]
    let progressIndicators: [ProgressIndicator]
    let recommendations: [Recommendation]
    let confidenceScore: Double
}
```

#### **Treatment Plan**
```swift
struct TreatmentPlan: Codable {
    let goals: [TherapeuticGoal]
    let interventions: [Intervention]
    let timeline: TreatmentTimeline
    let milestones: [Milestone]
    let exercises: [TherapeuticExercise]
}
```

## 📱 Views e Componentes

### **Componentes Reutilizáveis**

#### **StatCard.swift**
```swift
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: TrendData?
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(color)
                
                Spacer()
                
                if let trend = trend {
                    TrendIndicator(trend: trend)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.headingMedium)
                    .foregroundColor(.white)
                    .contentTransition(.numericText())
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(cardBackground)
    }
}
```

#### **PaymentStatusBadge.swift**
```swift
struct PaymentStatusBadge: View {
    let status: PaymentStatus
    
    var body: some View {
        Text(status.displayName)
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.color.opacity(0.3))
            .clipShape(Capsule())
    }
}
```

### **Views Principais**

#### **FinancialDashboardView.swift**
- Dashboard completo com métricas financeiras
- Gráficos interativos usando Swift Charts
- Animações fluidas e responsivas
- Integração com dados em tempo real

#### **WithdrawFundsView.swift**
- Interface premium para saques
- Validação de valores e contas bancárias
- Cálculo automático de taxas
- Confirmação segura de transações

#### **InvitePsychologistView.swift**
- Sistema de convites por email
- Templates personalizáveis
- Tracking de status de convites
- Interface intuitiva para pacientes

## 🔒 Segurança e Compliance

### **Criptografia**
```swift
// Criptografia E2E para mensagens
class EncryptionManager {
    private let keychain = Keychain(service: "com.ailun.manuspsiqueia")
    
    func encryptMessage(_ message: String, for recipient: User) throws -> EncryptedMessage
    func decryptMessage(_ encryptedMessage: EncryptedMessage) throws -> String
    func generateKeyPair() throws -> (publicKey: SecKey, privateKey: SecKey)
}
```

### **Biometric Authentication**
```swift
// Autenticação biométrica
class BiometricAuthManager {
    func authenticateWithBiometrics() async throws -> Bool {
        let context = LAContext()
        let reason = "Acesse sua conta ManusPsiqueia com segurança"
        
        return try await context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: reason
        )
    }
}
```

### **Data Protection**
```swift
// Proteção de dados sensíveis
class DataProtectionManager {
    func encryptSensitiveData(_ data: Data) throws -> Data
    func decryptSensitiveData(_ encryptedData: Data) throws -> Data
    func securelyStoreData(_ data: Data, key: String) throws
    func securelyRetrieveData(key: String) throws -> Data?
}
```

## 📊 Analytics e Métricas

### **Analytics Manager**
```swift
class AnalyticsManager: ObservableObject {
    // KPIs de Negócio
    func trackSubscriptionConversion(from invitation: Invitation)
    func trackUserRetention(user: User, period: AnalyticsPeriod)
    func trackRevenueMetrics() async -> RevenueMetrics
    
    // Métricas de Uso
    func trackSessionDuration(session: TherapySession)
    func trackFeatureUsage(feature: AppFeature, user: User)
    func trackUserEngagement(user: User) async -> EngagementMetrics
}
```

### **Revenue Metrics**
```swift
struct RevenueMetrics: Codable {
    let mrr: Decimal // Monthly Recurring Revenue
    let arr: Decimal // Annual Recurring Revenue
    let churnRate: Double
    let ltv: Decimal // Lifetime Value
    let cac: Decimal // Customer Acquisition Cost
    let conversionRate: Double
    let averageSessionValue: Decimal
}
```

## 🧪 Testes

### **Estrutura de Testes**
```
Tests/
├── UnitTests/
│   ├── ManagerTests/
│   │   ├── AuthenticationManagerTests.swift
│   │   ├── StripeManagerTests.swift
│   │   └── InvitationManagerTests.swift
│   ├── ModelTests/
│   │   ├── UserTests.swift
│   │   ├── FinancialTests.swift
│   │   └── SubscriptionTests.swift
├── IntegrationTests/
│   ├── StripeIntegrationTests.swift
│   ├── APIIntegrationTests.swift
│   └── DatabaseIntegrationTests.swift
└── UITests/
    ├── OnboardingUITests.swift
    ├── DashboardUITests.swift
    └── PaymentUITests.swift
```

### **Exemplo de Teste**
```swift
class StripeManagerTests: XCTestCase {
    var stripeManager: StripeManager!
    
    override func setUp() {
        super.setUp()
        stripeManager = StripeManager()
    }
    
    func testCreateSubscription() async throws {
        // Given
        let user = User.mockPsychologist
        
        // When
        let subscription = try await stripeManager.createSubscription(for: user)
        
        // Then
        XCTAssertEqual(subscription.amount, 89.90)
        XCTAssertEqual(subscription.status, .active)
        XCTAssertEqual(subscription.userId, user.id)
    }
}
```

## 🚀 Deployment

### **App Store Configuration**
```swift
// Info.plist configurações
<key>NSHealthShareUsageDescription</key>
<string>ManusPsiqueia integra com HealthKit para monitorar seu bem-estar mental</string>

<key>NSCameraUsageDescription</key>
<string>Permita acesso à câmera para videochamadas terapêuticas</string>

<key>NSMicrophoneUsageDescription</key>
<string>Permita acesso ao microfone para sessões de áudio</string>
```

### **Build Configuration**
```swift
// Build Settings
SWIFT_VERSION = 5.9
IPHONEOS_DEPLOYMENT_TARGET = 16.0
ENABLE_BITCODE = NO
SWIFT_COMPILATION_MODE = wholemodule
```

### **Continuous Integration**
```yaml
# .github/workflows/ios.yml
name: iOS CI
on: [push, pull_request]
jobs:
  test:
    runs-on: macos-latest
    steps:
    - uses: actions/checkout@v2
    - name: Build and Test
      run: |
        xcodebuild test -project ManusPsiqueia.xcodeproj -scheme ManusPsiqueia -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

## 📈 Performance

### **Otimizações**
- **Lazy Loading**: Carregamento sob demanda de dados
- **Image Caching**: Cache inteligente de imagens
- **Background Processing**: Tarefas pesadas em background
- **Memory Management**: Gestão eficiente de memória

### **Monitoring**
```swift
// Performance monitoring
class PerformanceMonitor {
    func trackAppLaunchTime()
    func trackViewLoadTime(view: String)
    func trackAPIResponseTime(endpoint: String, duration: TimeInterval)
    func trackMemoryUsage()
    func trackCrashes()
}
```

---

**Documentação mantida pela [AiLun Tecnologia](mailto:contato@ailun.com.br)**

*Última atualização: Janeiro 2024*
