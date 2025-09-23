#!/bin/bash

# ManusPsiqueia Xcode Build Validation Script
# This script validates that the project is ready for Xcode builds

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_section() {
    echo -e "${BLUE}📋 $1${NC}"
    echo "--------------------------------------------------------------"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Validate Xcode project structure
validate_xcode_project() {
    print_section "Validating Xcode Project Structure"
    
    # Check if we can list targets and schemes
    if command -v xcodebuild >/dev/null 2>&1; then
        print_info "Listing Xcode project information:"
        
        echo "📱 Available targets:"
        xcodebuild -list -project ManusPsiqueia.xcodeproj | grep -A 10 "Targets:" || print_warning "Could not list targets"
        
        echo "🎯 Available schemes:"
        xcodebuild -list -project ManusPsiqueia.xcodeproj | grep -A 10 "Schemes:" || print_warning "Could not list schemes"
        
        echo "⚙️  Build configurations:"
        xcodebuild -list -project ManusPsiqueia.xcodeproj | grep -A 10 "Build Configurations:" || print_warning "Could not list build configurations"
        
    else
        print_warning "xcodebuild not available - skipping Xcode-specific validation"
    fi
}

# Test different build configurations
test_build_configurations() {
    print_section "Testing Build Configurations"
    
    if command -v xcodebuild >/dev/null 2>&1; then
        local configurations=("Debug" "Release")
        
        for config in "${configurations[@]}"; do
            print_info "Testing $config configuration..."
            
            if xcodebuild -project ManusPsiqueia.xcodeproj \
                         -scheme ManusPsiqueia \
                         -configuration "$config" \
                         -destination "platform=iOS Simulator,name=iPhone 15" \
                         -dry-run 2>/dev/null; then
                print_success "$config configuration is valid"
            else
                print_warning "$config configuration has issues"
            fi
        done
    else
        print_warning "xcodebuild not available - cannot test build configurations"
    fi
}

# Validate environment setup
validate_environment() {
    print_section "Validating Environment Setup"
    
    # Check .env file
    if [ -f ".env" ]; then
        print_success ".env file found"
        
        # Check for required variables
        local required_vars=(
            "STRIPE_PUBLISHABLE_KEY_DEV"
            "SUPABASE_URL_DEV" 
            "SUPABASE_ANON_KEY_DEV"
            "OPENAI_API_KEY_DEV"
            "DEVELOPMENT_TEAM_ID"
        )
        
        for var in "${required_vars[@]}"; do
            if grep -q "^${var}=" .env && ! grep -q "^${var}=.*_here$" .env; then
                print_success "$var is configured"
            else
                print_warning "$var needs to be configured in .env"
            fi
        done
    else
        print_error ".env file not found - copy .env.example to .env and configure"
    fi
    
    # Check xcconfig files
    local environments=("Development" "Staging" "Production")
    for env in "${environments[@]}"; do
        local config_file="Configuration/${env}.xcconfig"
        if [ -f "$config_file" ]; then
            print_success "$env configuration found"
        else
            print_error "$env configuration missing: $config_file"
        fi
    done
}

# Check code signing setup
validate_code_signing() {
    print_section "Validating Code Signing"
    
    if [ -f ".env" ]; then
        local team_id=$(grep "^DEVELOPMENT_TEAM_ID=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'")
        
        if [ -n "$team_id" ] && [ "$team_id" != "YOUR_TEAM_ID_HERE" ]; then
            print_success "Development Team ID configured: $team_id"
        else
            print_warning "Development Team ID not configured - required for device builds"
        fi
    fi
    
    if command -v security >/dev/null 2>&1; then
        print_info "Available signing identities:"
        security find-identity -v -p codesigning 2>/dev/null | head -5 || print_warning "No signing identities found"
    fi
}

# Validate dependencies
validate_dependencies() {
    print_section "Validating Dependencies"
    
    # Check if Package.resolved exists
    if [ -f "Package.resolved" ]; then
        print_success "Package.resolved found - dependencies are locked"
        
        print_info "Key dependencies:"
        if command -v jq >/dev/null 2>&1; then
            # Use jq if available for better parsing
            jq -r '.pins[] | "\(.identity): \(.state.version // .state.revision[0:8])"' Package.resolved 2>/dev/null | head -10 || {
                # Fallback to grep if jq fails
                grep -E "(stripe|supabase|openai)" Package.resolved || print_info "Using all configured dependencies"
            }
        else
            grep -E "(stripe|supabase|openai)" Package.resolved || print_info "All dependencies resolved"
        fi
    else
        print_warning "Package.resolved not found - run 'swift package resolve'"
    fi
    
    # Check local modules
    local modules=("ManusPsiqueiaServices" "ManusPsiqueiaUI")
    for module in "${modules[@]}"; do
        if [ -d "Modules/$module" ] && [ -f "Modules/$module/Package.swift" ]; then
            print_success "Local module found: $module"
        else
            print_warning "Local module missing or incomplete: $module"
        fi
    done
}

# Generate validation report
generate_validation_report() {
    local report_file="xcode_validation_report.md"
    
    cat > "$report_file" << EOF
# ManusPsiqueia Xcode Validation Report

**Generated:** $(date)
**Validator Version:** 1.0.0

## 🔍 Validation Summary

### Project Structure
- Xcode Project: $(test -d "ManusPsiqueia.xcodeproj" && echo "✅ Present" || echo "❌ Missing")
- Swift Package: $(test -f "Package.swift" && echo "✅ Present" || echo "❌ Missing")
- Main App File: $(test -f "ManusPsiqueia/ManusPsiqueiaApp.swift" && echo "✅ Present" || echo "❌ Missing")
- Info.plist: $(test -f "ManusPsiqueia/Info.plist" && echo "✅ Present" || echo "❌ Missing")

### Configuration
- Environment Variables: $(test -f ".env" && echo "✅ Configured" || echo "❌ Missing")
- Development Config: $(test -f "Configuration/Development.xcconfig" && echo "✅ Present" || echo "❌ Missing")
- Staging Config: $(test -f "Configuration/Staging.xcconfig" && echo "✅ Present" || echo "❌ Missing")
- Production Config: $(test -f "Configuration/Production.xcconfig" && echo "✅ Present" || echo "❌ Missing")

### Dependencies
- Package.resolved: $(test -f "Package.resolved" && echo "✅ Present" || echo "❌ Missing")
- Local Modules: $(find Modules -name "Package.swift" | wc -l) configured

### CI/CD
- Pre-build Script: $(test -f "ci_scripts/ci_pre_xcodebuild.sh" && echo "✅ Present" || echo "❌ Missing")
- Setup Script: $(test -f "scripts/setup_project.sh" && echo "✅ Present" || echo "❌ Missing")

## 🚀 Build Commands

### Local Development
\`\`\`bash
# Open in Xcode
open ManusPsiqueia.xcodeproj

# Build with xcodebuild
xcodebuild -project ManusPsiqueia.xcodeproj -scheme ManusPsiqueia build

# Clean build
xcodebuild -project ManusPsiqueia.xcodeproj -scheme ManusPsiqueia clean build
\`\`\`

### CI/CD
\`\`\`bash
# Run pre-build script
./ci_scripts/ci_pre_xcodebuild.sh

# Deploy to different environments
./scripts/deploy.sh development
./scripts/deploy.sh staging
./scripts/deploy.sh production
\`\`\`

## ⚠️ Required Actions

1. Configure .env with real API keys
2. Set DEVELOPMENT_TEAM_ID for code signing
3. Test build in Xcode
4. Configure Xcode Cloud workflows (if using)

## 📱 Platform Support

- iOS 16.0+
- iPhone and iPad
- Xcode 15.0+
- Swift 5.9+

---

For issues, check the troubleshooting guide in docs/setup/
EOF

    print_success "Validation report generated: $report_file"
}

# Main validation
main() {
    echo -e "${BLUE}🔍 ManusPsiqueia Xcode Build Validation${NC}"
    echo "=============================================================="
    
    validate_xcode_project
    validate_environment
    validate_dependencies
    validate_code_signing
    test_build_configurations
    generate_validation_report
    
    echo
    print_success "Validation completed! Check xcode_validation_report.md for details."
    
    echo
    echo -e "${BLUE}💡 Quick Start Commands:${NC}"
    echo "  • Open project: open ManusPsiqueia.xcodeproj"
    echo "  • Configure env: cp .env.example .env && nano .env"
    echo "  • Test build: xcodebuild -project ManusPsiqueia.xcodeproj -scheme ManusPsiqueia build"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi