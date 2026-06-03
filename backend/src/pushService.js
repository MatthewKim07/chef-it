const apn = require('apn');

let provider = null;

function getProvider() {
    if (provider) return provider;
    const keyContent = process.env.APN_KEY;
    if (!keyContent || !process.env.APN_KEY_ID || !process.env.APN_TEAM_ID) return null;
    provider = new apn.Provider({
        token: {
            key: Buffer.from(keyContent),
            keyId: process.env.APN_KEY_ID,
            teamId: process.env.APN_TEAM_ID,
        },
        production: process.env.NODE_ENV === 'production',
    });
    return provider;
}

async function sendPush(deviceToken, title, body, data = {}) {
    const p = getProvider();
    if (!p || !deviceToken) return;

    const note = new apn.Notification();
    note.expiry = Math.floor(Date.now() / 1000) + 3600;
    note.badge = 1;
    note.sound = 'default';
    note.alert = { title, body };
    note.payload = data;
    note.topic = process.env.APN_BUNDLE_ID || 'com.chefit.app';

    try {
        const result = await p.send(note, deviceToken);
        if (result.failed.length > 0) {
            console.warn('APNs send failed:', result.failed[0].response);
        }
    } catch (err) {
        console.error('APNs error:', err.message);
    }
}

module.exports = { sendPush };
