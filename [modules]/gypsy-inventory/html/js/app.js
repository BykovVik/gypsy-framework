window.addEventListener('message', function (event) {
    if (event.data.action === "open") {
        document.getElementById('inventory-container').style.display = 'flex';
        Inventory.setupSlots(event.data.inventory, event.data.slots);
    } else if (event.data.action === "close") {
        document.getElementById('inventory-container').style.display = 'none';
        if (DragDrop.dragGhost) {
            DragDrop.dragGhost.remove();
            DragDrop.dragGhost = null;
        }
        DragDrop.draggedItem = null;
    }
});

// Close on Escape
window.addEventListener('keydown', function (e) {
    if (e.key === 'Escape') {
        Api.post('close');
    }
});
