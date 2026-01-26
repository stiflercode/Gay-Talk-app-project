/**
 * Seed script to initialize masked listeners (virtual identities for Hunt Group feature)
 * 
 * Run with: node seed-masked-listeners.js
 */

require('dotenv').config();
const mongoose = require('mongoose');
const AdminGroup = require('./models/AdminGroup');

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/gaytalk';

async function seedMaskedListeners() {
    try {
        await mongoose.connect(MONGODB_URI);
        console.log('✅ Connected to MongoDB');

        // Find or create the default admin group
        let group = await AdminGroup.findOne({ groupId: 'default' });

        if (!group) {
            console.log('📝 Creating new default admin group...');
            group = new AdminGroup({
                groupId: 'default',
                name: 'Main Hunt Group',
                adminIds: [], // Add your admin UIDs here
                maskedListeners: []
            });
        }

        // Add masked listeners if none exist
        if (!group.maskedListeners || group.maskedListeners.length === 0) {
            console.log('📝 Adding default masked listeners...');
            group.maskedListeners = [
                {
                    maskId: 'listener_1',
                    displayName: 'Listener 1',
                    languages: ['English', 'Hindi'],
                    rating: 4.9,
                    coinsPerMin: 5,
                    isActive: true
                },
                {
                    maskId: 'listener_2',
                    displayName: 'Listener 2',
                    languages: ['English', 'Tamil'],
                    rating: 4.8,
                    coinsPerMin: 5,
                    isActive: true
                },
                {
                    maskId: 'listener_3',
                    displayName: 'Listener 3',
                    languages: ['English', 'Telugu'],
                    rating: 4.7,
                    coinsPerMin: 5,
                    isActive: true
                }
            ];
        }

        await group.save();
        console.log('✅ Masked listeners seeded successfully!');
        console.log('📋 Masked Listeners:', group.maskedListeners.map(l => `${l.maskId}: ${l.displayName}`));

        // Show admin IDs if any
        if (group.adminIds && group.adminIds.length > 0) {
            console.log('👥 Admin IDs:', group.adminIds);
        } else {
            console.log('⚠️  No admin IDs configured. Add admin UIDs to the adminIds array.');
        }

    } catch (error) {
        console.error('❌ Error:', error);
    } finally {
        await mongoose.disconnect();
        console.log('🔌 Disconnected from MongoDB');
    }
}

seedMaskedListeners();
