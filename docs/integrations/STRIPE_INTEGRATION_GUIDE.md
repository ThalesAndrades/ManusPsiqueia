# 💳 Guia de Integração Stripe - ManusPsiqueia

## 🎯 Visão Geral

O ManusPsiqueia utiliza o **Stripe iOS SDK** para processar pagamentos de forma segura e nativa, seguindo as melhores práticas do exemplo oficial do PaymentSheet.

## 📱 Implementação Realizada

### **1. StripePaymentSheetManager**
Gerenciador principal que integra com o PaymentSheet oficial do Stripe:

```swift
@MainActor
class StripePaymentSheetManager: ObservableObject {
    @Published var paymentSheet: PaymentSheet?
    @Published var paymentResult: PaymentSheetResult?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Backend model baseado no exemplo oficial
    class BackendModel: ObservableObject {
        // Implementação seguindo stripe-ios/Example/PaymentSheet Example
    }
}
```

### **2. PaymentSheetView (SwiftUI)**
Interface nativa que apresenta o PaymentSheet:

```swift
struct PaymentSheetView: View {
    @StateObject private var stripeManager = StripePaymentSheetManager.shared
    @State private var showingPaymentSheet = false
    
    var body: some View {
        // Interface premium com design ManusPsiqueia
        // Integração nativa com PaymentSheet
    }
}
```

### **3. SubscriptionViewWithStripe**
Tela de assinatura para psicólogos com integração completa:

```swift
struct SubscriptionViewWithStripe: View {
    // Planos: Mensal (R$ 89,90) e Anual (R$ 898,80)
    // Interface premium com animações
    // Integração PaymentSheet nativa
}
```

## 🔧 Configuração Necessária

### **1. Dependências (Package.swift)**
```swift
dependencies: [
    .package(
        url: "https://github.com/stripe/stripe-ios",
        from: "23.0.0"
    )
]
```

### **2. Chaves de API**
```swift
// Substitua pelas suas chaves reais
private let publishableKey = "pk_test_51234567890abcdef"
private let backendURL = "https://your-backend.com/api"
```

### **3. Info.plist**
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>manuspsiqueia.stripe</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>manuspsiqueia</string>
        </array>
    </dict>
</array>
```

## 💰 Modelo de Negócio Implementado

### **Psicólogos (Assinatura)**
- **Mensal**: R$ 89,90/mês
- **Anual**: R$ 898,80/ano (economia de R$ 179,80)
- **Stripe Connect**: Conta para receber pagamentos
- **Taxa de saque**: 2,5% (R$ 2,50 para cada R$ 100)

### **Pacientes (Gratuito)**
- **Acesso gratuito** à plataforma
- **Pagamentos de consultas** processados via PaymentSheet
- **Vinculação obrigatória** com psicólogo ativo

## 🔄 Fluxo de Pagamento

### **1. Assinatura de Psicólogo**
```swift
// 1. Preparar PaymentSheet
await stripeManager.createPsychologistSubscription(userId: userId, email: email)

// 2. Apresentar PaymentSheet nativo
.paymentSheet(isPresented: $showingPaymentSheet, paymentSheet: paymentSheet)

// 3. Processar resultado
func handlePaymentResult(_ result: PaymentSheetResult) {
    switch result {
    case .completed: // Assinatura ativa
    case .canceled:  // Usuário cancelou
    case .failed:    // Erro no pagamento
    }
}
```

### **2. Pagamento de Consulta**
```swift
// 1. Processar pagamento do paciente
await stripeManager.processPatientPayment(
    amount: consultationAmount,
    patientId: patientId,
    psychologistId: psychologistId
)

// 2. Transferir para psicólogo (via Stripe Connect)
await stripeManager.createTransfer(
    amount: netAmount,
    destinationAccountId: psychologistStripeAccount
)
```

## 🏦 Stripe Connect (Psicólogos)

### **Configuração de Conta**
```swift
// 1. Criar conta Connect
let accountResult = try await stripeManager.setupPsychologistConnect(
    psychologistId: psychologist.id,
    email: psychologist.email
)

// 2. Onboarding
// Usuário é direcionado para URL de onboarding do Stripe
```

### **Saques**
```swift
// Criar saque com taxa de 2,5%
let payout = try await stripeManager.createPayout(
    amount: requestedAmount,
    accountId: psychologistAccount
)
// Valor líquido = amount - 2.5% fee
```

## 📊 Analytics e Relatórios

### **Dashboard Financeiro**
```swift
// Relatório de ganhos
let earnings = try await stripeManager.getPsychologistEarnings(
    accountId: accountId,
    period: .month
)

struct EarningsReport {
    let totalEarnings: Int
    let totalFees: Int
    let netEarnings: Int
    let transactionCount: Int
    let transactions: [EarningsTransaction]
}
```

## 🔒 Segurança Implementada

### **1. Configuração Segura**
- **Publishable Key**: Apenas chave pública no cliente
- **Secret Key**: Apenas no backend (nunca no app)
- **Webhook Signatures**: Validação de eventos

### **2. Compliance**
- **PCI DSS**: Stripe gerencia compliance
- **LGPD**: Dados criptografados e anonimizados
- **3D Secure**: Autenticação adicional quando necessária

## 🎨 Design Premium

### **Tema ManusPsiqueia**
```swift
var appearance = PaymentSheet.Appearance()
appearance.colors.primary = UIColor(red: 0.545, green: 0.373, blue: 0.965, alpha: 1.0)
appearance.colors.background = UIColor.systemBackground
appearance.cornerRadius = 12.0
appearance.font.base = UIFont.systemFont(ofSize: 16, weight: .regular)
```

### **Animações e Efeitos**
- **Gradientes animados** na tela de assinatura
- **Feedback háptico** em interações
- **Transições suaves** entre estados
- **Loading states** elegantes

## 🚀 Próximos Passos

### **1. Backend Setup**
- Configurar webhook endpoints
- Implementar criação de PaymentIntents
- Setup Stripe Connect webhooks

### **2. Testes**
- Usar chaves de teste do Stripe
- Testar fluxos completos
- Validar webhooks

### **3. Produção**
- Substituir chaves de teste
- Configurar domínio de produção
- Ativar webhooks em produção

## 📞 Suporte

**Documentação Stripe**: https://stripe.com/docs/payments/payment-sheet/ios
**Exemplo Oficial**: https://github.com/stripe/stripe-ios/tree/master/Example/PaymentSheet%20Example

**Desenvolvido por**: AiLun Tecnologia  
**CNPJ**: 60.740.536/0001-75  
**Contato**: contato@ailun.com.br

---

*Esta implementação segue fielmente o exemplo oficial do Stripe, garantindo máxima compatibilidade e segurança para o ManusPsiqueia.*
