#!/bin/bash

# Script para atualizar imports e referências após refatoração
# Autor: Manus AI
# Data: 23 de setembro de 2025

echo "🔄 Atualizando imports e referências após refatoração..."

# Função para atualizar imports em arquivos Swift
update_imports() {
    local file="$1"
    echo "  📝 Atualizando: $file"
    
    # Adicionar import ManusPsiqueiaUI onde necessário
    if grep -q "AdvancedButtons\|AdvancedInputFields\|AdvancedScrollView" "$file"; then
        if ! grep -q "import ManusPsiqueiaUI" "$file"; then
            sed -i '1i import ManusPsiqueiaUI' "$file"
        fi
    fi
    
    # Adicionar import ManusPsiqueiaServices onde necessário
    if grep -q "APIService\|NetworkManager" "$file"; then
        if ! grep -q "import ManusPsiqueiaServices" "$file"; then
            sed -i '1i import ManusPsiqueiaServices' "$file"
        fi
    fi
}

# Encontrar todos os arquivos Swift no projeto
echo "🔍 Procurando arquivos Swift..."
find /home/ubuntu/ManusPsiqueia/ManusPsiqueia -name "*.swift" -type f | while read -r file; do
    update_imports "$file"
done

echo "✅ Atualização de imports concluída!"

# Verificar se há problemas de compilação
echo "🧪 Verificando estrutura do projeto..."
cd /home/ubuntu/ManusPsiqueia

# Verificar se Package.swift está válido
if swift package resolve > /dev/null 2>&1; then
    echo "✅ Package.swift está válido"
else
    echo "⚠️ Possíveis problemas no Package.swift"
fi

echo "📊 Resumo da nova estrutura:"
echo "  📁 Features/: $(find ManusPsiqueia/Features -name "*.swift" | wc -l) arquivos Swift"
echo "  📁 Core/: $(find ManusPsiqueia/Core -name "*.swift" | wc -l) arquivos Swift"
echo "  📁 Modules/: $(find Modules -name "*.swift" | wc -l) arquivos Swift"

echo "🎉 Refatoração concluída com sucesso!"
