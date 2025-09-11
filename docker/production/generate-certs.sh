#!/bin/bash

# SSL Certificate Generation Script for Mobilizon
# This script helps generate SSL certificates for your Mobilizon instance

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CERTS_DIR="$SCRIPT_DIR/nginx/certs"
DOMAIN="${1:-your-domain.com}"

echo "🔐 SSL Certificate Setup for Mobilizon"
echo "======================================="

# Create certs directory if it doesn't exist
mkdir -p "$CERTS_DIR"

function show_help() {
    echo "Usage: $0 [DOMAIN] [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --self-signed    Generate self-signed certificates (for development)"
    echo "  --letsencrypt    Setup Let's Encrypt certificates (for production)"
    echo "  --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 mydomain.com --self-signed"
    echo "  $0 mydomain.com --letsencrypt"
    echo ""
    echo "Note: Replace 'your-domain.com' in nginx/conf/conf.d/mobilizon.conf with your actual domain"
}

function generate_self_signed() {
    local domain="$1"
    echo "📝 Generating self-signed certificates for $domain..."
    
    # Generate private key
    openssl genrsa -out "$CERTS_DIR/privkey.pem" 2048
    
    # Generate certificate signing request
    openssl req -new -key "$CERTS_DIR/privkey.pem" -out "$CERTS_DIR/cert.csr" -subj "/C=US/ST=State/L=City/O=Organization/CN=$domain"
    
    # Generate self-signed certificate
    openssl x509 -req -in "$CERTS_DIR/cert.csr" -signkey "$CERTS_DIR/privkey.pem" -out "$CERTS_DIR/fullchain.pem" -days 365 -sha256
    
    # Clean up CSR
    rm "$CERTS_DIR/cert.csr"
    
    echo "✅ Self-signed certificates generated successfully!"
    echo "⚠️  WARNING: Self-signed certificates are not trusted by browsers by default."
    echo "   Use these only for development or testing purposes."
}

function setup_letsencrypt() {
    local domain="$1"
    echo "🌐 Setting up Let's Encrypt certificates for $domain..."
    
    # Check if certbot is installed
    if ! command -v certbot &> /dev/null; then
        echo "❌ Certbot is not installed. Please install it first:"
        echo "   - Ubuntu/Debian: apt-get install certbot"
        echo "   - CentOS/RHEL: yum install certbot"
        echo "   - macOS: brew install certbot"
        exit 1
    fi
    
    echo "📋 Let's Encrypt setup requires manual steps:"
    echo ""
    echo "1. Make sure your domain ($domain) points to this server's IP address"
    echo "2. Ensure ports 80 and 443 are open and accessible"
    echo "3. Update nginx/conf/conf.d/mobilizon.conf to use your domain name"
    echo "4. Run the following commands:"
    echo ""
    echo "   # Start nginx without SSL first"
    echo "   docker-compose up -d nginx"
    echo ""
    echo "   # Generate certificates using certbot with webroot"
    echo "   certbot certonly --webroot -w /var/www/certbot -d $domain"
    echo ""
    echo "   # Copy certificates to the nginx certs directory"
    echo "   cp /etc/letsencrypt/live/$domain/fullchain.pem $CERTS_DIR/"
    echo "   cp /etc/letsencrypt/live/$domain/privkey.pem $CERTS_DIR/"
    echo ""
    echo "   # Restart the containers"
    echo "   docker-compose restart"
    echo ""
    echo "5. Set up automatic renewal with a cron job:"
    echo "   0 12 * * * /usr/bin/certbot renew --quiet"
}

function setup_letsencrypt_docker() {
    local domain="$1"
    echo "🐳 Setting up Let's Encrypt with Docker for $domain..."
    
    # Create certbot directories
    mkdir -p "$SCRIPT_DIR/certbot/conf"
    mkdir -p "$SCRIPT_DIR/certbot/www"
    
    echo "📋 Docker-based Let's Encrypt setup:"
    echo ""
    echo "1. Update nginx/conf/conf.d/mobilizon.conf to use your domain: $domain"
    echo "2. Add this to your docker-compose.yml:"
    echo ""
    cat << EOF
  certbot:
    image: certbot/certbot
    container_name: mobilizon_certbot
    volumes:
      - ./certbot/conf:/etc/letsencrypt
      - ./certbot/www:/var/www/certbot
      - ./nginx/certs:/etc/nginx/certs
    command: certonly --webroot -w /var/www/certbot --force-renewal --email your-email@example.com -d $domain --agree-tos
    depends_on:
      - nginx
EOF
    echo ""
    echo "3. Run: docker-compose run --rm certbot"
    echo "4. Copy certificates: docker-compose exec certbot cp /etc/letsencrypt/live/$domain/*.pem /etc/nginx/certs/"
    echo "5. Restart nginx: docker-compose restart nginx"
}

# Parse command line arguments
case "${2:-}" in
    --self-signed)
        generate_self_signed "$DOMAIN"
        ;;
    --letsencrypt)
        setup_letsencrypt "$DOMAIN"
        ;;
    --letsencrypt-docker)
        setup_letsencrypt_docker "$DOMAIN"
        ;;
    --help)
        show_help
        exit 0
        ;;
    "")
        echo "❓ No option specified. What would you like to do?"
        echo ""
        echo "1) Generate self-signed certificates (development)"
        echo "2) Setup Let's Encrypt certificates (production)"
        echo "3) Setup Let's Encrypt with Docker (production)"
        echo "4) Show help"
        echo ""
        read -p "Choose an option (1-4): " choice
        
        case $choice in
            1)
                generate_self_signed "$DOMAIN"
                ;;
            2)
                setup_letsencrypt "$DOMAIN"
                ;;
            3)
                setup_letsencrypt_docker "$DOMAIN"
                ;;
            4)
                show_help
                ;;
            *)
                echo "❌ Invalid choice"
                exit 1
                ;;
        esac
        ;;
    *)
        echo "❌ Unknown option: ${2:-}"
        show_help
        exit 1
        ;;
esac

echo ""
echo "🎉 Certificate setup completed!"
echo ""
echo "Next steps:"
echo "1. Update nginx/conf/conf.d/mobilizon.conf with your domain name"
echo "2. Run: docker-compose up -d"
echo ""
echo "Your certificates are located in: $CERTS_DIR"
