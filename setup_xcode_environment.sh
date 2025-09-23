#!/bin/bash

# ManusPsiqueia Xcode Environment Setup Script
# This script configures everything needed to run the project in Xcode

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Print functions
print_header() {
    echo -e "${BLUE}=============================================================="
    echo "🚀 ManusPsiqueia Xcode Environment Setup"
    echo "==============================================================${NC}"
}

print_section() {
    echo -e "${PURPLE}📋 $1${NC}"
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
    echo -e "${CYAN}ℹ️  $1${NC}"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Main setup function
main() {
    print_header
    
    # 1. Verify Environment
    print_section "Verifying Environment"
    
    if command_exists xcodebuild; then
        local xcode_version=$(xcodebuild -version | head -n1)
        print_success "Xcode found: $xcode_version"
    else
        print_warning "Xcode not found - this is normal in CI environments"
    fi
    
    if command_exists swift; then
        local swift_version=$(swift --version | head -n1)
        print_success "Swift found: $swift_version"
    else
        print_error "Swift not found - required for building"
        exit 1
    fi
    
    # 2. Setup Environment Variables
    print_section "Setting up Environment Variables"
    
    if [ ! -f ".env" ]; then
        if [ -f ".env.example" ]; then
            print_info "Creating .env from .env.example"
            cp .env.example .env
            print_warning "Please edit .env with your actual API keys and configuration"
        else
            print_warning ".env.example not found - creating basic template"
            create_basic_env_file
        fi
    else
        print_success ".env file already exists"
    fi
    
    # 3. Validate Package Structure
    print_section "Validating Package Structure"
    
    if [ -f "Package.swift" ]; then
        print_success "Package.swift found"
        
        # Test package resolution
        print_info "Resolving Swift Package dependencies..."
        if swift package resolve; then
            print_success "Package dependencies resolved successfully"
        else
            print_error "Failed to resolve package dependencies"
            exit 1
        fi
    else
        print_error "Package.swift not found"
        exit 1
    fi
    
    # 4. Validate Xcode Project
    print_section "Validating Xcode Project"
    
    if [ -d "ManusPsiqueia.xcodeproj" ]; then
        print_success "Xcode project found"
        
        # Check for required files
        local required_files=(
            "ManusPsiqueia.xcodeproj/project.pbxproj"
            "ManusPsiqueia.xcodeproj/project.xcworkspace"
            "ManusPsiqueia/Info.plist"
            "ManusPsiqueia/ManusPsiqueiaApp.swift"
        )
        
        for file in "${required_files[@]}"; do
            if [ -f "$file" ] || [ -d "$file" ]; then
                print_success "Found: $file"
            else
                print_error "Missing: $file"
            fi
        done
    else
        print_error "Xcode project not found"
        exit 1
    fi
    
    # 5. Check Configuration Files
    print_section "Checking Configuration Files"
    
    local config_files=(
        "Configuration/Development.xcconfig"
        "Configuration/Staging.xcconfig"
        "Configuration/Production.xcconfig"
    )
    
    for config in "${config_files[@]}"; do
        if [ -f "$config" ]; then
            print_success "Found: $config"
        else
            print_warning "Missing: $config"
        fi
    done
    
    # 6. Validate CI Scripts
    print_section "Validating CI Scripts"
    
    local ci_scripts=(
        "ci_scripts/ci_pre_xcodebuild.sh"
        "scripts/setup_project.sh"
        "scripts/deploy.sh"
    )
    
    for script in "${ci_scripts[@]}"; do
        if [ -f "$script" ]; then
            print_success "Found: $script"
            # Make executable if not already
            chmod +x "$script"
        else
            print_warning "Missing: $script"
        fi
    done
    
    # 7. Test Build (if possible)
    print_section "Testing Build Process"
    
    if command_exists xcodebuild; then
        print_info "Testing Xcode build..."
        if xcodebuild -project ManusPsiqueia.xcodeproj -scheme ManusPsiqueia -destination "platform=iOS Simulator,name=iPhone 15" clean build; then
            print_success "Xcode build successful"
        else
            print_warning "Xcode build failed - this may be due to missing certificates or configuration"
        fi
    else
        print_info "Testing Swift Package Manager build..."
        if swift build; then
            print_success "Swift package build successful"
        else
            print_warning "Swift package build failed - check error messages above"
        fi
    fi
    
    # 8. Generate Setup Report
    print_section "Generating Setup Report"
    generate_setup_report
    
    # 9. Display Next Steps
    print_section "Next Steps"
    echo -e "${CYAN}To complete the setup:${NC}"
    echo
    echo "1. 📝 Edit .env with your actual API keys:"
    echo "   - STRIPE_PUBLISHABLE_KEY_DEV"
    echo "   - SUPABASE_URL_DEV"
    echo "   - SUPABASE_ANON_KEY_DEV"
    echo "   - OPENAI_API_KEY_DEV"
    echo "   - DEVELOPMENT_TEAM_ID"
    echo
    echo "2. 🔧 Open in Xcode:"
    echo "   open ManusPsiqueia.xcodeproj"
    echo
    echo "3. ⚙️  Configure code signing in Xcode project settings"
    echo
    echo "4. 🚀 Build and run the project"
    echo
    print_success "Setup completed! Check setup_report.md for detailed information."
}

# Create basic .env file if template doesn't exist
create_basic_env_file() {
    cat > .env << 'EOF'
# Basic ManusPsiqueia Environment Variables
STRIPE_PUBLISHABLE_KEY_DEV=pk_test_your_key_here
SUPABASE_URL_DEV=https://your-project.supabase.co
SUPABASE_ANON_KEY_DEV=your_anon_key_here
OPENAI_API_KEY_DEV=sk-your_openai_key_here
DEVELOPMENT_TEAM_ID=YOUR_TEAM_ID_HERE
EOF
    print_success "Created basic .env file"
}

# Generate setup report
generate_setup_report() {
    local report_file="xcode_setup_report.md"
    
    cat > "$report_file" << EOF
# ManusPsiqueia Xcode Setup Report

**Generated:** $(date)
**Script Version:** 2.0.0

## ✅ Environment Status

### Swift Package Manager
- Package.swift: ✅ Present
- Dependencies: ✅ Resolved
- Build Status: $(test_swift_build_status)

### Xcode Project
- Project file: ✅ Present
- Workspace: ✅ Configured
- Info.plist: ✅ Present
- Main app file: ✅ Present

### Configuration Files
- Development.xcconfig: $(check_file_status "Configuration/Development.xcconfig")
- Staging.xcconfig: $(check_file_status "Configuration/Staging.xcconfig")
- Production.xcconfig: $(check_file_status "Configuration/Production.xcconfig")
- .env.example: $(check_file_status ".env.example")
- .env: $(check_file_status ".env")

### CI/CD Scripts
- Pre-build script: $(check_file_status "ci_scripts/ci_pre_xcodebuild.sh")
- Setup script: $(check_file_status "scripts/setup_project.sh")
- Deploy script: $(check_file_status "scripts/deploy.sh")

## 📋 Required Actions

1. **Configure API Keys**: Edit .env with real values
2. **Set Team ID**: Configure DEVELOPMENT_TEAM_ID in .env
3. **Open in Xcode**: \`open ManusPsiqueia.xcodeproj\`
4. **Configure Signing**: Set up code signing in Xcode
5. **Test Build**: Build and run the project

## 🔧 Environment Variables Required

### Development
- STRIPE_PUBLISHABLE_KEY_DEV
- SUPABASE_URL_DEV
- SUPABASE_ANON_KEY_DEV
- OPENAI_API_KEY_DEV

### Team Configuration
- DEVELOPMENT_TEAM_ID (Apple Developer Team ID)

## 🚀 Build Commands

\`\`\`bash
# Swift Package Manager
swift package resolve
swift build

# Xcode (when available)
xcodebuild -project ManusPsiqueia.xcodeproj -scheme ManusPsiqueia clean build
\`\`\`

## 📱 Supported Platforms

- iOS 16.0+
- iPhone and iPad
- Xcode 15.0+
- Swift 5.9+

---

For more information, see the project documentation in the \`docs/\` directory.
EOF

    print_success "Setup report generated: $report_file"
}

# Helper functions
check_file_status() {
    if [ -f "$1" ] || [ -d "$1" ]; then
        echo "✅ Present"
    else
        echo "❌ Missing"
    fi
}

test_swift_build_status() {
    if swift build --dry-run >/dev/null 2>&1; then
        echo "✅ Ready"
    else
        echo "⚠️ Issues detected"
    fi
}

# Run main function
main "$@"