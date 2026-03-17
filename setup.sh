#!/usr/bin/env bash
# =============================================================================
# TikTok Tap Support - Setup Script
# Built by Statick | https://statick.dev
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}══════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  TikTok Tap Support - Setup${NC}"
echo -e "${BLUE}  Built by Statick | https://statick.dev${NC}"
echo -e "${BLUE}══════════════════════════════════════════════════════════════════${NC}"
echo ""

# Check if Go is installed
if ! command -v go &> /dev/null; then
    echo -e "${RED}Error: Go is not installed. Please install Go 1.24 or later.${NC}"
    exit 1
fi

GO_VERSION=$(go version | grep -oP 'go\K[0-9]+\.[0-9]+')
echo -e "${GREEN}[OK]${NC} Go version: $GO_VERSION"

# Check if Make is installed
if ! command -v make &> /dev/null; then
    echo -e "${YELLOW}Warning: Make is not installed. Some features may not work.${NC}"
fi

# Create data directory
echo -e "${BLUE}[SETUP]${NC} Creating data directory..."
mkdir -p data

# Install dependencies
echo -e "${BLUE}[SETUP]${NC} Installing Go dependencies..."
go mod download
go mod tidy

# Build the application
echo -e "${BLUE}[SETUP]${NC} Building application..."
make build

# Copy environment file
if [ ! -f .env ]; then
    echo -e "${BLUE}[SETUP]${NC} Creating .env file..."
    cp .env.example .env
    echo -e "${YELLOW}Warning: Please edit .env file with your TikTok username.${NC}"
fi

echo ""
echo -e "${GREEN}══════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Setup Complete!${NC}"
echo -e "${GREEN}══════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "Run the application with:"
echo -e "  ${BLUE}./bin/tap-support${NC}"
echo ""
echo -e "Or use Make:"
echo -e "  ${BLUE}make run${NC}"
echo ""
echo -e "For help:"
echo -e "  ${BLUE}make help${NC}"
echo ""