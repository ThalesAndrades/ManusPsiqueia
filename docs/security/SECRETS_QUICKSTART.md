# 🔐 Secrets Management Quick Start Guide

## Overview

The ManusPsiqueia project now includes a **complete secrets management system** that handles the entire lifecycle of sensitive configuration data from development to production.

## 🚀 Quick Setup

### 1. Initial Setup
```bash
# Create structure and templates
./scripts/secrets_manager.sh setup
```

### 2. Configure Development Environment
```bash
# Copy template and fill with your development keys
cp Configuration/Templates/development.secrets.template Configuration/Secrets/development.secrets

# Edit the file with your actual API keys
nano Configuration/Secrets/development.secrets

# Validate configuration
./scripts/secrets_manager.sh validate --env development

# Store in macOS Keychain for secure access
./scripts/secrets_manager.sh keychain --env development
```

## 📋 Available Commands

| Command | Description | Example |
|---------|-------------|---------|
| `setup` | Create initial structure | `./scripts/secrets_manager.sh setup` |
| `validate` | Validate secrets configuration | `./scripts/secrets_manager.sh validate --env production` |
| `list` | List available secrets | `./scripts/secrets_manager.sh list --env staging` |
| `rotate` | Rotate a specific secret | `./scripts/secrets_manager.sh rotate --env production --key STRIPE_SECRET_KEY` |
| `backup` | Create encrypted backup | `./scripts/secrets_manager.sh backup --env production` |
| `restore` | Restore from backup | `./scripts/secrets_manager.sh restore --env production --backup file.enc` |
| `audit` | Security audit report | `./scripts/secrets_manager.sh audit --env production` |
| `export` | Export for CI/CD | `./scripts/secrets_manager.sh export --env staging` |
| `encrypt` | Encrypt file | `./scripts/secrets_manager.sh encrypt --file secrets.txt` |
| `decrypt` | Decrypt file | `./scripts/secrets_manager.sh decrypt --file secrets.txt.enc` |

## 🔧 Environment Configuration

### Development
- Uses local `.secrets` files
- Stored in macOS Keychain
- Validated but allows missing keys with warnings

### Staging/Production  
- Uses GitHub Secrets in CI/CD
- Strict validation required
- Automated deployment integration

## 🛡️ Security Features

- **🔒 Encrypted Storage**: AES-256-CBC encryption for backups
- **🔑 Keychain Integration**: Secure storage on macOS
- **🔍 Validation**: Environment-specific validation rules
- **📊 Auditing**: Comprehensive security auditing
- **🔄 Rotation**: Secure secret rotation procedures
- **💾 Backup/Recovery**: Encrypted backup system with integrity checks
- **🚨 Emergency**: Emergency lockdown procedures

## 📚 Documentation

- **[Complete Guide](docs/security/COMPLETE_SECRETS_MANAGEMENT.md)** - Full documentation
- **[Implementation Guide](docs/setup/SECRETS_IMPLEMENTATION_GUIDE.md)** - Step-by-step setup
- **[Security Plan](docs/security/SECRETS_MANAGEMENT_PLAN.md)** - Strategic overview

## 🚀 CI/CD Integration

### GitHub Actions Workflows

1. **Secrets Management Pipeline** (`.github/workflows/secrets-management.yml`)
   - Manual secret validation and auditing
   - Automated backup creation
   - Security reporting

2. **iOS CI/CD Pipeline** (`.github/workflows/ios-ci-cd.yml`)
   - Automated secret injection for builds
   - Production deployment with secret validation
   - Secure cleanup procedures

### Required GitHub Secrets

For each environment, configure these secrets in GitHub:
- `STRIPE_PUBLISHABLE_KEY_{ENV}`
- `STRIPE_SECRET_KEY_{ENV}`
- `SUPABASE_URL_{ENV}`
- `SUPABASE_ANON_KEY_{ENV}`
- `OPENAI_API_KEY_{ENV}`
- And more... (see complete list in documentation)

## 🔄 Recommended Workflow

### For Developers
1. Run initial setup
2. Configure development secrets
3. Validate configuration regularly
4. Use ConfigurationManager in code

### For DevOps
1. Configure GitHub Secrets for staging/production
2. Run regular audits
3. Schedule quarterly secret rotation
4. Monitor CI/CD pipelines

### For Security Team
1. Review quarterly audit reports
2. Approve secret rotation procedures  
3. Monitor access logs
4. Update security policies

## 🆘 Emergency Procedures

### Suspected Compromise
```bash
# Immediate rotation of critical secrets
./scripts/secrets_manager.sh rotate --env production --key STRIPE_SECRET_KEY
./scripts/secrets_manager.sh rotate --env production --key OPENAI_API_KEY

# Full audit
./scripts/secrets_manager.sh audit --env production
```

### Backup Recovery
```bash
# List available backups
ls Configuration/Secrets/backups/

# Restore from backup
./scripts/secrets_manager.sh restore --env production --backup backup_file.enc
```

## 📊 Health Monitoring

The system includes built-in health monitoring accessible via:

```swift
// In your iOS app
let healthStatus = ConfigurationManager.shared.performSecretsHealthCheck()
print(healthStatus.summary)
// Output: ✅ Secrets Health: 100%
```

## 🎯 Benefits

- **🔒 Security**: Industry-standard encryption and secure storage
- **🚀 Automation**: Streamlined CI/CD integration  
- **📋 Compliance**: Audit trails and monitoring
- **🔧 Maintainability**: Easy secret rotation and management
- **⚡ Performance**: Optimized for iOS development workflow
- **🛡️ Reliability**: Backup/recovery and emergency procedures

---

**📞 Need Help?**
- Check the [complete documentation](docs/security/COMPLETE_SECRETS_MANAGEMENT.md)
- Open an issue with the `secrets-management` label
- Contact the security team for emergencies