require('dotenv').config();
const mongoose = require('mongoose');
const AdminGroup = require('./models/AdminGroup');
const User = require('./models/User');

const MONGODB_URI = process.env.MONGODB_URI;

mongoose.connect(MONGODB_URI)
    .then(async () => {
        console.log('✅ Connected to MongoDB');

        // 1. Check for admins
        const admins = await User.find({ role: 'admin' });
        console.log(`Found ${admins.length} admins in User collection:`);
        admins.forEach(a => console.log(` - ${a.displayName} (${a.uid})`));

        if (admins.length === 0) {
            console.log('⚠️ No admins found! Promoting first user to admin for testing...');
            const firstUser = await User.findOne();
            if (firstUser) {
                firstUser.role = 'admin';
                await firstUser.save();
                console.log(`✅ Promoted ${firstUser.displayName} to admin`);
                admins.push(firstUser);
            }
        }

        // 2. Check AdminGroup
        let group = await AdminGroup.findOne({ groupId: 'default' });
        if (!group) {
            console.log('⚠️ No default admin group found. Creating one...');
            group = new AdminGroup({
                groupId: 'default',
                name: 'Main Hunt Group',
                adminIds: admins.map(a => a.uid)
            });
            await group.save();
            console.log('✅ Default admin group created');
        } else {
            console.log('✅ Admin group exists:', group.name);
            console.log('Admins in group:', group.adminIds);

            // Sync admins if needed
            const newAdminIds = admins.map(a => a.uid);
            let changed = false;
            newAdminIds.forEach(id => {
                if (!group.adminIds.includes(id)) {
                    group.adminIds.push(id);
                    changed = true;
                }
            });

            if (changed) {
                await group.save();
                console.log('✅ Updated admin group with new admins');
            }
        }

        process.exit(0);
    })
    .catch(err => {
        console.error('❌ Error:', err);
        process.exit(1);
    });
