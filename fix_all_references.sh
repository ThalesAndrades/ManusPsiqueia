#!/bin/bash

#  fix_all_references.sh
#  ManusPsiqueia
#
#  Script avançado para corrigir todas as referências quebradas no projeto Xcode
#  Created by Manus AI on 2025-09-23.

set -e

echo "🔧 Corrigindo todas as referências do projeto Xcode..."
echo "===================================================="

# Fazer backup adicional
cp ManusPsiqueia.xcodeproj/project.pbxproj ManusPsiqueia.xcodeproj/project.pbxproj.before_fix
echo "✅ Backup adicional criado"

PROJECT_FILE="ManusPsiqueia.xcodeproj/project.pbxproj"

echo ""
echo "🔍 Mapeando arquivos movidos durante a refatoração..."

# Mapear arquivos que foram movidos para Features/
declare -A FILE_MAPPINGS=(
    # Arquivos principais movidos para App/
    ["ContentView.swift"]="App/ContentView.swift"
    ["ManusPsiqueiaApp.swift"]="App/ManusPsiqueiaApp.swift"
    
    # Managers movidos para Features/
    ["AuthenticationManager.swift"]="Features/Authentication/Managers/AuthenticationManager.swift"
    ["InvitationManager.swift"]="Features/Profile/Managers/InvitationManager.swift"
    ["StripeManager.swift"]="Features/Payments/Managers/StripeManager.swift"
    ["WebhookManager.swift"]="Features/Payments/Managers/WebhookManager.swift"
    
    # Views movidas para Features/
    ["LoginView.swift"]="Features/Authentication/Views/LoginView.swift"
    ["OnboardingView.swift"]="Features/Onboarding/Views/OnboardingView.swift"
    ["PatientDiaryView.swift"]="Features/Journal/Views/PatientDiaryView.swift"
    ["IntegratedDiaryView.swift"]="Features/Journal/Views/IntegratedDiaryView.swift"
    ["PaymentView.swift"]="Features/Payments/Views/PaymentView.swift"
    ["SubscriptionView.swift"]="Features/Subscriptions/Views/SubscriptionView.swift"
    ["ProfileView.swift"]="Features/Profile/Views/ProfileView.swift"
    ["UserDashboardView.swift"]="Features/Profile/Views/UserDashboardView.swift"
    ["ProfessionalDashboardView.swift"]="Features/Profile/Views/ProfessionalDashboardView.swift"
    
    # Models movidos para Core/ ou Features/
    ["User.swift"]="Core/Models/User.swift"
    ["Subscription.swift"]="Core/Models/Subscription.swift"
    ["Payment.swift"]="Features/Payments/Models/Payment.swift"
    ["Invitation.swift"]="Features/Profile/Models/Invitation.swift"
    ["Financial.swift"]="Features/Payments/Models/Financial.swift"
    
    # Services movidos para Core/
    ["APIService.swift"]="Core/Services/APIService.swift"
    ["NetworkManager.swift"]="Core/Managers/NetworkManager.swift"
    ["ConfigurationManager.swift"]="Core/Managers/ConfigurationManager.swift"
    
    # Utils movidos para Core/
    ["PerformanceOptimizer.swift"]="Core/Utils/PerformanceOptimizer.swift"
    ["BuildErrorHandler.swift"]="Core/Utils/BuildErrorHandler.swift"
    ["ConfigurationFallbacks.swift"]="Core/Utils/ConfigurationFallbacks.swift"
    
    # Security movido para Core/
    ["SecurityThreatDetector.swift"]="Core/Security/SecurityThreatDetector.swift"
)

echo "📊 ${#FILE_MAPPINGS[@]} mapeamentos de arquivos identificados"

# Aplicar correções
echo ""
echo "🔧 Aplicando correções de referências..."

for old_path in "${!FILE_MAPPINGS[@]}"; do
    new_path="${FILE_MAPPINGS[$old_path]}"
    
    # Verificar se o arquivo existe no novo local
    if [ -f "ManusPsiqueia/$new_path" ]; then
        # Atualizar referência no project.pbxproj
        sed -i "s|path = $old_path|path = $new_path|g" "$PROJECT_FILE"
        echo "✅ $old_path → $new_path"
    else
        echo "⚠️ $new_path não encontrado, mantendo referência original"
    fi
done

# Corrigir referências de grupos/diretórios
echo ""
echo "🔧 Corrigindo referências de grupos..."

# Atualizar referências de diretórios que foram reorganizados
sed -i 's|path = Views;|path = Features;|g' "$PROJECT_FILE"
sed -i 's|path = Models;|path = Core/Models;|g' "$PROJECT_FILE"
sed -i 's|path = Managers;|path = Core/Managers;|g' "$PROJECT_FILE"
sed -i 's|path = Services;|path = Core/Services;|g' "$PROJECT_FILE"
sed -i 's|path = Utils;|path = Core/Utils;|g' "$PROJECT_FILE"
sed -i 's|path = Security;|path = Core/Security;|g' "$PROJECT_FILE"

echo "✅ Referências de grupos atualizadas"

# Verificar se há referências ainda quebradas
echo ""
echo "🔍 Verificando referências restantes..."

BROKEN_REFS=0

# Verificar cada arquivo referenciado no projeto
grep "path = " "$PROJECT_FILE" | \
grep -v "BUILT_PRODUCTS_DIR" | \
grep -v "Preview Assets.xcassets" | \
sed 's/.*path = \([^;]*\);.*/\1/' | \
sed 's/"//g' | \
while read file; do
    if [ ! -f "ManusPsiqueia/$file" ] && [ ! -d "ManusPsiqueia/$file" ]; then
        echo "❌ Referência ainda quebrada: $file"
        BROKEN_REFS=$((BROKEN_REFS + 1))
    fi
done

# Remover referências duplicadas ou inválidas
echo ""
echo "🧹 Limpando referências duplicadas..."

# Criar uma versão temporária limpa do project.pbxproj
cp "$PROJECT_FILE" "${PROJECT_FILE}.temp"

# Remover linhas duplicadas mantendo a primeira ocorrência
awk '!seen[$0]++' "${PROJECT_FILE}.temp" > "$PROJECT_FILE"
rm "${PROJECT_FILE}.temp"

echo "✅ Referências duplicadas removidas"

echo ""
echo "🎯 Correção de referências concluída!"
echo "📋 Projeto Xcode deve estar funcional agora"
