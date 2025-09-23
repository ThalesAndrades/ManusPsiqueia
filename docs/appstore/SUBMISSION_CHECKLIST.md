# App Store Connect Submission Checklist - ManusPsiqueia

## Pre-Submission Requirements ✅

### Developer Account Setup
- [x] **Apple Developer Program membership** - Active and verified
- [x] **Team member roles** - Proper permissions assigned
- [x] **Certificates** - Development and distribution certificates valid
- [x] **Provisioning profiles** - App Store distribution profile ready
- [x] **Bundle ID** - `com.ailun.manuspsiqueia` registered and configured

### App Store Connect Configuration
- [x] **App record created** - ManusPsiqueia app entry in App Store Connect
- [x] **Bundle ID linked** - Correct bundle ID associated
- [x] **Team permissions** - Team members have appropriate access
- [x] **Tax and banking** - Payment information configured
- [x] **Agreements** - All required agreements accepted

## App Information

### Basic App Information ✅
- [x] **App Name**: ManusPsiqueia
- [x] **Bundle ID**: com.ailun.manuspsiqueia  
- [x] **SKU**: MANUSPSIQ2024
- [x] **Primary Language**: Portuguese (Brazil)
- [x] **Category**: Medical
- [x] **Secondary Category**: Health & Fitness

### Version Information ✅
- [x] **Version Number**: 1.0
- [x] **Build Number**: Automated from CI/CD
- [x] **Copyright**: 2024 AiLun
- [x] **Version Release**: Manual release after approval

## Pricing and Availability

### Pricing Strategy ✅
- [x] **Base App**: Free
- [x] **In-App Purchases**: Premium subscription configured
- [x] **Pricing Tiers**:
  - Monthly Premium: R$ 19.90 (Tier 7)
  - Yearly Premium: R$ 199.90 (Custom pricing)
- [x] **Auto-Renewable Subscriptions**: Properly configured

### Availability ✅
- [x] **Countries/Regions**: Brazil (initial launch)
- [x] **Available Date**: After App Review approval
- [x] **Price Schedule**: No scheduled price changes
- [x] **Educational Discounts**: None initially

## App Store Listing

### App Store Information ✅
- [x] **Name**: ManusPsiqueia
- [x] **Subtitle**: Seu Diário Inteligente de Bem-Estar Mental
- [x] **Description**: Complete Portuguese description (4000 chars)
- [x] **Keywords**: diário,saúde mental,bem-estar,IA,privacidade,autoconhecimento,humor,emoções,reflexão,mindfulness
- [x] **Support URL**: https://manuspsiqueia.com/support
- [x] **Marketing URL**: https://manuspsiqueia.com
- [x] **Privacy Policy URL**: https://manuspsiqueia.com/privacy

### App Store Localization
#### Portuguese (Brazil) - Primary ✅
- [x] **Description**: Detailed Portuguese description
- [x] **Keywords**: Portuguese keywords optimized for Brazil
- [x] **What's New**: Launch description in Portuguese
- [x] **Promotional Text**: Featured text in Portuguese

#### English (International) ✅
- [x] **Description**: Complete English description
- [x] **Keywords**: English keywords for international markets
- [x] **What's New**: Launch description in English
- [x] **Promotional Text**: Featured text in English

## App Store Assets

### App Icon ✅
- [x] **App Icon Set**: All required sizes in AppIcon.appiconset
- [x] **1024x1024**: High resolution icon for App Store
- [x] **Format**: PNG without transparency
- [x] **Design**: Consistent with brand guidelines

### Screenshots
#### iPhone Screenshots (Required) 📸
- [ ] **6.7" (iPhone 14 Pro Max)**: 5 screenshots minimum
- [ ] **6.1" (iPhone 14)**: 5 screenshots minimum  
- [ ] **5.5" (iPhone 8 Plus)**: 5 screenshots minimum

**Screenshot Content Plan:**
1. **Main Diary View** - Clean diary interface with sample entry
2. **AI Insights** - AI-generated insights dashboard
3. **Mood Tracking** - Mood calendar and tracking interface
4. **Privacy Settings** - Security and privacy configuration
5. **Premium Features** - Premium subscription benefits

#### iPad Screenshots (Required) 📸
- [ ] **12.9" (iPad Pro)**: 5 screenshots minimum
- [ ] **11" (iPad Pro)**: 5 screenshots minimum

**iPad Screenshot Adaptations:**
- Landscape and portrait orientations
- Larger screen real estate showcase
- Split view capabilities if supported

### App Preview Videos (Optional but Recommended) 🎥
- [ ] **iPhone Video**: 15-30 second preview showing key features
- [ ] **iPad Video**: Adapted for iPad interface
- [ ] **Content**: Privacy focus, AI insights, easy journaling

**Video Content Outline:**
1. **Opening** (3s): App logo and name
2. **Privacy** (8s): Face ID protection, encryption
3. **Journaling** (10s): Easy entry creation
4. **AI Insights** (7s): Personalized analysis
5. **Closing** (2s): Download call-to-action

## Legal and Compliance

### Required Legal Documents ✅
- [x] **Privacy Policy**: Comprehensive LGPD/GDPR compliant policy
- [x] **Terms of Service**: Complete terms covering all usage scenarios
- [x] **End User License Agreement**: Standard EULA for app usage

### Content Rating ✅
- [x] **Age Rating**: 17+
- [x] **Content Descriptors**: 
  - Frequent/Intense Mature/Suggestive Themes
  - Medical/Treatment Information
- [x] **Questionnaire**: Completed accurately in App Store Connect

### Export Compliance ✅
- [x] **Uses Encryption**: Yes
- [x] **Exemption Status**: Standard encryption exemption
- [x] **Documentation**: Export compliance document prepared
- [x] **ECCN Classification**: 5D002 - Information Security Software

## Technical Requirements

### Build Configuration ✅
- [x] **iOS Deployment Target**: 16.0
- [x] **Supported Devices**: iPhone, iPad
- [x] **Architecture**: arm64
- [x] **Swift Version**: 5.0
- [x] **Xcode Version**: 15.0+

### Code Signing ✅
- [x] **Development Team**: AiLun team properly configured
- [x] **Distribution Certificate**: Valid Apple Distribution certificate
- [x] **Provisioning Profile**: App Store distribution profile
- [x] **Bundle ID Match**: Exact match with registered Bundle ID

### App Store Package ✅
- [x] **IPA Generation**: Automated through scripts/deploy.sh
- [x] **Symbols Upload**: dSYM files included for crash reporting
- [x] **Bitcode**: Disabled (iOS 14+ requirement)
- [x] **App Thinning**: Configured for optimal download sizes

## App Review Information

### Contact Information ✅
- [x] **First Name**: Support
- [x] **Last Name**: Team  
- [x] **Phone Number**: +55 11 99999-9999
- [x] **Email**: appstore@ailun.com

### Review Notes ✅
```
Review Team Notes:

This app is a personal diary and mental wellness tool featuring:

1. PRIVACY-FIRST DESIGN
- End-to-end encryption for all personal data
- Local authentication with Face ID/Touch ID
- No data sharing or selling to third parties
- Full user control over data

2. AI-POWERED INSIGHTS
- OpenAI integration for personalized mental health insights
- Data processed anonymously for privacy protection
- Optional feature - users can disable AI processing
- Clear disclaimers about not replacing medical care

3. MEDICAL DISCLAIMER
- App clearly states it's not medical advice
- Includes crisis support resources (CVV: 188, SAMU: 192)
- Encourages users to seek professional help when needed
- Positioned as wellness tool, not medical device

4. SUBSCRIPTION MODEL
- Freemium model with clear feature differentiation
- Premium subscription through Apple In-App Purchase
- Transparent pricing without dark patterns
- Easy cancellation through iOS settings

5. CONTENT MATURITY
- Rated 17+ due to mental health content complexity
- Appropriate warnings and disclaimers throughout
- Encourages responsible mental health discussions

Demo account available if needed:
Email: demo@manuspsiqueia.com
Password: AppReview2024!

All premium features unlocked for review purposes.
```

### Demo Account (If Requested) ✅
- [x] **Username**: demo@manuspsiqueia.com
- [x] **Password**: AppReview2024!
- [x] **Features**: Full access to premium features
- [x] **Sample Data**: Pre-populated with demonstration content

## Privacy Information for App Store

### Data Collection Categories ✅
- [x] **Contact Info**: Email address (for account creation)
- [x] **Health & Fitness**: Mood data, wellness metrics (user input)
- [x] **User Content**: Diary entries, reflections (user created)
- [x] **Usage Data**: App analytics (minimal, anonymized)
- [x] **Diagnostics**: Crash reports (automatic, anonymized)

### Data Linking ✅
- [x] **Linked to User**: Personal content, account info
- [x] **Not Linked to User**: Anonymous analytics, crash reports
- [x] **Tracking**: None - no cross-app tracking implemented

### Data Usage ✅
- [x] **App Functionality**: All personal data used only for app features
- [x] **Analytics**: Minimal usage analytics for app improvement
- [x] **Developer Advertising**: None
- [x] **Third-Party Advertising**: None

## Quality Assurance

### Testing Checklist ✅
- [x] **Functionality Testing**: All features tested on multiple devices
- [x] **Performance Testing**: Memory usage, battery impact optimized
- [x] **Security Testing**: Encryption, authentication verified
- [x] **Accessibility Testing**: VoiceOver and accessibility features tested
- [x] **Localization Testing**: Portuguese and English interfaces tested

### Device Testing ✅
- [x] **iPhone Models**: Tested on iPhone 14 Pro, iPhone 13, iPhone SE 3rd gen
- [x] **iPad Models**: Tested on iPad Pro 12.9", iPad Air 5th gen
- [x] **iOS Versions**: Tested on iOS 16.0, 16.6, 17.0+
- [x] **Performance**: Smooth operation on all tested devices

## Final Submission Steps

### Pre-Submission Validation 📋
- [ ] **App Store Guidelines Review**: Complete compliance review
- [ ] **Metadata Accuracy**: All information verified and accurate
- [ ] **Asset Quality**: Screenshots and videos meet Apple standards
- [ ] **Legal Review**: All documents reviewed by legal team
- [ ] **Technical Validation**: Final build tested and approved

### Submission Process 📤
- [ ] **Build Upload**: Upload final build through Xcode or Transporter
- [ ] **Build Processing**: Wait for build processing completion
- [ ] **Metadata Submission**: Submit for review with all information
- [ ] **Automatic Release**: Configure release settings (manual recommended)

### Post-Submission Monitoring 📊
- [ ] **Review Status**: Monitor App Store Connect for review updates
- [ ] **Response Time**: Prepare for potential reviewer questions
- [ ] **Marketing Preparation**: Prepare launch marketing materials
- [ ] **Support Readiness**: Customer support team briefed and ready

## Expected Timeline

### Review Process Timeline 📅
- **Submission**: Day 0
- **In Review**: Days 1-3 (typical)
- **Review Complete**: Days 2-7 (Apple guideline)
- **Ready for Sale**: Day of approval (if automatic release)

### Launch Coordination 🚀
- **Marketing Launch**: Coordinate with review approval
- **PR Outreach**: Press release ready for approval day
- **Social Media**: Launch posts scheduled
- **Customer Support**: Team ready for user inquiries

---

**Submission Readiness**: 90% Complete  
**Remaining Tasks**: Screenshots, Videos, Final Testing  
**Target Submission Date**: October 15, 2024  
**Expected App Store Launch**: October 22-29, 2024