# Temps CLI - Complete Reference

Comprehensive command-line reference for the Temps deployment platform CLI.

## What This Skill Covers

Complete documentation for all **54+ CLI commands** including:

- ✅ Authentication (login, logout, whoami)
- ✅ Projects (create, update, delete, settings)
- ✅ Deployments (Git, static, Docker images, local images)
- ✅ Environments (create, scale, variables, cron jobs)
- ✅ Services (PostgreSQL, Redis, MongoDB, S3)
- ✅ Git Providers (GitHub, GitLab, Bitbucket)
- ✅ Domains & TLS Certificates
- ✅ Custom Domains (environment targeting, redirects)
- ✅ DNS Management (records, zones, providers)
- ✅ Notifications (Slack, email, webhooks)
- ✅ Monitoring (uptime, incidents, health checks)
- ✅ Containers (lifecycle, metrics, logs)
- ✅ Backups (sources, schedules, restore)
- ✅ Security Scanning (vulnerability detection)
- ✅ Error Tracking (Sentry-compatible)
- ✅ Webhooks (delivery management)
- ✅ API Keys & Tokens
- ✅ Users Management
- ✅ Email (providers, domains, sending)
- ✅ IP Access Control
- ✅ Load Balancer
- ✅ Audit Logs
- ✅ Proxy Logs
- ✅ Platform Information
- ✅ Settings & Configuration
- ✅ Presets & Templates
- ✅ Imports (Docker containers)
- ✅ Temps Cloud (VPS management)

## Installation

```bash
# Run directly without installing (recommended)
npx @temps-sdk/cli --version
bunx @temps-sdk/cli --version

# Or install globally
npm install -g @temps-sdk/cli
bun add -g @temps-sdk/cli
```

## Quick Start

```bash
# Login to Temps
temps login

# Create a project
temps projects create my-app

# Deploy from Git
temps deploy my-app -b main -e production

# Set environment variables
temps env set DATABASE_URL="postgresql://..." -p my-app -e production

# View logs
temps logs -p my-app -f
```

## Common Commands

```bash
# Projects
temps projects list
temps projects create
temps projects show -p my-app

# Deployments
temps deploy my-app -b main -e production
temps deployments list -p my-app
temps deployments rollback -p my-app -e production

# Services
temps services create -t postgres -n mydb
temps services list
temps services link --id 1 --project-id 5

# Domains
temps domains add -p my-app -d example.com
temps domains verify -p my-app -d example.com

# Logs
temps logs -p my-app -f
temps runtime-logs -p my-app -e staging -f

# Monitoring
temps monitors create --project-id 5 -n "API Health" -t http
temps incidents list --project-id 5
```

## Configuration

**Config file**: `~/.temps/config.json`
**Credentials**: Stored securely in `~/.temps/` with restricted file permissions (mode 0600)

```bash
# View configuration
temps configure show

# Set API URL
temps configure set apiUrl https://temps.example.com

# Set output format
temps configure set outputFormat json
```

## Environment Variables

| Variable | Description |
|----------|-------------|
| `TEMPS_API_URL` | Override API endpoint |
| `TEMPS_TOKEN` | API token (highest priority) |
| `TEMPS_API_TOKEN` | API token (CI/CD) |
| `TEMPS_API_KEY` | API key |
| `NO_COLOR` | Disable colored output |

## Command Aliases

Common shortcuts:
- `temps p` → `temps projects`
- `temps svc` → `temps services`
- `temps cts` → `temps containers`
- `temps hooks` → `temps webhooks`
- `temps plogs` → `temps proxy-logs`
- `temps rtlogs` → `temps runtime-logs`

## JSON Output

All commands support `--json` for scripting:

```bash
# Get project ID
temps projects show -p my-app --json | jq '.id'

# List running services
temps services list --json | jq '.[] | select(.status == "running")'
```

## CI/CD Automation

Use `-y/--yes` to skip prompts:

```bash
export TEMPS_TOKEN=$TEMPS_TOKEN
export TEMPS_API_URL=https://temps.example.com

temps deploy my-app -b main -e production -y
temps env set VERSION="1.2.3" -p my-app -e production
temps scans trigger --project-id 5 --environment-id 1
```

## When to Use This Skill

Use this skill when you need:

- 📖 Complete CLI command reference
- 🔍 Find specific command syntax
- 🚀 Learn deployment workflows
- 🔧 Manage services and infrastructure
- 📊 Set up monitoring and logging
- 🔐 Configure security and access control
- 🌐 Manage domains and DNS
- 📧 Configure email and notifications

## Related Skills

- [temps-platform-setup](../temps-platform-setup/) - Install and configure Temps platform
- [deploy-to-temps](../deploy-to-temps/) - Deploy applications to Temps
- [add-custom-domain](../add-custom-domain/) - Custom domain configuration

## Full Documentation

See [SKILL.md](SKILL.md) for complete command reference with examples (1700+ lines).

---

**Package**: [@temps-sdk/cli](https://www.npmjs.com/package/@temps-sdk/cli)
**Version**: 0.1.9
