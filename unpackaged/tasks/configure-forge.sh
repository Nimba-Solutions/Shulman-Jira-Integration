#!/bin/bash
# JIRA Forge App Configuration Utility
# Small Office Helper Script

echo "🚀 JIRA Integration v4 - Configuration Helper"
echo "=============================================="
echo ""

# Check if required tools are installed
check_dependencies() {
    echo "📋 Checking dependencies..."
    
    if ! command -v curl &> /dev/null; then
        echo "❌ curl is required but not installed"
        exit 1
    fi
    
    if ! command -v forge &> /dev/null; then
        echo "❌ Forge CLI is required but not installed"
        echo "   Run: npm install -g @forge/cli"
        exit 1
    fi
    
    echo "✅ All dependencies found"
    echo ""
}

# Get Forge app URL
get_forge_url() {
    echo "🔍 Getting Forge app URL..."
    
    FORGE_URL=$(forge install --list | grep -oE 'https://[a-zA-Z0-9-]+\.atlassian[^/]*\.net')
    
    if [ -z "$FORGE_URL" ]; then
        echo "❌ Could not find Forge app URL"
        echo "   Make sure you've run: forge deploy && forge install"
        exit 1
    fi
    
    echo "✅ Found Forge app: $FORGE_URL"
    echo ""
}

# Test Forge app connectivity
test_connectivity() {
    echo "🔗 Testing Forge app connectivity..."
    
    CONFIG_URL="$FORGE_URL/webtrigger/config-handler"
    
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$CONFIG_URL")
    
    if [ "$HTTP_STATUS" -eq 200 ] || [ "$HTTP_STATUS" -eq 404 ]; then
        echo "✅ Forge app is accessible"
    else
        echo "❌ Forge app connectivity issue (HTTP $HTTP_STATUS)"
        echo "   URL: $CONFIG_URL"
        exit 1
    fi
    echo ""
}

# Configure Forge app
configure_forge() {
    echo "⚙️  Configuring Forge app..."
    echo ""
    
    # Prompt for configuration details
    read -p "Salesforce Instance URL: " SF_INSTANCE_URL
    read -p "Connected App Consumer Key: " CLIENT_ID
    read -s -p "Connected App Consumer Secret: " CLIENT_SECRET
    echo ""
    read -p "JIRA Project Key (default: SH): " JIRA_PROJECT_KEY
    read -p "JIRA Instance URL (default: https://shulman-hill.atlassian.net): " JIRA_INSTANCE_URL
    
    # Set defaults
    JIRA_PROJECT_KEY=${JIRA_PROJECT_KEY:-SH}
    JIRA_INSTANCE_URL=${JIRA_INSTANCE_URL:-https://shulman-hill.atlassian.net}
    
    # Remove trailing slashes
    SF_INSTANCE_URL=$(echo "$SF_INSTANCE_URL" | sed 's:/*$::')
    JIRA_INSTANCE_URL=$(echo "$JIRA_INSTANCE_URL" | sed 's:/*$::')
    
    echo ""
    echo "📝 Configuration Summary:"
    echo "   Salesforce: $SF_INSTANCE_URL"
    echo "   JIRA Project: $JIRA_PROJECT_KEY"  
    echo "   JIRA Instance: $JIRA_INSTANCE_URL"
    echo ""
    
    read -p "Proceed with configuration? (y/n): " CONFIRM
    if [ "$CONFIRM" != "y" ]; then
        echo "❌ Configuration cancelled"
        exit 1
    fi
    
    # Send configuration to Forge app
    CONFIG_URL="$FORGE_URL/webtrigger/config-handler"
    
    RESPONSE=$(curl -s -X POST "$CONFIG_URL" \
        -H "Content-Type: application/json" \
        -d "{
            \"instanceUrl\": \"$SF_INSTANCE_URL\",
            \"clientId\": \"$CLIENT_ID\",
            \"clientSecret\": \"$CLIENT_SECRET\",
            \"jiraProjectKey\": \"$JIRA_PROJECT_KEY\",
            \"jiraInstanceUrl\": \"$JIRA_INSTANCE_URL\"
        }")
    
    if echo "$RESPONSE" | grep -q '"success":true'; then
        echo "✅ Forge app configured successfully!"
    else
        echo "❌ Configuration failed"
        echo "   Response: $RESPONSE"
        exit 1
    fi
}

# Generate Salesforce External Service URL
generate_external_service_info() {
    echo ""
    echo "📋 Next Steps for Salesforce Configuration:"
    echo "==========================================="
    echo ""
    echo "1. In Salesforce Setup → External Services → New External Service"
    echo "   Service Name: Jira Bridge Forge App"
    echo "   Service URL: $FORGE_URL"
    echo "   Schema: Import from external-service-schema.json"
    echo ""
    echo "2. Update MANUAL_CONFIG_CHECKLIST.md with:"
    echo "   Forge App URL: $FORGE_URL"
    echo "   Configuration Status: ✅ Completed"
    echo ""
    echo "3. Test the integration by running:"
    echo "   cci task run robot --org dev"
    echo ""
}

# Main execution
main() {
    check_dependencies
    get_forge_url
    test_connectivity  
    configure_forge
    generate_external_service_info
    
    echo "🎉 Configuration completed successfully!"
    echo "   Your JIRA integration is ready for testing."
}

# Run the configuration
main