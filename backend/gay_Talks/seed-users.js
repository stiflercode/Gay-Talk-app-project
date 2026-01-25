// Seed script to add dummy users for testing
// Run with: node seed-users.js

require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./models/User');

const dummyUsers = [
    {
        uid: 'admin_user_001',
        email: 'admin1@gaytalks.com',
        displayName: 'Alex Kumar',
        role: 'admin',
        walletBalance: 500,
        isOnline: true,
        isBusy: false,
        language: 'en',
        profileComplete: true,
    },
    {
        uid: 'admin_user_002',
        email: 'admin2@gaytalks.com',
        displayName: 'Raj Sharma',
        role: 'admin',
        walletBalance: 350,
        isOnline: true,
        isBusy: false,
        language: 'hi',
        profileComplete: true,
    },
    {
        uid: 'admin_user_003',
        email: 'admin3@gaytalks.com',
        displayName: 'Vikram Singh',
        role: 'admin',
        walletBalance: 200,
        isOnline: false,
        isBusy: false,
        language: 'hi-en',
        profileComplete: true,
    },
    {
        uid: 'test_user_001',
        email: 'user1@test.com',
        displayName: 'Amit Patel',
        role: 'user',
        walletBalance: 100,
        isOnline: false,
        isBusy: false,
        language: 'en',
        profileComplete: true,
    },
    {
        uid: 'test_user_002',
        email: 'user2@test.com',
        displayName: 'Rohan Gupta',
        role: 'user',
        walletBalance: 50,
        isOnline: true,
        isBusy: false,
        language: 'hi',
        profileComplete: true,
    },
];

async function seedUsers() {
    try {
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('Connected to MongoDB');

        for (const userData of dummyUsers) {
            const existing = await User.findOne({ uid: userData.uid });
            if (existing) {
                console.log(`User ${userData.displayName} already exists, updating...`);
                await User.updateOne({ uid: userData.uid }, userData);
            } else {
                await User.create(userData);
                console.log(`Created user: ${userData.displayName} (${userData.role})`);
            }
        }

        console.log('\n✅ Dummy users seeded successfully!');
        console.log('\nAdmin users (for testing calls):');
        console.log('  - Alex Kumar (admin_user_001) - Online');
        console.log('  - Raj Sharma (admin_user_002) - Online');
        console.log('  - Vikram Singh (admin_user_003) - Offline');
        console.log('\nTest users:');
        console.log('  - Amit Patel (test_user_001)');
        console.log('  - Rohan Gupta (test_user_002)');

        await mongoose.disconnect();
        console.log('\nDisconnected from MongoDB');
    } catch (error) {
        console.error('Error seeding users:', error);
        process.exit(1);
    }
}

seedUsers();
