# Mobilizon Development Scripts

This directory contains scripts to help you develop Mobilizon locally in a dev container environment.

## 🚀 Quick Start

### Start Everything
```bash
./scripts/dev-start.sh
```

### Check Status
```bash
./scripts/dev-status.sh
```

### Stop Everything
```bash
./scripts/dev-stop.sh
```

## 📝 Detailed Script Documentation

### `dev-start.sh` - Complete Application Startup

**Purpose**: Starts the entire Mobilizon development environment with all dependencies.

**What it does**:
- ✅ Checks required dependencies (Elixir, Node.js, PostgreSQL)
- ✅ Installs/updates Elixir and Node.js dependencies
- ✅ Sets up and migrates the database
- ✅ Seeds test data (including events with attendees)
- ✅ Builds frontend assets with attendees feature
- ✅ Starts Phoenix server (backend)
- ✅ Configures environment variables for development
- ✅ Tests the attendees feature API
- ✅ Monitors service health

**Services Started**:
- **Phoenix Server**: http://localhost:4000
- **GraphQL API**: http://localhost:4000/api/graphql
- **PostgreSQL**: localhost:5432

**Features Available**:
- Public attendees list (above comments section)
- Auto-refresh when users join/leave events
- Full event management
- User registration & authentication

**Test Event**: 
- http://localhost:4000/events/d5b63687-ab95-4167-9af3-5798fb60b373

### `dev-status.sh` - Service Health Check

**Purpose**: Provides detailed status information about all running services.

**What it shows**:
- PostgreSQL database connection status
- Phoenix server status (port and HTTP response)
- GraphQL API functionality
- Running process information
- PID file status
- Log file information
- Attendees feature API test results

**Usage**:
```bash
./scripts/dev-status.sh
```

### `dev-stop.sh` - Clean Shutdown

**Purpose**: Safely stops all Mobilizon development services and cleans up resources.

**What it does**:
- Stops Phoenix server gracefully
- Kills processes on ports 4000 and 5173
- Cleans up remaining Elixir/Node.js processes
- Removes PID and log files
- Frees up system resources

**Usage**:
```bash
./scripts/dev-stop.sh
```

## 🔧 Environment Configuration

The scripts automatically configure these environment variables for development:

```bash
MIX_ENV=dev
MOBILIZON_INSTANCE_HOST=localhost
MOBILIZON_INSTANCE_PORT=4000
MOBILIZON_INSTANCE_REGISTRATIONS_OPEN=true
MOBILIZON_INSTANCE_SECRET_KEY_BASE=changethis
MOBILIZON_INSTANCE_SECRET_KEY=changethis
```

## 📊 Monitoring & Debugging

### Real-time Logs
```bash
tail -f /tmp/phoenix.log
```

### Process Information
```bash
ps aux | grep -E "(mix|beam|phoenix)"
```

### Port Usage
```bash
lsof -i :4000
```

### Database Connection
```bash
pg_isready -h localhost -p 5432
```

## 🧪 Testing the Attendees Feature

### GraphQL Query Test
```bash
curl -s "http://localhost:4000/api/graphql" \
  -H "Content-Type: application/json" \
  -d '{"query":"query TestParticipants($uuid: UUID!) { event(uuid: $uuid) { id uuid participants(limit: 5) { elements { id role actor { name preferredUsername } } } } }", "variables": {"uuid": "d5b63687-ab95-4167-9af3-5798fb60b373"}}' \
  | jq '.data.event.participants.elements[]'
```

### Frontend Test
1. Visit: http://localhost:4000/events/d5b63687-ab95-4167-9af3-5798fb60b373
2. Scroll down to see the "Attendees" section above comments
3. Try creating an account and joining events to test auto-refresh

## 🛠️ Build Scripts

### `build/pictures.sh`
Generates responsive versions of pictures for the application.

### `release.sh`
Creates and pushes Git tags for releases.

## 🔍 Troubleshooting

### Port Already in Use
```bash
# Find what's using the port
lsof -i :4000

# Kill the process
kill -9 <PID>

# Or use the stop script
./scripts/dev-stop.sh
```

### Database Issues
```bash
# Reset database
mix ecto.drop
mix ecto.create
mix ecto.migrate
mix run priv/repo/seeds.exs
```

### Permission Issues
```bash
# Make scripts executable
chmod +x scripts/*.sh
```

### Node.js Dependencies
```bash
# Clean install
rm -rf node_modules package-lock.json
npm install
```

### Elixir Dependencies
```bash
# Clean install
mix deps.clean --all
mix deps.get
```

## 📁 Log Files

- **Phoenix Server**: `/tmp/phoenix.log`
- **PID File**: `/tmp/phoenix.pid`

## 🎯 Development Workflow

1. **Start Development Environment**:
   ```bash
   ./scripts/dev-start.sh
   ```

2. **Make Code Changes**: 
   - Backend changes automatically reload
   - Frontend changes require rebuilding: `npm run build`

3. **Check Status**:
   ```bash
   ./scripts/dev-status.sh
   ```

4. **Stop When Done**:
   ```bash
   ./scripts/dev-stop.sh
   ```

## 🚨 Important Notes

- **Dev Container Environment**: These scripts are designed for use in VS Code dev containers
- **PostgreSQL Required**: Make sure PostgreSQL is running before starting
- **Port Requirements**: Ports 4000 and 5432 must be available
- **Memory Usage**: Elixir/Phoenix can use significant memory in development
- **Auto-reload**: Phoenix supports hot reloading for most backend changes

## 🎉 Features Included

The startup script configures Mobilizon with these enhanced features:

### ✨ Public Attendees List
- Visible to all users (no login required)
- Shows participant names and avatars
- Excludes event creators
- Located above comments section

### 🔄 Auto-refresh Functionality  
- Attendees list updates when users join/leave
- Real-time participant status changes
- Smooth user experience

### 🎯 Developer-friendly Setup
- Comprehensive error checking
- Detailed status reporting
- Easy cleanup and restart
- Rich logging and monitoring

Enjoy developing with Mobilizon! 🚀