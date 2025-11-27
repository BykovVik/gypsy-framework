// Format money
function formatMoney(amount) {
    return '$' + amount.toLocaleString('en-US');
}

// Animate number change
function animateValue(element, start, end, duration) {
    const range = end - start;
    const increment = range / (duration / 16); // 60fps
    let current = start;

    const timer = setInterval(() => {
        current += increment;
        if ((increment > 0 && current >= end) || (increment < 0 && current <= end)) {
            current = end;
            clearInterval(timer);
        }
        element.textContent = formatMoney(Math.floor(current));
    }, 16);
}

// Current balances for animation
let currentBalances = {
    cash: 0,
    bank: 0,
    savings: 0
};

let isFirstUpdate = true;

// Update account display with animation
function updateAccount(data) {
    console.log('[Bank UI] updateAccount called with:', data);

    const cashEl = document.getElementById('cash-balance');
    const bankEl = document.getElementById('bank-balance');
    const savingsEl = document.getElementById('savings-balance');
    const savingsDisplayEl = document.getElementById('savings-balance-display');

    console.log('[Bank UI] Elements found - savingsEl:', savingsEl, 'savingsDisplayEl:', savingsDisplayEl);

    // On first update, set values directly without animation
    if (isFirstUpdate) {
        currentBalances.cash = data.cash || 0;
        currentBalances.bank = data.bank || 0;
        currentBalances.savings = data.savings || 0;

        cashEl.textContent = formatMoney(currentBalances.cash);
        bankEl.textContent = formatMoney(currentBalances.bank);
        savingsEl.textContent = formatMoney(currentBalances.savings);
        if (savingsDisplayEl) savingsDisplayEl.textContent = formatMoney(currentBalances.savings);

        console.log('[Bank UI] First update - Savings set to:', formatMoney(currentBalances.savings));

        isFirstUpdate = false;
        return;
    }

    // Animate changes
    animateValue(cashEl, currentBalances.cash, data.cash || 0, 500);
    animateValue(bankEl, currentBalances.bank, data.bank || 0, 500);
    animateValue(savingsEl, currentBalances.savings, data.savings || 0, 500);
    if (savingsDisplayEl) animateValue(savingsDisplayEl, currentBalances.savings, data.savings || 0, 500);

    // Update current balances
    currentBalances.cash = data.cash || 0;
    currentBalances.bank = data.bank || 0;
    currentBalances.savings = data.savings || 0;
}

// Quick cash buttons - ONLY fill the field
function withdrawCash(amount) {
    document.getElementById('custom-amount').value = amount;
}

// Withdraw cash (custom amount)
function withdrawCashCustom() {
    const amount = parseInt(document.getElementById('custom-amount').value);
    if (!amount || amount <= 0) {
        showError('Введите корректную сумму');
        return;
    }

    // Check if enough funds in bank
    if (currentBalances.bank < amount) {
        showError('Недостаточно средств на счету');
        return;
    }

    fetch(`https://${GetParentResourceName()}/withdrawCash`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ amount: amount })
    });

    document.getElementById('custom-amount').value = '';
}

// Deposit cash (custom amount)
function depositCashCustom() {
    const amount = parseInt(document.getElementById('custom-amount').value);
    if (!amount || amount <= 0) {
        showError('Введите корректную сумму');
        return;
    }

    // Check if enough cash
    if (currentBalances.cash < amount) {
        showError('Недостаточно наличных');
        return;
    }

    fetch(`https://${GetParentResourceName()}/depositCash`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ amount: amount })
    });

    document.getElementById('custom-amount').value = '';
}

// Deposit to savings
function depositSavings() {
    const amount = parseInt(document.getElementById('savings-amount').value);
    if (!amount || amount <= 0) {
        showError('Введите корректную сумму');
        return;
    }

    // Check if enough funds in bank
    if (currentBalances.bank < amount) {
        showError('Недостаточно средств на счету');
        return;
    }

    fetch(`https://${GetParentResourceName()}/depositSavings`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ amount: amount })
    });

    document.getElementById('savings-amount').value = '';
}

// Withdraw from savings
function withdrawSavings() {
    const amount = parseInt(document.getElementById('savings-amount').value);
    if (!amount || amount <= 0) {
        showError('Введите корректную сумму');
        return;
    }

    // Check if enough funds in savings
    if (currentBalances.savings < amount) {
        showError('Недостаточно средств на вкладе');
        return;
    }

    fetch(`https://${GetParentResourceName()}/withdrawSavings`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ amount: amount })
    });

    document.getElementById('savings-amount').value = '';
}

// Close ATM
function closeATM() {
    fetch(`https://${GetParentResourceName()}/close`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

// Show error notification
function showError(message) {
    const notification = document.createElement('div');
    notification.className = 'error-notification';
    notification.textContent = message;
    document.body.appendChild(notification);

    setTimeout(() => notification.classList.add('show'), 10);

    setTimeout(() => {
        notification.classList.remove('show');
        setTimeout(() => notification.remove(), 300);
    }, 3000);
}

// Listen for messages from client
window.addEventListener('message', function (event) {
    const data = event.data;

    if (data.action === 'openATM') {
        document.getElementById('atm-container').style.display = 'flex';
        isFirstUpdate = true; // Reset for fresh data

        const atmScreen = document.querySelector('.atm-screen');
        const savingsSection = document.querySelector('.savings-section');
        const savingsBalanceRow = document.querySelector('.balance-item.savings');

        if (data.locationType === 'bank') {
            // Bank - show savings and enable horizontal layout
            atmScreen.classList.add('bank-mode');
            if (savingsSection) savingsSection.style.display = 'block';
            if (savingsBalanceRow) savingsBalanceRow.style.display = 'flex';
            document.querySelector('.atm-header h1').textContent = 'FLEECA BANK';
            document.querySelector('.retro-text').textContent = 'Полный банковский сервис';
        } else {
            // ATM - hide savings and disable horizontal layout
            atmScreen.classList.remove('bank-mode');
            if (savingsSection) savingsSection.style.display = 'none';
            if (savingsBalanceRow) savingsBalanceRow.style.display = 'none';
            document.querySelector('.atm-header h1').textContent = 'AMBER TERMINAL';
            document.querySelector('.retro-text').textContent = 'Быстрые операции 24/7';
        }
    } else if (data.action === 'closeATM') {
        document.getElementById('atm-container').style.display = 'none';
    } else if (data.action === 'updateAccount') {
        updateAccount(data.data);
    } else if (data.action === 'showError') {
        showError(data.message);
    }
});

// ESC to close
document.addEventListener('keydown', function (event) {
    if (event.key === 'Escape') {
        closeATM();
    }
});
