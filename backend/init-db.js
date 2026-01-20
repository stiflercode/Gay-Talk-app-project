require('dotenv').config();
const mongoose = require('mongoose');
const AdminGroup = require('./models/AdminGroup');

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/gaytalk';

async function seed() {
    try {
        await mongoose.connect(MONGODB_URI.replace('<db_password>', process.argv[2] || '<db_password>'));
        console.log('✅ Connected to MongoDB');

        // Create default group if it doesn't exist
        const existing = await AdminGroup.findOne({ groupId: 'default' });
        if (!existing) {
            const defaultGroup = new AdminGroup({
                groupId: 'default',
                name: 'Main Hunt Group',
                adminIds: [
                    'admin_uid_1', // Replace with real Firebase UIDs of your admins
                    'admin_uid_2'
                ]
            });
            await defaultGroup.save();
            console.log('🚀 Default Admin Group Created!');
        } else {
            console.log('ℹ️ Default Admin Group already exists.');
        }

        process.exit(0);
    } catch (err) {
        console.error('❌ Seeding Error:', err);
        process.exit(1);
    }
}

seed();
