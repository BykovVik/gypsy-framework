// Gypsy Notifications - NUI Script
let notificationQueue = [];
let maxNotifications = 5;
let notificationIdCounter = 0;

// ====================================================================================
//                                  MESSAGE HANDLER
// ====================================================================================

window.addEventListener('message', (event) => {
    const data = event.data;

    if (data.action === 'showNotification') {
        showNotification(data.data);
    }
});

// ====================================================================================
//                                  NOTIFICATION LOGIC
// ====================================================================================

function showNotification(data) {
    const { message, type, duration, icon } = data;

    // Создаём уникальный ID
    const notificationId = `notification-${notificationIdCounter++}`;

    // Создаём элемент уведомления
    const notification = createNotificationElement(notificationId, message, type, icon, duration);

    // Добавляем в контейнер
    const container = document.getElementById('notificationsContainer');
    container.appendChild(notification);

    // Добавляем в очередь
    notificationQueue.push({
        id: notificationId,
        element: notification,
        duration: duration
    });

    // Управляем количеством уведомлений
    manageNotificationQueue();

    // Автоматическое удаление через duration
    setTimeout(() => {
        removeNotification(notificationId);
    }, duration);
}

function createNotificationElement(id, message, type, icon, duration) {
    // Создаём основной div
    const notification = document.createElement('div');
    notification.id = id;
    notification.className = `notification ${type}`;

    // Создаём иконку
    const iconDiv = document.createElement('div');
    iconDiv.className = 'notification-icon';
    iconDiv.textContent = icon;

    // Создаём контент
    const content = document.createElement('div');
    content.className = 'notification-content';

    const messageDiv = document.createElement('div');
    messageDiv.className = 'notification-message';
    messageDiv.textContent = message;

    content.appendChild(messageDiv);

    // Собираем всё вместе (без прогресс-бара)
    notification.appendChild(iconDiv);
    notification.appendChild(content);

    return notification;
}

function removeNotification(notificationId) {
    const notification = document.getElementById(notificationId);

    if (notification) {
        // Добавляем класс для анимации удаления
        notification.classList.add('removing');

        // Удаляем из DOM после анимации
        setTimeout(() => {
            if (notification.parentNode) {
                notification.parentNode.removeChild(notification);
            }

            // Удаляем из очереди
            notificationQueue = notificationQueue.filter(n => n.id !== notificationId);
        }, 300); // Длительность анимации fadeOut
    }
}

function manageNotificationQueue() {
    // Если уведомлений больше максимума, удаляем самые старые
    while (notificationQueue.length > maxNotifications) {
        const oldest = notificationQueue[0];
        removeNotification(oldest.id);
    }
}

// ====================================================================================
//                                  INITIALIZATION
// ====================================================================================

console.log('[Gypsy Notifications] NUI initialized');
