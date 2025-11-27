// Gypsy Appearance - UI Script

let currentAppearance = {
    heritage: {
        mother: 0,
        father: 0,
        mix: 0.5,
        skinMix: 0.5
    },
    hair: {
        style: 0,
        color: 0,
        highlight: 0
    },
    eyeColor: 0,
    eyebrows: {
        style: 0,
        color: 0
    },
    clothing: {
        torso: { drawable: 15, texture: 0 },
        legs: { drawable: 4, texture: 0 },
        shoes: { drawable: 1, texture: 0 },
        arms: { drawable: 0, texture: 0 }
    }
};

let currentGender = 0; // 0 = male, 1 = female
let clothingOptions = null;

// ============================================================================
// NUI COMMUNICATION
// ============================================================================

window.addEventListener('message', function (event) {
    const data = event.data;

    switch (data.action) {
        case 'openEditor':
            openEditor(data.data);
            break;
        case 'closeEditor':
            closeEditor();
            break;
    }
});

// ============================================================================
// EDITOR FUNCTIONS
// ============================================================================

function openEditor(data) {
    currentGender = data.gender || 0;
    clothingOptions = data.config.clothing;

    // Merge appearance data
    if (data.appearance && Object.keys(data.appearance).length > 0) {
        currentAppearance = {
            ...currentAppearance,
            ...data.appearance,
            heritage: { ...currentAppearance.heritage, ...(data.appearance.heritage || {}) },
            hair: { ...currentAppearance.hair, ...(data.appearance.hair || {}) },
            eyebrows: { ...currentAppearance.eyebrows, ...(data.appearance.eyebrows || {}) },
            clothing: { ...currentAppearance.clothing, ...(data.appearance.clothing || {}) }
        };
    }

    // Initialize UI
    initializeSliders();
    loadHairstyles(data.config.hairstyles);
    loadHairColors(data.config.hairColors);
    loadEyeColors(data.config.eyeColors);
    loadClothing();

    // Show editor
    document.getElementById('appearance-editor').style.display = 'block';
}

function closeEditor() {
    document.getElementById('appearance-editor').style.display = 'none';
}

// ============================================================================
// INITIALIZE UI ELEMENTS
// ============================================================================

function initializeSliders() {
    // Heritage mix slider
    const heritageMix = document.getElementById('heritage-mix');
    const heritageMixValue = document.getElementById('heritage-mix-value');
    heritageMix.value = (currentAppearance.heritage.mix * 100);
    heritageMixValue.textContent = Math.round(currentAppearance.heritage.mix * 100) + '%';

    heritageMix.addEventListener('input', function () {
        const value = this.value / 100;
        currentAppearance.heritage.mix = value;
        heritageMixValue.textContent = Math.round(value * 100) + '%';
        updateAppearance();
    });

    // Skin tone slider
    const skinTone = document.getElementById('skin-tone');
    const skinToneValue = document.getElementById('skin-tone-value');
    skinTone.value = (currentAppearance.heritage.skinMix * 100);
    skinToneValue.textContent = Math.round(currentAppearance.heritage.skinMix * 100) + '%';

    skinTone.addEventListener('input', function () {
        const value = this.value / 100;
        currentAppearance.heritage.skinMix = value;
        skinToneValue.textContent = Math.round(value * 100) + '%';
        updateAppearance();
    });
}

function loadHairstyles(hairstyles) {
    const genderStyles = currentGender === 0 ? hairstyles.male : hairstyles.female;
    const container = document.getElementById('hair-styles');
    container.innerHTML = '';

    genderStyles.forEach(style => {
        const div = document.createElement('div');
        div.className = 'grid-item';
        if (style.id === currentAppearance.hair.style) {
            div.classList.add('selected');
        }
        div.innerHTML = `${style.label}<small>${style.hint}</small>`;
        div.onclick = () => selectHairstyle(style.id, div);
        container.appendChild(div);
    });
}

function loadHairColors(hairColors) {
    const container = document.getElementById('hair-colors');
    container.innerHTML = '';

    const colorMap = {
        0: '#000000', 1: '#3d2314', 2: '#6b4423', 3: '#8b6f47',
        4: '#f0e68c', 5: '#f5f5dc', 6: '#8b0000', 7: '#a0522d', 8: '#808080'
    };

    hairColors.forEach(color => {
        const div = document.createElement('div');
        div.className = 'color-item';
        div.style.backgroundColor = colorMap[color.id] || '#000000';
        if (color.id === currentAppearance.hair.color) {
            div.classList.add('selected');
        }
        div.title = `${color.label} (${color.hint})`;
        div.onclick = () => selectHairColor(color.id, div);
        container.appendChild(div);
    });
}

function loadEyeColors(eyeColors) {
    const container = document.getElementById('eye-colors');
    container.innerHTML = '';

    const colorMap = {
        0: '#228b22', 1: '#4169e1', 2: '#8b4513',
        3: '#cd853f', 4: '#708090', 5: '#87ceeb'
    };

    eyeColors.forEach(color => {
        const div = document.createElement('div');
        div.className = 'color-item';
        div.style.backgroundColor = colorMap[color.id] || '#000000';
        if (color.id === currentAppearance.eyeColor) {
            div.classList.add('selected');
        }
        div.title = `${color.label} (${color.hint})`;
        div.onclick = () => selectEyeColor(color.id, div);
        container.appendChild(div);
    });
}

function loadClothing() {
    if (!clothingOptions) return;

    const gender = currentGender === 0 ? 'male' : 'female';

    // Load torso
    loadClothingCategory('torso', clothingOptions[gender].torso);
    // Load legs
    loadClothingCategory('legs', clothingOptions[gender].legs);
    // Load shoes
    loadClothingCategory('shoes', clothingOptions[gender].shoes);
}

function loadClothingCategory(category, items) {
    const container = document.getElementById(`clothing-${category}`);
    container.innerHTML = '';

    items.forEach(item => {
        const div = document.createElement('div');
        div.className = 'grid-item';

        const current = currentAppearance.clothing[category];
        if (current && current.drawable === item.drawable && current.texture === item.texture) {
            div.classList.add('selected');
        }

        div.innerHTML = `${item.label}<small>${item.hint}</small>`;
        div.onclick = () => selectClothing(category, item, div);
        container.appendChild(div);
    });
}

// ============================================================================
// SELECTION FUNCTIONS
// ============================================================================

function selectHairstyle(id, element) {
    currentAppearance.hair.style = id;

    document.querySelectorAll('#hair-styles .grid-item').forEach(el => el.classList.remove('selected'));
    element.classList.add('selected');

    updateAppearance();
}

function selectHairColor(id, element) {
    currentAppearance.hair.color = id;

    document.querySelectorAll('#hair-colors .color-item').forEach(el => el.classList.remove('selected'));
    element.classList.add('selected');

    updateAppearance();
}

function selectEyeColor(id, element) {
    currentAppearance.eyeColor = id;

    document.querySelectorAll('#eye-colors .color-item').forEach(el => el.classList.remove('selected'));
    element.classList.add('selected');

    updateAppearance();
}

function selectClothing(category, item, element) {
    currentAppearance.clothing[category] = {
        drawable: item.drawable,
        texture: item.texture
    };

    document.querySelectorAll(`#clothing-${category} .grid-item`).forEach(el => el.classList.remove('selected'));
    element.classList.add('selected');

    updateAppearance();
}

// ============================================================================
// UPDATE APPEARANCE (send to client)
// ============================================================================

function updateAppearance() {
    fetch(`https://gypsy-appearance/updateAppearance`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(currentAppearance)
    });
}

// ============================================================================
// CAMERA CONTROLS
// ============================================================================

function changeCamera(view) {
    fetch(`https://gypsy-appearance/changeCamera`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ view: view })
    });
}

// ============================================================================
// SAVE/CANCEL
// ============================================================================

function saveAppearance() {
    fetch(`https://gypsy-appearance/saveAppearance`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(currentAppearance)
    });
}

function cancelAppearance() {
    fetch(`https://gypsy-appearance/closeEditor`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}
