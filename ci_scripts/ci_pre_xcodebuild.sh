#!/bin/sh

#  ci_pre_xcodebuild.sh
#  ManusPsiqueia
#
#  Script executado pelo Xcode Cloud antes do build
#  Created by Manus AI on 2025-09-22.

set -e

echo "🔨 Iniciando configuração pré-build para Xcode Cloud..."

# Definir variáveis de ambiente
export CI_XCODE_CLOUD=true
export BUILD_NUMBER=${CI_BUILD_NUMBER:-1}

echo "📋 Build Number: $BUILD_NUMBER"
echo "🔧 Xcode Version: $CI_XCODE_VERSION"
echo "📱 Platform: $CI_PLATFORM"
echo "🎯 Workflow: $CI_WORKFLOW"

# Configurar ambiente baseado no workflow
case "$CI_WORKFLOW" in
    "Development")
        echo "🔧 Preparando build de Development"
        export BUILD_CONFIGURATION="Debug"
        export XCCONFIG_FILE="Configuration/Development.xcconfig"
        ;;
    "Staging")
        echo "🧪 Preparando build de Staging"
        export BUILD_CONFIGURATION="Release"
        export XCCONFIG_FILE="Configuration/Staging.xcconfig"
        ;;
    "Production")
        echo "🚀 Preparando build de Production"
        export BUILD_CONFIGURATION="Release"
        export XCCONFIG_FILE="Configuration/Production.xcconfig"
        ;;
    "Psiqueia")
        echo "🔧 Preparando build principal (Psiqueia -> Development)"
        export BUILD_CONFIGURATION="Debug"
        export XCCONFIG_FILE="Configuration/Development.xcconfig"
        ;;
    *)
        echo "⚠️ Workflow não reconhecido: $CI_WORKFLOW"
        echo "🔧 Usando configuração padrão (Development)"
        export BUILD_CONFIGURATION="Debug"
        export XCCONFIG_FILE="Configuration/Development.xcconfig"
        ;;
esac

# Verificar se o arquivo xcconfig existe
echo "🔍 Diretório de trabalho atual: $(pwd)"
echo "🔍 Verificando arquivo xcconfig: $XCCONFIG_FILE"
echo "🔍 Arquivos na raiz do projeto:"
ls -la | head -10

if [ -f "$XCCONFIG_FILE" ]; then
    echo "✅ Arquivo xcconfig encontrado: $XCCONFIG_FILE"
else
    echo "❌ Arquivo xcconfig não encontrado: $XCCONFIG_FILE"
    echo "🔍 Conteúdo do diretório Configuration:"
    ls -la Configuration/ 2>/dev/null || echo "❌ Diretório Configuration não encontrado"
    echo "🔍 Tentando caminhos alternativos..."
    if [ -f "./Configuration/Development.xcconfig" ]; then
        echo "✅ Encontrado em: ./Configuration/Development.xcconfig"
        export XCCONFIG_FILE="./Configuration/Development.xcconfig"
    elif [ -f "../Configuration/Development.xcconfig" ]; then
        echo "✅ Encontrado em: ../Configuration/Development.xcconfig"
        export XCCONFIG_FILE="../Configuration/Development.xcconfig"
    else
        echo "❌ Arquivo não encontrado em nenhum caminho testado"
        exit 1
    fi
fi

# Função para validar variável de ambiente
validate_env_var() {
    local var_name=$1
    local var_value=$(eval echo \$$var_name)
    
    if [ -z "$var_value" ]; then
        echo "❌ ERRO: Variável de ambiente obrigatória não definida: $var_name"
        return 1
    else
        echo "✅ $var_name: [DEFINIDA]"
        return 0
    fi
}

# Validar variáveis obrigatórias
echo "🔐 Validando variáveis de ambiente obrigatórias..."

# Team ID é sempre obrigatório
if ! validate_env_var "DEVELOPMENT_TEAM_ID"; then
    echo "📋 Configure DEVELOPMENT_TEAM_ID no Xcode Cloud"
    exit 1
fi

# Validar variáveis específicas do ambiente
case "$CI_WORKFLOW" in
    "Development")
        required_vars="STRIPE_PUBLISHABLE_KEY_DEV SUPABASE_URL_DEV SUPABASE_ANON_KEY_DEV OPENAI_API_KEY_DEV"
        ;;
    "Staging")
        required_vars="STRIPE_PUBLISHABLE_KEY_STAGING SUPABASE_URL_STAGING SUPABASE_ANON_KEY_STAGING OPENAI_API_KEY_STAGING"
        ;;
    "Production")
        required_vars="STRIPE_PUBLISHABLE_KEY_PROD SUPABASE_URL_PROD SUPABASE_ANON_KEY_PROD OPENAI_API_KEY_PROD"
        ;;
    "Psiqueia")
        required_vars="STRIPE_PUBLISHABLE_KEY_DEV SUPABASE_URL_DEV SUPABASE_ANON_KEY_DEV OPENAI_API_KEY_DEV"
        ;;
    *)
        required_vars="STRIPE_PUBLISHABLE_KEY_DEV SUPABASE_URL_DEV SUPABASE_ANON_KEY_DEV OPENAI_API_KEY_DEV"
        ;;
esac

validation_failed=false
for var in $required_vars; do
    if ! validate_env_var $var; then
        validation_failed=true
    fi
done

if [ "$validation_failed" = true ]; then
    echo "❌ Validação de variáveis de ambiente falhou"
    echo "📋 Configure as variáveis no Xcode Cloud Environment Variables:"
    echo "   Settings > Environment Variables"
    exit 1
fi

# Configurar variáveis derivadas
echo "⚙️ Configurando variáveis derivadas..."

# Definir BUILD_NUMBER para o build
export CURRENT_PROJECT_VERSION=$BUILD_NUMBER
echo "✅ CURRENT_PROJECT_VERSION=$CURRENT_PROJECT_VERSION"

# Definir MARKETING_VERSION
export MARKETING_VERSION="1.0.0"
echo "✅ MARKETING_VERSION=$MARKETING_VERSION"

# Verificar dependências do projeto
echo "📦 Verificando dependências do projeto..."

# Verificar Package.swift
if [ -f "Package.swift" ]; then
    echo "✅ Package.swift encontrado"
    
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

# Verificar módulos locais
if [ -d "Modules" ]; then
    echo "✅ Diretório Modules encontrado"
    
    # Listar módulos disponíveis
    for module_dir in Modules/*/; do
        if [ -d "$module_dir" ]; then
            module_name=$(basename "$module_dir")
            echo "  📦 Módulo: $module_name"
            
            # Verificar se o módulo tem Package.swift
            if [ -f "$module_dir/Package.swift" ]; then
                echo "    ✅ Package.swift válido"
            else
                echo "    ⚠️ Package.swift não encontrado"
            fi
        fi
    done
fi

# Verificar Info.plist
echo "📱 Verificando Info.plist..."
if [ -f "ManusPsiqueia/Info.plist" ]; then
    echo "✅ Info.plist encontrado"
    
    # Verificar se contém as configurações necessárias
    if grep -q "STRIPE_PUBLISHABLE_KEY" ManusPsiqueia/Info.plist; then
        echo "✅ Configuração Stripe encontrada no Info.plist"
    fi
    
    if grep -q "SUPABASE_URL" ManusPsiqueia/Info.plist; then
        echo "✅ Configuração Supabase encontrada no Info.plist"
    fi
else
    echo "❌ Info.plist não encontrado"
    exit 1
fi

# Preparar ambiente para build
echo "🔧 Preparando ambiente para build..."

# Criar diretório de logs se não existir
mkdir -p "$CI_DERIVED_DATA_PATH/Logs" 2>/dev/null || true

# Salvar configurações do build
cat > "$CI_DERIVED_DATA_PATH/build_config.txt" << EOF
Build Configuration: $BUILD_CONFIGURATION
Workflow: $CI_WORKFLOW
Build Number: $BUILD_NUMBER
Marketing Version: $MARKETING_VERSION
XCConfig File: $XCCONFIG_FILE
Timestamp: $(date)
EOF

echo "✅ Configuração pré-build concluída com sucesso!"
echo "🚀 Pronto para iniciar build do ManusPsiqueia"

exit 0
