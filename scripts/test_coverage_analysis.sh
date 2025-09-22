#!/bin/bash

# Script de Análise de Cobertura de Testes - ManusPsiqueia
# Autor: Manus AI
# Data: 22 de setembro de 2025

echo "🔍 Análise de Cobertura de Testes - ManusPsiqueia"
echo "=================================================="
echo ""

# Criar diretório de scripts se não existir
mkdir -p scripts

# Contadores
total_source_files=0
total_test_files=0
files_without_tests=0

# Arrays para armazenar resultados
declare -a missing_tests=()
declare -a existing_tests=()

echo "📊 Estatísticas Gerais:"
echo "----------------------"

# Contar arquivos de código fonte
total_source_files=$(find ManusPsiqueia/ -name "*.swift" -type f | wc -l)
echo "Arquivos de código fonte: $total_source_files"

# Contar arquivos de teste
total_test_files=$(find ManusPsiqueiaTests/ -name "*.swift" -type f | wc -l)
echo "Arquivos de teste: $total_test_files"

echo ""
echo "🔍 Análise Detalhada:"
echo "---------------------"

# Analisar cada arquivo de código fonte
while IFS= read -r source_file; do
    # Extrair o nome do arquivo sem extensão e caminho
    relative_path=$(echo "$source_file" | sed 's|ManusPsiqueia/||')
    file_name=$(echo "$relative_path" | sed 's|\.swift||')
    
    # Verificar se existe teste correspondente
    test_file="ManusPsiqueiaTests/${file_name}Tests.swift"
    
    if [ -f "$test_file" ]; then
        existing_tests+=("$relative_path")
    else
        missing_tests+=("$relative_path")
        ((files_without_tests++))
    fi
done < <(find ManusPsiqueia/ -name "*.swift" -type f | sort)

# Calcular percentual de cobertura
if [ $total_source_files -gt 0 ]; then
    coverage_percentage=$(( (total_source_files - files_without_tests) * 100 / total_source_files ))
else
    coverage_percentage=0
fi

echo "Cobertura de testes: $coverage_percentage% ($((total_source_files - files_without_tests))/$total_source_files arquivos)"
echo ""

# Listar arquivos sem testes
if [ ${#missing_tests[@]} -gt 0 ]; then
    echo "❌ Arquivos SEM testes (${#missing_tests[@]}):"
    echo "----------------------------------------"
    for file in "${missing_tests[@]}"; do
        echo "  - $file"
    done
    echo ""
fi

# Listar arquivos com testes
if [ ${#existing_tests[@]} -gt 0 ]; then
    echo "✅ Arquivos COM testes (${#existing_tests[@]}):"
    echo "---------------------------------------"
    for file in "${existing_tests[@]}"; do
        echo "  - $file"
    done
    echo ""
fi

# Recomendações
echo "💡 Recomendações:"
echo "-----------------"
if [ $coverage_percentage -lt 80 ]; then
    echo "⚠️  Cobertura de testes abaixo do recomendado (80%)"
    echo "   Priorize criar testes para:"
    echo "   1. Managers (lógica de negócio crítica)"
    echo "   2. Models (estruturas de dados)"
    echo "   3. Services (integrações externas)"
elif [ $coverage_percentage -lt 90 ]; then
    echo "⚡ Boa cobertura! Considere adicionar testes para:"
    echo "   1. Views críticas (autenticação, pagamento)"
    echo "   2. ViewModels (lógica de apresentação)"
else
    echo "🎉 Excelente cobertura de testes!"
fi

echo ""
echo "📈 Próximos Passos:"
echo "-------------------"
echo "1. Executar: xcodebuild test -scheme ManusPsiqueia -destination 'platform=iOS Simulator,name=iPhone 15 Pro'"
echo "2. Gerar relatório: xcodebuild test -enableCodeCoverage YES"
echo "3. Analisar com: xcrun xccov view --report"
echo ""
echo "Análise concluída! 🎯"
