#!/bin/bash

# Script de Deploy Automatizado - ManusPsiqueia
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

# Configurações
SCHEME_NAME="ManusPsiqueia"
WORKSPACE_NAME="ManusPsiqueia.xcworkspace"
PROJECT_NAME="ManusPsiqueia.xcodeproj"

# Função para imprimir cabeçalho
print_header() {
    echo -e "${BLUE}"
    echo "=============================================================="
    echo "🚀 Deploy Automatizado - ManusPsiqueia"
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

# Função para mostrar ajuda
show_help() {
    echo "Uso: $0 [OPÇÕES] AMBIENTE"
    echo ""
    echo "AMBIENTES:"
    echo "  development    Deploy para ambiente de desenvolvimento"
    echo "  staging        Deploy para TestFlight (staging)"
    echo "  production     Deploy para App Store (produção)"
    echo ""
    echo "OPÇÕES:"
    echo "  -h, --help     Mostrar esta ajuda"
    echo "  -v, --verbose  Modo verboso"
    echo "  --skip-tests   Pular execução de testes"
    echo "  --skip-build   Pular build (apenas upload)"
    echo "  --dry-run      Simular deploy sem executar"
    echo ""
    echo "EXEMPLOS:"
    echo "  $0 staging                    # Deploy para TestFlight"
    echo "  $0 production --skip-tests    # Deploy para App Store sem testes"
    echo "  $0 development --dry-run      # Simular deploy de desenvolvimento"
}

# Função para verificar dependências
check_dependencies() {
    print_section "Verificando Dependências"
    
    local missing_deps=()
    
    # Verificar Xcode
    if ! command -v xcodebuild >/dev/null 2>&1; then
        missing_deps+=("xcodebuild")
    fi
    
    # Verificar altool (para upload)
    if ! command -v xcrun >/dev/null 2>&1; then
        missing_deps+=("xcrun")
    fi
    
    # Verificar Git
    if ! command -v git >/dev/null 2>&1; then
        missing_deps+=("git")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Dependências faltando:"
        for dep in "${missing_deps[@]}"; do
            echo "  - $dep"
        done
        exit 1
    fi
    
    print_success "Todas as dependências estão instaladas"
    echo ""
}

# Função para verificar configuração do ambiente
check_environment_config() {
    local environment=$1
    print_section "Verificando Configuração do Ambiente: $environment"
    
    # Verificar se o arquivo de configuração existe
    local config_file="Configuration/${environment^}.xcconfig"
    if [ ! -f "$config_file" ]; then
        print_error "Arquivo de configuração não encontrado: $config_file"
        exit 1
    fi
    
    print_success "Arquivo de configuração encontrado: $config_file"
    
    # Verificar variáveis de ambiente necessárias
    local required_vars=()
    
    case $environment in
        "development")
            required_vars=("DEVELOPMENT_TEAM_ID")
            ;;
        "staging")
            required_vars=("DEVELOPMENT_TEAM_ID" "STRIPE_PUBLISHABLE_KEY_STAGING")
            ;;
        "production")
            required_vars=("DEVELOPMENT_TEAM_ID" "STRIPE_PUBLISHABLE_KEY_PROD")
            ;;
    esac
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            print_warning "Variável de ambiente não definida: $var"
        else
            print_success "Variável de ambiente configurada: $var"
        fi
    done
    
    echo ""
}

# Função para executar testes
run_tests() {
    if [ "$SKIP_TESTS" = true ]; then
        print_warning "Pulando execução de testes (--skip-tests)"
        return 0
    fi
    
    print_section "Executando Testes"
    
    local test_scheme="${SCHEME_NAME}Tests"
    local destination="platform=iOS Simulator,name=iPhone 15,OS=latest"
    
    print_info "Executando testes unitários..."
    
    if [ "$DRY_RUN" = true ]; then
        print_info "[DRY RUN] Comando que seria executado:"
        echo "xcodebuild test -scheme $test_scheme -destination '$destination'"
    else
        if xcodebuild test \
            -scheme "$test_scheme" \
            -destination "$destination" \
            -quiet; then
            print_success "Todos os testes passaram!"
        else
            print_error "Alguns testes falharam"
            exit 1
        fi
    fi
    
    echo ""
}

# Função para fazer build
build_app() {
    local environment=$1
    
    if [ "$SKIP_BUILD" = true ]; then
        print_warning "Pulando build (--skip-build)"
        return 0
    fi
    
    print_section "Fazendo Build para $environment"
    
    # Determinar configuração baseada no ambiente
    local configuration
    local export_method
    
    case $environment in
        "development")
            configuration="Debug"
            export_method="development"
            ;;
        "staging")
            configuration="Release"
            export_method="app-store"
            ;;
        "production")
            configuration="Release"
            export_method="app-store"
            ;;
    esac
    
    # Limpar build anterior
    print_info "Limpando build anterior..."
    if [ "$DRY_RUN" = true ]; then
        print_info "[DRY RUN] xcodebuild clean"
    else
        xcodebuild clean \
            -scheme "$SCHEME_NAME" \
            -configuration "$configuration" \
            -quiet
    fi
    
    # Fazer build
    print_info "Fazendo build da aplicação..."
    
    local build_dir="build"
    local archive_path="$build_dir/${SCHEME_NAME}_${environment}.xcarchive"
    
    if [ "$DRY_RUN" = true ]; then
        print_info "[DRY RUN] Comando de build que seria executado:"
        echo "xcodebuild archive -scheme $SCHEME_NAME -configuration $configuration -archivePath $archive_path"
    else
        # Criar diretório de build
        mkdir -p "$build_dir"
        
        # Fazer archive
        if xcodebuild archive \
            -scheme "$SCHEME_NAME" \
            -configuration "$configuration" \
            -archivePath "$archive_path" \
            -quiet; then
            print_success "Build concluído com sucesso!"
            print_info "Archive salvo em: $archive_path"
        else
            print_error "Falha no build"
            exit 1
        fi
    fi
    
    echo ""
}

# Função para exportar IPA
export_ipa() {
    local environment=$1
    
    if [ "$SKIP_BUILD" = true ]; then
        print_warning "Pulando export (--skip-build)"
        return 0
    fi
    
    print_section "Exportando IPA para $environment"
    
    local build_dir="build"
    local archive_path="$build_dir/${SCHEME_NAME}_${environment}.xcarchive"
    local export_path="$build_dir/${environment}_export"
    
    # Criar plist de export
    local export_plist="$build_dir/export_${environment}.plist"
    
    case $environment in
        "development")
            cat > "$export_plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <key>teamID</key>
    <string>\${DEVELOPMENT_TEAM_ID}</string>
    <key>compileBitcode</key>
    <false/>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>thinning</key>
    <string>&lt;none&gt;</string>
</dict>
</plist>
EOF
            ;;
        "staging"|"production")
            cat > "$export_plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>\${DEVELOPMENT_TEAM_ID}</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>thinning</key>
    <string>&lt;none&gt;</string>
</dict>
</plist>
EOF
            ;;
    esac
    
    if [ "$DRY_RUN" = true ]; then
        print_info "[DRY RUN] Comando de export que seria executado:"
        echo "xcodebuild -exportArchive -archivePath $archive_path -exportPath $export_path -exportOptionsPlist $export_plist"
    else
        # Fazer export
        if xcodebuild -exportArchive \
            -archivePath "$archive_path" \
            -exportPath "$export_path" \
            -exportOptionsPlist "$export_plist" \
            -quiet; then
            print_success "IPA exportado com sucesso!"
            print_info "IPA salvo em: $export_path"
        else
            print_error "Falha no export do IPA"
            exit 1
        fi
    fi
    
    echo ""
}

# Função para fazer upload
upload_app() {
    local environment=$1
    
    if [ "$environment" = "development" ]; then
        print_info "Upload não necessário para ambiente de desenvolvimento"
        return 0
    fi
    
    print_section "Fazendo Upload para $environment"
    
    local build_dir="build"
    local export_path="$build_dir/${environment}_export"
    local ipa_file="$export_path/${SCHEME_NAME}.ipa"
    
    if [ "$DRY_RUN" = true ]; then
        print_info "[DRY RUN] Comando de upload que seria executado:"
        echo "xcrun altool --upload-app --type ios --file $ipa_file --username \$APPLE_ID --password \$APP_SPECIFIC_PASSWORD"
        return 0
    fi
    
    # Verificar se o IPA existe
    if [ ! -f "$ipa_file" ]; then
        print_error "Arquivo IPA não encontrado: $ipa_file"
        exit 1
    fi
    
    # Verificar credenciais
    if [ -z "$APPLE_ID" ] || [ -z "$APP_SPECIFIC_PASSWORD" ]; then
        print_error "Credenciais do Apple ID não configuradas"
        print_info "Configure as variáveis APPLE_ID e APP_SPECIFIC_PASSWORD"
        exit 1
    fi
    
    print_info "Fazendo upload para App Store Connect..."
    
    if xcrun altool --upload-app \
        --type ios \
        --file "$ipa_file" \
        --username "$APPLE_ID" \
        --password "$APP_SPECIFIC_PASSWORD" \
        --verbose; then
        print_success "Upload concluído com sucesso!"
        
        case $environment in
            "staging")
                print_info "O app estará disponível no TestFlight em alguns minutos"
                ;;
            "production")
                print_info "O app foi enviado para revisão da App Store"
                ;;
        esac
    else
        print_error "Falha no upload"
        exit 1
    fi
    
    echo ""
}

# Função para gerar relatório de deploy
generate_deploy_report() {
    local environment=$1
    local start_time=$2
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    print_section "Gerando Relatório de Deploy"
    
    local report_file="deploy_report_${environment}_$(date +%Y%m%d_%H%M%S).md"
    
    cat > "$report_file" << EOF
# Relatório de Deploy - ManusPsiqueia

**Ambiente:** $environment
**Data:** $(date)
**Duração:** ${duration}s

## Status do Deploy

### ✅ Etapas Concluídas
- Verificação de dependências
- Verificação de configuração do ambiente
$([ "$SKIP_TESTS" != true ] && echo "- Execução de testes")
$([ "$SKIP_BUILD" != true ] && echo "- Build da aplicação")
$([ "$SKIP_BUILD" != true ] && echo "- Export do IPA")
$([ "$environment" != "development" ] && echo "- Upload para App Store Connect")

### 📊 Informações do Build

- **Scheme:** $SCHEME_NAME
- **Configuração:** $([ "$environment" = "development" ] && echo "Debug" || echo "Release")
- **Ambiente:** $environment
- **Timestamp:** $(date -Iseconds)

### 📱 Próximos Passos

EOF

    case $environment in
        "development")
            echo "- Instalar o app no dispositivo de desenvolvimento" >> "$report_file"
            echo "- Testar funcionalidades localmente" >> "$report_file"
            ;;
        "staging")
            echo "- Aguardar processamento no TestFlight (5-10 minutos)" >> "$report_file"
            echo "- Adicionar testadores internos/externos" >> "$report_file"
            echo "- Distribuir para equipe de QA" >> "$report_file"
            ;;
        "production")
            echo "- Aguardar revisão da Apple (1-7 dias)" >> "$report_file"
            echo "- Monitorar status no App Store Connect" >> "$report_file"
            echo "- Preparar materiais de marketing" >> "$report_file"
            ;;
    esac
    
    cat >> "$report_file" << EOF

### 🔗 Links Úteis

- [App Store Connect](https://appstoreconnect.apple.com/)
- [TestFlight](https://testflight.apple.com/)
- [Documentação do Projeto](./docs/)

---
*Relatório gerado automaticamente pelo script de deploy*
EOF
    
    print_success "Relatório de deploy gerado: $report_file"
    echo ""
}

# Função principal
main() {
    local environment=""
    local start_time=$(date +%s)
    
    # Valores padrão
    SKIP_TESTS=false
    SKIP_BUILD=false
    DRY_RUN=false
    VERBOSE=false
    
    # Processar argumentos
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            --skip-tests)
                SKIP_TESTS=true
                shift
                ;;
            --skip-build)
                SKIP_BUILD=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            development|staging|production)
                environment=$1
                shift
                ;;
            *)
                print_error "Argumento desconhecido: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Verificar se ambiente foi especificado
    if [ -z "$environment" ]; then
        print_error "Ambiente não especificado"
        show_help
        exit 1
    fi
    
    print_header
    
    if [ "$DRY_RUN" = true ]; then
        print_warning "MODO DRY RUN - Nenhuma ação será executada"
        echo ""
    fi
    
    print_info "Iniciando deploy para ambiente: $environment"
    echo ""
    
    # Executar etapas do deploy
    check_dependencies
    check_environment_config "$environment"
    run_tests
    build_app "$environment"
    export_ipa "$environment"
    upload_app "$environment"
    generate_deploy_report "$environment" "$start_time"
    
    # Mensagem final
    print_section "Deploy Concluído!"
    print_success "Deploy para $environment executado com sucesso!"
    echo ""
    
    case $environment in
        "development")
            print_info "O app está pronto para instalação em dispositivos de desenvolvimento"
            ;;
        "staging")
            print_info "O app será processado no TestFlight em alguns minutos"
            ;;
        "production")
            print_info "O app foi enviado para revisão da Apple"
            ;;
    esac
    
    echo ""
}

# Executar função principal
main "$@"
