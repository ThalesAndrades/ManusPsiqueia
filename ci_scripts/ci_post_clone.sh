#!/bin/bash

#  ci_post_clone.sh
#  ManusPsiqueia
#
#  Script executado pelo Xcode Cloud após o clone do repositório
#  Created by Manus AI on 2025-09-22.

set -e

echo "🚀 Iniciando configuração pós-clone para Xcode Cloud..."

# Definir variáveis de ambiente
export CI_XCODE_CLOUD=true
export BUILD_NUMBER=${CI_BUILD_NUMBER:-1}

echo "📋 Build Number: $BUILD_NUMBER"
echo "🔧 Xcode Version: $CI_XCODE_VERSION"
echo "📱 Platform: $CI_PLATFORM"

# Verificar se estamos no ambiente correto
if [ "$CI_XCODE_CLOUD" = "true" ]; then
    echo "✅ Executando no Xcode Cloud"
else
    echo "⚠️ Não está executando no Xcode Cloud"
fi

# Configurar ambiente baseado no workflow
case "$CI_WORKFLOW" in
    "Development")
        echo "🔧 Configurando ambiente de Development"
        export BUILD_ENVIRONMENT="Development"
        export CONFIG_FILE="Configuration/Development.xcconfig"
        ;;
    "Staging")
        echo "🧪 Configurando ambiente de Staging"
        export BUILD_ENVIRONMENT="Staging"
        export CONFIG_FILE="Configuration/Staging.xcconfig"
        ;;
    "Production")
        echo "🚀 Configurando ambiente de Production"
        export BUILD_ENVIRONMENT="Production"
        export CONFIG_FILE="Configuration/Production.xcconfig"
        ;;
    *)
        echo "⚠️ Workflow não reconhecido: $CI_WORKFLOW"
        echo "🔧 Usando configuração padrão (Development)"
        export BUILD_ENVIRONMENT="Development"
        export CONFIG_FILE="Configuration/Development.xcconfig"
        ;;
esac

# Verificar se o arquivo de configuração existe
if [ -f "$CONFIG_FILE" ]; then
    echo "✅ Arquivo de configuração encontrado: $CONFIG_FILE"
else
    echo "❌ Arquivo de configuração não encontrado: $CONFIG_FILE"
    exit 1
fi

# Configurar variáveis de ambiente para build
echo "🔐 Configurando variáveis de ambiente..."

# Definir BUILD_NUMBER no ambiente (se CI_DERIVED_DATA_PATH estiver disponível)
if [ -n "$CI_DERIVED_DATA_PATH" ] && [ -d "$CI_DERIVED_DATA_PATH" ]; then
    echo "export BUILD_NUMBER=$BUILD_NUMBER" >> "$CI_DERIVED_DATA_PATH/environment.sh"
    echo "✅ Variáveis de ambiente salvas em $CI_DERIVED_DATA_PATH/environment.sh"
else
    echo "⚠️ CI_DERIVED_DATA_PATH não disponível, pulando salvamento de variáveis"
fi

# Verificar se as variáveis de ambiente necessárias estão definidas
check_env_var() {
    local var_name=$1
    local var_value=$(eval echo \$$var_name)
    
    if [ -z "$var_value" ]; then
        echo "⚠️ Variável de ambiente não definida: $var_name"
        return 1
    else
        echo "✅ $var_name está definida"
        return 0
    fi
}

# Lista de variáveis obrigatórias baseadas no ambiente
case "$BUILD_ENVIRONMENT" in
    "Development")
        ENV_VARS="STRIPE_PUBLISHABLE_KEY_DEV SUPABASE_URL_DEV SUPABASE_ANON_KEY_DEV OPENAI_API_KEY_DEV"
        ;;
    "Staging")
        ENV_VARS="STRIPE_PUBLISHABLE_KEY_STAGING SUPABASE_URL_STAGING SUPABASE_ANON_KEY_STAGING OPENAI_API_KEY_STAGING"
        ;;
    "Production")
        ENV_VARS="STRIPE_PUBLISHABLE_KEY_PROD SUPABASE_URL_PROD SUPABASE_ANON_KEY_PROD OPENAI_API_KEY_PROD"
        ;;
esac

# Verificar variáveis obrigatórias (modo não-bloqueante para CI/CD)
missing_vars=0
for var in $ENV_VARS; do
    if ! check_env_var $var; then
        missing_vars=$((missing_vars + 1))
    fi
done

# Verificar DEVELOPMENT_TEAM_ID
if ! check_env_var "DEVELOPMENT_TEAM_ID"; then
    missing_vars=$((missing_vars + 1))
fi

if [ $missing_vars -gt 0 ]; then
    echo "⚠️ $missing_vars variável(is) de ambiente não definida(s)"
    echo "📋 Configure as variáveis no Xcode Cloud Environment Variables para build completo"
    echo "🔄 Continuando com configuração básica para permitir setup inicial..."
fi

# Verificar estrutura do projeto
echo "📁 Verificando estrutura do projeto..."

required_files=(
    "ManusPsiqueia.xcodeproj"
    "Package.swift"
    "ManusPsiqueia/Info.plist"
    "$CONFIG_FILE"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ] || [ -d "$file" ]; then
        echo "✅ $file encontrado"
    else
        echo "❌ $file não encontrado"
        exit 1
    fi
done

# Verificar módulos Swift Package
echo "📦 Verificando módulos Swift Package..."

if [ -d "Modules" ]; then
    echo "✅ Diretório Modules encontrado"
    
    module_count=$(find Modules -name "Package.swift" | wc -l)
    echo "📊 $module_count módulo(s) encontrado(s)"
    
    if [ $module_count -eq 0 ]; then
        echo "⚠️ Nenhum módulo Swift Package encontrado"
    fi
else
    echo "⚠️ Diretório Modules não encontrado"
fi

# Configurar permissões se necessário
echo "🔐 Configurando permissões..."
chmod +x ci_scripts/*.sh 2>/dev/null || true

# Verificar se há scripts adicionais
if [ -f "scripts/secrets_manager.sh" ]; then
    echo "✅ Script de gestão de segredos encontrado"
    chmod +x scripts/secrets_manager.sh
fi

# Log de informações do sistema
echo "💻 Informações do sistema:"
echo "  - Xcode Version: $CI_XCODE_VERSION"
if command -v sw_vers >/dev/null 2>&1; then
    echo "  - macOS Version: $(sw_vers -productVersion)"
else
    echo "  - macOS Version: N/A (not running on macOS)"
fi
echo "  - Build Environment: $BUILD_ENVIRONMENT"
echo "  - Build Number: $BUILD_NUMBER"

# Finalizar configuração
echo "✅ Configuração pós-clone concluída com sucesso!"
echo "🚀 Pronto para build no ambiente: $BUILD_ENVIRONMENT"

exit 0
