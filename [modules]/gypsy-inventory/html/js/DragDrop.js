const DragDrop = {
    draggedItem: null,
    dragGhost: null,

    startDrag: function (e, item, originalElement) {
        if (this.draggedItem) return;

        this.draggedItem = { item: item, element: originalElement };
        originalElement.style.opacity = '0.5';

        // Create Ghost
        this.dragGhost = originalElement.cloneNode(true);
        this.dragGhost.className = 'item drag-ghost';
        this.dragGhost.style.position = 'fixed';
        this.dragGhost.style.left = e.clientX - (originalElement.offsetWidth / 2) + 'px';
        this.dragGhost.style.top = e.clientY - (originalElement.offsetHeight / 2) + 'px';
        this.dragGhost.style.width = originalElement.offsetWidth + 'px';
        this.dragGhost.style.height = originalElement.offsetHeight + 'px';
        this.dragGhost.style.zIndex = '1000';
        this.dragGhost.style.pointerEvents = 'none';
        document.body.appendChild(this.dragGhost);

        // Bind context to preserve 'this'
        this.onDragMove = this.onDragMove.bind(this);
        this.onDragEnd = this.onDragEnd.bind(this);

        document.addEventListener('mousemove', this.onDragMove);
        document.addEventListener('mouseup', this.onDragEnd);
    },

    onDragMove: function (e) {
        if (!this.dragGhost) return;
        this.dragGhost.style.left = e.clientX - (this.dragGhost.offsetWidth / 2) + 'px';
        this.dragGhost.style.top = e.clientY - (this.dragGhost.offsetHeight / 2) + 'px';
    },

    onDragEnd: function (e) {
        document.removeEventListener('mousemove', this.onDragMove);
        document.removeEventListener('mouseup', this.onDragEnd);

        if (this.dragGhost) {
            this.dragGhost.remove();
            this.dragGhost = null;
        }

        if (this.draggedItem) {
            this.draggedItem.element.style.opacity = '1';

            const elementUnder = document.elementFromPoint(e.clientX, e.clientY);
            const slotDiv = elementUnder ? elementUnder.closest('.slot') : null;

            if (slotDiv) {
                const toSlot = parseInt(slotDiv.dataset.slot);
                const fromSlot = this.draggedItem.item.slot;

                if (fromSlot !== toSlot) {
                    console.log(`Moving item from ${fromSlot} to ${toSlot}`);
                    Api.post('moveItem', {
                        fromSlot: parseInt(fromSlot),
                        toSlot: parseInt(toSlot)
                    });
                }
            }

            this.draggedItem = null;
        }
    }
};
