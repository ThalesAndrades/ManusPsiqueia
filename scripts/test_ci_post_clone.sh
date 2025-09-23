#!/bin/sh

# Test script for ci_post_clone.sh
# This script demonstrates how to run ci_post_clone.sh with proper environment variables

echo "🧪 Testing ci_post_clone.sh script..."

# Create a temporary derived data directory
mkdir -p /tmp/test_derived_data

# Set up environment variables for Development environment
export CI_WORKFLOW="Development"
export CI_BUILD_NUMBER="1"
export CI_XCODE_VERSION="15.0"
export CI_PLATFORM="iOS"
export CI_DERIVED_DATA_PATH="/tmp/test_derived_data"
export DEVELOPMENT_TEAM_ID="TEST_TEAM_ID"
export STRIPE_PUBLISHABLE_KEY_DEV="pk_test_123"
export SUPABASE_URL_DEV="https://test.supabase.co"
export SUPABASE_ANON_KEY_DEV="test_anon_key"
export OPENAI_API_KEY_DEV="sk-test_123"

echo "📋 Running ci_post_clone.sh with Development environment..."
./ci_scripts/ci_post_clone.sh

echo ""
echo "✅ Test completed!"
echo "💡 To use with other environments, set the appropriate CI_WORKFLOW and environment-specific variables:"
echo "   - Development: STRIPE_PUBLISHABLE_KEY_DEV, SUPABASE_URL_DEV, SUPABASE_ANON_KEY_DEV, OPENAI_API_KEY_DEV"
echo "   - Staging: STRIPE_PUBLISHABLE_KEY_STAGING, SUPABASE_URL_STAGING, SUPABASE_ANON_KEY_STAGING, OPENAI_API_KEY_STAGING"
echo "   - Production: STRIPE_PUBLISHABLE_KEY_PROD, SUPABASE_URL_PROD, SUPABASE_ANON_KEY_PROD, OPENAI_API_KEY_PROD"
echo "   - All environments require: DEVELOPMENT_TEAM_ID"