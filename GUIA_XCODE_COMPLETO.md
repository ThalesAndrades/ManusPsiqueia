# 🚀 ManusPsiqueia - Guia Completo de Setup no Xcode

Este guia fornece instruções completas para configurar e executar o projeto ManusPsiqueia no ambiente Xcode.

## 📋 Pré-requisitos

- **macOS** 13.0 ou superior
- **Xcode** 15.0 ou superior
- **Swift** 5.9 ou superior
- **Conta Apple Developer** (para builds em dispositivos)
- **Chaves de API** necessárias (Stripe, Supabase, OpenAI)

## 🔧 Setup Automático

Execute o script de setup automático:

```bash
# Navegar para o diretório do projeto
cd ManusPsiqueia

# Executar setup automático
./setup_xcode_environment.sh

# Validar configuração
./validate_xcode_setup.sh
```

## ⚙️ Configuração Manual

### 1. Configurar Variáveis de Ambiente

1. Copie o arquivo de template:
```bash
cp .env.example .env
```

2. Edite o arquivo `.env` com suas chaves reais:
```bash
# Desenvolvimento
STRIPE_PUBLISHABLE_KEY_DEV=pk_test_sua_chave_aqui
SUPABASE_URL_DEV=https://seu-projeto.supabase.co
SUPABASE_ANON_KEY_DEV=sua_chave_anon_aqui
OPENAI_API_KEY_DEV=sk-sua_chave_openai_aqui

# Configuração do Team
DEVELOPMENT_TEAM_ID=SEU_TEAM_ID_AQUI
```

### 2. Abrir no Xcode

```bash
open ManusPsiqueia.xcodeproj
```

### 3. Configurar Code Signing

1. Selecione o target **ManusPsiqueia**
2. Vá para **Signing & Capabilities**
3. Configure seu **Team** 
4. Verifique o **Bundle Identifier**

### 4. Selecionar Destino de Build

- **Simulador**: iPhone 15 (recomendado para desenvolvimento)
- **Dispositivo**: iPhone/iPad físico (requer certificados)

## 🏗️ Compilação e Execução

### Build via Xcode
1. Pressione `⌘ + B` para compilar
2. Pressione `⌘ + R` para executar

### Build via Command Line
```bash
# Build Debug
xcodebuild -project ManusPsiqueia.xcodeproj -scheme ManusPsiqueia -destination "platform=iOS Simulator,name=iPhone 15" build

# Build Release
xcodebuild -project ManusPsiqueia.xcodeproj -scheme ManusPsiqueia -configuration Release build

# Clean Build
xcodebuild -project ManusPsiqueia.xcodeproj -scheme ManusPsiqueia clean build
```

## 🔄 Ambientes de Build

### Development (Debug)
- **Configuração**: `Development.xcconfig`
- **Bundle ID**: `com.ailun.manuspsiqueia.dev`
- **Usar para**: Desenvolvimento local
- **Certificado**: Apple Development

### Staging (Beta)
- **Configuração**: `Staging.xcconfig`
- **Bundle ID**: `com.ailun.manuspsiqueia.beta`
- **Usar para**: TestFlight builds
- **Certificado**: Apple Distribution

### Production (Release)
- **Configuração**: `Production.xcconfig`
- **Bundle ID**: `com.ailun.manuspsiqueia`
- **Usar para**: App Store release
- **Certificado**: Apple Distribution

## 📦 Dependências

### Externas (via Swift Package Manager)
- **Stripe iOS SDK** (23.32.0): Pagamentos
- **Supabase Swift** (2.33.0): Backend/Database
- **OpenAI Swift** (0.4.6): Funcionalidades de IA
- **SwiftKeychainWrapper** (4.0.1): Armazenamento seguro

### Módulos Locais
- **ManusPsiqueiaServices**: Serviços centrais
- **ManusPsiqueiaUI**: Componentes de UI reutilizáveis

## 🧪 Testes

### Executar Testes
```bash
# Via Xcode
⌘ + U

# Via Command Line
xcodebuild test -project ManusPsiqueia.xcodeproj -scheme ManusPsiqueia -destination "platform=iOS Simulator,name=iPhone 15"
```

## 🚀 Deploy

### TestFlight (Staging)
```bash
./scripts/deploy.sh staging
```

### App Store (Production)
```bash
./scripts/deploy.sh production
```

## ☁️ Xcode Cloud

### Configuração
1. Configure workflows no Xcode Cloud
2. Adicione variáveis de ambiente:
   - `STRIPE_PUBLISHABLE_KEY_STAGING`
   - `SUPABASE_URL_STAGING`
   - `OPENAI_API_KEY_STAGING`
   - `DEVELOPMENT_TEAM_ID`

### Scripts CI/CD
- **Pre-build**: `ci_scripts/ci_pre_xcodebuild.sh`
- **Post-build**: Configurado para cada workflow

## 🛠️ Solução de Problemas

### Erro: "No such module"
```bash
# Resolver dependências
swift package resolve
swift package update
```

### Erro de Code Signing
1. Verifique se `DEVELOPMENT_TEAM_ID` está configurado
2. Confirme certificados no Keychain
3. Verifique provisioning profiles

### Erro de Build Configuration
1. Verifique se todos os arquivos `.xcconfig` existem
2. Confirme variáveis de ambiente no `.env`
3. Valide Info.plist

### Limpar Build Cache
```bash
# Xcode derived data
rm -rf ~/Library/Developer/Xcode/DerivedData

# Swift package cache
swift package clean
```

## 🔍 Validação

Execute a qualquer momento para verificar o status:
```bash
./validate_xcode_setup.sh
```

## 📁 Estrutura do Projeto

```
ManusPsiqueia/
├── ManusPsiqueia.xcodeproj/     # Projeto Xcode
├── ManusPsiqueia/               # Código fonte principal
│   ├── ManusPsiqueiaApp.swift   # Entry point
│   ├── ContentView.swift        # View principal
│   ├── Info.plist              # Configurações do app
│   └── Assets.xcassets/        # Recursos visuais
├── Configuration/              # Configurações por ambiente
│   ├── Development.xcconfig
│   ├── Staging.xcconfig
│   └── Production.xcconfig
├── Modules/                    # Módulos Swift locais
│   ├── ManusPsiqueiaServices/
│   └── ManusPsiqueiaUI/
├── ci_scripts/                 # Scripts para Xcode Cloud
├── scripts/                    # Scripts de automação
├── .env.example               # Template de variáveis
└── Package.swift              # Dependências SPM
```

## 📱 Funcionalidades Principais

- **Autenticação**: Supabase Auth
- **Pagamentos**: Stripe SDK
- **IA**: OpenAI GPT-4
- **Diário Seguro**: Face ID + Keychain
- **Multi-ambiente**: Dev/Staging/Prod

## 🔒 Segurança

- Face ID para proteção do diário
- Certificate pinning em produção
- Chaves API via variáveis de ambiente
- Armazenamento seguro com Keychain

## 📞 Suporte

- **Issues**: Use o GitHub Issues
- **Documentação**: Pasta `docs/`
- **Scripts**: Pasta `scripts/`

---

**Versão do Guia**: 2.0.0  
**Última Atualização**: $(date)  
**Projeto**: ManusPsiqueia by AiLun Tecnologia