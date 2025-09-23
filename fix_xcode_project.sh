#!/bin/bash

#  fix_xcode_project.sh
#  ManusPsiqueia
#
#  Script para corrigir referências quebradas no projeto Xcode
#  Created by Manus AI on 2025-09-23.

set -e

echo "🔧 Corrigindo projeto Xcode corrompido..."
echo "========================================"

# Fazer backup do project.pbxproj atual
cp ManusPsiqueia.xcodeproj/project.pbxproj ManusPsiqueia.xcodeproj/project.pbxproj.corrupted
echo "✅ Backup do projeto corrompido criado"

# Restaurar do backup anterior se existir
if [ -f "ManusPsiqueia.xcodeproj/project.pbxproj.backup" ]; then
    echo "🔄 Restaurando do backup anterior..."
    cp ManusPsiqueia.xcodeproj/project.pbxproj.backup ManusPsiqueia.xcodeproj/project.pbxproj
    echo "✅ Projeto restaurado do backup"
else
    echo "❌ Backup anterior não encontrado"
    exit 1
fi

# Verificar se os arquivos principais existem nos novos locais
echo ""
echo "🔍 Verificando arquivos principais..."

MAIN_FILES=(
    "App/ContentView.swift"
    "App/ManusPsiqueiaApp.swift"
    "Info.plist"
    "Assets.xcassets"
)

for file in "${MAIN_FILES[@]}"; do
    if [ -f "ManusPsiqueia/$file" ]; then
        echo "✅ $file encontrado"
    else
        echo "❌ $file não encontrado"
    fi
done

# Atualizar referências no project.pbxproj para os novos caminhos
echo ""
echo "🔧 Atualizando referências de arquivos..."

# Atualizar ContentView.swift
sed -i 's|path = ContentView.swift|path = App/ContentView.swift|g' ManusPsiqueia.xcodeproj/project.pbxproj
echo "✅ ContentView.swift atualizado para App/ContentView.swift"

# Atualizar ManusPsiqueiaApp.swift
sed -i 's|path = ManusPsiqueiaApp.swift|path = App/ManusPsiqueiaApp.swift|g' ManusPsiqueia.xcodeproj/project.pbxproj
echo "✅ ManusPsiqueiaApp.swift atualizado para App/ManusPsiqueiaApp.swift"

# Verificar se as correções foram aplicadas
echo ""
echo "🔍 Verificando correções aplicadas..."

if grep -q "path = App/ContentView.swift" ManusPsiqueia.xcodeproj/project.pbxproj; then
    echo "✅ ContentView.swift referência corrigida"
else
    echo "❌ ContentView.swift referência não corrigida"
fi

if grep -q "path = App/ManusPsiqueiaApp.swift" ManusPsiqueia.xcodeproj/project.pbxproj; then
    echo "✅ ManusPsiqueiaApp.swift referência corrigida"
else
    echo "❌ ManusPsiqueiaApp.swift referência não corrigida"
fi

echo ""
echo "🎯 Correção do projeto Xcode concluída!"
echo "📋 Tente abrir o projeto novamente no Xcode"
