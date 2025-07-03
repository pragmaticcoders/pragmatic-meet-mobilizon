# Mobilizon SMTP Configuration

## Overview

Mobilizon requires external SMTP configuration for all environments. No built-in SMTP services are provided in the Docker setup.

## External SMTP Configuration

### Required Environment Variables

Configure your environment files (`.env` for development, `.env` for production) with:

```bash
# SMTP Server Configuration
MOBILIZON_SMTP_SERVER=smtp.gmail.com
MOBILIZON_SMTP_PORT=587
MOBILIZON_SMTP_USERNAME=your-email@gmail.com
MOBILIZON_SMTP_PASSWORD=your-app-password
MOBILIZON_SMTP_TLS=always
MOBILIZON_SMTP_AUTH=always
```

### Popular SMTP Providers

#### Gmail
```bash
MOBILIZON_SMTP_SERVER=smtp.gmail.com
MOBILIZON_SMTP_PORT=587
MOBILIZON_SMTP_TLS=always
MOBILIZON_SMTP_AUTH=always
```

#### SendGrid
```bash
MOBILIZON_SMTP_SERVER=smtp.sendgrid.net
MOBILIZON_SMTP_PORT=587
MOBILIZON_SMTP_TLS=always
MOBILIZON_SMTP_AUTH=always
```

#### Mailgun
```bash
MOBILIZON_SMTP_SERVER=smtp.mailgun.org
MOBILIZON_SMTP_PORT=587
MOBILIZON_SMTP_TLS=always
MOBILIZON_SMTP_AUTH=always
```

#### Self-hosted SMTP
```bash
MOBILIZON_SMTP_SERVER=your-smtp-server.com
MOBILIZON_SMTP_PORT=587
MOBILIZON_SMTP_TLS=always
MOBILIZON_SMTP_AUTH=always
```

## Testing SMTP Configuration

### Production Environment
```bash
# Test email functionality
docker compose -f docker/production/docker-compose.yml exec mobilizon /bin/mobilizon_ctl test_email
```

### Development Environment
```bash
# Test email functionality
docker compose -f docker/development/docker-compose.yml exec api /bin/mobilizon_ctl test_email
```

## Troubleshooting

### Common Issues

1. **Authentication Failed**
   - Verify username and password
   - Check if 2FA is enabled (use app passwords for Gmail)
   - Ensure SMTP_AUTH is set to "always"

2. **Connection Refused**
   - Verify SMTP server and port
   - Check firewall settings
   - Ensure TLS settings match your provider

3. **TLS Issues**
   - Try different TLS settings: "always", "never", "if_available"
   - Check if your provider requires specific TLS configuration

### Debug Commands

```bash
# Check environment variables
docker compose -f docker/production/docker-compose.yml exec mobilizon env | grep MOBILIZON_SMTP

# View application logs
docker compose -f docker/production/docker-compose.yml logs mobilizon

# Test SMTP connection manually
docker compose -f docker/production/docker-compose.yml exec mobilizon telnet $MOBILIZON_SMTP_SERVER $MOBILIZON_SMTP_PORT
```

## Recommendations

- **Production**: Use a reliable external SMTP service (Gmail, SendGrid, Mailgun)
- **Development**: Use the same SMTP configuration as production for testing
- **Security**: Use app passwords instead of regular passwords when possible
- **Monitoring**: Set up email delivery monitoring for production environments 