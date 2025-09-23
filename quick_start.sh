#!/bin/bash

# ManusPsiqueia Quick Start Script
# One-command setup for Xcode development

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}"
echo "🚀 ManusPsiqueia - Quick Start Setup"
echo "===================================="
echo -e "${NC}"

# Check if we're in the right directory
if [ ! -f "ManusPsiqueia.xcodeproj/project.pbxproj" ]; then
    echo -e "${RED}❌ Error: ManusPsiqueia.xcodeproj not found${NC}"
    echo "Please run this script from the ManusPsiqueia project root directory"
    exit 1
fi

echo -e "${BLUE}📋 Step 1: Environment Setup${NC}"
if [ ! -f ".env" ]; then
    cp .env.example .env
    echo -e "${GREEN}✅ Created .env from template${NC}"
else
    echo -e "${GREEN}✅ .env already exists${NC}"
fi

echo -e "${BLUE}📋 Step 2: Resolve Dependencies${NC}"
swift package resolve
echo -e "${GREEN}✅ Dependencies resolved${NC}"

echo -e "${BLUE}📋 Step 3: Validate Setup${NC}"
if [ -x "./validate_xcode_setup.sh" ]; then
    ./validate_xcode_setup.sh
else
    echo -e "${YELLOW}⚠️ Validation script not found, skipping...${NC}"
fi

echo -e "${BLUE}📋 Step 4: Setup Complete!${NC}"
echo
echo -e "${GREEN}🎉 ManusPsiqueia is ready for development!${NC}"
echo
echo -e "${YELLOW}📝 Next Steps:${NC}"
echo "1. Edit .env with your real API keys:"
echo "   - STRIPE_PUBLISHABLE_KEY_DEV"
echo "   - SUPABASE_URL_DEV" 
echo "   - SUPABASE_ANON_KEY_DEV"
echo "   - OPENAI_API_KEY_DEV"
echo "   - DEVELOPMENT_TEAM_ID"
echo
echo "2. Open in Xcode:"
echo "   open ManusPsiqueia.xcodeproj"
echo
echo "3. Configure code signing with your Team ID"
echo
echo "4. Build and run! (⌘+R)"
echo
echo -e "${BLUE}📚 For detailed instructions, see: GUIA_XCODE_COMPLETO.md${NC}"
echo
echo -e "${GREEN}Happy coding! 🔥${NC}"