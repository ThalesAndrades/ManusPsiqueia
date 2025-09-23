#!/bin/sh

#  ci_post_xcodebuild.sh
#  ManusPsiqueia
#
#  Script executado pelo Xcode Cloud após o build
#  Created by Manus AI on 2025-09-22.

set -e

echo "🎉 Iniciando configuração pós-build para Xcode Cloud..."

# Definir variáveis de ambiente
export CI_XCODE_CLOUD=true
export BUILD_NUMBER=${CI_BUILD_NUMBER:-1}

echo "📋 Build Number: $BUILD_NUMBER"
echo "🔧 Xcode Version: $CI_XCODE_VERSION"
echo "📱 Platform: $CI_PLATFORM"
echo "🎯 Workflow: $CI_WORKFLOW"
echo "✅ Build Status: $CI_BUILD_RESULT"

# Verificar se o build foi bem-sucedido
if [ "$CI_BUILD_RESULT" = "SUCCEEDED" ]; then
    echo "✅ Build concluído com sucesso!"
else
    echo "❌ Build falhou com status: $CI_BUILD_RESULT"
    exit 1
fi

# Configurar ambiente baseado no workflow
case "$CI_WORKFLOW" in
    "Development")
        echo "🔧 Processando build de Development"
        export BUILD_TYPE="Development"
        ;;
    "Staging")
        echo "🧪 Processando build de Staging"
        export BUILD_TYPE="Staging"
        ;;
    "Production")
        echo "🚀 Processando build de Production"
        export BUILD_TYPE="Production"
        ;;
    *)
        echo "⚠️ Workflow não reconhecido: $CI_WORKFLOW"
        export BUILD_TYPE="Unknown"
        ;;
esac

# Verificar artefatos do build
echo "📦 Verificando artefatos do build..."

# Verificar se o app foi gerado
if [ -d "$CI_APP_STORE_SIGNED_APP_PATH" ]; then
    echo "✅ App assinado encontrado: $CI_APP_STORE_SIGNED_APP_PATH"
    
    # Obter informações do app
    app_size=$(du -sh "$CI_APP_STORE_SIGNED_APP_PATH" | cut -f1)
    echo "📊 Tamanho do app: $app_size"
else
    echo "⚠️ App assinado não encontrado"
fi

# Verificar se há arquivo IPA
if [ -f "$CI_AD_HOC_SIGNED_APP_PATH" ]; then
    echo "✅ IPA Ad Hoc encontrado: $CI_AD_HOC_SIGNED_APP_PATH"
elif [ -f "$CI_APP_STORE_SIGNED_APP_PATH" ]; then
    echo "✅ IPA App Store encontrado: $CI_APP_STORE_SIGNED_APP_PATH"
fi

# Gerar relatório de build
echo "📄 Gerando relatório de build..."

# Verificar se CI_DERIVED_DATA_PATH está definido, caso contrário usar diretório temporário
if [ -z "$CI_DERIVED_DATA_PATH" ]; then
    CI_DERIVED_DATA_PATH="/tmp/xcode_cloud_fallback"
    echo "⚠️ CI_DERIVED_DATA_PATH não definido, usando: $CI_DERIVED_DATA_PATH"
    mkdir -p "$CI_DERIVED_DATA_PATH"
fi

build_report_file="$CI_DERIVED_DATA_PATH/build_report.txt"
cat > "$build_report_file" << EOF
=== RELATÓRIO DE BUILD - MANUSPSIQUEIA ===

Data/Hora: $(date)
Build Number: $BUILD_NUMBER
Workflow: $CI_WORKFLOW
Tipo de Build: $BUILD_TYPE
Status: $CI_BUILD_RESULT
Xcode Version: $CI_XCODE_VERSION
Platform: $CI_PLATFORM

=== CONFIGURAÇÕES ===
Marketing Version: 1.0.0
Bundle Identifier: com.ailun.manuspsiqueia
Deployment Target: iOS 16.0

=== ARTEFATOS ===
EOF

# Adicionar informações dos artefatos ao relatório
if [ -d "$CI_APP_STORE_SIGNED_APP_PATH" ]; then
    echo "App Store Signed: ✅ Disponível" >> "$build_report_file"
    echo "Tamanho: $(du -sh "$CI_APP_STORE_SIGNED_APP_PATH" | cut -f1)" >> "$build_report_file"
else
    echo "App Store Signed: ❌ Não disponível" >> "$build_report_file"
fi

if [ -f "$CI_AD_HOC_SIGNED_APP_PATH" ]; then
    echo "Ad Hoc Signed: ✅ Disponível" >> "$build_report_file"
else
    echo "Ad Hoc Signed: ❌ Não disponível" >> "$build_report_file"
fi

echo "" >> "$build_report_file"
echo "=== PRÓXIMOS PASSOS ===" >> "$build_report_file"

case "$BUILD_TYPE" in
    "Development")
        echo "- Build de desenvolvimento concluído" >> "$build_report_file"
        echo "- Disponível para testes internos" >> "$build_report_file"
        ;;
    "Staging")
        echo "- Build de staging pronto para TestFlight" >> "$build_report_file"
        echo "- Pode ser distribuído para testadores beta" >> "$build_report_file"
        ;;
    "Production")
        echo "- Build de produção pronto para App Store" >> "$build_report_file"
        echo "- Pode ser submetido para revisão da Apple" >> "$build_report_file"
        ;;
esac

echo "✅ Relatório de build gerado: $build_report_file"

# Executar validações pós-build
echo "🔍 Executando validações pós-build..."

# Verificar se o app contém as configurações corretas
if [ -d "$CI_APP_STORE_SIGNED_APP_PATH" ]; then
    app_path="$CI_APP_STORE_SIGNED_APP_PATH"
    
    # Verificar Info.plist do app
    info_plist="$app_path/Info.plist"
    if [ -f "$info_plist" ]; then
        echo "✅ Info.plist encontrado no app"
        
        # Verificar bundle identifier
        bundle_id=$(plutil -p "$info_plist" | grep CFBundleIdentifier | cut -d'"' -f4)
        echo "📱 Bundle ID: $bundle_id"
        
        # Verificar versão
        version=$(plutil -p "$info_plist" | grep CFBundleShortVersionString | cut -d'"' -f4)
        build_version=$(plutil -p "$info_plist" | grep CFBundleVersion | cut -d'"' -f4)
        echo "📊 Versão: $version ($build_version)"
    fi
fi

# Preparar notificações (se configuradas)
echo "📢 Preparando notificações..."

case "$BUILD_TYPE" in
    "Staging")
        echo "🧪 Build de Staging concluído - Pronto para TestFlight"
        ;;
    "Production")
        echo "🚀 Build de Produção concluído - Pronto para App Store"
        ;;
esac

# Limpar arquivos temporários
echo "🧹 Limpando arquivos temporários..."
rm -rf /tmp/xcode_cloud_* 2>/dev/null || true

# Finalizar
echo "✅ Configuração pós-build concluída com sucesso!"
echo "🎯 Build $BUILD_NUMBER do $BUILD_TYPE está pronto!"

# Exibir resumo final
echo ""
echo "=== RESUMO FINAL ==="
echo "📱 App: ManusPsiqueia"
echo "🏷️ Versão: 1.0.0 ($BUILD_NUMBER)"
echo "🎯 Tipo: $BUILD_TYPE"
echo "✅ Status: Sucesso"
echo "📅 Data: $(date)"

exit 0
