#!/bin/bash

# Script de Setup Automático do Projeto ManusPsiqueia
# Autor: Manus AI
# Data: 22 de setembro de 2025

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Função para imprimir cabeçalho
print_header() {
    echo -e "${BLUE}"
    echo "=============================================================="
    echo "🚀 Setup Automático do Projeto ManusPsiqueia"
    echo "=============================================================="
    echo -e "${NC}"
}

# Função para imprimir seção
print_section() {
    echo -e "${PURPLE}📋 $1${NC}"
    echo "--------------------------------------------------------------"
}

# Função para imprimir sucesso
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Função para imprimir aviso
print_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

# Função para imprimir erro
print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Função para imprimir informação
print_info() {
    echo -e "${CYAN}ℹ️ $1${NC}"
}

# Função para verificar se um comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Função para verificar dependências
check_dependencies() {
    print_section "Verificando Dependências"
    
    local missing_deps=()
    
    # Verificar Xcode
    if ! command_exists xcodebuild; then
        missing_deps+=("Xcode Command Line Tools")
    else
        print_success "Xcode Command Line Tools instalado"
    fi
    
    # Verificar Swift
    if ! command_exists swift; then
        missing_deps+=("Swift")
    else
        local swift_version=$(swift --version | head -n1)
        print_success "Swift instalado: $swift_version"
    fi
    
    # Verificar Git
    if ! command_exists git; then
        missing_deps+=("Git")
    else
        local git_version=$(git --version)
        print_success "Git instalado: $git_version"
    fi
    
    # Verificar CocoaPods (opcional)
    if command_exists pod; then
        local pod_version=$(pod --version)
        print_success "CocoaPods instalado: $pod_version"
    else
        print_warning "CocoaPods não instalado (opcional)"
    fi
    
    # Verificar Homebrew (opcional)
    if command_exists brew; then
        print_success "Homebrew instalado"
    else
        print_warning "Homebrew não instalado (recomendado)"
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Dependências faltando:"
        for dep in "${missing_deps[@]}"; do
            echo "  - $dep"
        done
        echo ""
        print_info "Por favor, instale as dependências faltando antes de continuar."
        exit 1
    fi
    
    print_success "Todas as dependências necessárias estão instaladas!"
    echo ""
}

# Função para configurar o ambiente
setup_environment() {
    print_section "Configurando Ambiente"
    
    # Criar diretórios necessários se não existirem
    local directories=(
        "Configuration"
        "ci_scripts"
        "scripts"
        "docs/setup"
        "docs/features"
        "docs/technical"
        "docs/security"
        "docs/integrations"
        "docs/development"
        "Modules"
    )
    
    for dir in "${directories[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            print_success "Criado diretório: $dir"
        else
            print_info "Diretório já existe: $dir"
        fi
    done
    
    echo ""
}

# Função para configurar Swift Package Manager
setup_swift_packages() {
    print_section "Configurando Swift Package Manager"
    
    if [ -f "Package.swift" ]; then
        print_info "Resolvendo dependências do Swift Package Manager..."
        
        if swift package resolve; then
            print_success "Dependências resolvidas com sucesso"
        else
            print_warning "Falha ao resolver algumas dependências"
        fi
        
        # Verificar se as dependências foram baixadas
        if [ -d ".build" ]; then
            print_success "Diretório .build criado"
        fi
        
        # Gerar projeto Xcode se necessário
        if [ ! -f "*.xcodeproj" ] && [ ! -f "*.xcworkspace" ]; then
            print_info "Gerando projeto Xcode..."
            if swift package generate-xcodeproj; then
                print_success "Projeto Xcode gerado"
            else
                print_warning "Falha ao gerar projeto Xcode"
            fi
        fi
    else
        print_warning "Package.swift não encontrado"
    fi
    
    echo ""
}

# Função para configurar Git hooks
setup_git_hooks() {
    print_section "Configurando Git Hooks"
    
    if [ -d ".git" ]; then
        # Criar hook de pre-commit
        local pre_commit_hook=".git/hooks/pre-commit"
        
        cat > "$pre_commit_hook" << 'EOF'
#!/bin/bash

# Pre-commit hook para ManusPsiqueia
echo "🔍 Executando verificações pre-commit..."

# Verificar se há arquivos Swift para formatar
if git diff --cached --name-only --diff-filter=ACM | grep -q "\.swift$"; then
    echo "📝 Verificando formatação do código Swift..."
    
    # Executar SwiftLint se disponível
    if command -v swiftlint >/dev/null 2>&1; then
        swiftlint --strict
        if [ $? -ne 0 ]; then
            echo "❌ SwiftLint encontrou problemas. Corrija antes de fazer commit."
            exit 1
        fi
    fi
fi

# Verificar se há segredos no código
echo "🔒 Verificando segredos no código..."
if git diff --cached --name-only | xargs grep -l "sk_live\|pk_live\|sk_test.*[a-zA-Z0-9]{20}" 2>/dev/null; then
    echo "❌ Possíveis chaves de API encontradas no código. Remova antes de fazer commit."
    exit 1
fi

echo "✅ Verificações pre-commit concluídas com sucesso!"
EOF
        
        chmod +x "$pre_commit_hook"
        print_success "Hook pre-commit configurado"
        
        # Configurar Git para usar hooks
        git config core.hooksPath .git/hooks
        print_success "Git configurado para usar hooks"
    else
        print_warning "Não é um repositório Git"
    fi
    
    echo ""
}

# Função para configurar ferramentas de desenvolvimento
setup_dev_tools() {
    print_section "Configurando Ferramentas de Desenvolvimento"
    
    # Configurar SwiftLint se disponível
    if command_exists swiftlint; then
        if [ ! -f ".swiftlint.yml" ]; then
            print_info "Criando configuração do SwiftLint..."
            cat > ".swiftlint.yml" << 'EOF'
# Configuração do SwiftLint para ManusPsiqueia

# Regras habilitadas
opt_in_rules:
  - array_init
  - attributes
  - closure_end_indentation
  - closure_spacing
  - collection_alignment
  - contains_over_first_not_nil
  - empty_count
  - empty_string
  - explicit_init
  - extension_access_modifier
  - fallthrough
  - fatal_error_message
  - file_header
  - first_where
  - force_unwrapping
  - implicitly_unwrapped_optional
  - joined_default_parameter
  - let_var_whitespace
  - literal_expression_end_indentation
  - multiline_arguments
  - multiline_function_chains
  - multiline_literal_brackets
  - multiline_parameters
  - nimble_operator
  - number_separator
  - object_literal
  - operator_usage_whitespace
  - overridden_super_call
  - pattern_matching_keywords
  - prefer_self_type_over_type_of_self
  - redundant_nil_coalescing
  - redundant_type_annotation
  - strict_fileprivate
  - switch_case_on_newline
  - toggle_bool
  - trailing_closure
  - unneeded_parentheses_in_closure_argument
  - unused_import
  - unused_private_declaration
  - vertical_parameter_alignment_on_call
  - vertical_whitespace_closing_braces
  - vertical_whitespace_opening_braces
  - yoda_condition

# Regras desabilitadas
disabled_rules:
  - trailing_whitespace

# Configurações
line_length: 120
function_body_length: 60
file_length: 500
type_body_length: 300

# Diretórios excluídos
excluded:
  - .build
  - Pods
  - build
  - DerivedData

# Configuração do cabeçalho de arquivo
file_header:
  required_pattern: |
                    \/\/
                    \/\/  .*\.swift
                    \/\/  ManusPsiqueia
                    \/\/
                    \/\/  Created by .* on \d{4}-\d{2}-\d{2}\.
                    \/\/  Copyright © \d{4} AiLun Tecnologia\. All rights reserved\.
                    \/\/
EOF
            print_success "Configuração do SwiftLint criada"
        else
            print_info "Configuração do SwiftLint já existe"
        fi
    else
        print_warning "SwiftLint não instalado (recomendado)"
        print_info "Para instalar: brew install swiftlint"
    fi
    
    echo ""
}

# Função para configurar variáveis de ambiente
setup_environment_variables() {
    print_section "Configurando Variáveis de Ambiente"
    
    # Criar arquivo de exemplo para variáveis de ambiente
    local env_example=".env.example"
    
    if [ ! -f "$env_example" ]; then
        cat > "$env_example" << 'EOF'
# Variáveis de Ambiente - ManusPsiqueia
# Copie este arquivo para .env e configure com seus valores reais

# Development Environment
STRIPE_PUBLISHABLE_KEY_DEV=pk_test_your_development_key_here
SUPABASE_URL_DEV=https://your-dev-project.supabase.co
SUPABASE_ANON_KEY_DEV=your_development_anon_key_here
OPENAI_API_KEY_DEV=sk-your_development_openai_key_here

# Staging Environment
STRIPE_PUBLISHABLE_KEY_STAGING=pk_test_your_staging_key_here
SUPABASE_URL_STAGING=https://your-staging-project.supabase.co
SUPABASE_ANON_KEY_STAGING=your_staging_anon_key_here
OPENAI_API_KEY_STAGING=sk-your_staging_openai_key_here

# Production Environment
STRIPE_PUBLISHABLE_KEY_PROD=pk_live_your_production_key_here
SUPABASE_URL_PROD=https://your-prod-project.supabase.co
SUPABASE_ANON_KEY_PROD=your_production_anon_key_here
OPENAI_API_KEY_PROD=sk-your_production_openai_key_here

# Team Configuration
DEVELOPMENT_TEAM_ID=YOUR_TEAM_ID_HERE
EOF
        print_success "Arquivo .env.example criado"
    else
        print_info "Arquivo .env.example já existe"
    fi
    
    # Verificar se .env existe
    if [ ! -f ".env" ]; then
        print_warning "Arquivo .env não encontrado"
        print_info "Copie .env.example para .env e configure com seus valores reais"
    else
        print_success "Arquivo .env encontrado"
    fi
    
    echo ""
}

# Função para executar testes
run_tests() {
    print_section "Executando Testes"
    
    if [ -f "Package.swift" ]; then
        print_info "Executando testes do Swift Package Manager..."
        
        if swift test; then
            print_success "Todos os testes passaram!"
        else
            print_warning "Alguns testes falharam"
        fi
    else
        print_warning "Package.swift não encontrado, pulando testes"
    fi
    
    echo ""
}

# Função para gerar relatório de setup
generate_setup_report() {
    print_section "Gerando Relatório de Setup"
    
    local report_file="setup_report.md"
    
    cat > "$report_file" << EOF
# Relatório de Setup - ManusPsiqueia

**Data:** $(date)
**Versão do Script:** 1.0.0

## Status do Setup

### ✅ Concluído
- Verificação de dependências
- Configuração de ambiente
- Configuração do Swift Package Manager
- Configuração de Git hooks
- Configuração de ferramentas de desenvolvimento
- Configuração de variáveis de ambiente

### 📋 Próximos Passos Manuais

1. **Configurar Chaves de API:**
   - Copie \`.env.example\` para \`.env\`
   - Configure suas chaves reais do Stripe, Supabase e OpenAI

2. **Configurar Xcode:**
   - Abra o projeto no Xcode
   - Configure seu Team ID nas configurações de assinatura
   - Verifique se todos os targets compilam

3. **Configurar Xcode Cloud (opcional):**
   - Configure workflows no Xcode Cloud
   - Adicione variáveis de ambiente no Xcode Cloud
   - Configure scripts de CI/CD

4. **Testar Integrações:**
   - Execute testes unitários
   - Teste conectividade das APIs
   - Valide fluxos de pagamento

## Comandos Úteis

\`\`\`bash
# Resolver dependências
swift package resolve

# Executar testes
swift test

# Verificar conectividade das APIs
./scripts/check_api_connectivity.sh

# Verificar saúde do projeto
./scripts/project_health_monitor.sh

# Validar assinatura de código
./scripts/validate_code_signing.sh
\`\`\`

## Estrutura do Projeto

\`\`\`
ManusPsiqueia/
├── ManusPsiqueia/          # Código fonte principal
├── ManusPsiqueiaTests/     # Testes unitários
├── Configuration/          # Configurações por ambiente
├── ci_scripts/            # Scripts para Xcode Cloud
├── scripts/               # Scripts de automação
├── docs/                  # Documentação
├── Modules/               # Módulos Swift Package
└── Package.swift          # Configuração SPM
\`\`\`

## Contato

Para dúvidas ou problemas, consulte a documentação em \`docs/\` ou entre em contato com a equipe de desenvolvimento.
EOF
    
    print_success "Relatório de setup gerado: $report_file"
    echo ""
}

# Função principal
main() {
    print_header
    
    # Verificar se estamos no diretório correto
    if [ ! -f "Package.swift" ] && [ ! -d "ManusPsiqueia" ]; then
        print_error "Este script deve ser executado no diretório raiz do projeto ManusPsiqueia"
        exit 1
    fi
    
    print_info "Iniciando setup automático do projeto ManusPsiqueia..."
    echo ""
    
    # Executar etapas do setup
    check_dependencies
    setup_environment
    setup_swift_packages
    setup_git_hooks
    setup_dev_tools
    setup_environment_variables
    run_tests
    generate_setup_report
    
    # Mensagem final
    print_section "Setup Concluído!"
    print_success "O projeto ManusPsiqueia foi configurado com sucesso!"
    echo ""
    print_info "Próximos passos:"
    echo "  1. Configure suas chaves de API no arquivo .env"
    echo "  2. Abra o projeto no Xcode"
    echo "  3. Configure seu Team ID para assinatura de código"
    echo "  4. Execute os testes para validar a configuração"
    echo ""
    print_info "Para mais informações, consulte o arquivo setup_report.md"
    echo ""
}

# Executar função principal
main "$@"
