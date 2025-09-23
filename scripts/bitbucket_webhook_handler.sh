#!/bin/bash

# Bitbucket Server Webhook Handler for ManusPsiqueia
# Handles webhooks from Bitbucket Server for CI/CD automation
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
WEBHOOK_SECRET_FILE="/etc/bitbucket/webhook-secret"
LOG_FILE="/var/log/bitbucket-webhooks.log"
TEMP_DIR="/tmp/bitbucket-webhooks"
MAX_LOG_SIZE=10485760  # 10MB

# Função para logging
log_message() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    case $level in
        "ERROR")
            echo -e "${RED}[$timestamp] [$level] $message${NC}" >&2
            ;;
        "WARN")
            echo -e "${YELLOW}[$timestamp] [$level] $message${NC}"
            ;;
        "INFO")
            echo -e "${GREEN}[$timestamp] [$level] $message${NC}"
            ;;
        "DEBUG")
            echo -e "${BLUE}[$timestamp] [$level] $message${NC}"
            ;;
    esac
}

# Função para validar assinatura do webhook
validate_webhook_signature() {
    local payload=$1
    local signature=$2
    
    if [ ! -f "$WEBHOOK_SECRET_FILE" ]; then
        log_message "ERROR" "Webhook secret file not found: $WEBHOOK_SECRET_FILE"
        return 1
    fi
    
    local secret=$(cat "$WEBHOOK_SECRET_FILE")
    local expected_signature="sha256=$(echo -n "$payload" | openssl dgst -sha256 -hmac "$secret" | cut -d' ' -f2)"
    
    if [ "$signature" = "$expected_signature" ]; then
        log_message "INFO" "Webhook signature validated successfully"
        return 0
    else
        log_message "ERROR" "Invalid webhook signature. Expected: $expected_signature, Got: $signature"
        return 1
    fi
}

# Função para processar webhook do Bitbucket Server
process_bitbucket_webhook() {
    local event_type=$1
    local payload=$2
    
    log_message "INFO" "Processing Bitbucket webhook event: $event_type"
    
    case $event_type in
        "repo:refs_changed")
            handle_push_event "$payload"
            ;;
        "pr:opened"|"pr:modified"|"pr:merged"|"pr:declined")
            handle_pull_request_event "$event_type" "$payload"
            ;;
        "repo:forked")
            handle_fork_event "$payload"
            ;;
        "repo:comment:added"|"repo:comment:edited"|"repo:comment:deleted")
            handle_comment_event "$event_type" "$payload"
            ;;
        *)
            log_message "WARN" "Unknown event type: $event_type"
            ;;
    esac
}

# Função para lidar com eventos de push
handle_push_event() {
    local payload=$1
    
    log_message "INFO" "Handling push event"
    
    # Extrair informações do payload
    local repository=$(echo "$payload" | jq -r '.repository.name // "unknown"')
    local branch=$(echo "$payload" | jq -r '.changes[0].ref.displayId // "unknown"')
    local commit_hash=$(echo "$payload" | jq -r '.changes[0].toHash // "unknown"')
    local author=$(echo "$payload" | jq -r '.changes[0].commits[0].author.name // "unknown"')
    
    log_message "INFO" "Push to repository: $repository, branch: $branch, commit: $commit_hash, author: $author"
    
    # Trigger build pipeline if master or develop branch
    if [ "$branch" = "master" ] || [ "$branch" = "develop" ]; then
        trigger_pipeline "$repository" "$branch" "$commit_hash"
    fi
    
    # Notify Stripe webhook if payment-related changes
    if echo "$payload" | jq -r '.changes[0].commits[].message' | grep -i "payment\|stripe\|billing"; then
        notify_payment_system "$repository" "$branch" "$commit_hash"
    fi
    
    # Security scan for sensitive files
    if echo "$payload" | jq -r '.changes[0].commits[].message' | grep -i "security\|certificate\|key"; then
        trigger_security_scan "$repository" "$branch" "$commit_hash"
    fi
}

# Função para lidar com eventos de pull request
handle_pull_request_event() {
    local event_type=$1
    local payload=$2
    
    log_message "INFO" "Handling pull request event: $event_type"
    
    # Extrair informações do payload
    local repository=$(echo "$payload" | jq -r '.repository.name // "unknown"')
    local pr_id=$(echo "$payload" | jq -r '.pullRequest.id // "unknown"')
    local pr_title=$(echo "$payload" | jq -r '.pullRequest.title // "unknown"')
    local source_branch=$(echo "$payload" | jq -r '.pullRequest.fromRef.displayId // "unknown"')
    local target_branch=$(echo "$payload" | jq -r '.pullRequest.toRef.displayId // "unknown"')
    local author=$(echo "$payload" | jq -r '.pullRequest.author.user.name // "unknown"')
    
    log_message "INFO" "PR #$pr_id: '$pr_title' from $source_branch to $target_branch by $author"
    
    case $event_type in
        "pr:opened"|"pr:modified")
            # Trigger PR validation pipeline
            trigger_pr_pipeline "$repository" "$pr_id" "$source_branch"
            
            # Run security checks for PR
            run_pr_security_checks "$repository" "$pr_id" "$source_branch"
            ;;
        "pr:merged")
            # Handle successful merge
            handle_pr_merge "$repository" "$pr_id" "$target_branch"
            ;;
        "pr:declined")
            # Clean up PR artifacts
            cleanup_pr_artifacts "$repository" "$pr_id"
            ;;
    esac
}

# Função para triggerar pipeline
trigger_pipeline() {
    local repository=$1
    local branch=$2
    local commit_hash=$3
    
    log_message "INFO" "Triggering pipeline for repository: $repository, branch: $branch, commit: $commit_hash"
    
    # Bitbucket Server API call to trigger pipeline
    local bitbucket_url="${BITBUCKET_SERVER_URL:-http://localhost:7990}"
    local project_key="${BITBUCKET_PROJECT_KEY:-MANUS}"
    
    curl -X POST \
        "$bitbucket_url/rest/api/1.0/projects/$project_key/repos/$repository/pipelines" \
        -H "Authorization: Bearer $BITBUCKET_API_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{
            \"refType\": \"BRANCH\",
            \"refName\": \"$branch\",
            \"commitHash\": \"$commit_hash\"
        }" \
        -w "HTTP Status: %{http_code}\n" \
        -o "$TEMP_DIR/pipeline-trigger-$commit_hash.log" 2>&1
    
    if [ $? -eq 0 ]; then
        log_message "INFO" "Pipeline triggered successfully for commit $commit_hash"
    else
        log_message "ERROR" "Failed to trigger pipeline for commit $commit_hash"
    fi
}

# Função para triggerar pipeline de PR
trigger_pr_pipeline() {
    local repository=$1
    local pr_id=$2
    local branch=$3
    
    log_message "INFO" "Triggering PR pipeline for repository: $repository, PR: $pr_id, branch: $branch"
    
    local bitbucket_url="${BITBUCKET_SERVER_URL:-http://localhost:7990}"
    local project_key="${BITBUCKET_PROJECT_KEY:-MANUS}"
    
    curl -X POST \
        "$bitbucket_url/rest/api/1.0/projects/$project_key/repos/$repository/pipelines" \
        -H "Authorization: Bearer $BITBUCKET_API_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{
            \"refType\": \"BRANCH\",
            \"refName\": \"$branch\",
            \"pipelineName\": \"pull-requests\"
        }" \
        -w "HTTP Status: %{http_code}\n" \
        -o "$TEMP_DIR/pr-pipeline-$pr_id.log" 2>&1
    
    if [ $? -eq 0 ]; then
        log_message "INFO" "PR pipeline triggered successfully for PR $pr_id"
    else
        log_message "ERROR" "Failed to trigger PR pipeline for PR $pr_id"
    fi
}

# Função para executar verificações de segurança em PR
run_pr_security_checks() {
    local repository=$1
    local pr_id=$2
    local branch=$3
    
    log_message "INFO" "Running security checks for PR $pr_id"
    
    # Create temporary directory for this PR
    local pr_temp_dir="$TEMP_DIR/pr-$pr_id"
    mkdir -p "$pr_temp_dir"
    
    # Clone the branch for security analysis
    local bitbucket_url="${BITBUCKET_SERVER_URL:-http://localhost:7990}"
    local project_key="${BITBUCKET_PROJECT_KEY:-MANUS}"
    local clone_url="$bitbucket_url/scm/$project_key/$repository.git"
    
    cd "$pr_temp_dir"
    git clone -b "$branch" "$clone_url" . 2>/dev/null || {
        log_message "ERROR" "Failed to clone repository for security checks"
        return 1
    }
    
    # Run security checks
    local security_report="$pr_temp_dir/security-report.json"
    
    {
        echo "{"
        echo "  \"timestamp\": \"$(date -Iseconds)\","
        echo "  \"pr_id\": \"$pr_id\","
        echo "  \"branch\": \"$branch\","
        echo "  \"checks\": {"
        
        # Check for hardcoded secrets
        echo "    \"hardcoded_secrets\": {"
        if grep -r "sk_live\|pk_live\|sk_test.*[a-zA-Z0-9]{20}" . --exclude-dir=.git >/dev/null 2>&1; then
            echo "      \"found\": true,"
            echo "      \"files\": ["
            grep -r -l "sk_live\|pk_live\|sk_test.*[a-zA-Z0-9]{20}" . --exclude-dir=.git | sed 's/^/        "/' | sed 's/$/"/' | paste -sd, -
            echo "      ]"
        else
            echo "      \"found\": false"
        fi
        echo "    },"
        
        # Check for insecure URLs
        echo "    \"insecure_urls\": {"
        if grep -r "http://" . --exclude-dir=.git --exclude="*.md" >/dev/null 2>&1; then
            echo "      \"found\": true,"
            echo "      \"count\": $(grep -r "http://" . --exclude-dir=.git --exclude="*.md" | wc -l)"
        else
            echo "      \"found\": false"
        fi
        echo "    },"
        
        # Check for certificate files
        echo "    \"certificate_files\": {"
        local cert_files=$(find . -name "*.p12" -o -name "*.mobileprovision" -o -name "*.cer" | wc -l)
        echo "      \"count\": $cert_files"
        if [ "$cert_files" -gt 0 ]; then
            echo "      ,\"files\": ["
            find . -name "*.p12" -o -name "*.mobileprovision" -o -name "*.cer" | sed 's/^/        "/' | sed 's/$/"/' | paste -sd, -
            echo "      ]"
        fi
        echo "    }"
        
        echo "  }"
        echo "}"
    } > "$security_report"
    
    # Post security report as PR comment
    post_pr_comment "$repository" "$pr_id" "$security_report"
    
    # Cleanup
    cd /
    rm -rf "$pr_temp_dir"
}

# Função para postar comentário no PR
post_pr_comment() {
    local repository=$1
    local pr_id=$2
    local security_report=$3
    
    log_message "INFO" "Posting security report comment to PR $pr_id"
    
    local bitbucket_url="${BITBUCKET_SERVER_URL:-http://localhost:7990}"
    local project_key="${BITBUCKET_PROJECT_KEY:-MANUS}"
    
    # Generate comment text from security report
    local comment_text="🔒 **Security Analysis Report**\n\n"
    
    if [ -f "$security_report" ]; then
        local secrets_found=$(jq -r '.checks.hardcoded_secrets.found' "$security_report")
        local insecure_urls=$(jq -r '.checks.insecure_urls.found' "$security_report")
        local cert_count=$(jq -r '.checks.certificate_files.count' "$security_report")
        
        if [ "$secrets_found" = "true" ]; then
            comment_text="${comment_text}❌ **Hardcoded secrets detected** - Please remove API keys from source code\n"
        else
            comment_text="${comment_text}✅ **No hardcoded secrets found**\n"
        fi
        
        if [ "$insecure_urls" = "true" ]; then
            comment_text="${comment_text}⚠️ **Insecure HTTP URLs found** - Consider using HTTPS\n"
        else
            comment_text="${comment_text}✅ **No insecure URLs found**\n"
        fi
        
        if [ "$cert_count" -gt 0 ]; then
            comment_text="${comment_text}⚠️ **Certificate files found ($cert_count)** - Ensure they're not committed to source control\n"
        fi
    fi
    
    comment_text="${comment_text}\n*Generated by ManusPsiqueia Security Bot*"
    
    # Post comment via API
    curl -X POST \
        "$bitbucket_url/rest/api/1.0/projects/$project_key/repos/$repository/pull-requests/$pr_id/comments" \
        -H "Authorization: Bearer $BITBUCKET_API_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{
            \"text\": \"$comment_text\"
        }" \
        -w "HTTP Status: %{http_code}\n" \
        -o "$TEMP_DIR/comment-$pr_id.log" 2>&1
}

# Função para notificar sistema de pagamento
notify_payment_system() {
    local repository=$1
    local branch=$2
    local commit_hash=$3
    
    log_message "INFO" "Notifying payment system of changes in commit $commit_hash"
    
    # Webhook para sistema de pagamento (Stripe)
    if [ -n "$STRIPE_WEBHOOK_URL" ]; then
        curl -X POST \
            "$STRIPE_WEBHOOK_URL" \
            -H "Content-Type: application/json" \
            -H "X-Stripe-Signature: $(generate_stripe_signature "$repository" "$branch" "$commit_hash")" \
            -d "{
                \"type\": \"repository.payment_code_changed\",
                \"data\": {
                    \"repository\": \"$repository\",
                    \"branch\": \"$branch\",
                    \"commit\": \"$commit_hash\",
                    \"timestamp\": \"$(date -Iseconds)\"
                }
            }" \
            -w "HTTP Status: %{http_code}\n" \
            -o "$TEMP_DIR/stripe-notification-$commit_hash.log" 2>&1
    fi
}

# Função para triggerar scan de segurança
trigger_security_scan() {
    local repository=$1
    local branch=$2
    local commit_hash=$3
    
    log_message "INFO" "Triggering security scan for commit $commit_hash"
    
    # Trigger enhanced security pipeline
    local bitbucket_url="${BITBUCKET_SERVER_URL:-http://localhost:7990}"
    local project_key="${BITBUCKET_PROJECT_KEY:-MANUS}"
    
    curl -X POST \
        "$bitbucket_url/rest/api/1.0/projects/$project_key/repos/$repository/pipelines" \
        -H "Authorization: Bearer $BITBUCKET_API_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{
            \"refType\": \"BRANCH\",
            \"refName\": \"$branch\",
            \"pipelineName\": \"security-scan\",
            \"commitHash\": \"$commit_hash\"
        }" \
        -w "HTTP Status: %{http_code}\n" \
        -o "$TEMP_DIR/security-scan-$commit_hash.log" 2>&1
}

# Função para lidar com merge de PR
handle_pr_merge() {
    local repository=$1
    local pr_id=$2
    local target_branch=$3
    
    log_message "INFO" "Handling PR merge: PR $pr_id merged to $target_branch"
    
    # Se merge para master, trigger deploy pipeline
    if [ "$target_branch" = "master" ]; then
        log_message "INFO" "PR merged to master, considering deployment"
        
        # Check if this is a release merge
        local latest_commit=$(get_latest_commit "$repository" "$target_branch")
        if [ -n "$latest_commit" ]; then
            trigger_deployment_pipeline "$repository" "$target_branch" "$latest_commit"
        fi
    fi
    
    # Cleanup PR artifacts
    cleanup_pr_artifacts "$repository" "$pr_id"
}

# Função para triggerar pipeline de deployment
trigger_deployment_pipeline() {
    local repository=$1
    local branch=$2
    local commit_hash=$3
    
    log_message "INFO" "Triggering deployment pipeline for commit $commit_hash"
    
    local bitbucket_url="${BITBUCKET_SERVER_URL:-http://localhost:7990}"
    local project_key="${BITBUCKET_PROJECT_KEY:-MANUS}"
    
    curl -X POST \
        "$bitbucket_url/rest/api/1.0/projects/$project_key/repos/$repository/pipelines" \
        -H "Authorization: Bearer $BITBUCKET_API_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{
            \"refType\": \"BRANCH\",
            \"refName\": \"$branch\",
            \"pipelineName\": \"deploy\",
            \"commitHash\": \"$commit_hash\"
        }" \
        -w "HTTP Status: %{http_code}\n" \
        -o "$TEMP_DIR/deploy-$commit_hash.log" 2>&1
}

# Função para obter último commit
get_latest_commit() {
    local repository=$1
    local branch=$2
    
    local bitbucket_url="${BITBUCKET_SERVER_URL:-http://localhost:7990}"
    local project_key="${BITBUCKET_PROJECT_KEY:-MANUS}"
    
    curl -s \
        "$bitbucket_url/rest/api/1.0/projects/$project_key/repos/$repository/commits?until=$branch&limit=1" \
        -H "Authorization: Bearer $BITBUCKET_API_TOKEN" \
        | jq -r '.values[0].id // empty'
}

# Função para limpar artefatos de PR
cleanup_pr_artifacts() {
    local repository=$1
    local pr_id=$2
    
    log_message "INFO" "Cleaning up artifacts for PR $pr_id"
    
    # Remove temporary files
    rm -f "$TEMP_DIR/pr-pipeline-$pr_id.log"
    rm -f "$TEMP_DIR/comment-$pr_id.log"
    rm -rf "$TEMP_DIR/pr-$pr_id"
    
    log_message "INFO" "Cleanup completed for PR $pr_id"
}

# Função para gerar assinatura Stripe
generate_stripe_signature() {
    local repository=$1
    local branch=$2
    local commit_hash=$3
    
    local payload="{\"repository\":\"$repository\",\"branch\":\"$branch\",\"commit\":\"$commit_hash\"}"
    local secret="${STRIPE_WEBHOOK_SECRET:-default_secret}"
    
    echo -n "$payload" | openssl dgst -sha256 -hmac "$secret" | cut -d' ' -f2
}

# Função para rotar logs
rotate_logs() {
    if [ -f "$LOG_FILE" ] && [ $(stat -c%s "$LOG_FILE") -gt $MAX_LOG_SIZE ]; then
        mv "$LOG_FILE" "${LOG_FILE}.old"
        touch "$LOG_FILE"
        log_message "INFO" "Log file rotated"
    fi
}

# Função principal
main() {
    # Setup
    mkdir -p "$TEMP_DIR"
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"
    
    # Rotate logs if needed
    rotate_logs
    
    log_message "INFO" "Bitbucket Server webhook handler started"
    
    # Parse input
    local event_type="${1:-unknown}"
    local payload="${2:-{}}"
    local signature="${3:-}"
    
    # Validate signature if provided
    if [ -n "$signature" ]; then
        if ! validate_webhook_signature "$payload" "$signature"; then
            log_message "ERROR" "Webhook signature validation failed"
            exit 1
        fi
    fi
    
    # Process webhook
    process_bitbucket_webhook "$event_type" "$payload"
    
    log_message "INFO" "Webhook processing completed successfully"
}

# Execute main function with all arguments
main "$@"