#!/bin/bash

# Razorpay Live Mode Setup Script
# Replace the placeholders below with your actual Razorpay live credentials

echo "🚀 Setting up Razorpay Live Mode..."

# TODO: Replace these with your actual live credentials
RAZORPAY_KEY_ID="rzp_live_YOUR_KEY_ID_HERE"
RAZORPAY_KEY_SECRET="YOUR_SECRET_KEY_HERE"

# Check if credentials are provided
if [ "$RAZORPAY_KEY_ID" == "rzp_live_YOUR_KEY_ID_HERE" ] || [ "$RAZORPAY_KEY_SECRET" == "YOUR_SECRET_KEY_HERE" ]; then
    echo "❌ Error: Please update this script with your actual Razorpay live credentials!"
    echo ""
    echo "Edit this file and replace:"
    echo "  RAZORPAY_KEY_ID=\"rzp_live_YOUR_KEY_ID_HERE\""
    echo "  RAZORPAY_KEY_SECRET=\"YOUR_SECRET_KEY_HERE\""
    exit 1
fi

# Validate Key ID format
if [[ ! "$RAZORPAY_KEY_ID" =~ ^rzp_live_ ]]; then
    echo "⚠️  Warning: Key ID should start with 'rzp_live_' for production mode"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "📝 Setting Firebase Functions config..."
firebase functions:config:set razorpay.key_id="$RAZORPAY_KEY_ID" razorpay.key_secret="$RAZORPAY_KEY_SECRET"

if [ $? -eq 0 ]; then
    echo "✅ Razorpay credentials configured successfully!"
    echo ""
    echo "📋 Verifying configuration..."
    firebase functions:config:get | grep razorpay
    
    echo ""
    echo "🚀 Deploying Firebase Functions..."
    firebase deploy --only functions
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "✅ Setup complete! Razorpay is now in LIVE mode."
        echo ""
        echo "⚠️  IMPORTANT: Test with a small amount first (e.g., ₹1)!"
        echo "📊 Check payments in Razorpay Dashboard: https://dashboard.razorpay.com/"
    else
        echo "❌ Deployment failed. Check the error messages above."
        exit 1
    fi
else
    echo "❌ Failed to set Firebase Functions config."
    exit 1
fi


