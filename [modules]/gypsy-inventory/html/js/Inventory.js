const Inventory = {
    data: {},
    maxSlots: 40,

    setupSlots: function (inventoryData, maxSlots) {
        this.data = inventoryData || {};
        this.maxSlots = maxSlots || 40;

        console.log("=== SETUP SLOTS START ===");
        console.log("MaxSlots:", this.maxSlots);

        const grid = document.getElementById('slots-grid');
        if (!grid) {
            console.error("ERROR: slots-grid element not found!");
            return;
        }

        grid.innerHTML = '';

        for (let i = 1; i <= this.maxSlots; i++) {
            const slotDiv = document.createElement('div');
            slotDiv.className = 'slot';
            slotDiv.dataset.slot = i;
            slotDiv.style.backgroundColor = 'rgba(255, 255, 255, 0.05)';
            slotDiv.style.border = '1px solid #333';
            slotDiv.style.height = '100px';

            const item = Object.values(this.data).filter(x => x != null).find(x => x.slot === i);
            if (item) {
                this.renderItem(slotDiv, item);
            }

            grid.appendChild(slotDiv);
        }
        console.log("=== SETUP SLOTS COMPLETE ===");
    },

    renderItem: function (slotDiv, item) {
        const itemDiv = document.createElement('div');
        itemDiv.className = 'item';
        itemDiv.dataset.slot = item.slot;

        // Drag Start
        itemDiv.addEventListener('mousedown', function (e) {
            if (e.button !== 0) return;
            e.preventDefault();
            DragDrop.startDrag(e, item, itemDiv);
        });

        // Right Click - Show Context Menu
        itemDiv.addEventListener('contextmenu', function (e) {
            e.preventDefault();
            ContextMenu.show(e.clientX, e.clientY, item);
        });

        // Icon
        const icon = document.createElement('div');
        icon.className = 'item-icon';

        if (item.image) {
            let imageName = item.image;
            if (imageName.includes('html/icon/')) {
                imageName = imageName.replace('html/icon/', '');
            }

            const timestamp = new Date().getTime();
            const iconUrl = `nui://${Api.resourceName}/html/icon/${imageName}?t=${timestamp}`;

            const img = document.createElement('img');
            img.src = iconUrl;
            img.style.width = '100%';
            img.style.height = '100%';
            img.style.objectFit = 'contain';

            img.onerror = function () {
                if (!this.src.includes('cfx-nui')) {
                    const fallbackUrl = `icon/${imageName}?t=${timestamp}`;
                    this.src = fallbackUrl;
                }
            };

            icon.appendChild(img);
        }
        itemDiv.appendChild(icon);

        // Label
        const label = document.createElement('div');
        label.className = 'item-label';
        label.innerText = item.label || item.name;
        itemDiv.appendChild(label);

        // Count
        const count = document.createElement('div');
        count.className = 'item-count';
        count.innerText = item.amount;
        itemDiv.appendChild(count);

        slotDiv.appendChild(itemDiv);
    }
};
