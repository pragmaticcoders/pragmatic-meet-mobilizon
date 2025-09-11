# Nginx Setup for Mobilizon

This directory contains the nginx configuration for your Mobilizon Docker deployment.

## Quick Start

### 1. Update Domain Configuration

Edit `conf/conf.d/mobilizon.conf` and replace `your-domain.com` with your actual domain name.

### 2. Generate SSL Certificates

#### For Development (Self-signed certificates):
```bash
./generate-certs.sh your-domain.com --self-signed
```

#### For Production (Let's Encrypt):
```bash
./generate-certs.sh your-domain.com --letsencrypt
```

### 3. Start the Services

```bash
docker-compose up -d
```

## Directory Structure

```
nginx/
├── conf/
│   ├── nginx.conf              # Main nginx configuration
│   └── conf.d/
│       └── mobilizon.conf      # Mobilizon-specific configuration
├── certs/                      # SSL certificates go here
│   ├── fullchain.pem          # SSL certificate
│   └── privkey.pem            # Private key
└── README.md                   # This file
```

## SSL Certificate Options

### Self-signed Certificates (Development)
- Quick setup for local development
- Browser warnings expected
- Generated with OpenSSL

### Let's Encrypt Certificates (Production)
- Free, trusted SSL certificates
- Automatic renewal possible
- Requires domain to point to your server

## Troubleshooting

### nginx fails to start
- Check that all certificates exist in the `certs/` directory
- Verify domain name is correctly set in `mobilizon.conf`
- Check nginx logs: `docker-compose logs nginx`

### SSL certificate errors
- Ensure certificates are properly generated
- Check certificate permissions
- Verify certificate paths in nginx configuration

### Can't access site
- Ensure domain points to your server
- Check firewall settings (ports 80, 443)
- Verify docker network connectivity

## Configuration Notes

- The nginx configuration is optimized for production use
- Includes security headers and SSL best practices
- Static assets are cached for better performance
- Gzip compression is enabled for faster loading

## Let's Encrypt Automatic Renewal

For automatic certificate renewal, add this to your crontab:

```bash
0 12 * * * /usr/bin/certbot renew --quiet && docker-compose restart nginx
```
