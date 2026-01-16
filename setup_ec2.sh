#!/bin/bash
# Quick setup script for EC2 Ubuntu deployment

set -e  # Exit on error

echo "======================================"
echo "Baseline V1 Live - EC2 Setup"
echo "======================================"
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    echo "✓ Docker installed"
else
    echo "✓ Docker already installed"
fi

# Check if Docker Compose is installed
if ! command -v docker compose &> /dev/null; then
    echo "Installing Docker Compose plugin..."
    sudo apt update
    sudo apt install -y docker-compose-plugin
    echo "✓ Docker Compose installed"
else
    echo "✓ Docker Compose already installed"
fi

# Create directories
echo "Creating directories..."
mkdir -p logs backups
chmod 755 logs backups
echo "✓ Directories created"

# Setup .env if not exists
if [ ! -f "baseline_v1_live/.env" ]; then
    echo "Creating .env from sample..."
    if [ -f ".env.sample" ]; then
        cp .env.sample baseline_v1_live/.env
        echo "✓ .env created - PLEASE EDIT WITH YOUR CREDENTIALS!"
        echo ""
        echo "Edit with: nano baseline_v1_live/.env"
        echo "Required fields:"
        echo "  - OPENALGO_API_KEY"
        echo "  - EXPIRY (format: DDMMMYY)"
        echo "  - ATM (current NIFTY ATM strike)"
    else
        echo "⚠ .env.sample not found - please create .env manually"
    fi
else
    echo "✓ .env already exists"
fi

# Configure firewall (optional)
read -p "Configure UFW firewall? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Configuring UFW..."
    sudo ufw allow 22/tcp      # SSH
    sudo ufw allow 8050/tcp    # Monitor dashboard
    sudo ufw --force enable
    echo "✓ Firewall configured"
fi

echo ""
echo "======================================"
echo "Setup Complete!"
echo "======================================"
echo ""
echo "Next steps:"
echo "1. Edit .env: nano baseline_v1_live/.env"
echo "2. Start system: docker compose up -d"
echo "3. View logs: docker compose logs -f trading_agent"
echo "4. Monitor: http://$(hostname -I | awk '{print $1}'):8050"
echo ""
echo "IMPORTANT: Keep PAPER_TRADING=true until tested!"
echo ""
