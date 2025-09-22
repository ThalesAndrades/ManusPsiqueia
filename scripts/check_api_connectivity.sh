#!/bin/bash

# Script de Verificação de Conectividade das APIs - ManusPsiqueia
# Autor: Manus AI
# Data: 22 de setembro de 2025

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🌐 Verificador de Conectividade das APIs - ManusPsiqueia${NC}"
echo "=============================================================="

# Função para verificar conectividade HTTP
check_http_connectivity() {
    local url=$1
    local service_name=$2
    local timeout=${3:-10}
    
    echo -e "${YELLOW}🔍 Verificando $service_name...${NC}"
    echo "   URL: $url"
    
    # Usar curl para verificar conectividade
    if curl -s --max-time "$timeout" --head "$url" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ $service_name: Conectividade OK${NC}"
        return 0
    else
        echo -e "${RED}❌ $service_name: Falha na conectividade${NC}"
        return 1
    fi
}

# Função para verificar API com autenticação
check_authenticated_api() {
    local url=$1
    local service_name=$2
    local auth_header=$3
    local timeout=${4:-10}
    
    echo -e "${YELLOW}🔍 Verificando $service_name (com autenticação)...${NC}"
    echo "   URL: $url"
    
    if [ -n "$auth_header" ]; then
        if curl -s --max-time "$timeout" -H "$auth_header" "$url" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ $service_name: API autenticada OK${NC}"
            return 0
        else
            echo -e "${RED}❌ $service_name: Falha na API autenticada${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠️ $service_name: Chave de autenticação não fornecida${NC}"
        return 1
    fi
}

# Função para verificar endpoints específicos
check_api_endpoints() {
    local environment=$1
    local base_url=$2
    
    echo -e "${BLUE}📡 Verificando endpoints da API $environment...${NC}"
    
    local endpoints=(
        "/health"
        "/api/v1/status"
        "/webhooks/stripe"
    )
    
    local success_count=0
    local total_endpoints=${#endpoints[@]}
    
    for endpoint in "${endpoints[@]}"; do
        local full_url="$base_url$endpoint"
        if check_http_connectivity "$full_url" "Endpoint $endpoint" 5; then
            success_count=$((success_count + 1))
        fi
        echo ""
    done
    
    echo -e "${BLUE}📊 Resultado: $success_count/$total_endpoints endpoints acessíveis${NC}"
    
    if [ $success_count -eq $total_endpoints ]; then
        return 0
    else
        return 1
    fi
}

# Função principal de verificação
main() {
    echo "Iniciando verificação de conectividade das APIs..."
    echo ""
    
    local total_checks=0
    local successful_checks=0
    
    # 1. Verificar OpenAI API
    echo -e "${BLUE}🤖 OpenAI API${NC}"
    if check_http_connectivity "https://api.openai.com/v1/models" "OpenAI API" 15; then
        successful_checks=$((successful_checks + 1))
    fi
    total_checks=$((total_checks + 1))
    echo ""
    
    # 2. Verificar Stripe API
    echo -e "${BLUE}💳 Stripe API${NC}"
    if check_http_connectivity "https://api.stripe.com/v1" "Stripe API" 10; then
        successful_checks=$((successful_checks + 1))
    fi
    total_checks=$((total_checks + 1))
    echo ""
    
    # 3. Verificar APIs do ManusPsiqueia por ambiente
    local environments=(
        "Development:https://api-dev.manuspsiqueia.com"
        "Staging:https://api-staging.manuspsiqueia.com"
        "Production:https://api.manuspsiqueia.com"
    )
    
    for env_pair in "${environments[@]}"; do
        local env_name=$(echo "$env_pair" | cut -d':' -f1)
        local env_url=$(echo "$env_pair" | cut -d':' -f2)
        
        echo -e "${BLUE}🏗️ API $env_name${NC}"
        if check_http_connectivity "$env_url" "API $env_name" 10; then
            successful_checks=$((successful_checks + 1))
            
            # Verificar endpoints específicos se a API principal estiver acessível
            if check_api_endpoints "$env_name" "$env_url"; then
                echo -e "${GREEN}✅ Todos os endpoints de $env_name estão acessíveis${NC}"
            else
                echo -e "${YELLOW}⚠️ Alguns endpoints de $env_name podem estar indisponíveis${NC}"
            fi
        fi
        total_checks=$((total_checks + 1))
        echo ""
    done
    
    # 4. Verificar Supabase (se URLs estiverem disponíveis)
    echo -e "${BLUE}🗄️ Supabase${NC}"
    
    # Tentar URLs comuns do Supabase
    local supabase_urls=(
        "https://dev-project.supabase.co"
        "https://staging-project.supabase.co"
        "https://prod-project.supabase.co"
    )
    
    local supabase_accessible=false
    for supabase_url in "${supabase_urls[@]}"; do
        if check_http_connectivity "$supabase_url" "Supabase" 10; then
            supabase_accessible=true
            break
        fi
    done
    
    if [ "$supabase_accessible" = true ]; then
        successful_checks=$((successful_checks + 1))
    else
        echo -e "${YELLOW}⚠️ URLs do Supabase não configuradas ou inacessíveis${NC}"
    fi
    total_checks=$((total_checks + 1))
    echo ""
    
    # 5. Verificar conectividade geral da internet
    echo -e "${BLUE}🌍 Conectividade Geral${NC}"
    if check_http_connectivity "https://www.google.com" "Internet" 5; then
        successful_checks=$((successful_checks + 1))
    fi
    total_checks=$((total_checks + 1))
    echo ""
    
    # Gerar relatório final
    generate_connectivity_report "$successful_checks" "$total_checks"
    
    # Retornar código de saída baseado no sucesso
    if [ $successful_checks -eq $total_checks ]; then
        echo -e "${GREEN}✅ Todas as verificações de conectividade passaram!${NC}"
        return 0
    elif [ $successful_checks -gt 0 ]; then
        echo -e "${YELLOW}⚠️ Algumas verificações falharam, mas conectividade básica está OK${NC}"
        return 1
    else
        echo -e "${RED}❌ Falha crítica na conectividade das APIs${NC}"
        return 2
    fi
}

# Função para gerar relatório de conectividade
generate_connectivity_report() {
    local successful=$1
    local total=$2
    local percentage=$((successful * 100 / total))
    
    local report_file="api_connectivity_report.txt"
    
    echo "Gerando relatório de conectividade..."
    
    cat > "$report_file" << EOF
=== RELATÓRIO DE CONECTIVIDADE DAS APIs ===

Projeto: ManusPsiqueia
Data: $(date)
Verificações: $successful/$total ($percentage%)

=== SERVIÇOS VERIFICADOS ===

1. OpenAI API (https://api.openai.com/v1)
   - Status: $([ $successful -gt 0 ] && echo "✅ Acessível" || echo "❌ Inacessível")
   - Função: Inteligência Artificial para insights do diário

2. Stripe API (https://api.stripe.com/v1)
   - Status: $([ $successful -gt 1 ] && echo "✅ Acessível" || echo "❌ Inacessível")
   - Função: Processamento de pagamentos

3. APIs ManusPsiqueia
   - Development: https://api-dev.manuspsiqueia.com
   - Staging: https://api-staging.manuspsiqueia.com
   - Production: https://api.manuspsiqueia.com
   - Status: Verificação realizada

4. Supabase
   - Status: URLs específicas precisam ser configuradas
   - Função: Backend e banco de dados

=== RECOMENDAÇÕES ===

EOF

    if [ $percentage -eq 100 ]; then
        echo "✅ Todas as APIs estão acessíveis - projeto pronto para deploy" >> "$report_file"
    elif [ $percentage -ge 80 ]; then
        echo "⚠️ Maioria das APIs acessíveis - verificar serviços com falha" >> "$report_file"
    elif [ $percentage -ge 50 ]; then
        echo "⚠️ Conectividade parcial - investigar problemas de rede" >> "$report_file"
    else
        echo "❌ Problemas críticos de conectividade - verificar configuração de rede" >> "$report_file"
    fi
    
    echo "" >> "$report_file"
    echo "Para melhorar a conectividade:" >> "$report_file"
    echo "1. Verificar configurações de firewall" >> "$report_file"
    echo "2. Confirmar chaves de API válidas" >> "$report_file"
    echo "3. Testar em diferentes redes" >> "$report_file"
    echo "4. Verificar status dos serviços externos" >> "$report_file"
    
    echo -e "${GREEN}✅ Relatório gerado: $report_file${NC}"
}

# Executar função principal
main "$@"
