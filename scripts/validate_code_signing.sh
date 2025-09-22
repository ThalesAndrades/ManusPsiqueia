#!/bin/bash

# Script de Validação de Assinatura de Código - ManusPsiqueia
# Autor: Manus AI
# Data: 22 de setembro de 2025

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔐 Validador de Assinatura de Código - ManusPsiqueia${NC}"
echo "========================================================"

# Função para verificar se estamos no Xcode Cloud
is_xcode_cloud() {
    [ "$CI_XCODE_CLOUD" = "true" ]
}

# Função para verificar configurações de assinatura
check_code_signing_config() {
    local config_file=$1
    local environment=$2
    
    echo -e "${YELLOW}📋 Verificando configurações de assinatura para $environment...${NC}"
    
    if [ ! -f "$config_file" ]; then
        echo -e "${RED}❌ Arquivo de configuração não encontrado: $config_file${NC}"
        return 1
    fi
    
    # Verificar configurações obrigatórias
    local required_settings=(
        "CODE_SIGN_STYLE"
        "DEVELOPMENT_TEAM"
        "CODE_SIGN_IDENTITY"
        "PRODUCT_BUNDLE_IDENTIFIER"
    )
    
    local missing_settings=0
    
    for setting in "${required_settings[@]}"; do
        if grep -q "^$setting" "$config_file"; then
            local value=$(grep "^$setting" "$config_file" | cut -d'=' -f2 | xargs)
            echo -e "${GREEN}✅ $setting = $value${NC}"
        else
            echo -e "${RED}❌ $setting não encontrado${NC}"
            missing_settings=$((missing_settings + 1))
        fi
    done
    
    if [ $missing_settings -eq 0 ]; then
        echo -e "${GREEN}✅ Todas as configurações de assinatura estão presentes${NC}"
        return 0
    else
        echo -e "${RED}❌ $missing_settings configuração(ões) de assinatura faltando${NC}"
        return 1
    fi
}

# Função para validar Bundle IDs
validate_bundle_ids() {
    echo -e "${YELLOW}📱 Validando Bundle Identifiers...${NC}"
    
    local configs=(
        "Configuration/Development.xcconfig:com.ailun.manuspsiqueia.dev"
        "Configuration/Staging.xcconfig:com.ailun.manuspsiqueia.beta"
        "Configuration/Production.xcconfig:com.ailun.manuspsiqueia"
    )
    
    for config_pair in "${configs[@]}"; do
        local config_file=$(echo "$config_pair" | cut -d':' -f1)
        local expected_bundle_id=$(echo "$config_pair" | cut -d':' -f2)
        local environment=$(basename "$config_file" .xcconfig)
        
        if [ -f "$config_file" ]; then
            if grep -q "PRODUCT_BUNDLE_IDENTIFIER.*$expected_bundle_id" "$config_file"; then
                echo -e "${GREEN}✅ $environment: Bundle ID correto ($expected_bundle_id)${NC}"
            else
                echo -e "${RED}❌ $environment: Bundle ID incorreto ou não encontrado${NC}"
                echo -e "${YELLOW}   Esperado: $expected_bundle_id${NC}"
            fi
        else
            echo -e "${RED}❌ $environment: Arquivo de configuração não encontrado${NC}"
        fi
    done
}

# Função para verificar certificados (apenas no Xcode Cloud)
check_certificates() {
    if is_xcode_cloud; then
        echo -e "${YELLOW}🔑 Verificando certificados no Xcode Cloud...${NC}"
        
        # Verificar se o DEVELOPMENT_TEAM_ID está definido
        if [ -n "$DEVELOPMENT_TEAM_ID" ]; then
            echo -e "${GREEN}✅ DEVELOPMENT_TEAM_ID definido: $DEVELOPMENT_TEAM_ID${NC}"
        else
            echo -e "${RED}❌ DEVELOPMENT_TEAM_ID não definido${NC}"
            echo -e "${YELLOW}   Configure no Xcode Cloud Environment Variables${NC}"
            return 1
        fi
        
        # Listar certificados disponíveis
        echo -e "${BLUE}📋 Certificados disponíveis:${NC}"
        security find-identity -v -p codesigning 2>/dev/null || echo "Nenhum certificado encontrado"
        
    else
        echo -e "${YELLOW}⚠️ Não está executando no Xcode Cloud - pulando verificação de certificados${NC}"
    fi
}

# Função para verificar provisioning profiles
check_provisioning_profiles() {
    if is_xcode_cloud; then
        echo -e "${YELLOW}📄 Verificando Provisioning Profiles no Xcode Cloud...${NC}"
        
        # Listar provisioning profiles disponíveis
        local profiles_dir="$HOME/Library/MobileDevice/Provisioning Profiles"
        if [ -d "$profiles_dir" ]; then
            local profile_count=$(find "$profiles_dir" -name "*.mobileprovision" | wc -l)
            echo -e "${GREEN}✅ $profile_count provisioning profile(s) encontrado(s)${NC}"
            
            # Listar profiles
            find "$profiles_dir" -name "*.mobileprovision" | while read profile; do
                local profile_name=$(security cms -D -i "$profile" 2>/dev/null | plutil -p - | grep -A1 Name | tail -1 | cut -d'"' -f2)
                echo -e "${BLUE}  📄 $profile_name${NC}"
            done
        else
            echo -e "${YELLOW}⚠️ Diretório de provisioning profiles não encontrado${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️ Não está executando no Xcode Cloud - pulando verificação de provisioning profiles${NC}"
    fi
}

# Função para validar configurações do Info.plist
validate_info_plist() {
    echo -e "${YELLOW}📱 Validando Info.plist...${NC}"
    
    local info_plist="ManusPsiqueia/Info.plist"
    
    if [ ! -f "$info_plist" ]; then
        echo -e "${RED}❌ Info.plist não encontrado: $info_plist${NC}"
        return 1
    fi
    
    # Verificar configurações obrigatórias
    local required_keys=(
        "CFBundleIdentifier"
        "CFBundleVersion"
        "CFBundleShortVersionString"
        "CFBundleDisplayName"
    )
    
    local missing_keys=0
    
    for key in "${required_keys[@]}"; do
        if grep -q "$key" "$info_plist"; then
            echo -e "${GREEN}✅ $key presente no Info.plist${NC}"
        else
            echo -e "${RED}❌ $key não encontrado no Info.plist${NC}"
            missing_keys=$((missing_keys + 1))
        fi
    done
    
    # Verificar se usa variáveis de build
    if grep -q '$(CURRENT_PROJECT_VERSION)' "$info_plist"; then
        echo -e "${GREEN}✅ CFBundleVersion usa variável de build${NC}"
    else
        echo -e "${YELLOW}⚠️ CFBundleVersion não usa variável de build${NC}"
    fi
    
    if grep -q '$(MARKETING_VERSION)' "$info_plist"; then
        echo -e "${GREEN}✅ CFBundleShortVersionString usa variável de build${NC}"
    else
        echo -e "${YELLOW}⚠️ CFBundleShortVersionString não usa variável de build${NC}"
    fi
    
    if [ $missing_keys -eq 0 ]; then
        echo -e "${GREEN}✅ Info.plist está válido${NC}"
        return 0
    else
        echo -e "${RED}❌ Info.plist tem $missing_keys chave(s) faltando${NC}"
        return 1
    fi
}

# Função para gerar relatório de validação
generate_validation_report() {
    local report_file="code_signing_validation_report.txt"
    
    echo "Gerando relatório de validação..."
    
    cat > "$report_file" << EOF
=== RELATÓRIO DE VALIDAÇÃO DE ASSINATURA DE CÓDIGO ===

Projeto: ManusPsiqueia
Data: $(date)
Ambiente: $(if is_xcode_cloud; then echo "Xcode Cloud"; else echo "Local"; fi)

=== CONFIGURAÇÕES VERIFICADAS ===

1. Arquivos de Configuração (.xcconfig)
   - Development.xcconfig: $([ -f "Configuration/Development.xcconfig" ] && echo "✅ Presente" || echo "❌ Ausente")
   - Staging.xcconfig: $([ -f "Configuration/Staging.xcconfig" ] && echo "✅ Presente" || echo "❌ Ausente")
   - Production.xcconfig: $([ -f "Configuration/Production.xcconfig" ] && echo "✅ Presente" || echo "❌ Ausente")

2. Info.plist
   - Arquivo: $([ -f "ManusPsiqueia/Info.plist" ] && echo "✅ Presente" || echo "❌ Ausente")
   - Configurações: $(grep -q "CFBundleIdentifier" "ManusPsiqueia/Info.plist" 2>/dev/null && echo "✅ Válidas" || echo "❌ Inválidas")

3. Bundle Identifiers
   - Development: com.ailun.manuspsiqueia.dev
   - Staging: com.ailun.manuspsiqueia.beta
   - Production: com.ailun.manuspsiqueia

=== VARIÁVEIS DE AMBIENTE ===

EOF

    if is_xcode_cloud; then
        echo "DEVELOPMENT_TEAM_ID: $([ -n "$DEVELOPMENT_TEAM_ID" ] && echo "✅ Definida" || echo "❌ Não definida")" >> "$report_file"
    else
        echo "Ambiente local - variáveis de ambiente não verificadas" >> "$report_file"
    fi
    
    echo "" >> "$report_file"
    echo "=== RECOMENDAÇÕES ===" >> "$report_file"
    echo "" >> "$report_file"
    echo "1. Certifique-se de que DEVELOPMENT_TEAM_ID está configurado no Xcode Cloud" >> "$report_file"
    echo "2. Verifique se os certificados de distribuição estão válidos" >> "$report_file"
    echo "3. Confirme que os provisioning profiles estão atualizados" >> "$report_file"
    echo "4. Teste o build em cada ambiente antes do deploy" >> "$report_file"
    
    echo -e "${GREEN}✅ Relatório gerado: $report_file${NC}"
}

# Função principal
main() {
    echo "Iniciando validação de assinatura de código..."
    echo ""
    
    local validation_errors=0
    
    # Verificar configurações de assinatura para cada ambiente
    if ! check_code_signing_config "Configuration/Development.xcconfig" "Development"; then
        validation_errors=$((validation_errors + 1))
    fi
    
    echo ""
    
    if ! check_code_signing_config "Configuration/Staging.xcconfig" "Staging"; then
        validation_errors=$((validation_errors + 1))
    fi
    
    echo ""
    
    if ! check_code_signing_config "Configuration/Production.xcconfig" "Production"; then
        validation_errors=$((validation_errors + 1))
    fi
    
    echo ""
    
    # Validar Bundle IDs
    validate_bundle_ids
    echo ""
    
    # Validar Info.plist
    if ! validate_info_plist; then
        validation_errors=$((validation_errors + 1))
    fi
    
    echo ""
    
    # Verificar certificados e provisioning profiles (apenas no Xcode Cloud)
    check_certificates
    echo ""
    
    check_provisioning_profiles
    echo ""
    
    # Gerar relatório
    generate_validation_report
    echo ""
    
    # Resultado final
    if [ $validation_errors -eq 0 ]; then
        echo -e "${GREEN}✅ Validação de assinatura de código concluída com sucesso!${NC}"
        echo -e "${GREEN}🚀 Projeto está pronto para build no Xcode Cloud${NC}"
        return 0
    else
        echo -e "${RED}❌ Validação falhou com $validation_errors erro(s)${NC}"
        echo -e "${YELLOW}⚠️ Corrija os problemas antes de fazer build no Xcode Cloud${NC}"
        return 1
    fi
}

# Executar função principal
main "$@"
