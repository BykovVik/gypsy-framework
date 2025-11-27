const QuantityDialog = {
    element: null,
    callback: null,
    maxAmount: 1,

    init: function () {
        // Create dialog element
        this.element = document.createElement('div');
        this.element.className = 'quantity-dialog-overlay';
        this.element.style.display = 'none';
        this.element.innerHTML = `
            <div class="quantity-dialog">
                <h3>Выберите количество</h3>
                <div class="quantity-controls">
                    <button class="quantity-btn" id="qty-minus">-</button>
                    <input type="number" id="qty-input" value="1" min="1" max="1">
                    <button class="quantity-btn" id="qty-plus">+</button>
                </div>
                <div class="quantity-actions">
                    <button class="quantity-action-btn confirm" id="qty-confirm">Подтвердить</button>
                    <button class="quantity-action-btn cancel" id="qty-cancel">Отмена</button>
                </div>
            </div>
        `;

        document.body.appendChild(this.element);

        // Event listeners
        this.element.querySelector('#qty-minus').addEventListener('click', () => this.decrease());
        this.element.querySelector('#qty-plus').addEventListener('click', () => this.increase());
        this.element.querySelector('#qty-confirm').addEventListener('click', () => this.confirm());
        this.element.querySelector('#qty-cancel').addEventListener('click', () => this.hide());

        // Enter to confirm, Escape to cancel
        this.element.querySelector('#qty-input').addEventListener('keydown', (e) => {
            if (e.key === 'Enter') this.confirm();
            if (e.key === 'Escape') this.hide();
        });

        // Click outside to cancel
        this.element.addEventListener('click', (e) => {
            if (e.target === this.element) this.hide();
        });
    },

    show: function (maxAmount, callback) {
        this.maxAmount = maxAmount;
        this.callback = callback;

        const input = this.element.querySelector('#qty-input');
        input.max = maxAmount;
        input.value = Math.min(1, maxAmount);

        this.element.style.display = 'flex';
        input.focus();
        input.select();
    },

    hide: function () {
        this.element.style.display = 'none';
        this.callback = null;
    },

    decrease: function () {
        const input = this.element.querySelector('#qty-input');
        const current = parseInt(input.value) || 1;
        input.value = Math.max(1, current - 1);
    },

    increase: function () {
        const input = this.element.querySelector('#qty-input');
        const current = parseInt(input.value) || 1;
        input.value = Math.min(this.maxAmount, current + 1);
    },

    confirm: function () {
        const input = this.element.querySelector('#qty-input');
        let amount = parseInt(input.value) || 1;
        amount = Math.max(1, Math.min(this.maxAmount, amount));

        if (this.callback) {
            this.callback(amount);
        }
        this.hide();
    }
};

// Initialize immediately or on load
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
        QuantityDialog.init();
    });
} else {
    QuantityDialog.init();
}
