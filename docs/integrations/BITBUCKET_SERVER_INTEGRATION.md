# 🚀 Bitbucket Server Integration Guide - ManusPsiqueia

**Developed by:** AiLun Tecnologia  
**CNPJ:** 60.740.536/0001-75  
**Date:** September 2025

## 🎯 Overview

This guide provides comprehensive instructions for integrating the **ManusPsiqueia** project with **Bitbucket Server**, an on-premises Git repository management solution from Atlassian. This integration enables organizations to maintain full control over their source code while benefiting from enterprise-grade CI/CD capabilities.

## 🌟 Why Bitbucket Server?

### **Enterprise Benefits**
- **🏢 On-Premises Control**: Complete control over source code and infrastructure
- **🔒 Enhanced Security**: Air-gapped environments and custom security policies
- **📊 Compliance**: Meet strict regulatory requirements (HIPAA, SOX, PCI DSS)
- **🔧 Customization**: Tailored workflows and integrations
- **💰 Cost Control**: Predictable licensing without per-user scaling costs

### **Perfect for Healthcare Applications**
- **🏥 HIPAA Compliance**: On-premises hosting ensures data sovereignty
- **🔐 Audit Requirements**: Complete audit trails and access controls
- **🌍 International Compliance**: Meet LGPD (Brazil) and GDPR requirements
- **🛡️ Zero Trust**: No external cloud dependencies for critical code

## 📋 Prerequisites

### **Bitbucket Server Requirements**
- **Bitbucket Server** 7.0+ (recommended 8.0+)
- **Bitbucket Pipelines** enabled
- **macOS build agents** with Xcode 15.1+
- **Administrator access** to Bitbucket Server instance

### **Development Environment**
- **Xcode** 15.1 or later
- **macOS** Monterey (12.0) or later
- **iOS Simulator** 17.2+
- **Apple Developer Account** (for certificates)

### **Build Infrastructure**
- **macOS build agents** configured in Bitbucket
- **Shared build agents** or **dedicated iOS build pool**
- **Network access** to Apple Developer Portal and App Store Connect

## 🔧 Installation and Setup

### **Step 1: Repository Migration**

#### **From GitHub to Bitbucket Server**

```bash
# 1. Clone the existing GitHub repository
git clone https://github.com/ThalesAndrades/ManusPsiqueia.git
cd ManusPsiqueia

# 2. Add Bitbucket Server as new remote
git remote add bitbucket https://your-bitbucket-server.com/scm/proj/manuspsiqueia.git

# 3. Push all branches and tags to Bitbucket Server
git push bitbucket --all
git push bitbucket --tags

# 4. Update default remote (optional)
git remote set-url origin https://your-bitbucket-server.com/scm/proj/manuspsiqueia.git
```

#### **Fresh Installation on Bitbucket Server**

```bash
# 1. Create new repository in Bitbucket Server UI
# 2. Clone the empty repository
git clone https://your-bitbucket-server.com/scm/proj/manuspsiqueia.git
cd manuspsiqueia

# 3. Download and extract ManusPsiqueia source
# 4. Add files and push
git add .
git commit -m "Initial import of ManusPsiqueia"
git push origin master
```

### **Step 2: Configure Bitbucket Pipelines**

#### **Enable Pipelines**
1. Navigate to your repository in Bitbucket Server
2. Go to **Repository settings** → **Pipelines**
3. Enable **Pipelines** for the repository
4. Configure **Build agents** (macOS required for iOS builds)

#### **Pipeline Configuration**
The repository includes a pre-configured `bitbucket-pipelines.yml` file with:
- **iOS CI/CD pipeline** with Xcode builds
- **Security analysis** and vulnerability scanning
- **Code quality** checks with SwiftLint
- **Automated testing** with unit and UI tests
- **Deployment** to TestFlight and App Store

### **Step 3: Environment Variables Setup**

Configure the following variables in **Repository settings** → **Pipelines** → **Repository variables**:

#### **iOS Development Certificates**
```bash
# Required for iOS app signing
IOS_CERTIFICATE_P12          # Base64 encoded .p12 certificate file
CERTIFICATE_PASSWORD          # Password for .p12 certificate
PROVISIONING_PROFILE         # Base64 encoded provisioning profile
KEYCHAIN_PASSWORD           # Password for build keychain
```

#### **App Store Connect**
```bash
# Required for TestFlight/App Store deployment
APP_STORE_CONNECT_API_KEY    # App Store Connect API key (JSON)
APP_STORE_CONNECT_ISSUER_ID  # Issuer ID from App Store Connect
APP_STORE_CONNECT_KEY_ID     # Key ID from App Store Connect
```

#### **Third-Party Integrations**
```bash
# Stripe configuration (for payment processing)
STRIPE_PUBLISHABLE_KEY_TEST  # Stripe test publishable key
STRIPE_SECRET_KEY_TEST       # Stripe test secret key
STRIPE_WEBHOOK_SECRET        # Stripe webhook secret

# OpenAI configuration (for AI features)
OPENAI_API_KEY              # OpenAI API key for AI insights

# Supabase configuration (for backend)
SUPABASE_URL                # Supabase project URL
SUPABASE_ANON_KEY           # Supabase anonymous key
```

### **Step 4: Webhook Configuration**

#### **For Payment Processing (Stripe)**

Configure Stripe webhooks to point to your Bitbucket Server environment:

```javascript
// Webhook endpoint configuration
const webhookEndpoint = {
  url: 'https://your-app-backend.com/webhooks/stripe',
  events: [
    'invoice.payment_succeeded',
    'invoice.payment_failed',
    'customer.subscription.created',
    'customer.subscription.updated',
    'customer.subscription.deleted',
    'payment_intent.succeeded'
  ]
};
```

#### **Bitbucket Server Webhooks**

Configure repository webhooks in Bitbucket Server:

1. Go to **Repository settings** → **Webhooks**
2. Add webhook for external integrations:
   - **URL**: Your application's webhook endpoint
   - **Events**: Push, Pull request created/updated/merged
   - **Headers**: Add authentication if required

## 🔒 Security Configuration

### **Branch Permissions**

Configure branch permissions in **Repository settings** → **Branch permissions**:

```yaml
# Master branch protection
master:
  - Prevent deletion: ✅
  - Restrict pushes: ✅ (Admin and specific users only)
  - Prevent rewriting history: ✅
  - Require pull request: ✅
  - Minimum approvals: 2
  - Required builds: ✅

# Development branch protection  
develop:
  - Prevent deletion: ✅
  - Restrict pushes: ✅ (Developers and above)
  - Require pull request: ✅
  - Minimum approvals: 1
  - Required builds: ✅
```

### **Access Controls**

Set up project permissions:

```yaml
# Project permissions
Administrators:
  - Project admin access
  - Repository admin access
  - Pipeline configuration

Developers:
  - Repository write access
  - Create/merge pull requests
  - Trigger pipelines

Reviewers:
  - Repository read access
  - Review pull requests
  - View build results
```

### **Audit and Compliance**

Enable comprehensive audit logging:

1. **System audit log** for all administrative actions
2. **Repository audit log** for all code changes
3. **Pipeline audit log** for all CI/CD activities
4. **Access audit log** for authentication and authorization

## 🏗️ CI/CD Pipeline Details

### **Pipeline Structure**

The Bitbucket Pipelines configuration includes:

#### **Default Pipeline (All Branches)**
```yaml
1. 🔍 Code Quality & Security Analysis
   - SwiftLint analysis
   - Security vulnerability scan
   - Dependency analysis
   
2. 🏗️ Build & Test
   - iOS application build
   - Unit test execution
   - Test coverage reporting
```

#### **Master Branch Pipeline**
```yaml
1. 🔍 Code Quality & Security Analysis
2. 🏗️ Build & Test  
3. 🔒 Advanced Security Scan
4. 📦 Dependency Analysis
5. 🚀 Deploy to TestFlight (Manual trigger)
```

#### **Pull Request Pipeline**
```yaml
1. 🔍 PR Code Quality Check
2. 🧪 PR Build & Test
```

### **Custom Pipelines**

#### **Full Analysis Pipeline**
Run comprehensive analysis manually:
```bash
# Trigger custom pipeline
curl -X POST \
  https://your-bitbucket-server.com/rest/api/1.0/projects/PROJ/repos/manuspsiqueia/pipelines \
  -H 'Authorization: Bearer YOUR_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{"refType": "BRANCH", "refName": "master", "pipelineName": "full-analysis"}'
```

### **Build Artifacts**

Each pipeline run generates artifacts:
- **SwiftLint reports** (JSON and XML formats)
- **Test coverage reports**
- **Build logs**
- **Security scan results**
- **Dependency analysis**
- **IPA files** (for deployment builds)

## 📱 iOS-Specific Configuration

### **Xcode Project Settings**

Ensure your Xcode project is configured for Bitbucket Server CI/CD:

```swift
// Build Settings
CODE_SIGNING_ALLOWED = NO (for CI builds)
ENABLE_TESTABILITY = YES
SWIFT_OPTIMIZATION_LEVEL = -Onone (for Debug)

// Schemes
- Shared schemes enabled
- Test coverage enabled
- Environment variables configured
```

### **ExportOptions.plist**

Create `ExportOptions.plist` for App Store deployment:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
</dict>
</plist>
```

## 🔧 Development Workflow

### **Feature Development**

1. **Create feature branch** from `develop`
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/new-feature
   ```

2. **Develop and commit changes**
   ```bash
   git add .
   git commit -m "feat: implement new feature"
   git push origin feature/new-feature
   ```

3. **Create pull request** in Bitbucket Server UI
   - Select reviewers
   - Add description
   - Link to relevant issues

4. **Pipeline execution**
   - Automatic PR pipeline triggers
   - Code quality checks run
   - Security analysis performed

5. **Code review and merge**
   - Reviewers approve changes
   - Pipeline passes all checks
   - Merge to develop branch

### **Release Process**

1. **Create release branch**
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b release/1.0.0
   ```

2. **Prepare release**
   - Update version numbers
   - Update changelog
   - Final testing

3. **Merge to master**
   ```bash
   git checkout master
   git merge release/1.0.0
   git tag v1.0.0
   git push origin master --tags
   ```

4. **Deploy to TestFlight**
   - Manual trigger in Bitbucket Pipelines
   - Automatic build and upload

## 🛠️ Troubleshooting

### **Common Issues**

#### **Pipeline Failures**

**Issue**: Xcode build fails with signing errors
```bash
Solution:
1. Verify iOS certificates are properly configured
2. Check provisioning profile validity
3. Ensure CERTIFICATE_PASSWORD is correct
4. Verify build agent has necessary permissions
```

**Issue**: SwiftLint failures blocking pipeline
```bash
Solution:
1. Run SwiftLint locally: swiftlint lint
2. Fix reported issues or update .swiftlint.yml
3. Commit fixes and re-run pipeline
```

#### **Deployment Issues**

**Issue**: App Store Connect upload fails
```bash
Solution:
1. Verify APP_STORE_CONNECT_API_KEY is valid
2. Check App Store Connect API permissions
3. Ensure bundle ID matches App Store Connect
4. Verify provisioning profile for distribution
```

### **Debug Commands**

```bash
# Check pipeline logs
curl -X GET \
  "https://your-bitbucket-server.com/rest/api/1.0/projects/PROJ/repos/manuspsiqueia/pipelines/{buildNumber}/logs" \
  -H "Authorization: Bearer YOUR_TOKEN"

# List pipeline artifacts
curl -X GET \
  "https://your-bitbucket-server.com/rest/api/1.0/projects/PROJ/repos/manuspsiqueia/pipelines/{buildNumber}/artifacts" \
  -H "Authorization: Bearer YOUR_TOKEN"

# Check build agent status
curl -X GET \
  "https://your-bitbucket-server.com/rest/api/1.0/admin/agents" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## 📊 Monitoring and Analytics

### **Pipeline Metrics**

Monitor pipeline performance through Bitbucket Server:
- **Build success rate**
- **Average build time**
- **Test coverage trends**
- **Security vulnerability trends**

### **Custom Dashboards**

Create custom dashboards for:
- **Development team productivity**
- **Code quality metrics**
- **Security compliance status**
- **Deployment frequency**

### **Integration with External Tools**

Connect Bitbucket Server with:
- **JIRA** for issue tracking
- **Confluence** for documentation
- **SonarQube** for code quality
- **Splunk** for log analysis

## 🔄 Migration Best Practices

### **Gradual Migration**

1. **Phase 1**: Set up Bitbucket Server repository
2. **Phase 2**: Configure basic CI/CD pipelines
3. **Phase 3**: Migrate webhook integrations
4. **Phase 4**: Train development team
5. **Phase 5**: Complete migration and decommission GitHub

### **Data Preservation**

Ensure preservation of:
- **Complete git history** and tags
- **Issue tracking** data (migrate to JIRA)
- **Wiki pages** (migrate to Confluence)
- **Release notes** and documentation

### **Team Training**

Provide training on:
- **Bitbucket Server UI** and workflow
- **Pipeline configuration** and debugging
- **Security features** and best practices
- **Integration tools** (JIRA, Confluence)

## 📞 Support and Maintenance

### **Ongoing Support**

- **Bitbucket Server administration** and updates
- **Build agent maintenance** and scaling
- **Security monitoring** and compliance
- **Performance optimization**

### **Contact Information**

**Technical Support:**
- **Company**: AiLun Tecnologia
- **CNPJ**: 60.740.536/0001-75
- **Email**: contato@ailun.com.br
- **Documentation**: Bitbucket Server wiki

**Bitbucket Server Administration:**
- **System administrators** for infrastructure issues
- **Repository administrators** for access control
- **Pipeline administrators** for CI/CD configuration

---

## 🎯 Conclusion

The **ManusPsiqueia** integration with **Bitbucket Server** provides enterprise-grade source code management with complete on-premises control. This setup ensures HIPAA compliance, enhanced security, and customizable workflows while maintaining the high-quality CI/CD capabilities essential for healthcare application development.

The implementation supports the full software development lifecycle from code commit to App Store deployment, with comprehensive security analysis and compliance reporting suitable for regulated healthcare environments.

---

*Document version: 1.0.0 | Last updated: September 2025*  
*Prepared by: AiLun Tecnologia | CNPJ: 60.740.536/0001-75*