#!/bin/bash

# Script de Gerenciamento de Segredos - ManusPsiqueia
# Autor: Manus AI
# Data: 22 de setembro de 2025

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações
SECRETS_DIR="Configuration/Secrets"
TEMPLATE_DIR="Configuration/Templates"
KEYCHAIN_SERVICE="com.ailun.manuspsiqueia.secrets"

echo -e "${BLUE}🔐 Gerenciador de Segredos - ManusPsiqueia${NC}"
echo "=============================================="
echo ""

# Função para exibir ajuda
show_help() {
    echo "Uso: $0 [COMANDO] [OPÇÕES]"
    echo ""
    echo "Comandos:"
    echo "  setup       - Configurar estrutura inicial de segredos"
    echo "  validate    - Validar configuração de segredos"
    echo "  encrypt     - Criptografar arquivo de segredos"
    echo "  decrypt     - Descriptografar arquivo de segredos"
    echo "  keychain    - Gerenciar segredos no Keychain"
    echo "  template    - Gerar templates de configuração"
    echo "  clean       - Limpar arquivos temporários"
    echo ""
    echo "Opções:"
    echo "  -e, --env     Ambiente (development|staging|production)"
    echo "  -f, --file    Arquivo específico"
    echo "  -h, --help    Exibir esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  $0 setup"
    echo "  $0 validate --env production"
    echo "  $0 keychain --env staging"
}

# Função para criar estrutura de diretórios
setup_structure() {
    echo -e "${YELLOW}📁 Criando estrutura de diretórios...${NC}"
    
    mkdir -p "$SECRETS_DIR"
    mkdir -p "$TEMPLATE_DIR"
    mkdir -p "Configuration/Environments"
    
    # Criar .gitignore para segredos
    cat > "$SECRETS_DIR/.gitignore" << 'EOF'
# Ignorar todos os arquivos de segredos
*.secrets
*.env
*.key
*.pem
*.p12
*.mobileprovision

# Permitir apenas templates
!*.template
!.gitignore
EOF
    
    echo -e "${GREEN}✅ Estrutura criada com sucesso!${NC}"
}

# Função para criar templates
create_templates() {
    echo -e "${YELLOW}📝 Criando templates de configuração...${NC}"
    
    # Template para desenvolvimento
    cat > "$TEMPLATE_DIR/development.secrets.template" << 'EOF'
# Configurações de Desenvolvimento - ManusPsiqueia
# ATENÇÃO: Este é um template. Copie para development.secrets e preencha os valores reais.

# Stripe Configuration
STRIPE_PUBLISHABLE_KEY=pk_test_your_development_key_here
STRIPE_SECRET_KEY=sk_test_your_development_secret_here

# Supabase Configuration
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_anon_key_here
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key_here

# OpenAI Configuration
OPENAI_API_KEY=your_openai_api_key_here

# Database Configuration
DATABASE_URL=postgresql://user:password@localhost:5432/manuspsiqueia_dev

# Email Configuration
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your_email@gmail.com
SMTP_PASS=your_app_password_here

# Push Notifications
APNS_KEY_ID=your_apns_key_id
APNS_TEAM_ID=your_team_id
APNS_BUNDLE_ID=com.ailun.manuspsiqueia.dev

# Analytics
FIREBASE_CONFIG_FILE=GoogleService-Info-Dev.plist
MIXPANEL_TOKEN=your_mixpanel_token_dev
EOF
    
    # Template para staging
    cat > "$TEMPLATE_DIR/staging.secrets.template" << 'EOF'
# Configurações de Staging - ManusPsiqueia
# ATENÇÃO: Este é um template. Copie para staging.secrets e preencha os valores reais.

# Stripe Configuration
STRIPE_PUBLISHABLE_KEY=pk_test_your_staging_key_here
STRIPE_SECRET_KEY=sk_test_your_staging_secret_here

# Supabase Configuration
SUPABASE_URL=https://your-staging-project.supabase.co
SUPABASE_ANON_KEY=your_staging_anon_key_here
SUPABASE_SERVICE_ROLE_KEY=your_staging_service_role_key_here

# OpenAI Configuration
OPENAI_API_KEY=your_openai_api_key_here

# Database Configuration
DATABASE_URL=postgresql://user:password@staging-db:5432/manuspsiqueia_staging

# Email Configuration
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=staging@ailun.com.br
SMTP_PASS=your_staging_app_password_here

# Push Notifications
APNS_KEY_ID=your_apns_key_id
APNS_TEAM_ID=your_team_id
APNS_BUNDLE_ID=com.ailun.manuspsiqueia.staging

# Analytics
FIREBASE_CONFIG_FILE=GoogleService-Info-Staging.plist
MIXPANEL_TOKEN=your_mixpanel_token_staging
EOF
    
    # Template para produção
    cat > "$TEMPLATE_DIR/production.secrets.template" << 'EOF'
# Configurações de Produção - ManusPsiqueia
# ATENÇÃO: Este é um template. Use GitHub Secrets ou Keychain para valores reais.

# Stripe Configuration
STRIPE_PUBLISHABLE_KEY=pk_live_your_production_key_here
STRIPE_SECRET_KEY=sk_live_your_production_secret_here

# Supabase Configuration
SUPABASE_URL=https://your-production-project.supabase.co
SUPABASE_ANON_KEY=your_production_anon_key_here
SUPABASE_SERVICE_ROLE_KEY=your_production_service_role_key_here

# OpenAI Configuration
OPENAI_API_KEY=your_openai_api_key_here

# Database Configuration
DATABASE_URL=postgresql://user:password@prod-db:5432/manuspsiqueia_production

# Email Configuration
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=contato@ailun.com.br
SMTP_PASS=your_production_app_password_here

# Push Notifications
APNS_KEY_ID=your_apns_key_id
APNS_TEAM_ID=your_team_id
APNS_BUNDLE_ID=com.ailun.manuspsiqueia

# Analytics
FIREBASE_CONFIG_FILE=GoogleService-Info.plist
MIXPANEL_TOKEN=your_mixpanel_token_production
EOF
    
    echo -e "${GREEN}✅ Templates criados com sucesso!${NC}"
}

# Função para validar configuração
validate_secrets() {
    local env=${1:-"development"}
    echo -e "${YELLOW}🔍 Validando configuração para ambiente: $env${NC}"
    
    local secrets_file="$SECRETS_DIR/$env.secrets"
    local template_file="$TEMPLATE_DIR/$env.secrets.template"
    
    if [ ! -f "$secrets_file" ]; then
        echo -e "${RED}❌ Arquivo de segredos não encontrado: $secrets_file${NC}"
        if [ -f "$template_file" ]; then
            echo -e "${YELLOW}💡 Template disponível em: $template_file${NC}"
            echo -e "${YELLOW}   Copie o template e preencha os valores reais.${NC}"
        fi
        return 1
    fi
    
    # Verificar se há valores de template não preenchidos
    local template_values=$(grep -E "(your_|here|template)" "$secrets_file" || true)
    if [ ! -z "$template_values" ]; then
        echo -e "${RED}❌ Valores de template encontrados (não preenchidos):${NC}"
        echo "$template_values"
        return 1
    fi
    
    # Verificar variáveis obrigatórias
    local required_vars=("STRIPE_PUBLISHABLE_KEY" "SUPABASE_URL" "OPENAI_API_KEY")
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if ! grep -q "^$var=" "$secrets_file"; then
            missing_vars+=("$var")
        fi
    done
    
    if [ ${#missing_vars[@]} -gt 0 ]; then
        echo -e "${RED}❌ Variáveis obrigatórias não encontradas:${NC}"
        printf '%s\n' "${missing_vars[@]}"
        return 1
    fi
    
    echo -e "${GREEN}✅ Configuração válida para $env!${NC}"
}

# Função para gerenciar Keychain
manage_keychain() {
    local env=${1:-"development"}
    echo -e "${YELLOW}🔑 Gerenciando Keychain para ambiente: $env${NC}"
    
    local secrets_file="$SECRETS_DIR/$env.secrets"
    
    if [ ! -f "$secrets_file" ]; then
        echo -e "${RED}❌ Arquivo de segredos não encontrado: $secrets_file${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Importando segredos para o Keychain...${NC}"
    
    # Ler arquivo de segredos e importar para Keychain
    while IFS='=' read -r key value; do
        # Ignorar comentários e linhas vazias
        if [[ $key =~ ^[[:space:]]*# ]] || [[ -z $key ]]; then
            continue
        fi
        
        # Remover espaços em branco
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)
        
        if [ ! -z "$key" ] && [ ! -z "$value" ]; then
            # Adicionar ao Keychain
            security add-generic-password \
                -a "$key" \
                -s "$KEYCHAIN_SERVICE.$env" \
                -w "$value" \
                -U 2>/dev/null || \
            security delete-generic-password \
                -a "$key" \
                -s "$KEYCHAIN_SERVICE.$env" 2>/dev/null && \
            security add-generic-password \
                -a "$key" \
                -s "$KEYCHAIN_SERVICE.$env" \
                -w "$value" \
                -U
            
            echo -e "${GREEN}✅ $key adicionado ao Keychain${NC}"
        fi
    done < "$secrets_file"
    
    echo -e "${GREEN}✅ Segredos importados para o Keychain!${NC}"
}

# Função para criptografar arquivo
encrypt_file() {
    local file=$1
    
    if [ -z "$file" ]; then
        echo -e "${RED}❌ Arquivo não especificado${NC}"
        return 1
    fi
    
    if [ ! -f "$file" ]; then
        echo -e "${RED}❌ Arquivo não encontrado: $file${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}🔒 Criptografando arquivo: $file${NC}"
    
    # Usar OpenSSL para criptografar
    openssl enc -aes-256-cbc -salt -in "$file" -out "$file.enc"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Arquivo criptografado: $file.enc${NC}"
        echo -e "${YELLOW}⚠️  Remova o arquivo original se necessário${NC}"
    else
        echo -e "${RED}❌ Erro ao criptografar arquivo${NC}"
        return 1
    fi
}

# Função para descriptografar arquivo
decrypt_file() {
    local file=$1
    
    if [ -z "$file" ]; then
        echo -e "${RED}❌ Arquivo não especificado${NC}"
        return 1
    fi
    
    if [ ! -f "$file" ]; then
        echo -e "${RED}❌ Arquivo não encontrado: $file${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}🔓 Descriptografando arquivo: $file${NC}"
    
    # Remover extensão .enc para o arquivo de saída
    local output_file="${file%.enc}"
    
    # Usar OpenSSL para descriptografar
    openssl enc -aes-256-cbc -d -in "$file" -out "$output_file"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Arquivo descriptografado: $output_file${NC}"
    else
        echo -e "${RED}❌ Erro ao descriptografar arquivo${NC}"
        return 1
    fi
}

# Função para limpar arquivos temporários
clean_temp_files() {
    echo -e "${YELLOW}🧹 Limpando arquivos temporários...${NC}"
    
    # Remover arquivos temporários
    find . -name "*.tmp" -delete
    find . -name "*.temp" -delete
    find . -name ".DS_Store" -delete
    
    # Limpar cache do Xcode
    if [ -d ~/Library/Developer/Xcode/DerivedData ]; then
        echo -e "${BLUE}Limpando cache do Xcode...${NC}"
        rm -rf ~/Library/Developer/Xcode/DerivedData/*
    fi
    
    echo -e "${GREEN}✅ Limpeza concluída!${NC}"
}

# Função principal
main() {
    local command=$1
    shift
    
    case $command in
        "setup")
            setup_structure
            create_templates
            ;;
        "validate")
            local env="development"
            while [[ $# -gt 0 ]]; do
                case $1 in
                    -e|--env)
                        env="$2"
                        shift 2
                        ;;
                    *)
                        shift
                        ;;
                esac
            done
            validate_secrets "$env"
            ;;
        "keychain")
            local env="development"
            while [[ $# -gt 0 ]]; do
                case $1 in
                    -e|--env)
                        env="$2"
                        shift 2
                        ;;
                    *)
                        shift
                        ;;
                esac
            done
            manage_keychain "$env"
            ;;
        "encrypt")
            local file=""
            while [[ $# -gt 0 ]]; do
                case $1 in
                    -f|--file)
                        file="$2"
                        shift 2
                        ;;
                    *)
                        shift
                        ;;
                esac
            done
            encrypt_file "$file"
            ;;
        "decrypt")
            local file=""
            while [[ $# -gt 0 ]]; do
                case $1 in
                    -f|--file)
                        file="$2"
                        shift 2
                        ;;
                    *)
                        shift
                        ;;
                esac
            done
            decrypt_file "$file"
            ;;
        "template")
            create_templates
            ;;
        "clean")
            clean_temp_files
            ;;
        "help"|"-h"|"--help"|"")
            show_help
            ;;
        *)
            echo -e "${RED}❌ Comando desconhecido: $command${NC}"
            show_help
            exit 1
            ;;
    esac
}

# Executar função principal com todos os argumentos
main "$@"
