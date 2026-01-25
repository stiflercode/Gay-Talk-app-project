require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./models/User');

const MONGODB_URI = process.env.MONGODB_URI;

mongoose.connect(MONGODB_URI)
    .then(async () => {
        console.log('✅ Connected to MongoDB');
        const users = await User.find({}, 'uid email role isOnline');
        console.log('Users in DB:');
        users.forEach(u => {
            console.log(` - ${u.email} (${u.uid}): Role=${u.role}, Online=${u.isOnline}`);
        });
        process.exit(0);
    })
    .catch(err => {
        console.error('❌ Error:', err);
        process.exit(1);
    });
