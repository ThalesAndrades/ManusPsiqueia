# Gerenciamento Completo de Segredos - ManusPsiqueia

**Data:** 2025-01-28  
**Versão:** 2.0  
**Status:** Implementação Completa

## 🎯 Visão Geral

Este documento descreve o sistema completo de gerenciamento de segredos implementado no ManusPsiqueia, incluindo todas as funcionalidades necessárias para um ciclo de vida completo de segredos desde o desenvolvimento local até a produção.

## 🏗️ Arquitetura do Sistema

### Componentes Principais

1. **Scripts de Automação** (`scripts/secrets_manager.sh`)
2. **Gerenciador de Configuração** (`ConfigurationManager.swift`)
3. **Workflows CI/CD** (GitHub Actions)
4. **Templates de Configuração** (`.xcconfig` files)
5. **Sistema de Backup e Recuperação**
6. **Auditoria e Monitoramento**

## 📋 Funcionalidades Implementadas

### ✅ Funcionalidades Básicas
- [x] Configuração inicial de estrutura
- [x] Templates para todos os ambientes (development, staging, production)
- [x] Validação de configurações
- [x] Integração com Keychain do macOS
- [x] Criptografia/descriptografia de arquivos
- [x] Limpeza de arquivos temporários

### ✅ Funcionalidades Avançadas
- [x] Listagem de segredos disponíveis
- [x] Rotação de segredos
- [x] Backup criptografado de segredos
- [x] Restauração de backups
- [x] Auditoria completa de segurança
- [x] Exportação para CI/CD (GitHub Actions)
- [x] Health check de segredos
- [x] Validação por ambiente
- [x] Integração completa com CI/CD

## 🚀 Guia de Uso

### 1. Configuração Inicial

```bash
# Criar estrutura e templates
./scripts/secrets_manager.sh setup

# Verificar ajuda completa
./scripts/secrets_manager.sh --help
```

### 2. Configuração de Desenvolvimento

```bash
# Copiar template e preencher
cp Configuration/Templates/development.secrets.template Configuration/Secrets/development.secrets

# Editar o arquivo com suas chaves reais
nano Configuration/Secrets/development.secrets

# Validar configuração
./scripts/secrets_manager.sh validate --env development

# Armazenar no Keychain
./scripts/secrets_manager.sh keychain --env development
```

### 3. Gerenciamento de Segredos

#### Listar Segredos
```bash
./scripts/secrets_manager.sh list --env development
./scripts/secrets_manager.sh list --env staging
./scripts/secrets_manager.sh list --env production
```

#### Rotacionar Segredos
```bash
# Rotacionar uma chave específica
./scripts/secrets_manager.sh rotate --env production --key STRIPE_SECRET_KEY

# O script irá:
# 1. Fazer backup automático
# 2. Solicitar novo valor
# 3. Atualizar arquivo
# 4. Atualizar Keychain
```

#### Backup e Restauração
```bash
# Criar backup criptografado
./scripts/secrets_manager.sh backup --env production

# Restaurar backup
./scripts/secrets_manager.sh restore --env production --backup Configuration/Secrets/backups/production.secrets.backup.20250128_143022.enc
```

#### Auditoria de Segurança
```bash
# Executar auditoria completa
./scripts/secrets_manager.sh audit --env production

# Gera relatório com:
# - Status de validação
# - Permissões de arquivos
# - Verificação de chaves obrigatórias
# - Status no Keychain
# - Última modificação
```

### 4. Exportação para CI/CD

```bash
# Gerar comandos para GitHub CLI
./scripts/secrets_manager.sh export --env staging

# Saída exemplo:
# gh secret set STRIPE_PUBLISHABLE_KEY_STAGING --body "pk_test_..."
# gh secret set SUPABASE_URL_STAGING --body "https://..."
```

### 5. Criptografia Manual

```bash
# Criptografar arquivo
./scripts/secrets_manager.sh encrypt --file Configuration/Secrets/production.secrets

# Descriptografar arquivo
./scripts/secrets_manager.sh decrypt --file Configuration/Secrets/production.secrets.enc
```

## 🔄 Integração com CI/CD

### GitHub Actions Workflows

#### 1. Secrets Management Pipeline (`secrets-management.yml`)

**Triggers:**
- Manual dispatch com opções para ambiente e ação
- Suporte para validation, audit, backup, rotation

**Funcionalidades:**
- Validação automática de segredos
- Auditoria de segurança
- Backup automático
- Geração de relatórios
- Notificações de segurança

**Uso:**
1. Acesse Actions > Secrets Management Pipeline
2. Clique em "Run workflow"
3. Selecione ambiente (staging/production)
4. Selecione ação (validate/audit/backup/rotate)

#### 2. iOS CI/CD Pipeline (atualizado)

**Melhorias implementadas:**
- Configuração automática de segredos para builds
- Validação de segredos antes do build
- Cleanup automático de arquivos sensíveis
- Integração com certificados e provisioning profiles
- Upload automático para TestFlight

### Configuração de Secrets no GitHub

**Secrets Necessários:**

#### Para Staging:
- `STRIPE_PUBLISHABLE_KEY_STAGING`
- `STRIPE_SECRET_KEY_STAGING`
- `SUPABASE_URL_STAGING`
- `SUPABASE_ANON_KEY_STAGING`
- `SUPABASE_SERVICE_ROLE_KEY_STAGING`
- `OPENAI_API_KEY_STAGING`
- `DATABASE_URL_STAGING`
- `SMTP_*_STAGING` (host, port, user, pass)
- `APNS_*_STAGING` (key_id, team_id)
- `MIXPANEL_TOKEN_STAGING`

#### Para Production:
- `STRIPE_PUBLISHABLE_KEY_PRODUCTION`
- `STRIPE_SECRET_KEY_PRODUCTION`
- `SUPABASE_URL_PRODUCTION`
- `SUPABASE_ANON_KEY_PRODUCTION`
- `SUPABASE_SERVICE_ROLE_KEY_PRODUCTION`
- `OPENAI_API_KEY_PRODUCTION`
- `DATABASE_URL_PRODUCTION`
- `SMTP_*_PRODUCTION`
- `APNS_*_PRODUCTION`
- `MIXPANEL_TOKEN_PRODUCTION`

#### Para Certificados:
- `CERTIFICATES_P12` (base64 encoded)
- `CERTIFICATES_PASSWORD`
- `PROVISIONING_PROFILE` (base64 encoded)
- `DEVELOPMENT_TEAM_ID`
- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_API_ISSUER_ID`
- `APP_STORE_CONNECT_API_KEY` (base64 encoded)

## 🛡️ Recursos de Segurança

### 1. Validação Avançada

O `ConfigurationManager` agora inclui:
- Validação específica por ambiente
- Verificação de formato de chaves
- Detecção de chaves de teste em produção
- Health check contínuo
- Relatórios detalhados de status

### 2. Keychain Integration

- Armazenamento seguro por ambiente
- Service identifiers únicos
- Acesso apenas quando device desbloqueado
- Limpeza automática entre ambientes

### 3. Backup e Recovery

- Backups criptografados com AES-256-CBC
- Hash SHA-256 para verificação de integridade
- Versionamento automático por timestamp
- Restauração com validação

### 4. Auditoria e Monitoramento

- Logs detalhados de acesso
- Relatórios de conformidade
- Tracking de modificações
- Alertas automáticos para problemas

### 5. Emergency Procedures

- Workflow de lockdown de emergência
- Revogação automática de acesso
- Procedimentos de incident response
- Notificações para equipe de segurança

## 📊 Monitoramento e Métricas

### Health Check Automático

```swift
// Uso no código
let healthStatus = ConfigurationManager.shared.performSecretsHealthCheck()
print(healthStatus.summary)

// Saída exemplo:
// ✅ Secrets Health: 100%
// Available: 4/4
// Missing: 
// Last Check: 28/01/25 14:30
```

### Relatórios de Validação

```swift
let validation = ConfigurationManager.shared.validateConfiguration()
print(validation.summary)

// Saída exemplo:
// Validation: ✅ PASSED
// Warnings (1):
//   • Analytics disabled in development mode
```

## 🔄 Workflow de Rotação de Segredos

### Processo Recomendado

1. **Planejamento** (Trimestral)
   - Identificar segredos para rotação
   - Comunicar com equipe
   - Agendar janela de manutenção

2. **Execução**
   ```bash
   # Backup antes da rotação
   ./scripts/secrets_manager.sh backup --env production
   
   # Rotacionar chave
   ./scripts/secrets_manager.sh rotate --env production --key STRIPE_SECRET_KEY
   
   # Validar nova configuração
   ./scripts/secrets_manager.sh validate --env production
   
   # Executar auditoria
   ./scripts/secrets_manager.sh audit --env production
   ```

3. **Verificação**
   - Testar funcionalidades críticas
   - Verificar logs de aplicação
   - Confirmar integrações funcionando

4. **Cleanup**
   - Revogar chaves antigas nos provedores
   - Atualizar documentação
   - Notificar equipe de conclusão

## 🚨 Procedimentos de Emergência

### Suspeita de Comprometimento

1. **Executar Lockdown**
   ```bash
   # Ativar modo de emergência no workflow
   # (Atualmente desabilitado para segurança)
   ```

2. **Rotação Imediata**
   ```bash
   # Rotacionar todas as chaves críticas
   for key in STRIPE_SECRET_KEY SUPABASE_SERVICE_ROLE_KEY OPENAI_API_KEY; do
     ./scripts/secrets_manager.sh rotate --env production --key $key
   done
   ```

3. **Auditoria de Incident**
   ```bash
   ./scripts/secrets_manager.sh audit --env production > incident-report.txt
   ```

## 📚 Best Practices

### Para Desenvolvedores

1. **NUNCA** commitar arquivos `.secrets`
2. **SEMPRE** usar `ConfigurationManager` para acessar segredos
3. **VALIDAR** configurações no startup da aplicação
4. **ROTACIONAR** chaves de desenvolvimento regularmente
5. **REPORTAR** suspeitas de comprometimento imediatamente

### Para DevOps

1. **MONITORAR** access logs do GitHub Secrets
2. **AUTOMATIZAR** rotações de segredos
3. **MANTER** backups atualizados
4. **TESTAR** procedures de recovery
5. **DOCUMENTAR** todos os procedimentos

### Para Segurança

1. **AUDITAR** acessos mensalmente
2. **REVISAR** configurações trimestralmente
3. **ATUALIZAR** políticas de segurança
4. **TREINAR** equipe em procedures
5. **MANTER** incident response plan atualizado

## 🔗 Recursos Adicionais

- [Secrets Flow Diagram](./secrets_flow.mmd)
- [Security Plan](./SECRETS_MANAGEMENT_PLAN.md)
- [Implementation Guide](../setup/SECRETS_IMPLEMENTATION_GUIDE.md)
- [GitHub Actions Workflows](../../.github/workflows/)

## 📞 Suporte

Para questões relacionadas ao gerenciamento de segredos:

1. **Issues técnicos:** Abrir issue no GitHub com label `secrets-management`
2. **Emergências de segurança:** Notificar equipe de segurança imediatamente
3. **Dúvidas de implementação:** Consultar documentação ou equipe de desenvolvimento

---

**📋 Checklist de Implementação Completa:**

- [x] Scripts de automação com todas as funcionalidades
- [x] ConfigurationManager aprimorado com validação avançada
- [x] Workflows GitHub Actions para CI/CD integrado
- [x] Sistema de backup e recovery criptografado
- [x] Auditoria e monitoramento automatizado
- [x] Rotação segura de segredos
- [x] Documentação completa e guias de uso
- [x] Procedimentos de emergência definidos
- [x] Best practices documentadas
- [x] Health check e métricas implementadas

**🎉 O sistema de gerenciamento de segredos está agora completamente implementado e pronto para uso em produção!**