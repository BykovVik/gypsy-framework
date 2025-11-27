let currentShopId = null;

window.addEventListener('message', function (event) {
    console.log('NUI Message Received:', JSON.stringify(event.data));
    if (event.data.action === "open") {
        console.log('Opening Shop UI');
        currentShopId = event.data.shopId;
        const container = document.getElementById('shop-container');
        if (container) {
            container.style.display = 'flex';
            console.log('Container display set to flex');
        } else {
            console.log('Error: shop-container not found');
        }
        document.getElementById('shop-title').innerText = event.data.label;
        setupItems(event.data.items);
    } else if (event.data.action === "close") {
        closeShop();
    }
});

document.onkeyup = function (data) {
    if (data.which == 27) { // ESC
        closeShop();
    }
};

document.getElementById('close-btn').onclick = function () {
    closeShop();
}

function closeShop() {
    document.getElementById('shop-container').style.display = 'none';
    fetch(`https://${GetParentResourceName()}/close`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({})
    });
}

function setupItems(items) {
    const grid = document.getElementById('items-grid');
    grid.innerHTML = '';

    items.forEach((item, index) => {
        const card = document.createElement('div');
        card.className = 'item-card';

        // Placeholder icon logic - in real app use item.image
        const iconDiv = document.createElement('div');
        iconDiv.className = 'item-icon';
        iconDiv.innerHTML = '📦';
        card.appendChild(iconDiv);

        const name = document.createElement('div');
        name.className = 'item-name';
        name.innerText = item.label;
        card.appendChild(name);

        const price = document.createElement('div');
        price.className = 'item-price';
        price.innerText = '$' + item.price;
        card.appendChild(price);

        const btn = document.createElement('button');
        btn.className = 'buy-btn';
        btn.innerText = 'BUY';
        btn.onclick = function () {
            buyItem(index + 1); // Lua is 1-based usually, check server logic
        };
        card.appendChild(btn);

        grid.appendChild(card);
    });
}

function buyItem(index) {
    console.log('[Shops] Buying item at index:', index, 'from shop:', currentShopId);
    fetch(`https://${GetParentResourceName()}/buy`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({
            shopId: currentShopId,
            itemIndex: index
        })
    }).then(response => {
        console.log('[Shops] Buy request sent successfully');
    }).catch(error => {
        console.error('[Shops] Buy request failed:', error);
    });
}
