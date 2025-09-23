#!/bin/bash

#  validate_imports.sh
#  ManusPsiqueia
#
#  Script para validar imports de módulos locais e estrutura do projeto
#  Created by Manus AI on 2025-09-23.

set -e

echo "🔍 Validando imports de módulos locais..."
echo "=================================================="

# Obter o diretório do script e navegar para a raiz do projeto
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
PROJECT_ROOT="$SCRIPT_DIR/.."
cd "$PROJECT_ROOT"

echo "📁 Diretório de trabalho: $(pwd)"

# Verificar se os módulos existem
MODULES_DIR="Modules"
UI_MODULE="$MODULES_DIR/ManusPsiqueiaUI"
SERVICES_MODULE="$MODULES_DIR/ManusPsiqueiaServices"

echo ""
echo "📦 Verificando módulos locais..."

if [ ! -d "$UI_MODULE" ]; then
    echo "❌ Módulo ManusPsiqueiaUI não encontrado em $UI_MODULE"
    exit 1
else
    echo "✅ Módulo ManusPsiqueiaUI encontrado"
    UI_FILES=$(find "$UI_MODULE" -name "*.swift" | wc -l)
    echo "   📊 $UI_FILES arquivo(s) Swift no módulo UI"
fi

if [ ! -d "$SERVICES_MODULE" ]; then
    echo "❌ Módulo ManusPsiqueiaServices não encontrado em $SERVICES_MODULE"
    exit 1
else
    echo "✅ Módulo ManusPsiqueiaServices encontrado"
    SERVICES_FILES=$(find "$SERVICES_MODULE" -name "*.swift" | wc -l)
    echo "   📊 $SERVICES_FILES arquivo(s) Swift no módulo Services"
fi

# Verificar Package.swift dos módulos
echo ""
echo "📋 Verificando Package.swift dos módulos..."

if [ -f "$UI_MODULE/Package.swift" ]; then
    echo "✅ Package.swift do ManusPsiqueiaUI encontrado"
else
    echo "❌ Package.swift do ManusPsiqueiaUI não encontrado"
fi

if [ -f "$SERVICES_MODULE/Package.swift" ]; then
    echo "✅ Package.swift do ManusPsiqueiaServices encontrado"
else
    echo "❌ Package.swift do ManusPsiqueiaServices não encontrado"
fi

# Verificar arquivos com imports problemáticos
echo ""
echo "🔍 Verificando imports de módulos locais..."

PROBLEMATIC_IMPORTS=$(grep -r "import ManusPsiqueia" ManusPsiqueia/ --include="*.swift" 2>/dev/null | wc -l)

if [ $PROBLEMATIC_IMPORTS -gt 0 ]; then
    echo "📊 $PROBLEMATIC_IMPORTS arquivo(s) com imports de módulos locais"
    echo ""
    echo "📋 Arquivos afetados:"
    grep -r "import ManusPsiqueia" ManusPsiqueia/ --include="*.swift" 2>/dev/null | cut -d: -f1 | sort | uniq | while read file; do
        echo "   - $file"
    done
    echo ""
    echo "✅ Imports de módulos locais são esperados e corretos"
else
    echo "⚠️ Nenhum import de módulo local encontrado"
    echo "   Isso pode indicar que os imports não foram aplicados corretamente"
fi

# Verificar estrutura do projeto principal
echo ""
echo "📁 Verificando estrutura do projeto principal..."

MAIN_SWIFT_FILES=$(find ManusPsiqueia/ -name "*.swift" | wc -l)
echo "📊 $MAIN_SWIFT_FILES arquivo(s) Swift no projeto principal"

# Verificar se Package.swift principal tem seção targets
echo ""
echo "📋 Verificando Package.swift principal..."

if grep -q "targets:" Package.swift; then
    echo "✅ Package.swift contém seção targets"
    
    if grep -q "ManusPsiqueiaUI" Package.swift; then
        echo "✅ ManusPsiqueiaUI está listado como dependência"
    else
        echo "❌ ManusPsiqueiaUI não está listado como dependência"
    fi
    
    if grep -q "ManusPsiqueiaServices" Package.swift; then
        echo "✅ ManusPsiqueiaServices está listado como dependência"
    else
        echo "❌ ManusPsiqueiaServices não está listado como dependência"
    fi
else
    echo "❌ Package.swift não contém seção targets"
    echo "   Isso causará falha na resolução de dependências"
fi

# Verificar arquivos críticos
echo ""
echo "🔍 Verificando arquivos críticos..."

CRITICAL_FILES=(
    "ManusPsiqueia.xcodeproj"
    "Package.swift"
    "ManusPsiqueia/Info.plist"
    "Configuration/Development.xcconfig"
    "Configuration/Staging.xcconfig"
    "Configuration/Production.xcconfig"
)

for file in "${CRITICAL_FILES[@]}"; do
    if [ -f "$file" ] || [ -d "$file" ]; then
        echo "✅ $file encontrado"
    else
        echo "❌ $file não encontrado"
    fi
done

# Resumo final
echo ""
echo "=================================================="
echo "🎯 Resumo da Validação:"
echo ""

TOTAL_MODULES=2
FOUND_MODULES=0

if [ -d "$UI_MODULE" ]; then
    FOUND_MODULES=$((FOUND_MODULES + 1))
fi

if [ -d "$SERVICES_MODULE" ]; then
    FOUND_MODULES=$((FOUND_MODULES + 1))
fi

echo "📦 Módulos: $FOUND_MODULES/$TOTAL_MODULES encontrados"
echo "📊 Arquivos Swift (principal): $MAIN_SWIFT_FILES"
echo "📊 Arquivos Swift (módulos): $((UI_FILES + SERVICES_FILES))"
echo "📋 Imports de módulos: $PROBLEMATIC_IMPORTS arquivo(s)"

if [ $FOUND_MODULES -eq $TOTAL_MODULES ] && grep -q "targets:" Package.swift; then
    echo ""
    echo "✅ Validação concluída com sucesso!"
    echo "🚀 Projeto pronto para build no Xcode Cloud"
    exit 0
else
    echo ""
    echo "❌ Validação encontrou problemas"
    echo "🔧 Corrija os problemas antes de fazer build"
    exit 1
fi
