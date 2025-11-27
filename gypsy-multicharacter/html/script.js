// Character Selection Script

let characters = [];
let selectedSlot = null;
let selectedCharacter = null;
let spawnPoints = [];
let pendingCharacterData = null;

// ============================================================================
// NUI COMMUNICATION
// ============================================================================

window.addEventListener('message', function (event) {
    const data = event.data;

    switch (data.action) {
        case 'show':
            showSelection(data.data);
            break;
        case 'hide':
            hideSelection();
            break;
        case 'showSpawnSelection':
            showSpawnSelection(data.data);
            break;
        case 'refreshCharacters':
            refreshCharacters(data.characters);
            break;
        case 'showError':
            showError(data.message);
            break;
    }
});

// ============================================================================
// DISPLAY FUNCTIONS
// ============================================================================

function showSelection(data) {
    characters = data.characters || [];
    spawnPoints = data.spawnPoints || [];

    document.getElementById('char-container').style.display = 'flex';
    renderSlots();
}

function hideSelection() {
    document.getElementById('char-container').style.display = 'none';
}

function renderSlots() {
    if (!Array.isArray(characters)) characters = [];

    for (let i = 1; i <= 3; i++) {
        const slot = document.getElementById(`slot-${i}`);
        const character = characters.find(c => c.slot === i);

        if (character) {
            slot.innerHTML = `
                <div class="slot-filled">
                    <div class="char-name">${character.charinfo.firstname} ${character.charinfo.lastname}</div>
                    <div class="char-info">
                        <p>Job: ${character.job.label}</p>
                        <p>Gender: ${character.charinfo.gender === 0 ? 'Male' : 'Female'}</p>
                        <p>DOB: ${character.charinfo.birthdate}</p>
                    </div>
                    <div class="char-money">$${formatMoney(character.money.cash + character.money.bank)}</div>
                </div>
            `;
            slot.onclick = () => selectCharacter(character, i);
        } else {
            slot.innerHTML = `
                <div class="slot-empty">
                    <div class="plus-icon">+</div>
                    <p>CREATE CHARACTER</p>
                    <small>создать персонажа</small>
                </div>
            `;
            slot.onclick = () => showCreationForm(i);
        }

        slot.classList.remove('selected');
    }
}

// ============================================================================
// CHARACTER SELECTION
// ============================================================================

function selectCharacter(character, slot) {
    selectedCharacter = character;
    selectedSlot = slot;

    document.querySelectorAll('.slot-card').forEach(s => s.classList.remove('selected'));
    document.getElementById(`slot-${slot}`).classList.add('selected');

    document.getElementById('char-actions').style.display = 'flex';

    const form = document.getElementById('creation-form');
    form.style.display = 'none';
    form.classList.remove('show');
}

function playCharacter() {
    if (!selectedCharacter) return;

    fetch(`https://gypsy-multicharacter/selectCharacter`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ citizenid: selectedCharacter.citizenid })
    });
}

function deleteCharacter() {
    if (!selectedCharacter) return;
    document.getElementById('confirm-delete').style.display = 'flex';
}

function confirmDelete() {
    if (!selectedCharacter) return;

    fetch(`https://gypsy-multicharacter/deleteCharacter`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ citizenid: selectedCharacter.citizenid })
    });

    cancelDelete();
    backToSelection();
}

function cancelDelete() {
    document.getElementById('confirm-delete').style.display = 'none';
}

function backToSelection() {
    selectedCharacter = null;
    selectedSlot = null;

    document.querySelectorAll('.slot-card').forEach(s => s.classList.remove('selected'));
    document.getElementById('char-actions').style.display = 'none';
}

// ============================================================================
// CHARACTER CREATION
// ============================================================================

function showCreationForm(slot) {
    selectedSlot = slot;
    selectedCharacter = null;

    // Hide slots and actions
    document.getElementById('slots-container').style.display = 'none';
    document.getElementById('char-actions').style.display = 'none';

    // Show backdrop
    const backdrop = document.getElementById('modal-backdrop');
    backdrop.style.display = 'block';
    backdrop.classList.add('show');

    // Show creation form as pop-up modal
    const form = document.getElementById('creation-form');
    form.style.display = 'block';
    form.classList.add('show');

    // Reset form
    document.getElementById('firstname').value = '';
    document.getElementById('lastname').value = '';
    document.getElementById('birthdate').value = '';
    document.getElementById('gender').value = '0';
}

function createCharacter() {
    const firstname = document.getElementById('firstname').value.trim();
    const lastname = document.getElementById('lastname').value.trim();
    const birthdate = document.getElementById('birthdate').value;
    const gender = parseInt(document.getElementById('gender').value);

    if (!firstname || !lastname) {
        showError('Please enter first and last name');
        return;
    }

    if (!birthdate) {
        showError('Please select date of birth');
        return;
    }

    // Send to appearance editor (will trigger spawn selection after)
    fetch(`https://gypsy-multicharacter/createCharacter`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            slot: selectedSlot,
            data: {
                firstname: firstname,
                lastname: lastname,
                birthdate: birthdate,
                gender: gender
            }
        })
    });

    // Close the creation form
    cancelCreation();
}

function cancelCreation() {
    const form = document.getElementById('creation-form');
    form.style.display = 'none';
    form.classList.remove('show');

    const backdrop = document.getElementById('modal-backdrop');
    backdrop.style.display = 'none';
    backdrop.classList.remove('show');

    document.getElementById('slots-container').style.display = 'grid';
    selectedSlot = null;
}

// ============================================================================
// SPAWN LOCATION SELECTION
// ============================================================================

function showSpawnSelection(data) {
    spawnPoints = data.spawnPoints || [];
    pendingCharacterData = data.characterData || null;

    // Hide character selection
    document.getElementById('char-container').style.display = 'none';

    // Show spawn selection
    const spawnSelection = document.getElementById('spawn-selection');
    spawnSelection.style.display = 'flex';

    // Populate spawn grid
    const spawnGrid = document.getElementById('spawn-grid');
    spawnGrid.innerHTML = '';

    const icons = ['🏙️', '🏨', '🏘️', '🏜️', '🏔️', '🏖️'];

    spawnPoints.forEach((spawn, index) => {
        const card = document.createElement('div');
        card.className = 'spawn-card';
        card.innerHTML = `
            <div class="spawn-icon">${icons[index] || '📍'}</div>
            <div class="spawn-name">${spawn.name}</div>
            <div class="spawn-hint">${spawn.hint}</div>
            <div class="spawn-description">${spawn.description}</div>
        `;
        card.onclick = () => selectSpawnLocation(spawn);
        spawnGrid.appendChild(card);
    });
}

function selectSpawnLocation(spawn) {
    fetch(`https://gypsy-multicharacter/selectSpawnLocation`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            spawnPoint: spawn.coords,
            characterData: pendingCharacterData
        })
    });

    // Hide spawn selection
    document.getElementById('spawn-selection').style.display = 'none';
}

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

function formatMoney(amount) {
    return amount.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

function showError(message) {
    const errorEl = document.getElementById('error-message');
    errorEl.textContent = message;
    errorEl.classList.add('show');

    setTimeout(() => {
        errorEl.classList.remove('show');
    }, 3000);
}

function refreshCharacters(newCharacters) {
    characters = newCharacters || [];
    renderSlots();
    backToSelection();
}
