//firebase-messaging-sw.js
importScripts('https://www.gstatic.com/firebasejs/8.2.1/firebase-app.js');
importScripts('https://www.gstatic.com/firebasejs/8.2.1/firebase-messaging.js');

try {
    let firebaseConfig = {"apiKey":"AIzaSyDUdSTLKInlwkJkBXaM7dbALC9gW_ym6Hk","authDomain":"dressydz.firebaseapp.com","projectId":"dressydz","storageBucket":"dressydz.firebasestorage.app","messagingSenderId":"828256414245","appId":"1:828256414245:web:ae6b9564edcf8efb452dcc","measurementId":"G-GTRGZ9Q334","databaseURL":"https://dressydz-default-rtdb.firebaseio.com"};

    let messaging = null
    if (firebase.messaging.isSupported()) {
        firebase.initializeApp(firebaseConfig)
        messaging = firebase.messaging()
    } else {
        console.log('no-support :(')
    }

    if (messaging) {
        messaging.setBackgroundMessageHandler(function (payload) {
            console.log('[firebase-messaging-sw.js] Received background message ', payload);
            const notificationTitle = payload.notification.title || '';
            const notificationOptions = {
                body: payload.notification.body || '',
                icon: '/fbs_ico.ico',
                click_action: payload.data.click_action
            };

            return self.registration.showNotification(notificationTitle,
                notificationOptions);
        });
        messaging.onBackgroundMessage(payload => {
            const notificationTitle = payload.notification.title || '';
            const notificationOptions = {
                body: payload.notification.body || '',
                icon: '/fbs_ico.ico',
                data: payload.data
            };

            return self.registration.showNotification(notificationTitle, notificationOptions);
        });

        self.addEventListener('notificationclick', event => {
            event.notification.close();
            event.waitUntil(clients.matchAll({ type: "window" }).then(function (clientList) {
                for (let i = 0; i < clientList.length; i++) {
                    const client = clientList[i];
                    if (client.url === '/' && 'focus' in client) {
                        if (event.notification.data.route) client.href(event.notification.data.route);
                        return client.focus();
                    }
                }
                if (clients.openWindow)
                    return clients.openWindow(event.notification.data.route || '/');
            }));
        });
    }
}
catch (err) {
    console.log(err);
}
