window.addEventListener('message', function (event) {
    const data = event.data;

    if (data.action === 'showEye') {
        document.getElementById('eye-container').style.display = 'block';
    } else if (data.action === 'hideEye') {
        document.getElementById('eye-container').style.display = 'none';
        document.getElementById('menu-container').style.display = 'none';
    } else if (data.action === 'activeEye') {
        document.querySelector('.eye-icon').classList.add('active');
    } else if (data.action === 'inactiveEye') {
        document.querySelector('.eye-icon').classList.remove('active');
    } else if (data.action === 'setOptions') {
        console.log('JS received options:', data.options);
        const list = document.getElementById('options-list');
        list.innerHTML = '';
        document.getElementById('menu-container').style.display = 'block';

        data.options.forEach((opt, index) => {
            const li = document.createElement('li');
            li.className = 'option';
            li.innerHTML = `<i class="${opt.icon || 'fas fa-circle'}"></i> ${opt.label}`;
            li.onclick = () => {
                fetch(`https://${GetParentResourceName()}/selectOption`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
                    body: JSON.stringify({ index: index })
                });
                // Hide menu after selection? Or keep open?
                // document.getElementById('menu-container').style.display = 'none';
            };
            list.appendChild(li);
        });
    }
});

// Close on Escape key
document.addEventListener('keyup', function (event) {
    if (event.key === 'Escape') {
        fetch(`https://${GetParentResourceName()}/close`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify({})
        });
    }
});

// Close on Click Outside (if clicking directly on the body/container but not the menu)
document.addEventListener('click', function (event) {
    const menu = document.getElementById('menu-container');
    // If menu is visible and click is NOT inside the menu
    if (menu.style.display === 'block' && !menu.contains(event.target)) {
        fetch(`https://${GetParentResourceName()}/close`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify({})
        });
    }
});
