const app = document.getElementById('app');
const vehicleList = document.getElementById('vehicle-list');
const closeBtn = document.getElementById('close-btn');

window.addEventListener('message', (event) => {
    const data = event.data;

    if (data.action === 'open') {
        renderVehicles(data.vehicles);
        app.classList.remove('hidden');
    } else if (data.action === 'close') {
        app.classList.add('hidden');
    }
});

closeBtn.addEventListener('click', () => {
    fetch(`https://${GetParentResourceName()}/close`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({})
    });
    app.classList.add('hidden');
});

function renderVehicles(vehicles) {
    vehicleList.innerHTML = '';

    if (!vehicles || vehicles.length === 0) {
        vehicleList.innerHTML = '<div style="text-align:center; color:#888; margin-top:50px;">No vehicles in impound</div>';
        return;
    }

    vehicles.forEach(veh => {
        const div = document.createElement('div');
        div.className = 'vehicle-item';

        // Determine name (fallback to model if name not available)
        const name = veh.vehicle.toUpperCase();
        const fee = veh.impound_fee || 500;

        div.innerHTML = `
            <div class="veh-info">
                <span class="veh-name">${name}</span>
                <span class="veh-plate">${veh.plate}</span>
            </div>
            <div class="veh-action">
                <span class="veh-fee">$${fee}</span>
                <button class="pay-btn" onclick="retrieveVehicle('${veh.plate}')">PAY & RETRIEVE</button>
            </div>
        `;

        vehicleList.appendChild(div);
    });
}

window.retrieveVehicle = function (plate) {
    fetch(`https://${GetParentResourceName()}/retrieve`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({
            plate: plate
        })
    });
    app.classList.add('hidden');
}

document.onkeyup = function (data) {
    if (data.which == 27) { // ESC
        fetch(`https://${GetParentResourceName()}/close`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=UTF-8',
            },
            body: JSON.stringify({})
        });
        app.classList.add('hidden');
    }
};
