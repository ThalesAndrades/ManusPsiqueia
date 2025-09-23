# Backend Integration Examples

## Node.js/Express.js Webhook Endpoint

Here's a complete example of how to handle Stripe webhooks on the backend that integrates with the iOS app's webhook system:

### package.json
```json
{
  "name": "manuspsiqueia-webhook-server",
  "version": "1.0.0",
  "description": "Webhook server for ManusPsiqueia",
  "main": "server.js",
  "dependencies": {
    "express": "^4.18.0",
    "stripe": "^12.0.0",
    "cors": "^2.8.5",
    "helmet": "^7.0.0",
    "dotenv": "^16.0.0"
  }
}
```

### server.js
```javascript
const express = require('express');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const cors = require('cors');
const helmet = require('helmet');
require('dotenv').config();

const app = express();
const port = process.env.PORT || 3000;

// Security middleware
app.use(helmet());
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3000']
}));

// Webhook endpoint - raw body needed for signature verification
app.use('/webhooks/stripe', express.raw({type: 'application/json'}));

// Other routes - parsed JSON
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    timestamp: new Date().toISOString(),
    service: 'ManusPsiqueia Webhook Server'
  });
});

// Stripe webhook endpoint
app.post('/webhooks/stripe', async (req, res) => {
  const sig = req.headers['stripe-signature'];
  const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;
  
  let event;
  
  try {
    // Verify webhook signature
    event = stripe.webhooks.constructEvent(req.body, sig, webhookSecret);
    console.log(`✅ Webhook verified: ${event.type}`);
  } catch (err) {
    console.log(`❌ Webhook signature verification failed:`, err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  try {
    // Handle the event
    await handleWebhookEvent(event);
    
    // Send success response
    res.json({received: true, eventId: event.id});
    
  } catch (error) {
    console.error(`❌ Error processing webhook ${event.id}:`, error);
    res.status(500).json({
      error: 'Internal server error',
      eventId: event.id
    });
  }
});

// Webhook event handler
async function handleWebhookEvent(event) {
  console.log(`🔄 Processing event: ${event.type} (${event.id})`);
  
  switch (event.type) {
    case 'invoice.payment_succeeded':
      await handlePaymentSucceeded(event.data.object);
      break;
      
    case 'invoice.payment_failed':
      await handlePaymentFailed(event.data.object);
      break;
      
    case 'customer.subscription.created':
      await handleSubscriptionCreated(event.data.object);
      break;
      
    case 'customer.subscription.updated':
      await handleSubscriptionUpdated(event.data.object);
      break;
      
    case 'customer.subscription.deleted':
      await handleSubscriptionCanceled(event.data.object);
      break;
      
    case 'payment_intent.succeeded':
      await handlePaymentIntentSucceeded(event.data.object);
      break;
      
    case 'customer.created':
      await handleCustomerCreated(event.data.object);
      break;
      
    default:
      console.log(`⚠️  Unhandled event type: ${event.type}`);
  }
}

// Event handlers
async function handlePaymentSucceeded(invoice) {
  console.log(`💰 Payment succeeded for customer: ${invoice.customer}`);
  
  // Update user subscription status in your database
  await updateUserSubscriptionStatus(invoice.customer, 'active');
  
  // Send confirmation email/notification
  await sendPaymentConfirmation(invoice);
  
  // Log for analytics
  await logPaymentEvent('payment_succeeded', {
    customerId: invoice.customer,
    amount: invoice.amount_paid,
    currency: invoice.currency
  });
}

async function handlePaymentFailed(invoice) {
  console.log(`❌ Payment failed for customer: ${invoice.customer}`);
  
  // Handle payment failure
  await updateUserSubscriptionStatus(invoice.customer, 'past_due');
  
  // Send payment failure notification
  await sendPaymentFailureNotification(invoice);
  
  // Log for analytics
  await logPaymentEvent('payment_failed', {
    customerId: invoice.customer,
    failureReason: invoice.last_payment_error?.message
  });
}

async function handleSubscriptionCreated(subscription) {
  console.log(`✨ Subscription created: ${subscription.id}`);
  
  // Store subscription in database
  await storeSubscription(subscription);
  
  // Activate premium features for user
  await activatePremiumFeatures(subscription.customer);
  
  // Send welcome email
  await sendWelcomeEmail(subscription.customer);
}

async function handleSubscriptionUpdated(subscription) {
  console.log(`🔄 Subscription updated: ${subscription.id}`);
  
  // Update subscription in database
  await updateSubscription(subscription);
  
  // Handle plan changes
  if (subscription.status === 'active') {
    await activatePremiumFeatures(subscription.customer);
  } else {
    await deactivatePremiumFeatures(subscription.customer);
  }
}

async function handleSubscriptionCanceled(subscription) {
  console.log(`🛑 Subscription canceled: ${subscription.id}`);
  
  // Update subscription status
  await updateUserSubscriptionStatus(subscription.customer, 'canceled');
  
  // Deactivate premium features
  await deactivatePremiumFeatures(subscription.customer);
  
  // Send cancelation confirmation
  await sendCancelationConfirmation(subscription.customer);
}

async function handlePaymentIntentSucceeded(paymentIntent) {
  console.log(`✅ Payment intent succeeded: ${paymentIntent.id}`);
  
  // Handle one-time payments
  await processOneTimePayment(paymentIntent);
}

async function handleCustomerCreated(customer) {
  console.log(`👤 Customer created: ${customer.id}`);
  
  // Store customer data
  await storeCustomerData(customer);
}

// Database operations (implement based on your chosen database)
async function updateUserSubscriptionStatus(customerId, status) {
  // Implementation depends on your database
  console.log(`📝 Updating subscription status for ${customerId} to ${status}`);
  
  // Example with PostgreSQL/Supabase:
  // await supabase
  //   .from('users')
  //   .update({ subscription_status: status })
  //   .eq('stripe_customer_id', customerId);
}

async function storeSubscription(subscription) {
  console.log(`💾 Storing subscription: ${subscription.id}`);
  
  // Store subscription details in database
  // Implementation depends on your database choice
}

async function updateSubscription(subscription) {
  console.log(`🔄 Updating subscription: ${subscription.id}`);
  
  // Update subscription in database
}

async function activatePremiumFeatures(customerId) {
  console.log(`⭐ Activating premium features for customer: ${customerId}`);
  
  // Enable premium features in your system
}

async function deactivatePremiumFeatures(customerId) {
  console.log(`🔒 Deactivating premium features for customer: ${customerId}`);
  
  // Disable premium features
}

async function storeCustomerData(customer) {
  console.log(`👤 Storing customer data: ${customer.id}`);
  
  // Store customer information
}

async function processOneTimePayment(paymentIntent) {
  console.log(`💳 Processing one-time payment: ${paymentIntent.id}`);
  
  // Handle one-time payment logic
}

// Notification functions
async function sendPaymentConfirmation(invoice) {
  console.log(`📧 Sending payment confirmation for invoice: ${invoice.id}`);
  // Implement email/push notification logic
}

async function sendPaymentFailureNotification(invoice) {
  console.log(`📧 Sending payment failure notification for invoice: ${invoice.id}`);
  // Implement failure notification logic
}

async function sendWelcomeEmail(customerId) {
  console.log(`👋 Sending welcome email to customer: ${customerId}`);
  // Implement welcome email logic
}

async function sendCancelationConfirmation(customerId) {
  console.log(`👋 Sending cancelation confirmation to customer: ${customerId}`);
  // Implement cancelation email logic
}

// Analytics logging
async function logPaymentEvent(eventType, data) {
  console.log(`📊 Logging payment event: ${eventType}`, data);
  // Implement analytics logging
}

// Error handling middleware
app.use((error, req, res, next) => {
  console.error('Unhandled error:', error);
  res.status(500).json({
    error: 'Internal server error',
    timestamp: new Date().toISOString()
  });
});

// Start server
app.listen(port, () => {
  console.log(`🚀 ManusPsiqueia webhook server running on port ${port}`);
  console.log(`📡 Webhook endpoint: http://localhost:${port}/webhooks/stripe`);
  console.log(`🔍 Health check: http://localhost:${port}/health`);
});

module.exports = app;
```

### .env (Environment Variables)
```bash
# Stripe Configuration
STRIPE_SECRET_KEY=sk_test_your_secret_key_here
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret_here

# Server Configuration
PORT=3000
ALLOWED_ORIGINS=http://localhost:3000,https://manuspsiqueia.com

# Database Configuration (example for Supabase)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_KEY=your-service-key-here

# Other services
SENDGRID_API_KEY=your-sendgrid-key-here
```

## Setting up Stripe Webhooks

### 1. Create Webhook Endpoint in Stripe Dashboard

1. Go to [Stripe Dashboard](https://dashboard.stripe.com)
2. Navigate to Developers → Webhooks
3. Click "Add endpoint"
4. Enter your endpoint URL: `https://your-server.com/webhooks/stripe`
5. Select events to send:
   - `invoice.payment_succeeded`
   - `invoice.payment_failed`
   - `customer.subscription.created`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
   - `payment_intent.succeeded`
   - `payment_intent.payment_failed`
   - `customer.created`

### 2. Get Webhook Signing Secret

After creating the webhook, copy the signing secret (starts with `whsec_`) and add it to your environment variables.

## Testing with Stripe CLI

### Install Stripe CLI
```bash
# macOS
brew install stripe/stripe-cli/stripe

# Other platforms: https://stripe.com/docs/stripe-cli
```

### Forward webhooks to local development
```bash
# Login to Stripe
stripe login

# Forward webhooks to your local server
stripe listen --forward-to localhost:3000/webhooks/stripe

# In another terminal, trigger test events
stripe trigger payment_intent.succeeded
stripe trigger invoice.payment_failed
```

## Deployment Considerations

### Security
- Always verify webhook signatures
- Use HTTPS in production
- Set up proper CORS policies
- Use environment variables for secrets
- Implement rate limiting

### Monitoring
- Log all webhook events
- Set up alerts for failed webhooks
- Monitor webhook delivery in Stripe Dashboard
- Implement health checks

### Scaling
- Use queues for heavy processing
- Implement idempotency for webhook handling
- Set up load balancing if needed
- Use database transactions for critical updates

This server implementation works seamlessly with the iOS app's `WebhookManager` and provides a complete solution for handling Stripe webhooks in the ManusPsiqueia platform.