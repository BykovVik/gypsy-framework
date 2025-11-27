// Format money
function formatMoney(amount) {
    return '$' + amount.toLocaleString('en-US');
}

// Current balances for bank
let bankBalances = {
    cash: 0,
    bank: 0,
    savings: 0
};

// Update bank account display
function updateBankAccount(data) {
    console.log('[Bank UI] Updating account:', data);

    bankBalances.cash = data.cash || 0;
    bankBalances.bank = data.bank || 0;
    bankBalances.savings = data.savings || 0;

    const cashEl = document.getElementById('cash-balance-bank');
    const bankEl = document.getElementById('bank-balance-bank');
    const savingsEl = document.getElementById('savings-balance-bank');
    const savingsDisplayEl = document.getElementById('savings-display-bank');

    if (cashEl) cashEl.textContent = formatMoney(bankBalances.cash);
    if (bankEl) bankEl.textContent = formatMoney(bankBalances.bank);
    if (savingsEl) savingsEl.textContent = formatMoney(bankBalances.savings);
    if (savingsDisplayEl) savingsDisplayEl.textContent = formatMoney(bankBalances.savings);
}

// Set amount in input
function setAmount(type, amount) {
    if (type === 'cash') {
        document.getElementById('cash-amount-bank').value = amount;
    }
}

// Withdraw cash
function withdrawCashBank() {
    const amount = parseInt(document.getElementById('cash-amount-bank').value);
    if (!amount || amount <= 0) {
        showBankError('INVALID AMOUNT / Введите корректную сумму');
        return;
    }

    if (bankBalances.bank < amount) {
        showBankError('INSUFFICIENT FUNDS / Недостаточно средств на счету');
        return;
    }

    fetch(`https://${GetParentResourceName()}/withdrawCash`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ amount: amount })
    });

    document.getElementById('cash-amount-bank').value = '';
}

// Deposit cash
function depositCashBank() {
    const amount = parseInt(document.getElementById('cash-amount-bank').value);
    if (!amount || amount <= 0) {
        showBankError('INVALID AMOUNT / Введите корректную сумму');
        return;
    }

    if (bankBalances.cash < amount) {
        showBankError('INSUFFICIENT CASH / Недостаточно наличных');
        return;
    }

    fetch(`https://${GetParentResourceName()}/depositCash`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ amount: amount })
    });

    document.getElementById('cash-amount-bank').value = '';
}

// Deposit to savings
function depositSavingsBank() {
    const amount = parseInt(document.getElementById('savings-amount-bank').value);
    if (!amount || amount <= 0) {
        showBankError('INVALID AMOUNT / Введите корректную сумму');
        return;
    }

    if (bankBalances.bank < amount) {
        showBankError('INSUFFICIENT FUNDS / Недостаточно средств на счету');
        return;
    }

    fetch(`https://${GetParentResourceName()}/depositSavings`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ amount: amount })
    });

    document.getElementById('savings-amount-bank').value = '';
}

// Withdraw from savings
function withdrawSavingsBank() {
    const amount = parseInt(document.getElementById('savings-amount-bank').value);
    if (!amount || amount <= 0) {
        showBankError('INVALID AMOUNT / Введите корректную сумму');
        return;
    }

    if (bankBalances.savings < amount) {
        showBankError('INSUFFICIENT SAVINGS / Недостаточно средств на вкладе');
        return;
    }

    fetch(`https://${GetParentResourceName()}/withdrawSavings`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ amount: amount })
    });

    document.getElementById('savings-amount-bank').value = '';
}

// Close bank UI
function closeBank() {
    fetch(`https://${GetParentResourceName()}/close`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

// Show error
function showBankError(message) {
    console.error('[Bank] Error:', message);

    // Create error element if it doesn't exist
    let errorEl = document.getElementById('bank-error-notification');
    if (!errorEl) {
        errorEl = document.createElement('div');
        errorEl.id = 'bank-error-notification';
        errorEl.className = 'bank-error';
        document.body.appendChild(errorEl);
    }

    // Set message and show
    errorEl.textContent = message;
    errorEl.classList.add('show');

    // Hide after 3 seconds
    setTimeout(() => {
        errorEl.classList.remove('show');
    }, 3000);
}

// Update time
function updateTime() {
    const now = new Date();
    const hours = String(now.getHours()).padStart(2, '0');
    const minutes = String(now.getMinutes()).padStart(2, '0');
    const timeEl = document.getElementById('bank-time');
    if (timeEl) {
        timeEl.textContent = `${hours}:${minutes}`;
    }
}

setInterval(updateTime, 1000);
updateTime();

// Listen for messages
window.addEventListener('message', function (event) {
    const data = event.data;

    if (data.action === 'openBank') {
        document.getElementById('bank-container').style.display = 'flex';
        document.getElementById('atm-container').style.display = 'none';
    } else if (data.action === 'closeBank' || data.action === 'closeATM') {
        document.getElementById('bank-container').style.display = 'none';
        document.getElementById('atm-container').style.display = 'none';
    } else if (data.action === 'updateAccount') {
        updateBankAccount(data.data);
    } else if (data.action === 'showError') {
        showBankError(data.message);
    }
});

// ESC to close
document.addEventListener('keydown', function (event) {
    if (event.key === 'Escape') {
        const bankOpen = document.getElementById('bank-container').style.display === 'flex';
        if (bankOpen) {
            closeBank();
        }
    }
});
