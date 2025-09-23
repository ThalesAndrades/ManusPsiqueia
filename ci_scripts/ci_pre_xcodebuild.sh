#!/bin/sh

#  ci_pre_xcodebuild.sh
#  ManusPsiqueia
#
#  Script executado pelo Xcode Cloud antes do build
#  Created by Manus AI on 2025-09-22.

set -e

echo "🔧 Iniciando configuração pré-build para Xcode Cloud..."

# Definir variáveis de ambiente
export BUILD_ENVIRONMENT=${BUILD_ENVIRONMENT:-"Development"}
export BUILD_NUMBER=${CI_BUILD_NUMBER:-1}

echo "📋 Ambiente: $BUILD_ENVIRONMENT"
echo "📋 Build Number: $BUILD_NUMBER"

# Função para verificar variável de ambiente
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

# Verificar DEVELOPMENT_TEAM_ID (obrigatório)
if check_env_var "DEVELOPMENT_TEAM_ID"; then
    echo "✅ Team ID configurado"
else
    echo "❌ DEVELOPMENT_TEAM_ID não configurado"
    echo "📋 Configure no Xcode Cloud Environment Variables"
    exit 1
fi

# Configurar variáveis específicas do ambiente
case "$BUILD_ENVIRONMENT" in
    "Development")
        echo "🔧 Configurando variáveis para Development"
        # Usar valores padrão se não estiverem definidos
        export STRIPE_PUBLISHABLE_KEY=${STRIPE_PUBLISHABLE_KEY_DEV:-"pk_test_placeholder"}
        export SUPABASE_URL=${SUPABASE_URL_DEV:-"https://placeholder.supabase.co"}
        export SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY_DEV:-"placeholder_anon_key"}
        export OPENAI_API_KEY=${OPENAI_API_KEY_DEV:-"placeholder_openai_key"}
        ;;
    "Staging")
        echo "🧪 Configurando variáveis para Staging"
        export STRIPE_PUBLISHABLE_KEY=${STRIPE_PUBLISHABLE_KEY_STAGING:-"pk_test_placeholder"}
        export SUPABASE_URL=${SUPABASE_URL_STAGING:-"https://placeholder.supabase.co"}
        export SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY_STAGING:-"placeholder_anon_key"}
        export OPENAI_API_KEY=${OPENAI_API_KEY_STAGING:-"placeholder_openai_key"}
        ;;
    "Production")
        echo "🚀 Configurando variáveis para Production"
        export STRIPE_PUBLISHABLE_KEY=${STRIPE_PUBLISHABLE_KEY_PROD:-"pk_live_placeholder"}
        export SUPABASE_URL=${SUPABASE_URL_PROD:-"https://placeholder.supabase.co"}
        export SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY_PROD:-"placeholder_anon_key"}
        export OPENAI_API_KEY=${OPENAI_API_KEY_PROD:-"placeholder_openai_key"}
        ;;
esac

# Verificar se as chaves são placeholders
if [[ "$STRIPE_PUBLISHABLE_KEY" == *"placeholder"* ]]; then
    echo "⚠️ Usando chave Stripe placeholder"
fi

if [[ "$SUPABASE_URL" == *"placeholder"* ]]; then
    echo "⚠️ Usando URL Supabase placeholder"
fi

if [[ "$OPENAI_API_KEY" == *"placeholder"* ]]; then
    echo "⚠️ Usando chave OpenAI placeholder"
fi

# Configurar variáveis de build adicionais
export DEBUG_BUILD="NO"
if [ "$BUILD_ENVIRONMENT" = "Development" ]; then
    export DEBUG_BUILD="YES"
fi

echo "🔐 Variáveis de ambiente configuradas:"
echo "  - BUILD_ENVIRONMENT: $BUILD_ENVIRONMENT"
echo "  - DEBUG_BUILD: $DEBUG_BUILD"
echo "  - BUILD_NUMBER: $BUILD_NUMBER"

# Verificar se o projeto pode ser buildado
echo "🔍 Verificando configuração do projeto..."

# Verificar se o arquivo de projeto existe
if [ -f "ManusPsiqueia.xcodeproj/project.pbxproj" ]; then
    echo "✅ Projeto Xcode encontrado"
else
    echo "❌ Arquivo de projeto não encontrado"
    exit 1
fi

# Verificar se Info.plist existe
if [ -f "ManusPsiqueia/Info.plist" ]; then
    echo "✅ Info.plist encontrado"
else
    echo "❌ Info.plist não encontrado"
    exit 1
fi

# Verificar dependências do Package.swift
if [ -f "Package.swift" ]; then
    echo "📦 Package.swift encontrado"
    
    # Verificar se há dependências problemáticas
    if grep -q "stripe-ios" Package.swift; then
        echo "✅ Dependência Stripe encontrada"
    fi
    
    if grep -q "supabase-swift" Package.swift; then
        echo "✅ Dependência Supabase encontrada"
    fi
    
    if grep -q "OpenAI" Package.swift; then
        echo "✅ Dependência OpenAI encontrada"
    fi
else
    echo "⚠️ Package.swift não encontrado"
fi

# Limpar cache se necessário
echo "🧹 Limpando cache..."
rm -rf ~/Library/Developer/Xcode/DerivedData/* 2>/dev/null || true

echo "✅ Configuração pré-build concluída com sucesso!"
echo "🚀 Pronto para iniciar build do projeto"

exit 0
