#!/bin/bash
set -euo pipefail

# Supabase Backend Deployment Script
# This script deploys the database migrations and functions to Supabase
# Requires: SUPABASE_ACCESS_TOKEN environment variable

echo "=== Supabase Backend Deployment ==="

# Check required environment variables
if [ -z "${SUPABASE_ACCESS_TOKEN:-}" ]; then
    echo "Error: SUPABASE_ACCESS_TOKEN environment variable is not set"
    echo "This value must be provided via environment variables."
    exit 1
fi

# Set project directory
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

echo "Working directory: $PROJECT_DIR"

# Check if .env exists and load project ref if available
ENV_FILE="$PROJECT_DIR/.env"
if [ -f "$ENV_FILE" ]; then
    echo "Loading existing .env file..."
    set -a
    source "$ENV_FILE"
    set +a
fi

# Create or link Supabase project
if [ -z "${SUPABASE_PROJECT_REF:-}" ]; then
    echo "Creating new Supabase project..."

    PROJECT_NAME="import-template-test2"

    # Get organization ID first
    ORG_RESPONSE=$(curl -s "https://api.supabase.com/v1/organizations" \
        -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" 2>&1) || true

    ORG_ID=$(echo "$ORG_RESPONSE" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4) || true

    if [ -z "$ORG_ID" ]; then
        echo "Error: Could not determine Supabase organization ID"
        echo "Please ensure your SUPABASE_ACCESS_TOKEN has the correct permissions"
        exit 1
    fi

    echo "Organization ID: $ORG_ID"

    # Check if project already exists
    PROJECTS_RESPONSE=$(curl -s "https://api.supabase.com/v1/projects" \
        -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" 2>&1) || true

    # Look for project with matching name
    SUPABASE_PROJECT_REF=$(echo "$PROJECTS_RESPONSE" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for p in data:
        if p.get('name') == '$PROJECT_NAME':
            print(p.get('id', ''))
            break
except: pass
" 2>/dev/null) || true

    if [ -z "$SUPABASE_PROJECT_REF" ]; then
        # Create new project
        echo "Creating Supabase project: $PROJECT_NAME"

        # Generate a random database password
        DB_PASS=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c 24)

        CREATE_RESPONSE=$(curl -s -X POST "https://api.supabase.com/v1/projects" \
            -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" \
            -H "Content-Type: application/json" \
            -d "{
                \"name\": \"$PROJECT_NAME\",
                \"organization_id\": \"$ORG_ID\",
                \"region\": \"us-east-1\",
                \"plan\": \"free\",
                \"db_pass\": \"$DB_PASS\"
            }" 2>&1) || true

        SUPABASE_PROJECT_REF=$(echo "$CREATE_RESPONSE" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('id', ''))
except: pass
" 2>/dev/null) || true

        if [ -z "$SUPABASE_PROJECT_REF" ]; then
            echo "Warning: Could not create Supabase project"
            echo "Response: $CREATE_RESPONSE"
        else
            echo "Project created: $SUPABASE_PROJECT_REF"
            echo "Waiting for project initialization (60 seconds)..."
            sleep 60
        fi
    else
        echo "Using existing Supabase project: $SUPABASE_PROJECT_REF"
    fi

    if [ -n "$SUPABASE_PROJECT_REF" ]; then
        echo "Writing Supabase project ref to .env..."
        touch "$ENV_FILE"
        grep -v "^SUPABASE_PROJECT_REF=" "$ENV_FILE" > "$ENV_FILE.tmp" 2>/dev/null || true
        mv "$ENV_FILE.tmp" "$ENV_FILE" 2>/dev/null || touch "$ENV_FILE"
        echo "SUPABASE_PROJECT_REF=$SUPABASE_PROJECT_REF" >> "$ENV_FILE"

        # Get and store Supabase URL and anon key
        echo "Fetching API keys..."
        sleep 5  # Give time for keys to be ready

        PROJECT_INFO=$(curl -s "https://api.supabase.com/v1/projects/$SUPABASE_PROJECT_REF/api-keys" \
            -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" 2>&1) || true

        ANON_KEY=$(echo "$PROJECT_INFO" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for key in data:
        if key.get('name') == 'anon':
            print(key.get('api_key', ''))
            break
except: pass
" 2>/dev/null) || true

        if [ -n "$ANON_KEY" ]; then
            grep -v "^NEXT_PUBLIC_SUPABASE_ANON_KEY=" "$ENV_FILE" > "$ENV_FILE.tmp" 2>/dev/null || true
            mv "$ENV_FILE.tmp" "$ENV_FILE" 2>/dev/null || touch "$ENV_FILE"
            echo "NEXT_PUBLIC_SUPABASE_ANON_KEY=$ANON_KEY" >> "$ENV_FILE"
            echo "Anon key stored in .env"
        else
            echo "Warning: Could not retrieve anon key"
        fi

        SUPABASE_URL="https://$SUPABASE_PROJECT_REF.supabase.co"
        grep -v "^NEXT_PUBLIC_SUPABASE_URL=" "$ENV_FILE" > "$ENV_FILE.tmp" 2>/dev/null || true
        mv "$ENV_FILE.tmp" "$ENV_FILE" 2>/dev/null || touch "$ENV_FILE"
        echo "NEXT_PUBLIC_SUPABASE_URL=$SUPABASE_URL" >> "$ENV_FILE"
    fi
fi

# Run database migrations via API
if [ -n "${SUPABASE_PROJECT_REF:-}" ] && [ -d "$PROJECT_DIR/supabase/migrations" ]; then
    echo "Running database migrations via API..."

    for migration_file in "$PROJECT_DIR/supabase/migrations"/*.sql; do
        if [ -f "$migration_file" ]; then
            echo "Applying migration: $(basename "$migration_file")"
            SQL_CONTENT=$(cat "$migration_file")

            # Execute SQL via Supabase API
            EXEC_RESPONSE=$(curl -s -X POST "https://api.supabase.com/v1/projects/$SUPABASE_PROJECT_REF/database/query" \
                -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" \
                -H "Content-Type: application/json" \
                -d "$(python3 -c "import json; print(json.dumps({'query': '''$SQL_CONTENT'''}))")" 2>&1) || true

            # Check for errors
            if echo "$EXEC_RESPONSE" | grep -q '"error"'; then
                echo "Warning: Migration may have failed or already applied"
                echo "Response: $EXEC_RESPONSE"
            else
                echo "Migration applied successfully"
            fi
        fi
    done
else
    echo "No migrations to apply or project ref not set"
fi

echo ""
echo "=== Supabase Deployment Complete ==="
if [ -n "${SUPABASE_PROJECT_REF:-}" ]; then
    echo "Supabase Dashboard: https://supabase.com/dashboard/project/$SUPABASE_PROJECT_REF"
    echo "API URL: https://$SUPABASE_PROJECT_REF.supabase.co"
fi
