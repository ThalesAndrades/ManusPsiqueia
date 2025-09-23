# Export Compliance Information - ManusPsiqueia

## Export Administration Regulations (EAR) Compliance

### App Classification
- **Product**: ManusPsiqueia - Mobile Application
- **Platform**: iOS
- **ECCN**: 5D002 (Information Security Software)

### Encryption Usage

#### Standard iOS Encryption
✅ **Uses Standard iOS Encryption**
- Core Data encryption
- Keychain Services
- Transport Layer Security (TLS)
- File system encryption

#### Custom Encryption
❌ **No Custom Encryption Implemented**
- No proprietary encryption algorithms
- No custom cryptographic implementations
- Uses only Apple-provided encryption APIs

### Export Control Classification

#### Category: 5D002.a.1
**Information Security Software**
- Uses only standard cryptographic functionality provided by iOS
- No custom encryption beyond what's available in standard iOS SDK
- Falls under standard encryption exemption

#### Exemption Status: **EXEMPT**
**Reasoning:**
1. Uses only encryption available in publicly available iOS SDK
2. No proprietary or custom encryption algorithms
3. Standard implementation of TLS for network communications
4. Standard implementation of iOS keychain for local data protection

### Third-Party Encryption

#### Supabase Database
- **Type**: Cloud database with standard encryption
- **Implementation**: PostgreSQL with standard TLS/SSL
- **Status**: Uses standard encryption provided by service

#### Stripe Payment Processing
- **Type**: Payment processing service
- **Implementation**: PCI DSS compliant standard encryption
- **Status**: Uses Stripe's standard encryption, no custom implementation

#### OpenAI API Integration
- **Type**: AI service integration
- **Implementation**: Standard HTTPS/TLS communication
- **Status**: Uses standard transport encryption

### Declaration for App Store Connect

#### Question: "Does your app use encryption?"
**Answer: YES**

#### Follow-up: "Does your app qualify for any of the exemptions?"
**Answer: YES - Uses only standard encryption**

#### Specific Exemption:
**"Your app uses standard cryptographic functionality provided by iOS"**

### Documentation for Submission

#### Required Information for App Store Connect:

1. **Encryption Usage**: Standard iOS encryption only
2. **Custom Algorithms**: None
3. **Export Compliance**: Exempt under standard encryption rules
4. **Third-party Libraries**: Only standard, publicly available libraries

#### Self-Classification:
```
ECCN: 5D002
Exemption: Standard Encryption
Reason: Uses only iOS-provided cryptographic functionality
```

### Compliance Statement

**ManusPsiqueia App Export Compliance Declaration:**

We, AiLun, developers of ManusPsiqueia, hereby declare that:

1. ✅ Our app uses only standard encryption provided by the iOS operating system
2. ✅ We do not implement any custom or proprietary encryption algorithms
3. ✅ All encryption is limited to:
   - Standard iOS keychain services
   - Standard iOS Core Data encryption
   - Standard TLS/HTTPS for network communications
   - Standard iOS file system encryption
4. ✅ No encryption source code is included beyond standard iOS APIs
5. ✅ App qualifies for standard encryption exemption under EAR

### Supporting Documentation

#### Technical Implementation Details:

**Local Data Encryption:**
- iOS Keychain Services for sensitive data storage
- Core Data with NSPersistentStoreFileProtectionKey
- iOS file system encryption for app sandbox

**Network Communication Encryption:**
- TLS 1.3 for all network communications
- Certificate pinning using standard iOS APIs
- No custom TLS implementation

**Third-Party Service Encryption:**
- Supabase: Standard PostgreSQL encryption
- Stripe: Standard PCI DSS compliant encryption
- OpenAI: Standard HTTPS transport encryption

### Submission Process

#### App Store Connect Steps:
1. Select "Yes" for encryption usage
2. Select "Yes" for standard encryption exemption
3. Provide this document as supporting evidence if requested
4. Complete automated compliance screening

#### Expected Outcome:
**Approved for distribution without additional export license requirements**

### Annual Compliance Review

#### Review Date: September 2024
#### Next Review: September 2025
#### Responsible Party: Technical Lead, AiLun

#### Changes Requiring Re-evaluation:
- Addition of custom encryption algorithms
- Implementation of proprietary security protocols
- Integration with services using non-standard encryption
- Distribution to embargoed countries

### Contact Information

#### Export Compliance Officer:
- **Name**: Legal Team
- **Email**: legal@ailun.com
- **Phone**: +55 11 99999-9999

#### Technical Contact:
- **Name**: Development Team
- **Email**: dev@ailun.com
- **Documentation**: This compliance document

---

**Document Version**: 1.0  
**Last Updated**: September 23, 2024  
**Valid Until**: September 23, 2025  
**Approved By**: AiLun Legal Team