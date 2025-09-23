/**
 * ManusPsiqueia Stripe Connect Integration Sample
 * 
 * This server demonstrates a complete Stripe Connect integration including:
 * - Creating Connected Accounts with controller properties
 * - Onboarding with Account Links
 * - Product creation for connected accounts
 * - Simple storefront for customer purchases
 * - Direct charges with application fees
 * 
 * Uses Stripe API version: 2025-08-27.basil
 * 
 * IMPORTANT: Replace placeholder values in .env file before running
 */

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { v4: uuidv4 } = require('uuid');
require('dotenv').config();

// Initialize Stripe with the latest API version
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY, {
  apiVersion: '2025-08-27.basil' // Using the latest version as requested
});

const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'", "https://fonts.googleapis.com"],
      fontSrc: ["'self'", "https://fonts.gstatic.com"],
      scriptSrc: ["'self'", "https://js.stripe.com"],
      frameSrc: ["https://js.stripe.com", "https://hooks.stripe.com"],
      connectSrc: ["'self'", "https://api.stripe.com"]
    }
  }
}));

// CORS configuration
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3000'],
  credentials: true
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use(limiter);

// Body parsing middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve static files
app.use(express.static('public'));

// Validation middleware to check if Stripe keys are configured
const validateStripeConfig = (req, res, next) => {
  if (!process.env.STRIPE_SECRET_KEY || process.env.STRIPE_SECRET_KEY === 'sk_test_YOUR_SECRET_KEY_HERE') {
    return res.status(500).json({
      error: 'Stripe configuration missing',
      message: 'Please set STRIPE_SECRET_KEY in your .env file. Copy .env.template to .env and add your keys.'
    });
  }
  if (!process.env.STRIPE_PUBLISHABLE_KEY || process.env.STRIPE_PUBLISHABLE_KEY === 'pk_test_YOUR_PUBLISHABLE_KEY_HERE') {
    return res.status(500).json({
      error: 'Stripe configuration missing',
      message: 'Please set STRIPE_PUBLISHABLE_KEY in your .env file. Copy .env.template to .env and add your keys.'
    });
  }
  next();
};

// Apply validation to all Stripe-related routes
app.use('/api', validateStripeConfig);

// ==============================================================================
// CONNECTED ACCOUNTS CREATION
// ==============================================================================

/**
 * Creates a new connected account using controller properties
 * This follows the exact pattern specified in the requirements
 */
app.post('/api/accounts/create', async (req, res) => {
  try {
    const { email, country = 'US' } = req.body;
    
    if (!email) {
      return res.status(400).json({
        error: 'Missing required field',
        message: 'Email is required to create a connected account'
      });
    }

    console.log('Creating connected account for:', email);

    // Create connected account with controller properties as specified
    // IMPORTANT: Using only controller properties, NOT top-level type
    const account = await stripe.accounts.create({
      controller: {
        // Platform controls fee collection - connected account pays fees
        fees: {
          payer: 'account' // Connected account pays the fees
        },
        // Stripe handles payment disputes and losses
        losses: {
          payments: 'stripe' // Stripe handles losses
        },
        // Connected account gets full access to Stripe dashboard
        stripe_dashboard: {
          type: 'full' // Full dashboard access
        }
      },
      // Basic account information
      country: country,
      email: email,
      // Capabilities that will be requested during onboarding
      capabilities: {
        card_payments: { requested: true },
        transfers: { requested: true }
      }
    });

    console.log('Connected account created:', account.id);

    res.json({
      success: true,
      account_id: account.id,
      email: account.email,
      country: account.country,
      controller: account.controller,
      message: 'Connected account created successfully. Use the account ID for onboarding.'
    });

  } catch (error) {
    console.error('Error creating connected account:', error.message);
    res.status(500).json({
      error: 'Account creation failed',
      message: error.message,
      type: error.type || 'api_error'
    });
  }
});

// ==============================================================================
// ACCOUNT ONBOARDING WITH ACCOUNT LINKS
// ==============================================================================

/**
 * Creates an Account Link for onboarding the connected account
 * This allows the connected account to complete their setup
 */
app.post('/api/accounts/:accountId/onboarding', async (req, res) => {
  try {
    const { accountId } = req.params;
    const { refresh_url, return_url } = req.body;

    console.log('Creating onboarding link for account:', accountId);

    // Create Account Link for onboarding
    const accountLink = await stripe.accountLinks.create({
      account: accountId,
      refresh_url: refresh_url || `http://${process.env.APP_DOMAIN}/onboarding/refresh?account=${accountId}`,
      return_url: return_url || `http://${process.env.APP_DOMAIN}/onboarding/return?account=${accountId}`,
      type: 'account_onboarding'
    });

    console.log('Onboarding link created for account:', accountId);

    res.json({
      success: true,
      account_id: accountId,
      onboarding_url: accountLink.url,
      expires_at: accountLink.expires_at,
      message: 'Onboarding link created successfully. Direct the user to onboarding_url to complete setup.'
    });

  } catch (error) {
    console.error('Error creating onboarding link:', error.message);
    res.status(500).json({
      error: 'Onboarding link creation failed',
      message: error.message,
      type: error.type || 'api_error'
    });
  }
});

/**
 * Gets the current status of a connected account
 * This allows checking the onboarding progress
 */
app.get('/api/accounts/:accountId/status', async (req, res) => {
  try {
    const { accountId } = req.params;

    console.log('Fetching account status for:', accountId);

    // Retrieve account directly from Stripe API as requested
    const account = await stripe.accounts.retrieve(accountId);

    // Determine onboarding status
    const charges_enabled = account.charges_enabled;
    const details_submitted = account.details_submitted;
    const payouts_enabled = account.payouts_enabled;

    let status = 'incomplete';
    let message = 'Account setup is incomplete';

    if (charges_enabled && details_submitted && payouts_enabled) {
      status = 'complete';
      message = 'Account is fully set up and ready to accept payments';
    } else if (details_submitted) {
      status = 'pending';
      message = 'Account details submitted, pending review';
    }

    // Check for any requirements
    const requirements = account.requirements || {};
    const currently_due = requirements.currently_due || [];
    const eventually_due = requirements.eventually_due || [];

    res.json({
      success: true,
      account_id: accountId,
      status: status,
      message: message,
      details: {
        charges_enabled,
        details_submitted,
        payouts_enabled,
        country: account.country,
        email: account.email,
        created: account.created,
        requirements: {
          currently_due,
          eventually_due,
          disabled_reason: requirements.disabled_reason
        }
      }
    });

  } catch (error) {
    console.error('Error fetching account status:', error.message);
    res.status(500).json({
      error: 'Failed to fetch account status',
      message: error.message,
      type: error.type || 'api_error'
    });
  }
});

// ==============================================================================
// PRODUCT CREATION FOR CONNECTED ACCOUNTS
// ==============================================================================

/**
 * Creates a product for a connected account using the Stripe-Account header
 * This allows connected accounts to create their own products
 */
app.post('/api/accounts/:accountId/products', async (req, res) => {
  try {
    const { accountId } = req.params;
    const { name, description, price_in_cents, currency = 'usd' } = req.body;

    if (!name || !price_in_cents) {
      return res.status(400).json({
        error: 'Missing required fields',
        message: 'name and price_in_cents are required'
      });
    }

    console.log(`Creating product for connected account ${accountId}:`, { name, price_in_cents, currency });

    // Create product on the connected account using stripeAccount parameter
    const product = await stripe.products.create({
      name: name,
      description: description,
      default_price_data: {
        unit_amount: price_in_cents,
        currency: currency,
      },
    }, {
      stripeAccount: accountId, // Use stripeAccount for the Stripe-Account header
    });

    console.log('Product created:', product.id, 'for account:', accountId);

    res.json({
      success: true,
      product_id: product.id,
      account_id: accountId,
      name: product.name,
      description: product.description,
      default_price: product.default_price,
      price_in_cents: price_in_cents,
      currency: currency,
      message: 'Product created successfully for connected account'
    });

  } catch (error) {
    console.error('Error creating product:', error.message);
    res.status(500).json({
      error: 'Product creation failed',
      message: error.message,
      type: error.type || 'api_error'
    });
  }
});

/**
 * Lists products for a connected account
 * Uses the connected account header when retrieving products
 */
app.get('/api/accounts/:accountId/products', async (req, res) => {
  try {
    const { accountId } = req.params;
    const { limit = 10 } = req.query;

    console.log('Fetching products for connected account:', accountId);

    // Retrieve products using the connected account header
    const products = await stripe.products.list({
      limit: parseInt(limit),
      expand: ['data.default_price'], // Expand price information
    }, {
      stripeAccount: accountId, // Use stripeAccount for the Stripe-Account header
    });

    console.log(`Found ${products.data.length} products for account:`, accountId);

    res.json({
      success: true,
      account_id: accountId,
      products: products.data.map(product => ({
        id: product.id,
        name: product.name,
        description: product.description,
        default_price: product.default_price ? {
          id: product.default_price.id,
          unit_amount: product.default_price.unit_amount,
          currency: product.default_price.currency
        } : null,
        created: product.created,
        updated: product.updated
      })),
      has_more: products.has_more,
      total_count: products.data.length
    });

  } catch (error) {
    console.error('Error fetching products:', error.message);
    res.status(500).json({
      error: 'Failed to fetch products',
      message: error.message,
      type: error.type || 'api_error'
    });
  }
});

// ==============================================================================
// HOSTED CHECKOUT WITH DIRECT CHARGES AND APPLICATION FEES
// ==============================================================================

/**
 * Creates a checkout session for a connected account's product
 * Uses Direct Charge with an application fee to monetize the transaction
 */
app.post('/api/accounts/:accountId/checkout', async (req, res) => {
  try {
    const { accountId } = req.params;
    const { price_id, quantity = 1, application_fee_amount = 123 } = req.body;

    if (!price_id) {
      return res.status(400).json({
        error: 'Missing required field',
        message: 'price_id is required to create checkout session'
      });
    }

    console.log(`Creating checkout session for account ${accountId}, price ${price_id}`);

    // Create checkout session with Direct Charge and application fee
    const session = await stripe.checkout.sessions.create({
      line_items: [
        {
          price: price_id,
          quantity: quantity,
        },
      ],
      payment_intent_data: {
        // Application fee for platform monetization
        application_fee_amount: application_fee_amount,
      },
      mode: 'payment',
      success_url: `http://${process.env.APP_DOMAIN}/success?session_id={CHECKOUT_SESSION_ID}&account=${accountId}`,
      cancel_url: `http://${process.env.APP_DOMAIN}/storefront/${accountId}?canceled=true`,
      // Optional: Add metadata for tracking
      metadata: {
        account_id: accountId,
        platform: 'ManusPsiqueia'
      }
    }, {
      stripeAccount: accountId, // Connected account header
    });

    console.log('Checkout session created:', session.id, 'for account:', accountId);

    res.json({
      success: true,
      session_id: session.id,
      account_id: accountId,
      checkout_url: session.url,
      application_fee_amount: application_fee_amount,
      message: 'Checkout session created successfully'
    });

  } catch (error) {
    console.error('Error creating checkout session:', error.message);
    res.status(500).json({
      error: 'Checkout session creation failed',
      message: error.message,
      type: error.type || 'api_error'
    });
  }
});

/**
 * Retrieves checkout session details after successful payment
 */
app.get('/api/checkout-session/:sessionId', async (req, res) => {
  try {
    const { sessionId } = req.params;
    const { account } = req.query;

    console.log('Retrieving checkout session:', sessionId, 'for account:', account);

    const session = await stripe.checkout.sessions.retrieve(sessionId, {
      stripeAccount: account, // Use connected account if provided
    });

    res.json({
      success: true,
      session: {
        id: session.id,
        payment_status: session.payment_status,
        amount_total: session.amount_total,
        currency: session.currency,
        customer_email: session.customer_details?.email,
        payment_intent: session.payment_intent
      }
    });

  } catch (error) {
    console.error('Error retrieving checkout session:', error.message);
    res.status(500).json({
      error: 'Failed to retrieve checkout session',
      message: error.message,
      type: error.type || 'api_error'
    });
  }
});

// ==============================================================================
// UTILITY ENDPOINTS
// ==============================================================================

/**
 * Health check endpoint
 */
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    service: 'ManusPsiqueia Stripe Connect Sample',
    stripe_api_version: '2025-08-27.basil'
  });
});

/**
 * Configuration endpoint for frontend
 */
app.get('/api/config', (req, res) => {
  res.json({
    publishable_key: process.env.STRIPE_PUBLISHABLE_KEY,
    app_domain: process.env.APP_DOMAIN,
    app_name: process.env.APP_NAME
  });
});

// ==============================================================================
// ERROR HANDLING
// ==============================================================================

// Global error handler
app.use((error, req, res, next) => {
  console.error('Unhandled error:', error);
  res.status(500).json({
    error: 'Internal server error',
    message: 'An unexpected error occurred'
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Not found',
    message: 'The requested resource was not found'
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`
🚀 ManusPsiqueia Stripe Connect Sample Server running on port ${PORT}

📋 Setup Instructions:
1. Copy .env.template to .env
2. Add your Stripe keys to .env file
3. Visit http://localhost:${PORT} to access the demo

🔧 API Endpoints:
- POST /api/accounts/create - Create connected account
- POST /api/accounts/:id/onboarding - Create onboarding link  
- GET  /api/accounts/:id/status - Check account status
- POST /api/accounts/:id/products - Create product
- GET  /api/accounts/:id/products - List products
- POST /api/accounts/:id/checkout - Create checkout session

🌐 Frontend:
- http://localhost:${PORT} - Main dashboard
- http://localhost:${PORT}/storefront/:accountId - Account storefront

⚠️  Important: Replace placeholder values in .env before testing!
  `);
});

module.exports = app;