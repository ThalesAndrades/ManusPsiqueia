#!/bin/bash

# Bitbucket Server Deployment Script for ManusPsiqueia
# Optimized for on-premises Bitbucket Server with macOS build agents
# Author: AiLun Tecnologia
# CNPJ: 60.740.536/0001-75

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCHEME_NAME="ManusPsiqueia"
WORKSPACE_NAME="ManusPsiqueia.xcworkspace"
PROJECT_NAME="ManusPsiqueia.xcodeproj"

# Bitbucket Server specific configuration
BITBUCKET_SERVER_URL="${BITBUCKET_SERVER_URL:-https://bitbucket-server.internal}"
BITBUCKET_PROJECT_KEY="${BITBUCKET_PROJECT_KEY:-MANUS}"
BITBUCKET_REPO_NAME="${BITBUCKET_REPO_NAME:-manuspsiqueia}"

# Pipeline environment variables
BITBUCKET_BUILD_NUMBER="${BITBUCKET_BUILD_NUMBER:-local}"
BITBUCKET_COMMIT="${BITBUCKET_COMMIT:-$(git rev-parse HEAD)}"
BITBUCKET_BRANCH="${BITBUCKET_BRANCH:-$(git branch --show-current)}"

# Function to print header
print_header() {
    echo -e "${BLUE}"
    echo "=============================================================="
    echo "🚀 Bitbucket Server Deploy - ManusPsiqueia"
    echo "=============================================================="
    echo -e "${NC}"
}

# Function to print section
print_section() {
    echo -e "${PURPLE}"
    echo ""
    echo "▶ $1"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${NC}"
}

# Function to print info
print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

# Function to print success
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Function to print error
print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [environment] [options]"
    echo ""
    echo "ENVIRONMENTS:"
    echo "  development   Deploy to development environment"
    echo "  staging       Deploy to TestFlight (requires certificates)"
    echo "  production    Deploy to App Store (requires certificates)"
    echo ""
    echo "OPTIONS:"
    echo "  -h, --help         Show this help"
    echo "  -v, --verbose      Enable verbose logging"
    echo "  --skip-tests       Skip test execution"
    echo "  --skip-build       Skip build (upload only)"
    echo "  --dry-run          Simulate deployment"
    echo "  --bitbucket-build  Running in Bitbucket Pipelines"
    echo ""
    echo "EXAMPLES:"
    echo "  $0 staging                     # Deploy to TestFlight"
    echo "  $0 production --skip-tests     # Deploy to App Store without tests"
    echo "  $0 development --dry-run       # Simulate development deploy"
    echo ""
    echo "BITBUCKET SERVER INTEGRATION:"
    echo "  This script is optimized for Bitbucket Server pipelines"
    echo "  Set BITBUCKET_BUILD_NUMBER, BITBUCKET_COMMIT, BITBUCKET_BRANCH"
    echo "  Configure build agents with Xcode 15.1+ and macOS Monterey+"
}

# Function to check dependencies
check_dependencies() {
    print_section "Checking Dependencies"
    
    local missing_deps=()
    
    # Check Xcode tools
    if ! command -v xcodebuild >/dev/null 2>&1; then
        missing_deps+=("xcodebuild")
    fi
    
    if ! command -v xcrun >/dev/null 2>&1; then
        missing_deps+=("xcrun")
    fi
    
    # Check Git
    if ! command -v git >/dev/null 2>&1; then
        missing_deps+=("git")
    fi
    
    # Check jq for JSON processing (Bitbucket API)
    if ! command -v jq >/dev/null 2>&1; then
        print_warning "jq not found, installing..."
        if command -v brew >/dev/null 2>&1; then
            brew install jq
        else
            print_error "Please install jq manually for Bitbucket API integration"
        fi
    fi
    
    # Check curl for API calls
    if ! command -v curl >/dev/null 2>&1; then
        missing_deps+=("curl")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing dependencies:"
        for dep in "${missing_deps[@]}"; do
            echo "  - $dep"
        done
        exit 1
    fi
    
    print_success "All dependencies are available"
    
    # Display tool versions
    print_info "Xcode version: $(xcodebuild -version | head -1)"
    print_info "Git version: $(git --version)"
    print_info "Build environment: $(uname -a)"
    echo ""
}

# Function to check environment configuration
check_environment_config() {
    local environment=$1
    print_section "Checking Environment Configuration: $environment"
    
    # Check Bitbucket Server environment
    if [ -z "$BITBUCKET_SERVER_URL" ]; then
        print_warning "BITBUCKET_SERVER_URL not set, using default"
    else
        print_info "Bitbucket Server: $BITBUCKET_SERVER_URL"
    fi
    
    print_info "Project: $BITBUCKET_PROJECT_KEY"
    print_info "Repository: $BITBUCKET_REPO_NAME"
    print_info "Build #: $BITBUCKET_BUILD_NUMBER"
    print_info "Commit: ${BITBUCKET_COMMIT:0:8}"
    print_info "Branch: $BITBUCKET_BRANCH"
    
    # Check for environment-specific configuration
    local config_file="Configuration/${environment^}.xcconfig"
    if [ ! -f "$config_file" ]; then
        print_error "Configuration file not found: $config_file"
        exit 1
    fi
    
    print_success "Configuration file found: $config_file"
    
    # Verify certificates for staging/production
    if [ "$environment" != "development" ]; then
        check_certificates "$environment"
    fi
    
    echo ""
}

# Function to check certificates
check_certificates() {
    local environment=$1
    print_info "Checking certificates for $environment deployment..."
    
    # Check if running in Bitbucket Pipelines
    if [ -n "$BITBUCKET_BUILD_NUMBER" ]; then
        # In Bitbucket Pipelines, certificates should be in environment variables
        if [ -z "$IOS_CERTIFICATE_P12" ]; then
            print_error "IOS_CERTIFICATE_P12 environment variable not set"
            exit 1
        fi
        
        if [ -z "$CERTIFICATE_PASSWORD" ]; then
            print_error "CERTIFICATE_PASSWORD environment variable not set"
            exit 1
        fi
        
        if [ -z "$PROVISIONING_PROFILE" ]; then
            print_error "PROVISIONING_PROFILE environment variable not set"
            exit 1
        fi
        
        # Decode and setup certificates
        setup_certificates_from_env
    else
        # Local development - check for certificate files
        if [ ! -f "Certificates/Distribution.p12" ]; then
            print_error "Distribution certificate not found: Certificates/Distribution.p12"
            exit 1
        fi
        
        if [ ! -f "Certificates/Distribution.mobileprovision" ]; then
            print_error "Provisioning profile not found: Certificates/Distribution.mobileprovision"
            exit 1
        fi
    fi
    
    print_success "Certificates validated"
}

# Function to setup certificates from environment variables
setup_certificates_from_env() {
    print_info "Setting up certificates from environment variables..."
    
    # Create certificates directory
    mkdir -p Certificates
    
    # Decode certificate
    echo "$IOS_CERTIFICATE_P12" | base64 -d > Certificates/Distribution.p12
    
    # Decode provisioning profile
    echo "$PROVISIONING_PROFILE" | base64 -d > Certificates/Distribution.mobileprovision
    
    # Create keychain
    local keychain_password="${KEYCHAIN_PASSWORD:-build_keychain}"
    security create-keychain -p "$keychain_password" build.keychain || true
    security default-keychain -s build.keychain
    security unlock-keychain -p "$keychain_password" build.keychain
    
    # Import certificate
    security import Certificates/Distribution.p12 \
        -k build.keychain \
        -P "$CERTIFICATE_PASSWORD" \
        -T /usr/bin/codesign \
        -T /usr/bin/xcodebuild
    
    # Set key partition list
    security set-key-partition-list \
        -S apple-tool:,apple:,codesign: \
        -s -k "$keychain_password" \
        build.keychain
    
    # Install provisioning profile
    local pp_uuid=$(grep -a UUID Certificates/Distribution.mobileprovision | head -1 | sed 's/.*<string>//' | sed 's/<\/string>.*//')
    mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
    cp Certificates/Distribution.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/$pp_uuid.mobileprovision
    
    print_success "Certificates configured successfully"
}

# Function to run tests
run_tests() {
    if [ "$SKIP_TESTS" = true ]; then
        print_warning "Skipping tests as requested"
        return 0
    fi
    
    print_section "Running Tests"
    
    local test_destination='platform=iOS Simulator,name=iPhone 15 Pro,OS=17.2'
    
    print_info "Running unit tests..."
    xcodebuild test \
        -project "$PROJECT_NAME" \
        -scheme "$SCHEME_NAME" \
        -destination "$test_destination" \
        -configuration Debug \
        CODE_SIGNING_ALLOWED=NO \
        -enableCodeCoverage YES \
        | tee test_output.log \
        | xcpretty --color || {
            print_error "Tests failed"
            exit 1
        }
    
    # Generate test report for Bitbucket
    generate_test_report
    
    print_success "All tests passed"
    echo ""
}

# Function to generate test report
generate_test_report() {
    print_info "Generating test report for Bitbucket Server..."
    
    # Find test results
    local test_results=$(find . -name "*.xcresult" | head -1)
    
    if [ -n "$test_results" ]; then
        # Generate coverage report
        xcrun xccov view --report --json "$test_results" > coverage.json
        
        # Create JUnit-style report for Bitbucket
        xcrun xcresulttool export --type junit --path "$test_results" --output-path test-results.xml
        
        # Generate summary
        cat > test-summary.md << EOF
# 🧪 Test Results - Build #$BITBUCKET_BUILD_NUMBER

**Commit:** \`${BITBUCKET_COMMIT:0:8}\`  
**Branch:** \`$BITBUCKET_BRANCH\`  
**Date:** $(date)

## Test Coverage
$(xcrun xccov view --report "$test_results" | grep "All targets")

## Status
✅ All tests passed successfully

EOF
        
        print_success "Test report generated"
    else
        print_warning "No test results found for reporting"
    fi
}

# Function to build app
build_app() {
    local environment=$1
    print_section "Building Application for $environment"
    
    local configuration
    case $environment in
        "development")
            configuration="Debug"
            ;;
        "staging"|"production")
            configuration="Release"
            ;;
    esac
    
    print_info "Building with configuration: $configuration"
    
    if [ "$environment" = "development" ]; then
        # Development build for simulator
        xcodebuild clean build \
            -project "$PROJECT_NAME" \
            -scheme "$SCHEME_NAME" \
            -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=17.2' \
            -configuration "$configuration" \
            CODE_SIGNING_ALLOWED=NO \
            | tee build_output.log \
            | xcpretty --color || {
                print_error "Build failed"
                exit 1
            }
    else
        # Archive for distribution
        xcodebuild clean archive \
            -project "$PROJECT_NAME" \
            -scheme "$SCHEME_NAME" \
            -destination 'generic/platform=iOS' \
            -configuration "$configuration" \
            -archivePath "build/$SCHEME_NAME.xcarchive" \
            | tee build_output.log \
            | xcpretty --color || {
                print_error "Archive failed"
                exit 1
            }
    fi
    
    print_success "Build completed successfully"
    echo ""
}

# Function to export IPA
export_ipa() {
    local environment=$1
    
    if [ "$environment" = "development" ]; then
        print_info "Skipping IPA export for development build"
        return 0
    fi
    
    print_section "Exporting IPA for $environment"
    
    # Create export options plist
    create_export_options "$environment"
    
    print_info "Exporting IPA..."
    xcodebuild -exportArchive \
        -archivePath "build/$SCHEME_NAME.xcarchive" \
        -exportPath "build" \
        -exportOptionsPlist "build/ExportOptions.plist" \
        | tee export_output.log \
        | xcpretty --color || {
            print_error "IPA export failed"
            exit 1
        }
    
    # Find exported IPA
    local ipa_file=$(find build -name "*.ipa" | head -1)
    if [ -n "$ipa_file" ]; then
        print_success "IPA exported: $ipa_file"
        
        # Generate IPA info
        local ipa_size=$(stat -f%z "$ipa_file" 2>/dev/null || stat -c%s "$ipa_file")
        local ipa_size_mb=$((ipa_size / 1024 / 1024))
        
        cat > build/ipa-info.json << EOF
{
  "file": "$ipa_file",
  "size_bytes": $ipa_size,
  "size_mb": $ipa_size_mb,
  "environment": "$environment",
  "build_number": "$BITBUCKET_BUILD_NUMBER",
  "commit": "$BITBUCKET_COMMIT",
  "branch": "$BITBUCKET_BRANCH",
  "timestamp": "$(date -Iseconds)"
}
EOF
        
        print_info "IPA size: ${ipa_size_mb}MB"
    else
        print_error "IPA file not found after export"
        exit 1
    fi
    
    echo ""
}

# Function to create export options plist
create_export_options() {
    local environment=$1
    
    local method
    case $environment in
        "staging")
            method="app-store"
            ;;
        "production")
            method="app-store"
            ;;
    esac
    
    mkdir -p build
    
    cat > build/ExportOptions.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>$method</string>
    <key>teamID</key>
    <string>$APPLE_TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
    <key>thinning</key>
    <string>&lt;none&gt;</string>
</dict>
</plist>
EOF
}

# Function to upload app
upload_app() {
    local environment=$1
    
    if [ "$environment" = "development" ]; then
        print_info "Skipping upload for development build"
        return 0
    fi
    
    print_section "Uploading to App Store Connect"
    
    local ipa_file=$(find build -name "*.ipa" | head -1)
    if [ -z "$ipa_file" ]; then
        print_error "No IPA file found for upload"
        exit 1
    fi
    
    print_info "Uploading $ipa_file to App Store Connect..."
    
    # Use App Store Connect API if available
    if [ -n "$APP_STORE_CONNECT_API_KEY" ] && [ -n "$APP_STORE_CONNECT_ISSUER_ID" ] && [ -n "$APP_STORE_CONNECT_KEY_ID" ]; then
        upload_with_api "$ipa_file" "$environment"
    else
        # Fallback to altool
        upload_with_altool "$ipa_file" "$environment"
    fi
    
    print_success "Upload completed successfully"
    echo ""
}

# Function to upload with App Store Connect API
upload_with_api() {
    local ipa_file=$1
    local environment=$2
    
    print_info "Using App Store Connect API for upload..."
    
    # This would be implemented with the actual API calls
    # For now, showing the structure
    print_info "API upload functionality would be implemented here"
    print_warning "Currently using altool fallback"
    
    upload_with_altool "$ipa_file" "$environment"
}

# Function to upload with altool
upload_with_altool() {
    local ipa_file=$1
    local environment=$2
    
    print_info "Using altool for upload..."
    
    if [ -z "$APPLE_ID_USERNAME" ] || [ -z "$APPLE_ID_PASSWORD" ]; then
        print_error "Apple ID credentials not configured"
        print_info "Set APPLE_ID_USERNAME and APPLE_ID_PASSWORD environment variables"
        exit 1
    fi
    
    xcrun altool --upload-app \
        --type ios \
        --file "$ipa_file" \
        --username "$APPLE_ID_USERNAME" \
        --password "$APPLE_ID_PASSWORD" \
        --verbose || {
            print_error "Upload failed"
            exit 1
        }
}

# Function to report build status to Bitbucket
report_build_status() {
    local status=$1  # SUCCESS, FAILED, INPROGRESS
    local description="${2:-Build status update}"
    
    if [ -z "$BITBUCKET_API_TOKEN" ]; then
        print_warning "BITBUCKET_API_TOKEN not set, skipping status report"
        return 0
    fi
    
    print_info "Reporting build status to Bitbucket Server: $status"
    
    local state
    case $status in
        "SUCCESS")
            state="SUCCESSFUL"
            ;;
        "FAILED")
            state="FAILED"
            ;;
        "INPROGRESS")
            state="INPROGRESS"
            ;;
    esac
    
    curl -X POST \
        "$BITBUCKET_SERVER_URL/rest/build-status/1.0/commits/$BITBUCKET_COMMIT" \
        -H "Authorization: Bearer $BITBUCKET_API_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{
            \"state\": \"$state\",
            \"key\": \"ios-deploy-$environment\",
            \"name\": \"iOS Deployment - $environment\",
            \"url\": \"$BITBUCKET_SERVER_URL/projects/$BITBUCKET_PROJECT_KEY/repos/$BITBUCKET_REPO_NAME/builds\",
            \"description\": \"$description\"
        }" || {
            print_warning "Failed to report build status"
        }
}

# Function to generate deployment report
generate_deploy_report() {
    local environment=$1
    local start_time=$2
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    print_section "Generating Deployment Report"
    
    local report_file="build/deploy-report-$environment-$BITBUCKET_BUILD_NUMBER.md"
    
    cat > "$report_file" << EOF
# 📱 ManusPsiqueia Deployment Report

## Build Information
- **Environment**: $environment
- **Build Number**: $BITBUCKET_BUILD_NUMBER
- **Commit**: \`$BITBUCKET_COMMIT\`
- **Branch**: \`$BITBUCKET_BRANCH\`
- **Deployment Duration**: ${duration}s

## Bitbucket Server Information
- **Server**: $BITBUCKET_SERVER_URL
- **Project**: $BITBUCKET_PROJECT_KEY
- **Repository**: $BITBUCKET_REPO_NAME

## Deployment Steps
✅ Dependencies check  
✅ Environment configuration  
$([ "$SKIP_TESTS" != true ] && echo "✅ Tests execution" || echo "⏭️ Tests skipped")  
✅ Application build  
$([ "$environment" != "development" ] && echo "✅ IPA export" || echo "⏭️ IPA export skipped")  
$([ "$environment" != "development" ] && echo "✅ App Store Connect upload" || echo "⏭️ Upload skipped")  

## Build Configuration
- **Scheme**: $SCHEME_NAME
- **Configuration**: $([ "$environment" = "development" ] && echo "Debug" || echo "Release")
- **Xcode Version**: $(xcodebuild -version | head -1)

## Next Steps
EOF

    case $environment in
        "development")
            echo "- Install app on development devices" >> "$report_file"
            echo "- Test functionality locally" >> "$report_file"
            ;;
        "staging")
            echo "- Wait for TestFlight processing (usually 10-30 minutes)" >> "$report_file"
            echo "- Invite internal testers" >> "$report_file"
            echo "- Conduct beta testing" >> "$report_file"
            ;;
        "production")
            echo "- Wait for App Store review (24-48 hours typical)" >> "$report_file"
            echo "- Monitor App Store Connect for review status" >> "$report_file"
            echo "- Prepare release notes and marketing materials" >> "$report_file"
            ;;
    esac
    
    echo "" >> "$report_file"
    echo "---" >> "$report_file"
    echo "*Generated by Bitbucket Server Deployment Script*" >> "$report_file"
    echo "*AiLun Tecnologia - CNPJ: 60.740.536/0001-75*" >> "$report_file"
    
    print_success "Deployment report generated: $report_file"
    
    # If in Bitbucket pipeline, make it an artifact
    if [ -n "$BITBUCKET_BUILD_NUMBER" ]; then
        cp "$report_file" deploy-report.md
    fi
}

# Main function
main() {
    local start_time=$(date +%s)
    
    # Parse arguments
    local environment=""
    local skip_tests=false
    local skip_build=false
    local dry_run=false
    local verbose=false
    local bitbucket_build=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            development|staging|production)
                environment=$1
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            --skip-tests)
                skip_tests=true
                shift
                ;;
            --skip-build)
                skip_build=true
                shift
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            --bitbucket-build)
                bitbucket_build=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Validate environment
    if [ -z "$environment" ]; then
        print_error "Environment not specified"
        show_usage
        exit 1
    fi
    
    # Set global variables
    export SKIP_TESTS=$skip_tests
    export SKIP_BUILD=$skip_build
    export DRY_RUN=$dry_run
    export VERBOSE=$verbose
    
    # Print header
    print_header
    
    # Show configuration
    print_info "Environment: $environment"
    print_info "Build Number: $BITBUCKET_BUILD_NUMBER"
    print_info "Commit: ${BITBUCKET_COMMIT:0:8}"
    print_info "Branch: $BITBUCKET_BRANCH"
    
    if [ "$dry_run" = true ]; then
        print_warning "DRY RUN MODE - No actions will be executed"
    fi
    
    echo ""
    
    # Report start status
    report_build_status "INPROGRESS" "Starting deployment to $environment"
    
    # Execute deployment steps
    if [ "$dry_run" = false ]; then
        check_dependencies
        check_environment_config "$environment"
        
        if [ "$skip_tests" = false ]; then
            run_tests
        fi
        
        if [ "$skip_build" = false ]; then
            build_app "$environment"
            export_ipa "$environment"
        fi
        
        upload_app "$environment"
        generate_deploy_report "$environment" "$start_time"
        
        # Report success
        report_build_status "SUCCESS" "Deployment to $environment completed successfully"
    else
        print_info "Dry run completed - no actual deployment performed"
    fi
    
    # Final message
    print_section "Deployment Complete!"
    print_success "Deployment to $environment completed successfully!"
    
    case $environment in
        "development")
            print_info "App is ready for installation on development devices"
            ;;
        "staging")
            print_info "App will be processed in TestFlight within 10-30 minutes"
            ;;
        "production")
            print_info "App has been submitted for App Store review"
            ;;
    esac
    
    echo ""
    print_info "View deployment status in Bitbucket Server:"
    print_info "$BITBUCKET_SERVER_URL/projects/$BITBUCKET_PROJECT_KEY/repos/$BITBUCKET_REPO_NAME/builds"
}

# Trap errors and report failure status
trap 'report_build_status "FAILED" "Deployment failed with error"; exit 1' ERR

# Execute main function
main "$@"