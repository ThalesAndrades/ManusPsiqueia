#!/bin/bash
echo "🔍 Verificando arquivos referenciados no .xcodeproj que não existem..."
echo "=================================================================="

# Extrair caminhos de arquivos do project.pbxproj
grep "path = " ManusPsiqueia.xcodeproj/project.pbxproj | \
grep -v "BUILT_PRODUCTS_DIR" | \
sed 's/.*path = \([^;]*\);.*/\1/' | \
sed 's/"//g' | \
while read file; do
    if [ ! -f "ManusPsiqueia/$file" ] && [ ! -d "ManusPsiqueia/$file" ]; then
        echo "❌ Arquivo não encontrado: ManusPsiqueia/$file"
    fi
done
