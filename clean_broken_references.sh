#!/bin/bash

#  clean_broken_references.sh
#  ManusPsiqueia
#
#  Script para remover referências de arquivos que não existem mais
#  Created by Manus AI on 2025-09-23.

set -e

echo "🧹 Removendo referências quebradas do projeto Xcode..."
echo "===================================================="

PROJECT_FILE="ManusPsiqueia.xcodeproj/project.pbxproj"

# Fazer backup antes da limpeza
cp "$PROJECT_FILE" "${PROJECT_FILE}.before_cleanup"
echo "✅ Backup criado antes da limpeza"

# Lista de arquivos que não existem mais e devem ser removidos das referências
REMOVED_FILES=(
    "UserTypeSelectionView.swift"
    "InvitePsychologistView.swift"
    "FinancialDashboardView.swift"
    "WithdrawFundsView.swift"
    "AdvancedScrollView.swift"
    "AdvancedButtons.swift"
    "AdvancedInputFields.swift"
    "DiaryEntry.swift"
    "DiaryManager.swift"
    "DiaryPrivacyInfoView.swift"
    "NewDiaryEntryView.swift"
    "DiarySecurityManager.swift"
    "DiaryAIInsightsManager.swift"
    "DiaryAIModels.swift"
    "CertificatePinningManager.swift"
    "AuditLogger.swift"
    "SecurityIncidentManager.swift"
    "SecurityConfiguration.swift"
    "SplashScreenView.swift"
    "LoadingView.swift"
    "ParticlesView.swift"
    "Particle.swift"
    "DynamicPricing.swift"
)

echo "📊 ${#REMOVED_FILES[@]} arquivos para remover das referências"

# Remover referências de arquivos que não existem mais
echo ""
echo "🗑️ Removendo referências de arquivos inexistentes..."

for file in "${REMOVED_FILES[@]}"; do
    # Encontrar e remover linhas que referenciam o arquivo
    if grep -q "$file" "$PROJECT_FILE"; then
        # Remover a linha de referência do arquivo
        sed -i "/$file/d" "$PROJECT_FILE"
        echo "✅ Removido: $file"
    else
        echo "⚪ Não encontrado: $file"
    fi
done

# Remover referências de grupos/diretórios que não existem mais
echo ""
echo "🗑️ Removendo referências de grupos inexistentes..."

REMOVED_GROUPS=(
    "Components"
    "AI"
    "Advanced"
    "PatientDiary"
    "DiaryProtection"
    "DiaryInsights"
)

for group in "${REMOVED_GROUPS[@]}"; do
    if grep -q "path = $group;" "$PROJECT_FILE"; then
        sed -i "/path = $group;/d" "$PROJECT_FILE"
        echo "✅ Grupo removido: $group"
    fi
done

# Limpar linhas vazias e duplicadas
echo ""
echo "🧹 Limpando arquivo do projeto..."

# Remover linhas vazias
sed -i '/^[[:space:]]*$/d' "$PROJECT_FILE"

# Remover possíveis referências órfãs (linhas que referenciam IDs que não existem mais)
# Isso é mais complexo e pode precisar de ajuste manual, mas vamos tentar uma limpeza básica

echo "✅ Limpeza básica concluída"

# Verificar integridade básica do arquivo
echo ""
echo "🔍 Verificando integridade do arquivo..."

if grep -q "rootObject" "$PROJECT_FILE" && grep -q "PBXProject" "$PROJECT_FILE"; then
    echo "✅ Estrutura básica do projeto mantida"
else
    echo "❌ Estrutura do projeto pode estar corrompida"
    echo "🔄 Restaurando backup..."
    cp "${PROJECT_FILE}.before_cleanup" "$PROJECT_FILE"
    exit 1
fi

# Contar referências restantes
REMAINING_REFS=$(grep -c "path.*=" "$PROJECT_FILE" || echo "0")
echo "📊 $REMAINING_REFS referências de arquivos restantes"

echo ""
echo "🎯 Limpeza de referências concluída!"
echo "📋 Projeto deve estar mais limpo agora"
