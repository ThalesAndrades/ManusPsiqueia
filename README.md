# 🧠 ManusPsiqueia

**Plataforma Premium de Saúde Mental com IA**

Uma solução completa para conectar psicólogos e pacientes através de tecnologia avançada, sistema de assinaturas e gestão financeira integrada.

![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)
![iOS](https://img.shields.io/badge/iOS-16.0+-blue.svg)
![SwiftUI](https://img.shields.io/badge/SwiftUI-4.0-green.svg)
![Stripe](https://img.shields.io/badge/Stripe-Payments-purple.svg)

## 🌟 Características Principais

### 💼 **Modelo de Negócio Inovador**
- **Assinatura para Psicólogos**: R$ 89,90/mês para acesso à plataforma
- **Gratuito para Pacientes**: Acesso sem custo, vinculados aos psicólogos
- **Sistema de Convites**: Pacientes podem convidar psicólogos para a plataforma
- **Vinculação Exclusiva**: Relacionamento terapêutico protegido e controlado

### 🎨 **Interface Premium**
- **SwiftUI Avançado**: Componentes nativos com animações fluidas
- **Design Tecnológico**: Visual imersivo focado em saúde mental
- **Efeitos Visuais**: Partículas, gradientes e transições cinematográficas
- **Responsividade**: Adaptado para todos os dispositivos Apple

### 💰 **Gestão Financeira Completa**
- **Dashboard Financeiro**: Métricas em tempo real para psicólogos
- **Integração Stripe**: Pagamentos seguros e transferências automáticas
- **Sistema de Saques**: Interface premium para retirada de fundos
- **Analytics Avançados**: Relatórios detalhados de receitas e performance

### 🤖 **Inteligência Artificial**
- **Assistente IA**: Suporte inteligente para sessões terapêuticas
- **Análise de Sentimentos**: Monitoramento do progresso dos pacientes
- **Recomendações**: Sugestões personalizadas baseadas em dados

## 📚 Documentação

Toda a documentação do projeto está organizada no diretório `docs/`. Consulte o `docs/README.md` para uma visão geral da estrutura da documentação.

## 🏗️ Arquitetura Técnica

### **Frontend (iOS)**
```
SwiftUI 4.0+
iOS 16.0+
Combine Framework
Core Data
HealthKit Integration
```

### **Backend & Serviços**
```
Stripe Connect (Pagamentos)
Stripe Subscriptions (Assinaturas)
OpenAI GPT-4 (IA)
Apple Push Notifications
CloudKit (Sincronização)
```

### **Segurança**
```
Biometric Authentication
End-to-End Encryption
HIPAA Compliance Ready
Data Privacy (LGPD)
```

## 📱 Funcionalidades por Usuário

### 👨‍⚕️ **Psicólogos**
- ✅ **Assinatura Premium** (R$ 89,90/mês)
- ✅ **Dashboard Financeiro** com métricas completas
- ✅ **Gestão de Pacientes** e sessões
- ✅ **Sistema de Saques** via Stripe
- ✅ **Assistente IA** para suporte terapêutico
- ✅ **Agenda Inteligente** com sincronização
- ✅ **Relatórios Detalhados** de progresso

### 👤 **Pacientes**
- ✅ **Acesso Gratuito** à plataforma
- ✅ **Vinculação com Psicólogo** ativo
- ✅ **Sistema de Convites** para psicólogos
- ✅ **Acompanhamento de Pagamentos** mensais
- ✅ **Chat Seguro** com criptografia
- ✅ **Exercícios Terapêuticos** personalizados
- ✅ **Histórico de Sessões** completo

## 📦 Arquitetura Modular

O ManusPsiqueia implementa uma arquitetura modular avançada usando Swift Package Manager, organizando o código em módulos independentes e reutilizáveis:

### **🔧 Módulos Principais**

#### **ManusPsiqueiaCore**
- **Responsabilidade**: Lógica de negócios central, modelos de dados e segurança
- **Conteúdo**: 
  - Modelos (User, Subscription, Payment, etc.)
  - Managers de negócio (AuthenticationManager, SecurityManager, etc.)
  - Componentes de segurança (Certificate Pinning, Threat Detection)
  - Utilitários e helpers
- **Dependências**: SwiftKeychainWrapper

#### **ManusPsiqueiaUI**
- **Responsabilidade**: Componentes de interface e views SwiftUI
- **Conteúdo**:
  - Views e componentes reutilizáveis
  - Sistema de temas e styling
  - Animações e efeitos visuais
  - Componentes avançados (Advanced Components)
- **Dependências**: ManusPsiqueiaCore

#### **ManusPsiqueiaServices**
- **Responsabilidade**: Integrações com serviços externos
- **Conteúdo**:
  - Integração Stripe (pagamentos)
  - Integração Supabase (backend)
  - Integração OpenAI (IA)
  - Clientes de API e network services
- **Dependências**: ManusPsiqueiaCore, Stripe, Supabase, OpenAI

### **🏗️ Benefícios da Arquitetura Modular**
- **Separação de Responsabilidades**: Cada módulo tem função específica
- **Reutilização**: Componentes podem ser usados em outros projetos
- **Testabilidade**: Testes mais granulares e independentes
- **Desenvolvimento em Equipe**: Equipes podem trabalhar em módulos paralelos
- **Compilação Incremental**: Build mais rápido com módulos independentes
- **Manutenibilidade**: Código mais organizado e fácil de manter

## 🚀 Instalação e Configuração

### **Pré-requisitos**
```bash
Xcode 15.0+
iOS 16.0+ Simulator/Device
Apple Developer Account
Stripe Account (Connect enabled)
OpenAI API Key
```

### **1. Clone o Repositório**
```bash
git clone https://github.com/ThalesAndrades/ManusPsiqueia.git
cd ManusPsiqueia
```

### **2. Configuração do Stripe**
```swift
// Em StripeManager.swift
private let publishableKey = "pk_test_YOUR_PUBLISHABLE_KEY"
private let secretKey = "sk_test_YOUR_SECRET_KEY"
```

### **3. Configuração da OpenAI**
```swift
// Em AIManager.swift
private let apiKey = "sk-YOUR_OPENAI_API_KEY"
```

### **4. Configuração de Push Notifications**
```swift
// Em NotificationManager.swift
// Adicione seu certificado APNs no Apple Developer Portal
```

### **5. Build e Run**
```bash
# Abra o projeto no Xcode
open ManusPsiqueia.xcodeproj

# Ou via linha de comando
xcodebuild -project ManusPsiqueia.xcodeproj -scheme ManusPsiqueia -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build
```

## 💳 Configuração de Pagamentos

### **Stripe Connect Setup**
1. **Criar Conta Stripe**: [dashboard.stripe.com](https://dashboard.stripe.com)
2. **Ativar Connect**: Habilitar marketplace functionality
3. **Configurar Webhooks**: Para eventos de pagamento
4. **KYC/Compliance**: Configurar verificação de identidade

### **Fluxo de Pagamentos**
```
Paciente → Pagamento Mensal → Stripe → Psicólogo (menos taxa)
Psicólogo → Assinatura → Stripe → Plataforma
```

### **Taxas da Plataforma**
- **Assinatura Psicólogo**: R$ 89,90/mês
- **Taxa de Saque**: 2,5% sobre valor sacado
- **Taxa Stripe**: 3,4% + R$ 0,60 por transação

## 🔧 Estrutura do Projeto

```
ManusPsiqueia/
├── ManusPsiqueia/
│   ├── Models/
│   │   ├── User.swift              # Modelos de usuário
│   │   ├── Subscription.swift      # Sistema de assinaturas
│   │   ├── Payment.swift           # Pagamentos de pacientes
│   │   ├── Financial.swift         # Dados financeiros
│   │   └── Invitation.swift        # Sistema de convites
│   ├── Managers/
│   │   ├── AuthenticationManager.swift  # Autenticação
│   │   ├── StripeManager.swift          # Integração Stripe
│   │   ├── InvitationManager.swift      # Gestão de convites
│   │   └── AIManager.swift              # Inteligência Artificial
│   ├── Views/
│   │   ├── OnboardingView.swift         # Onboarding premium
│   │   ├── SubscriptionView.swift       # Assinatura psicólogos
│   │   ├── FinancialDashboardView.swift # Dashboard financeiro
│   │   ├── WithdrawFundsView.swift      # Sistema de saques
│   │   └── InvitePsychologistView.swift # Convites de pacientes
│   └── Resources/
│       ├── Assets.xcassets         # Recursos visuais
│       └── Info.plist              # Configurações do app
└── README.md
```

## 🎯 Roadmap de Desenvolvimento

### **Versão 1.0 (MVP)** ✅
- [x] Sistema de autenticação
- [x] Assinaturas via Stripe
- [x] Dashboard financeiro
- [x] Sistema de convites
- [x] Interface premium SwiftUI

### **Versão 1.1 (Q2 2024)**
- [ ] Chat em tempo real
- [ ] Videochamadas integradas
- [ ] Notificações push avançadas
- [ ] Sincronização CloudKit

### **Versão 1.2 (Q3 2024)**
- [ ] IA avançada para diagnósticos
- [ ] Integração HealthKit
- [ ] Relatórios PDF automáticos
- [ ] Sistema de avaliações

### **Versão 2.0 (Q4 2024)**
- [ ] Versão macOS
- [ ] Apple Watch companion
- [ ] Integração Siri Shortcuts
- [ ] Modo offline avançado

## 📊 Métricas e Analytics

### **KPIs Principais**
- **Taxa de Conversão**: Convites → Assinaturas
- **Churn Rate**: Cancelamentos mensais
- **LTV**: Lifetime Value por psicólogo
- **MRR**: Monthly Recurring Revenue
- **Satisfação**: NPS de usuários

### **Dashboard Financeiro**
- Receita total e disponível
- Gráficos de performance
- Histórico de transações
- Previsões de crescimento
- Análise de tendências

## 🔒 Segurança e Compliance

### **Proteção de Dados**
- **Criptografia E2E**: Todas as comunicações
- **Biometria**: Face ID / Touch ID
- **LGPD Compliance**: Proteção de dados brasileira
- **HIPAA Ready**: Padrões de saúde americanos

### **Auditoria e Logs**
- Logs de acesso detalhados
- Trilha de auditoria completa
- Backup automático seguro
- Recuperação de desastres

## 🤝 Contribuição

### **Como Contribuir**
1. Fork o repositório
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

### **Padrões de Código**
- **SwiftLint**: Linting automático
- **Conventional Commits**: Padrão de commits
- **Code Review**: Obrigatório para PRs
- **Testes**: Cobertura mínima de 80%

## 📞 Suporte e Contato

### **Suporte Técnico**
- **Email**: contato@ailun.com.br
- **GitHub Issues**: Para bugs e features
- **Documentação**: Wiki do repositório

### **Informações Corporativas**
- **Empresa**: AiLun Tecnologia
- **CNPJ**: 60.740.536/0001-75
- **Email**: contato@ailun.com.br

## 📄 Licença

Este projeto está licenciado sob a Licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.

## 🙏 Agradecimentos

- **Stripe**: Pela infraestrutura de pagamentos robusta
- **OpenAI**: Pela tecnologia de IA avançada
- **Apple**: Pelas ferramentas de desenvolvimento excepcionais
- **Comunidade Swift**: Pelo suporte e recursos

---

**Desenvolvido com ❤️ pela [AiLun Tecnologia](mailto:contato@ailun.com.br)**

*Transformando a saúde mental através da tecnologia*
