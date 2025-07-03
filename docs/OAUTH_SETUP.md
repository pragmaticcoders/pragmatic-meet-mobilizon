# OAuth Authentication Setup Guide

Mobilizon supports multiple OAuth authentication providers to allow users to sign in with their existing accounts from various platforms.

## Overview

OAuth providers are configured through environment variables and are dynamically loaded at runtime. The system uses the [Ueberauth](https://github.com/ueberauth/ueberauth) library for OAuth integrations.

## Supported OAuth Providers

- **LinkedIn** - Professional networking
- **Google** - Google accounts
- **GitHub** - Developer accounts
- **Facebook** - Social media accounts
- **Discord** - Gaming and community platform
- **GitLab** - DevOps platform (GitLab.com or self-hosted)
- **Twitter** - Social media platform
- **Keycloak** - Enterprise identity management
- **CAS** - Central Authentication Service

## Enabling OAuth Providers

### 1. Environment Configuration

OAuth providers are enabled by setting the `OAUTH_CONSUMER_STRATEGIES` environment variable:

```bash
# Enable multiple OAuth providers
OAUTH_CONSUMER_STRATEGIES="linkedin google github discord"

# Enable single provider
OAUTH_CONSUMER_STRATEGIES="linkedin"
```

### 2. Provider-Specific Configuration

Each provider requires specific client credentials obtained from their developer portals.

## LinkedIn Setup

### 1. Create LinkedIn Application

1. Go to [LinkedIn Developers](https://www.linkedin.com/developers/)
2. Sign in with your LinkedIn account
3. Click "Create app"
4. Fill in the required information:
   - **App name**: Your Mobilizon instance name
   - **Company**: Your organization
   - **Privacy policy URL**: Your privacy policy
   - **App logo**: Upload a logo (optional)
5. Under "Products", add "Sign In with LinkedIn v2"
6. Configure OAuth 2.0 settings:
   - **Authorized redirect URLs**: `https://your-domain.com/auth/linkedin/callback`

### 2. Configure Environment Variables

```bash
# LinkedIn OAuth Configuration
LINKEDIN_CLIENT_ID=your-linkedin-client-id
LINKEDIN_CLIENT_SECRET=your-linkedin-client-secret
```

### 3. Enable LinkedIn Provider

```bash
# Add linkedin to your OAuth strategies
OAUTH_CONSUMER_STRATEGIES="linkedin"
```

## Google Setup

### 1. Create Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable the Google+ API
4. Go to "Credentials" → "Create Credentials" → "OAuth client ID"
5. Configure OAuth consent screen
6. Set authorized redirect URIs: `https://your-domain.com/auth/google/callback`

### 2. Environment Configuration

```bash
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret
```

## GitHub Setup

### 1. Create GitHub OAuth App

1. Go to GitHub Settings → Developer settings → OAuth Apps
2. Click "New OAuth App"
3. Fill in details:
   - **Authorization callback URL**: `https://your-domain.com/auth/github/callback`

### 2. Environment Configuration

```bash
GITHUB_CLIENT_ID=your-github-client-id
GITHUB_CLIENT_SECRET=your-github-client-secret
```

## Discord Setup

### 1. Create Discord Application

1. Go to [Discord Developer Portal](https://discord.com/developers/applications)
2. Create "New Application"
3. Go to OAuth2 settings
4. Add redirect URI: `https://your-domain.com/auth/discord/callback`

### 2. Environment Configuration

```bash
DISCORD_CLIENT_ID=your-discord-client-id
DISCORD_CLIENT_SECRET=your-discord-client-secret
```

## Facebook Setup

### 1. Create Facebook App

1. Go to [Facebook for Developers](https://developers.facebook.com/)
2. Create new app
3. Add "Facebook Login" product
4. Configure OAuth redirect URIs: `https://your-domain.com/auth/facebook/callback`

### 2. Environment Configuration

```bash
FACEBOOK_CLIENT_ID=your-facebook-client-id
FACEBOOK_CLIENT_SECRET=your-facebook-client-secret
```

## GitLab Setup

### 1. Create GitLab Application

1. For GitLab.com: Go to User Settings → Applications
2. For self-hosted: Go to Admin Area → Applications
3. Set redirect URI: `https://your-domain.com/auth/gitlab/callback`

### 2. Environment Configuration

```bash
GITLAB_CLIENT_ID=your-gitlab-client-id
GITLAB_CLIENT_SECRET=your-gitlab-client-secret
# For self-hosted GitLab instances
GITLAB_SITE=https://your-gitlab-instance.com
```

## Twitter Setup

### 1. Create Twitter App

1. Go to [Twitter Developer Portal](https://developer.twitter.com/)
2. Create new app
3. Enable OAuth 1.0a
4. Set callback URL: `https://your-domain.com/auth/twitter/callback`

### 2. Environment Configuration

```bash
TWITTER_CONSUMER_KEY=your-twitter-consumer-key
TWITTER_CONSUMER_SECRET=your-twitter-consumer-secret
```

## Keycloak Setup

### 1. Configure Keycloak Client

1. Access your Keycloak admin console
2. Create new client
3. Set redirect URIs: `https://your-domain.com/auth/keycloak/callback`

### 2. Environment Configuration

```bash
KEYCLOAK_CLIENT_ID=your-keycloak-client-id
KEYCLOAK_CLIENT_SECRET=your-keycloak-client-secret
KEYCLOAK_SITE=https://your-keycloak-instance.com
KEYCLOAK_REALM=your-realm
```

## Deployment

### Development Environment

1. Update your `.env` file with the OAuth provider configurations
2. Add the provider to `OAUTH_CONSUMER_STRATEGIES`
3. Restart the development server:

```bash
make stop
make start
```

### Production Environment

1. Update your production `.env` file
2. Rebuild and restart the containers:

```bash
cd docker/production
./update.sh
```

Or manually:

```bash
docker compose -f docker/production/docker-compose.yml down
docker compose -f docker/production/docker-compose.yml up --build -d
```

## Testing OAuth Integration

1. Go to your Mobilizon login page
2. The enabled OAuth providers should appear as sign-in buttons
3. Click on a provider to test the OAuth flow
4. Verify successful authentication and user creation

## Troubleshooting

### Common Issues

1. **"Provider not found" error**
   - Verify `OAUTH_CONSUMER_STRATEGIES` includes the provider
   - Check that environment variables are set correctly
   - Restart the application

2. **"Invalid redirect URI" error**
   - Ensure callback URLs match exactly in provider settings
   - Check for HTTP vs HTTPS mismatches
   - Verify domain spelling

3. **"Invalid client credentials" error**
   - Double-check client ID and secret
   - Ensure environment variables are loaded properly
   - Check for trailing spaces in environment values

### Debug Commands

```bash
# Check environment variables
docker compose exec mobilizon env | grep -E "(LINKEDIN|GOOGLE|GITHUB)_"

# View application logs
docker compose logs mobilizon

# Test OAuth endpoint
curl https://your-domain.com/auth/linkedin
```

## Security Considerations

1. **Environment Variables**: Store OAuth credentials securely and never commit them to version control
2. **HTTPS**: Always use HTTPS in production for OAuth callbacks
3. **Scopes**: Request minimal scopes necessary for authentication
4. **Secrets Rotation**: Regularly rotate OAuth client secrets
5. **Monitoring**: Monitor OAuth authentication attempts and failures

## Support

For additional help:
- Check the [Mobilizon documentation](https://docs.joinmobilizon.org/)
- Review provider-specific OAuth documentation
- Check Ueberauth strategy documentation for each provider 