#!/bin/bash
set -euo pipefail

# Vercel Frontend Deployment Script
# This script deploys the Next.js frontend to Vercel
# Requires: VERCEL_TOKEN environment variable

echo "=== Vercel Frontend Deployment ==="

# Check required environment variables
if [ -z "${VERCEL_TOKEN:-}" ]; then
    echo "Error: VERCEL_TOKEN environment variable is not set"
    echo "This value must be provided via environment variables."
    exit 1
fi

# Check if Vercel CLI is installed
if ! command -v vercel &> /dev/null; then
    echo "Installing Vercel CLI..."
    npm install -g vercel
fi

# Set project directory
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

echo "Working directory: $PROJECT_DIR"

# Check if .env exists and load project IDs if available
ENV_FILE="$PROJECT_DIR/.env"
if [ -f "$ENV_FILE" ]; then
    echo "Loading existing .env file..."
    set -a
    source "$ENV_FILE"
    set +a
fi

# Create or link Vercel project
if [ -z "${VERCEL_PROJECT_ID:-}" ] || [ -z "${VERCEL_ORG_ID:-}" ]; then
    echo "Creating new Vercel project..."

    # Get project info using Vercel API
    PROJECT_NAME="import-template-test2"

    # Create project via API
    RESPONSE=$(curl -s -X POST "https://api.vercel.com/v10/projects" \
        -H "Authorization: Bearer $VERCEL_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"name\": \"$PROJECT_NAME\", \"framework\": \"nextjs\"}" 2>&1) || true

    # Extract project ID and org ID from response
    VERCEL_PROJECT_ID=$(echo "$RESPONSE" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4) || true
    VERCEL_ORG_ID=$(echo "$RESPONSE" | grep -o '"accountId":"[^"]*"' | head -1 | cut -d'"' -f4) || true

    # If project already exists, try to get its info
    if [ -z "$VERCEL_PROJECT_ID" ]; then
        echo "Project may already exist, fetching info..."
        RESPONSE=$(curl -s "https://api.vercel.com/v9/projects/$PROJECT_NAME" \
            -H "Authorization: Bearer $VERCEL_TOKEN" 2>&1) || true
        VERCEL_PROJECT_ID=$(echo "$RESPONSE" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4) || true
        VERCEL_ORG_ID=$(echo "$RESPONSE" | grep -o '"accountId":"[^"]*"' | head -1 | cut -d'"' -f4) || true
    fi

    if [ -n "$VERCEL_PROJECT_ID" ] && [ -n "$VERCEL_ORG_ID" ]; then
        echo "Writing Vercel project IDs to .env..."
        # Update or create .env file
        if [ -f "$ENV_FILE" ]; then
            # Remove old entries if they exist
            grep -v "^VERCEL_PROJECT_ID=" "$ENV_FILE" > "$ENV_FILE.tmp" || true
            grep -v "^VERCEL_ORG_ID=" "$ENV_FILE.tmp" > "$ENV_FILE" || true
            rm -f "$ENV_FILE.tmp"
        fi
        echo "VERCEL_PROJECT_ID=$VERCEL_PROJECT_ID" >> "$ENV_FILE"
        echo "VERCEL_ORG_ID=$VERCEL_ORG_ID" >> "$ENV_FILE"
    else
        echo "Warning: Could not determine Vercel project IDs"
    fi
fi

# Run tests before deployment
echo "Running tests..."
npm run test:run

# Build the project
echo "Building the project..."
npm run build

# Deploy to Vercel
echo "Deploying to Vercel..."
DEPLOY_OUTPUT=$(vercel deploy --prod --token="$VERCEL_TOKEN" --yes 2>&1)

# Extract and display the deployed URL
DEPLOYED_URL=$(echo "$DEPLOY_OUTPUT" | grep -E "https://.*\.vercel\.app" | tail -1) || true

echo ""
echo "=== Deployment Complete ==="
if [ -n "$DEPLOYED_URL" ]; then
    echo "Deployed URL: $DEPLOYED_URL"
else
    echo "Deployment output:"
    echo "$DEPLOY_OUTPUT"
fi
