#!/bin/bash

# Script de Monitoramento de Saúde do Projeto - ManusPsiqueia
# Autor: Manus AI
# Data: 22 de setembro de 2025

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configurações
PROJECT_NAME="ManusPsiqueia"
REPORT_FILE="project_health_report.md"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

echo -e "${BLUE}🏥 Monitor de Saúde do Projeto - $PROJECT_NAME${NC}"
echo "=================================================="
echo "Executado em: $TIMESTAMP"
echo ""

# Função para criar cabeçalho do relatório
create_report_header() {
    cat > "$REPORT_FILE" << EOF
# Relatório de Saúde do Projeto

**Projeto:** $PROJECT_NAME  
**Data:** $TIMESTAMP  
**Gerado por:** Monitor de Saúde Automatizado

## Resumo Executivo

EOF
}

# Função para verificar estrutura de arquivos
check_file_structure() {
    echo -e "${YELLOW}📁 Verificando estrutura de arquivos...${NC}"
    
    local score=0
    local total=10
    
    # Verificar arquivos essenciais
    if [ -f "README.md" ]; then
        score=$((score + 1))
        echo "✅ README.md encontrado"
    else
        echo "❌ README.md não encontrado"
    fi
    
    if [ -f "CONTRIBUTING.md" ]; then
        score=$((score + 1))
        echo "✅ CONTRIBUTING.md encontrado"
    else
        echo "❌ CONTRIBUTING.md não encontrado"
    fi
    
    if [ -f "CHANGELOG.md" ]; then
        score=$((score + 1))
        echo "✅ CHANGELOG.md encontrado"
    else
        echo "❌ CHANGELOG.md não encontrado"
    fi
    
    if [ -f ".gitignore" ]; then
        score=$((score + 1))
        echo "✅ .gitignore encontrado"
    else
        echo "❌ .gitignore não encontrado"
    fi
    
    # Verificar estrutura de diretórios
    if [ -d "docs" ]; then
        score=$((score + 1))
        echo "✅ Diretório docs/ encontrado"
    else
        echo "❌ Diretório docs/ não encontrado"
    fi
    
    if [ -d "scripts" ]; then
        score=$((score + 1))
        echo "✅ Diretório scripts/ encontrado"
    else
        echo "❌ Diretório scripts/ não encontrado"
    fi
    
    if [ -d "Modules" ]; then
        score=$((score + 1))
        echo "✅ Diretório Modules/ encontrado"
    else
        echo "❌ Diretório Modules/ não encontrado"
    fi
    
    if [ -d "Configuration" ]; then
        score=$((score + 1))
        echo "✅ Diretório Configuration/ encontrado"
    else
        echo "❌ Diretório Configuration/ não encontrado"
    fi
    
    if [ -d ".github" ]; then
        score=$((score + 1))
        echo "✅ Diretório .github/ encontrado"
    else
        echo "❌ Diretório .github/ não encontrado"
    fi
    
    if [ -f "Package.swift" ]; then
        score=$((score + 1))
        echo "✅ Package.swift encontrado"
    else
        echo "❌ Package.swift não encontrado"
    fi
    
    local percentage=$((score * 100 / total))
    echo ""
    echo -e "📊 Pontuação da Estrutura: ${GREEN}$score/$total ($percentage%)${NC}"
    
    # Adicionar ao relatório
    cat >> "$REPORT_FILE" << EOF
### 📁 Estrutura de Arquivos

**Pontuação:** $score/$total ($percentage%)

EOF
    
    if [ $percentage -ge 80 ]; then
        echo -e "✅ ${GREEN}Estrutura de arquivos está em boa condição${NC}"
        echo "**Status:** ✅ Excelente" >> "$REPORT_FILE"
    elif [ $percentage -ge 60 ]; then
        echo -e "⚠️ ${YELLOW}Estrutura de arquivos precisa de melhorias${NC}"
        echo "**Status:** ⚠️ Precisa de Melhorias" >> "$REPORT_FILE"
    else
        echo -e "❌ ${RED}Estrutura de arquivos está inadequada${NC}"
        echo "**Status:** ❌ Inadequada" >> "$REPORT_FILE"
    fi
    
    echo "" >> "$REPORT_FILE"
}

# Função para verificar cobertura de testes
check_test_coverage() {
    echo -e "${YELLOW}🧪 Verificando cobertura de testes...${NC}"
    
    if [ -f "scripts/test_coverage_analysis.sh" ]; then
        ./scripts/test_coverage_analysis.sh > /tmp/coverage_output.txt 2>&1
        
        # Extrair informações do output
        local source_files=$(grep "Arquivos de código fonte:" /tmp/coverage_output.txt | grep -o '[0-9]\+' || echo "0")
        local test_files=$(grep "Arquivos de teste:" /tmp/coverage_output.txt | grep -o '[0-9]\+' || echo "0")
        local coverage_percentage=$(grep "Cobertura de testes:" /tmp/coverage_output.txt | grep -o '[0-9]\+%' | head -1 || echo "0%")
        
        echo "📊 Arquivos de código fonte: $source_files"
        echo "📊 Arquivos de teste: $test_files"
        echo "📊 Cobertura estimada: $coverage_percentage"
        
        # Adicionar ao relatório
        cat >> "$REPORT_FILE" << EOF
### 🧪 Cobertura de Testes

**Arquivos de código fonte:** $source_files  
**Arquivos de teste:** $test_files  
**Cobertura estimada:** $coverage_percentage

EOF
        
        local coverage_num=$(echo "$coverage_percentage" | sed 's/%//')
        if [ "$coverage_num" -ge 70 ]; then
            echo -e "✅ ${GREEN}Cobertura de testes está boa${NC}"
            echo "**Status:** ✅ Boa Cobertura" >> "$REPORT_FILE"
        elif [ "$coverage_num" -ge 50 ]; then
            echo -e "⚠️ ${YELLOW}Cobertura de testes precisa melhorar${NC}"
            echo "**Status:** ⚠️ Precisa Melhorar" >> "$REPORT_FILE"
        else
            echo -e "❌ ${RED}Cobertura de testes está baixa${NC}"
            echo "**Status:** ❌ Cobertura Baixa" >> "$REPORT_FILE"
        fi
        
        rm -f /tmp/coverage_output.txt
    else
        echo "❌ Script de análise de cobertura não encontrado"
        echo "**Status:** ❌ Script Não Encontrado" >> "$REPORT_FILE"
    fi
    
    echo "" >> "$REPORT_FILE"
}

# Função para verificar configuração de segredos
check_secrets_configuration() {
    echo -e "${YELLOW}🔒 Verificando configuração de segredos...${NC}"
    
    local score=0
    local total=8
    
    # Verificar estrutura de configuração
    if [ -d "Configuration/Secrets" ]; then
        score=$((score + 1))
        echo "✅ Diretório Configuration/Secrets encontrado"
    else
        echo "❌ Diretório Configuration/Secrets não encontrado"
    fi
    
    if [ -d "Configuration/Templates" ]; then
        score=$((score + 1))
        echo "✅ Diretório Configuration/Templates encontrado"
    else
        echo "❌ Diretório Configuration/Templates não encontrado"
    fi
    
    if [ -f "Configuration/Development.xcconfig" ]; then
        score=$((score + 1))
        echo "✅ Development.xcconfig encontrado"
    else
        echo "❌ Development.xcconfig não encontrado"
    fi
    
    if [ -f "Configuration/Staging.xcconfig" ]; then
        score=$((score + 1))
        echo "✅ Staging.xcconfig encontrado"
    else
        echo "❌ Staging.xcconfig não encontrado"
    fi
    
    if [ -f "Configuration/Production.xcconfig" ]; then
        score=$((score + 1))
        echo "✅ Production.xcconfig encontrado"
    else
        echo "❌ Production.xcconfig não encontrado"
    fi
    
    if [ -f "scripts/secrets_manager.sh" ]; then
        score=$((score + 1))
        echo "✅ Script secrets_manager.sh encontrado"
    else
        echo "❌ Script secrets_manager.sh não encontrado"
    fi
    
    # Verificar se há arquivos .secrets commitados (não deveria haver)
    if find . -name "*.secrets" -not -path "./.git/*" | grep -q .; then
        echo "❌ Arquivos .secrets encontrados no repositório (risco de segurança)"
    else
        score=$((score + 1))
        echo "✅ Nenhum arquivo .secrets commitado"
    fi
    
    # Verificar ConfigurationManager
    if [ -f "ManusPsiqueia/Managers/ConfigurationManager.swift" ]; then
        score=$((score + 1))
        echo "✅ ConfigurationManager.swift encontrado"
    else
        echo "❌ ConfigurationManager.swift não encontrado"
    fi
    
    local percentage=$((score * 100 / total))
    echo ""
    echo -e "📊 Pontuação de Segredos: ${GREEN}$score/$total ($percentage%)${NC}"
    
    # Adicionar ao relatório
    cat >> "$REPORT_FILE" << EOF
### 🔒 Configuração de Segredos

**Pontuação:** $score/$total ($percentage%)

EOF
    
    if [ $percentage -ge 80 ]; then
        echo -e "✅ ${GREEN}Configuração de segredos está segura${NC}"
        echo "**Status:** ✅ Segura" >> "$REPORT_FILE"
    elif [ $percentage -ge 60 ]; then
        echo -e "⚠️ ${YELLOW}Configuração de segredos precisa de melhorias${NC}"
        echo "**Status:** ⚠️ Precisa de Melhorias" >> "$REPORT_FILE"
    else
        echo -e "❌ ${RED}Configuração de segredos está inadequada${NC}"
        echo "**Status:** ❌ Inadequada" >> "$REPORT_FILE"
    fi
    
    echo "" >> "$REPORT_FILE"
}

# Função para verificar modularização
check_modularization() {
    echo -e "${YELLOW}📦 Verificando modularização...${NC}"
    
    local modules_count=0
    local modules_with_tests=0
    
    if [ -d "Modules" ]; then
        modules_count=$(find Modules -name "Package.swift" | wc -l)
        
        echo "📊 Módulos encontrados: $modules_count"
        
        # Verificar se os módulos têm testes
        for module_dir in Modules/*/; do
            if [ -d "$module_dir" ]; then
                module_name=$(basename "$module_dir")
                if [ -d "$module_dir/Tests" ]; then
                    modules_with_tests=$((modules_with_tests + 1))
                    echo "✅ Módulo $module_name tem testes"
                else
                    echo "❌ Módulo $module_name não tem testes"
                fi
            fi
        done
        
        # Adicionar ao relatório
        cat >> "$REPORT_FILE" << EOF
### 📦 Modularização

**Módulos encontrados:** $modules_count  
**Módulos com testes:** $modules_with_tests

EOF
        
        if [ $modules_count -ge 2 ]; then
            echo -e "✅ ${GREEN}Modularização está implementada${NC}"
            echo "**Status:** ✅ Implementada" >> "$REPORT_FILE"
        elif [ $modules_count -eq 1 ]; then
            echo -e "⚠️ ${YELLOW}Modularização está em progresso${NC}"
            echo "**Status:** ⚠️ Em Progresso" >> "$REPORT_FILE"
        else
            echo -e "❌ ${RED}Modularização não implementada${NC}"
            echo "**Status:** ❌ Não Implementada" >> "$REPORT_FILE"
        fi
    else
        echo "❌ Diretório Modules não encontrado"
        echo "**Status:** ❌ Não Implementada" >> "$REPORT_FILE"
    fi
    
    echo "" >> "$REPORT_FILE"
}

# Função para verificar CI/CD
check_cicd() {
    echo -e "${YELLOW}🚀 Verificando CI/CD...${NC}"
    
    local score=0
    local total=5
    
    if [ -d ".github/workflows" ]; then
        score=$((score + 1))
        echo "✅ Diretório .github/workflows encontrado"
        
        local workflows_count=$(find .github/workflows -name "*.yml" -o -name "*.yaml" | wc -l)
        echo "📊 Workflows encontrados: $workflows_count"
        
        if [ $workflows_count -ge 1 ]; then
            score=$((score + 1))
            echo "✅ Pelo menos um workflow configurado"
        fi
    else
        echo "❌ Diretório .github/workflows não encontrado"
    fi
    
    if [ -f ".github/ISSUE_TEMPLATE/bug_report.md" ]; then
        score=$((score + 1))
        echo "✅ Template de issue para bugs encontrado"
    else
        echo "❌ Template de issue para bugs não encontrado"
    fi
    
    if [ -f ".github/ISSUE_TEMPLATE/feature_request.md" ]; then
        score=$((score + 1))
        echo "✅ Template de issue para features encontrado"
    else
        echo "❌ Template de issue para features não encontrado"
    fi
    
    if [ -f ".github/pull_request_template.md" ]; then
        score=$((score + 1))
        echo "✅ Template de pull request encontrado"
    else
        echo "❌ Template de pull request não encontrado"
    fi
    
    local percentage=$((score * 100 / total))
    echo ""
    echo -e "📊 Pontuação de CI/CD: ${GREEN}$score/$total ($percentage%)${NC}"
    
    # Adicionar ao relatório
    cat >> "$REPORT_FILE" << EOF
### 🚀 CI/CD

**Pontuação:** $score/$total ($percentage%)

EOF
    
    if [ $percentage -ge 80 ]; then
        echo -e "✅ ${GREEN}CI/CD está bem configurado${NC}"
        echo "**Status:** ✅ Bem Configurado" >> "$REPORT_FILE"
    elif [ $percentage -ge 60 ]; then
        echo -e "⚠️ ${YELLOW}CI/CD precisa de melhorias${NC}"
        echo "**Status:** ⚠️ Precisa de Melhorias" >> "$REPORT_FILE"
    else
        echo -e "❌ ${RED}CI/CD está inadequado${NC}"
        echo "**Status:** ❌ Inadequado" >> "$REPORT_FILE"
    fi
    
    echo "" >> "$REPORT_FILE"
}

# Função para gerar recomendações
generate_recommendations() {
    echo -e "${PURPLE}💡 Gerando recomendações...${NC}"
    
    cat >> "$REPORT_FILE" << EOF
## 💡 Recomendações

### Prioridade Alta
- Aumentar cobertura de testes para pelo menos 70%
- Configurar GitHub Secrets para ambientes de staging e produção
- Implementar workflows de CI/CD com permissões adequadas

### Prioridade Média
- Criar mais módulos para funcionalidades específicas
- Adicionar documentação automática com DocC
- Implementar análise de qualidade de código (SwiftLint)

### Prioridade Baixa
- Configurar notificações automáticas para builds falhos
- Implementar métricas de performance
- Adicionar badges de status no README

## 📊 Próximos Passos

1. **Semana 1:** Focar na melhoria da cobertura de testes
2. **Semana 2:** Configurar GitHub Secrets e workflows
3. **Semana 3:** Implementar módulos adicionais
4. **Semana 4:** Documentação e refinamentos finais

---

*Relatório gerado automaticamente pelo Monitor de Saúde do Projeto*
EOF
    
    echo "💡 Recomendações adicionadas ao relatório"
}

# Função principal
main() {
    create_report_header
    check_file_structure
    check_test_coverage
    check_secrets_configuration
    check_modularization
    check_cicd
    generate_recommendations
    
    echo ""
    echo -e "${GREEN}✅ Análise de saúde do projeto concluída!${NC}"
    echo -e "${BLUE}📄 Relatório salvo em: $REPORT_FILE${NC}"
    echo ""
    echo "Para visualizar o relatório:"
    echo "  cat $REPORT_FILE"
    echo ""
    echo "Para executar novamente:"
    echo "  ./scripts/project_health_monitor.sh"
}

# Executar função principal
main "$@"
