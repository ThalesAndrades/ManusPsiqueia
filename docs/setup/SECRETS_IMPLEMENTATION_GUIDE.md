# Guia Prático de Implementação de Segredos

**Data:** 22 de setembro de 2025  
**Autor:** Manus AI  
**Projeto:** ManusPsiqueia

## 1. Configuração Inicial

### Pré-requisitos

Antes de começar, certifique-se de que você tem:

- Xcode 15.1 ou superior instalado
- Acesso ao repositório ManusPsiqueia no GitHub
- Chaves de API para desenvolvimento (Stripe Test, Supabase Dev, OpenAI)

### Passo 1: Executar o Setup Inicial

Execute o script de configuração para criar a estrutura necessária:

```bash
cd ManusPsiqueia
./scripts/secrets_manager.sh setup
```

Este comando criará:
- Diretório `Configuration/Secrets/`
- Diretório `Configuration/Templates/`
- Templates para todos os ambientes
- Arquivo `.gitignore` para proteger os segredos

### Passo 2: Configurar Ambiente de Desenvolvimento

1. **Copie o template de desenvolvimento:**
   ```bash
   cp Configuration/Templates/development.secrets.template Configuration/Secrets/development.secrets
   ```

2. **Preencha suas chaves de desenvolvimento:**
   Abra o arquivo `Configuration/Secrets/development.secrets` e substitua os valores de exemplo pelas suas chaves reais:

   ```bash
   # Stripe Configuration
   STRIPE_PUBLISHABLE_KEY=pk_test_sua_chave_aqui
   STRIPE_SECRET_KEY=sk_test_sua_chave_secreta_aqui

   # Supabase Configuration
   SUPABASE_URL=https://seu-projeto.supabase.co
   SUPABASE_ANON_KEY=sua_chave_anon_aqui

   # OpenAI Configuration
   OPENAI_API_KEY=sk-sua_chave_openai_aqui
   ```

3. **Armazene no Keychain:**
   ```bash
   ./scripts/secrets_manager.sh keychain --env development
   ```

### Passo 3: Validar Configuração

Verifique se tudo está configurado corretamente:

```bash
./scripts/secrets_manager.sh validate --env development
```

Se tudo estiver correto, você verá: `✅ Configuração válida para development!`

## 2. Uso no Código

### Acessando Configurações

Use sempre o `ConfigurationManager` para acessar configurações:

```swift
import Foundation

// Obter configurações do ambiente atual
let config = ConfigurationManager.shared

// Acessar chaves de API
let stripeKey = config.stripePublishableKey
let supabaseURL = config.supabaseURL
let openAIKey = config.openAIAPIKey

// Verificar ambiente atual
let environment = config.currentEnvironment
print("Executando em: \(environment.displayName)")

// Usar feature flags
if config.isDebugMenuEnabled {
    // Mostrar menu de debug apenas em desenvolvimento
}
```

### Validação de Configuração

Sempre valide as configurações na inicialização do app:

```swift
@main
struct ManusPsiqueiaApp: App {
    
    init() {
        validateConfiguration()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    private func validateConfiguration() {
        let errors = ConfigurationManager.shared.validateConfiguration()
        
        if !errors.isEmpty {
            print("❌ Erros de configuração encontrados:")
            errors.forEach { print("  - \($0)") }
            
            #if DEBUG
            fatalError("Configuração inválida em ambiente de desenvolvimento")
            #endif
        }
    }
}
```

## 3. Configuração de Ambientes

### Desenvolvimento Local

Para desenvolvimento local, use o arquivo `development.secrets` criado anteriormente. O `ConfigurationManager` detectará automaticamente que está em modo DEBUG e usará as configurações apropriadas.

### Staging

Para configurar o ambiente de staging:

1. **Configure GitHub Secrets:**
   Vá para `Settings > Secrets and variables > Actions` no repositório e adicione:
   - `STRIPE_PUBLISHABLE_KEY_STAGING`
   - `SUPABASE_URL_STAGING`
   - `SUPABASE_ANON_KEY_STAGING`
   - `OPENAI_API_KEY`

2. **O workflow de CI/CD** automaticamente injetará estes valores durante o build de staging.

### Produção

Para produção, siga o mesmo processo do staging, mas use as chaves de produção:
- `STRIPE_PUBLISHABLE_KEY_PROD`
- `SUPABASE_URL_PROD`
- `SUPABASE_ANON_KEY_PROD`

## 4. Boas Práticas

### Segurança

1. **NUNCA** faça commit de arquivos `.secrets`
2. **SEMPRE** use o `ConfigurationManager` para acessar segredos
3. **ROTACIONE** chaves regularmente
4. **LIMITE** o acesso aos GitHub Secrets apenas para pessoas autorizadas

### Desenvolvimento

1. **VALIDE** configurações na inicialização do app
2. **USE** feature flags para funcionalidades específicas de ambiente
3. **TESTE** em todos os ambientes antes do deploy

### Manutenção

1. **DOCUMENTE** novas configurações adicionadas
2. **ATUALIZE** templates quando necessário
3. **MONITORE** logs para erros de configuração

## 5. Solução de Problemas

### Erro: "Stripe Publishable Key não configurada"

**Causa:** O arquivo de segredos não foi configurado ou está incompleto.

**Solução:**
1. Verifique se o arquivo `Configuration/Secrets/development.secrets` existe
2. Execute: `./scripts/secrets_manager.sh validate --env development`
3. Preencha as chaves faltantes

### Erro: "Keychain item not found"

**Causa:** Os segredos não foram armazenados no Keychain.

**Solução:**
```bash
./scripts/secrets_manager.sh keychain --env development
```

### Erro de Build: "Variable not found"

**Causa:** Variável não definida no arquivo `.xcconfig` ou GitHub Secrets.

**Solução:**
1. Para desenvolvimento: Verifique o arquivo `.secrets`
2. Para CI/CD: Verifique os GitHub Secrets
3. Certifique-se de que a variável está definida no arquivo `.xcconfig` correto

## 6. Comandos Úteis

### Verificar Status
```bash
# Validar configuração atual
./scripts/secrets_manager.sh validate --env development

# Listar informações de debug
# (Execute no simulador ou dispositivo)
print(ConfigurationManager.shared.getDebugInfo())
```

### Gerenciar Keychain
```bash
# Armazenar segredos no Keychain
./scripts/secrets_manager.sh keychain --env development

# Limpar cache e arquivos temporários
./scripts/secrets_manager.sh clean
```

### Criptografia (Opcional)
```bash
# Criptografar arquivo de segredos
./scripts/secrets_manager.sh encrypt --file Configuration/Secrets/staging.secrets

# Descriptografar arquivo
./scripts/secrets_manager.sh decrypt --file Configuration/Secrets/staging.secrets.enc
```

## 7. Checklist de Configuração

- [ ] Script de setup executado com sucesso
- [ ] Arquivo `development.secrets` criado e preenchido
- [ ] Segredos armazenados no Keychain
- [ ] Configuração validada sem erros
- [ ] App compila e executa corretamente
- [ ] GitHub Secrets configurados para staging/produção
- [ ] Workflows de CI/CD testados

Seguindo este guia, você terá um ambiente de desenvolvimento seguro e funcional para o ManusPsiqueia!
