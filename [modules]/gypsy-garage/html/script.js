console.log('GARAGE UI: Script Initialized');

window.addEventListener('message', function (event) {
    console.log('GARAGE UI: Message received', event.data.action);

    if (event.data.action === "openGarage") {
        openGarage(event.data.vehicles);
    } else if (event.data.action === "closeGarage") {
        closeGarage();
    }
});

document.addEventListener('DOMContentLoaded', () => {
    document.getElementById('close-btn').addEventListener('click', function () {
        closeGarage();
    });
});

document.addEventListener('keydown', function (event) {
    if (event.key === "Escape") {
        closeGarage();
    }
});

function openGarage(vehicles) {
    console.log('GARAGE UI: Opening garage with', vehicles ? vehicles.length : 0, 'vehicles');
    const container = document.getElementById('garage-container');
    if (!container) {
        console.error('GARAGE UI: Container not found!');
        return;
    }
    container.style.display = 'flex';

    const list = document.getElementById('vehicle-list');
    list.innerHTML = '';

    if (!vehicles || !Array.isArray(vehicles)) {
        list.innerHTML = '<div style="color:white; padding:20px;">No vehicles found.</div>';
        return;
    }

    vehicles.forEach(veh => {
        const card = document.createElement('div');
        card.className = 'vehicle-card';

        let fuel = 100;
        let engine = 1000;
        if (veh.mods) {
            try {
                const props = JSON.parse(veh.mods);
                if (props.fuelLevel !== undefined) fuel = props.fuelLevel;
                if (props.engineHealth !== undefined) engine = props.engineHealth;
            } catch (e) { console.error(e); }
        }

        const enginePercent = Math.floor((engine / 1000) * 100);
        const fuelPercent = Math.floor(fuel);
        const stateClass = veh.state === 1 ? 'status-in' : 'status-out';
        const stateText = veh.state === 1 ? 'In Garage' : 'Out';
        const btnDisabled = veh.state !== 1 ? 'disabled' : '';
        const btnText = veh.state === 1 ? 'Drive' : 'Unavailable';

        card.innerHTML = `
            <div class="card-header">
                <div>
                    <div class="vehicle-name">${veh.vehicle}</div>
                    <div class="vehicle-plate">${veh.plate}</div>
                </div>
                <div class="status-badge ${stateClass}">${stateText}</div>
            </div>
            <div class="vehicle-stats">
                <div class="stat fuel"><i class="fas fa-gas-pump"></i> ${fuelPercent}%</div>
                <div class="stat engine"><i class="fas fa-wrench"></i> ${enginePercent}%</div>
            </div>
            <button class="spawn-btn" ${btnDisabled} onclick="spawnVehicle('${veh.plate}')">${btnText}</button>
        `;
        list.appendChild(card);
    });
}

function closeGarage() {
    document.getElementById('garage-container').style.display = 'none';
    fetch(`https://${GetParentResourceName()}/close`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({})
    });
}

function spawnVehicle(plate) {
    fetch(`https://${GetParentResourceName()}/spawn`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({ plate: plate })
    });
    document.getElementById('garage-container').style.display = 'none';
}
