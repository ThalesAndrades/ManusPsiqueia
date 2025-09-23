# Flow and Webhook Management Implementation Guide

## Overview

This implementation provides comprehensive flow management and webhook handling for the ManusPsiqueia platform, enabling robust user journey tracking and secure payment processing.

## Flow Management

### FlowManager Usage

The `FlowManager` handles application navigation flows and deep links:

```swift
// Start a new flow
FlowManager.shared.startFlow(.diary, metadata: ["source": "user_action"])

// Complete a flow
FlowManager.shared.completeFlow(metadata: ["duration": 30])

// Handle deep links
FlowManager.shared.handleDeepLink(URL(string: "manuspsiqueia://diary/new")!)
```

### Supported Deep Links

- `manuspsiqueia://diary/new` - Create new diary entry
- `manuspsiqueia://diary/entry/{id}` - View specific diary entry
- `manuspsiqueia://insights` - Navigate to insights
- `manuspsiqueia://goals/new` - Create new goal
- `manuspsiqueia://subscription` - Show paywall/subscription
- `manuspsiqueia://settings/{section}` - Navigate to specific settings

### Flow Analytics

```swift
// Get completion rate for a specific flow
let completionRate = FlowManager.shared.getFlowCompletionRate(for: .subscription)

// Get all events for a flow type
let events = FlowManager.shared.getFlowEvents(for: .diary)
```

## Webhook Management

### WebhookManager Usage

The `WebhookManager` handles Stripe webhook events securely:

```swift
// Validate webhook signature
let isValid = WebhookManager.shared.validateWebhook(
    payload: requestBody,
    signature: stripeSignature,
    secret: webhookSecret
)

// Process webhook event
let result = await WebhookManager.shared.processWebhookWithRetry(event)
```

### Supported Webhook Events

- `invoice.payment_succeeded` - Payment successful
- `invoice.payment_failed` - Payment failed
- `customer.subscription.created` - Subscription created
- `customer.subscription.updated` - Subscription updated
- `customer.subscription.deleted` - Subscription cancelled
- `payment_intent.succeeded` - One-time payment successful
- `payment_intent.payment_failed` - One-time payment failed
- `customer.created` - Customer created
- `price.created` - Price created (for dynamic pricing)
- `payment_method.attached` - Payment method added

## Integration Examples

### Using in SwiftUI Views

```swift
struct ContentView: View {
    @EnvironmentObject var flowManager: FlowManager
    @EnvironmentObject var webhookManager: WebhookManager
    
    var body: some View {
        VStack {
            Button("Start Subscription Flow") {
                flowManager.startFlow(.subscription)
            }
            
            Button("Show Diary") {
                flowManager.startFlow(.diary)
            }
        }
        .onOpenURL { url in
            flowManager.handleDeepLink(url)
        }
    }
}
```

### Backend Webhook Endpoint

If you're using a custom backend, implement webhook handling like this:

```javascript
// Express.js webhook endpoint
app.post('/webhooks/stripe', express.raw({type: 'application/json'}), (req, res) => {
  const sig = req.headers['stripe-signature'];
  const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;
  
  let event;
  try {
    event = stripe.webhooks.constructEvent(req.body, sig, webhookSecret);
  } catch (err) {
    console.log(`Webhook signature verification failed.`, err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }
  
  // Forward to app if needed or handle directly
  console.log('Received event:', event.type);
  res.json({received: true});
});
```

## Security Features

### Webhook Security

- **Signature Validation**: Uses HMAC-SHA256 for cryptographic verification
- **Timestamp Protection**: Rejects webhooks older than 5 minutes
- **Duplicate Prevention**: Prevents processing the same event multiple times
- **Secure Storage**: Webhook secrets stored in Keychain

### Flow Security

- **Audit Logging**: All flow events are logged for security monitoring
- **State Validation**: Prevents invalid flow transitions
- **Error Recovery**: Automatic recovery from failed states
- **Memory Management**: Automatic cleanup of old events

## Configuration

### Environment Variables

Set these environment variables for production:

```bash
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret_here
STRIPE_PUBLISHABLE_KEY=pk_live_your_publishable_key_here
```

### Info.plist Configuration

Add URL scheme to your Info.plist:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.ailun.manuspsiqueia.deeplink</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>manuspsiqueia</string>
        </array>
    </dict>
</array>
```

## Testing

### Flow Manager Tests

The implementation includes comprehensive tests for flow management:

- Deep link handling
- Flow state transitions
- Analytics tracking
- Error recovery
- Memory management

### Webhook Manager Tests

Tests cover all webhook functionality:

- Signature validation
- Event processing
- Retry mechanisms
- Duplicate handling
- Integration with flows

## Performance Considerations

### Memory Management

- Flow events are automatically limited to the last 100 entries
- Processed webhook events are limited to the last 1000 entries
- Automatic cleanup runs hourly

### Retry Strategy

Webhook processing uses exponential backoff:
- First retry: 1 second delay
- Second retry: 5 seconds delay
- Third retry: 15 seconds delay
- Maximum 3 retry attempts

## Error Handling

### Flow Errors

```swift
enum FlowError: LocalizedError {
    case invalidDeepLink(URL)
    case flowInProgress
    case authenticationRequired
    case subscriptionRequired
}
```

### Webhook Errors

```swift
enum WebhookError: LocalizedError {
    case invalidSignature
    case unsupportedEventType(String)
    case invalidEventData
    case paymentFailed(String)
    case maxRetriesExceeded
    case processingError(String)
}
```

## Best Practices

1. **Always validate webhook signatures** before processing
2. **Use deep links** for better user experience
3. **Monitor flow completion rates** for UX optimization
4. **Handle failed flows gracefully** with recovery options
5. **Log all webhook events** for debugging and compliance
6. **Test webhook handling** with Stripe CLI in development

## Development Tools

### Stripe CLI for Testing

```bash
# Install Stripe CLI
brew install stripe/stripe-cli/stripe

# Forward webhooks to local development
stripe listen --forward-to localhost:3000/webhooks/stripe

# Trigger test events
stripe trigger payment_intent.succeeded
```

### Testing Deep Links

```bash
# Test deep links in iOS Simulator
xcrun simctl openurl booted "manuspsiqueia://diary/new"
```

This implementation provides a solid foundation for flow management and webhook processing that can scale with your application's needs while maintaining security and performance standards.