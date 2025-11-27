const ContextMenu = {
    element: null,
    currentItem: null,

    init: function () {
        // Create menu element
        this.element = document.createElement('div');
        this.element.className = 'context-menu';
        this.element.style.display = 'none';

        // Add to body
        document.body.appendChild(this.element);

        // Close menu on click outside
        document.addEventListener('click', (e) => {
            if (!this.element.contains(e.target)) {
                this.hide();
            }
        });
    },

    show: function (x, y, item) {
        this.currentItem = item;

        // Build menu HTML
        this.element.innerHTML = `
            <div class="context-menu-item" data-action="use">
                <span>Использовать</span>
            </div>
            <div class="context-menu-item" data-action="drop">
                <span>Выбросить</span>
            </div>
        `;

        // Position menu
        this.element.style.left = x + 'px';
        this.element.style.top = y + 'px';
        this.element.style.display = 'block';

        // Add click handlers
        const items = this.element.querySelectorAll('.context-menu-item');
        items.forEach(menuItem => {
            menuItem.addEventListener('click', (e) => {
                e.stopPropagation();
                const action = menuItem.dataset.action;
                this.handleAction(action);
            });
        });
    },

    hide: function () {
        this.element.style.display = 'none';
        this.currentItem = null;
    },

    handleAction: function (action) {
        if (!this.currentItem) return;

        const item = this.currentItem;

        // If item has more than 1, show quantity dialog
        if (item.amount > 1 && (action === 'use' || action === 'drop')) {
            QuantityDialog.show(item.amount, (quantity) => {
                this.executeAction(action, item, quantity);
            });
        } else {
            this.executeAction(action, item, 1);
        }

        this.hide();
    },

    executeAction: function (action, item, quantity) {
        switch (action) {
            case 'use':
                Api.post('useItem', { slot: item.slot, amount: quantity });
                break;
            case 'drop':
                Api.post('dropItem', { slot: item.slot, amount: quantity });
                break;
        }
    }
};

// Initialize immediately or on load
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
        ContextMenu.init();
    });
} else {
    // DOM already loaded
    ContextMenu.init();
}
