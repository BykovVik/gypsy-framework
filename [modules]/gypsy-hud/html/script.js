window.addEventListener('message', function (event) {
    if (event.data.action === "updateStats") {
        setProgress('health-fill', event.data.health);
        setProgress('armor-fill', event.data.armor);
        setProgress('stamina-fill', event.data.stamina);
    } else if (event.data.action === "updateStatus") {
        setProgress('hunger-fill', event.data.hunger);
        setProgress('thirst-fill', event.data.thirst);
    } else if (event.data.action === "updateVehicle") {
        // Show Vehicle HUD
        document.getElementById('vehicle-hud').style.display = 'flex';
        document.getElementById('minimap-border').style.display = 'block';
        
        // Update Values
        document.getElementById('speed').innerText = Math.floor(event.data.speed);
        setProgress('fuel-fill', event.data.fuel);
        
        // Engine Health (0-1000) -> Percent (0-100)
        let enginePercent = (event.data.engine / 1000) * 100;
        setProgress('engine-fill', enginePercent);
        
        // Optional: Change engine color based on health
        const engineCircle = document.querySelector('#engine-fill');
        if (event.data.engine < 300) {
            engineCircle.style.stroke = '#ff4444'; // Red
        } else if (event.data.engine < 600) {
            engineCircle.style.stroke = '#ffaa00'; // Orange
        } else {
            engineCircle.style.stroke = '#4caf50'; // Green
        }

    } else if (event.data.action === "hideVehicle") {
        document.getElementById('vehicle-hud').style.display = 'none';
        document.getElementById('minimap-border').style.display = 'none';
    } else if (event.data.action === "hide") {
        document.getElementById('hud-container').style.display = 'none';
    } else if (event.data.action === "show") {
        document.getElementById('hud-container').style.display = 'block';
    }
});

function setProgress(elementId, percent) {
    const circle = document.getElementById(elementId);
    if (!circle) return;
    
    const radius = circle.r.baseVal.value;
    const circumference = radius * 2 * Math.PI;

    // Clamp percent between 0 and 100
    percent = Math.max(0, Math.min(100, percent));

    const offset = circumference - (percent / 100) * circumference;

    // Set both dasharray and dashoffset to prevent glitches
    circle.style.strokeDasharray = `${circumference} ${circumference}`;
    circle.style.strokeDashoffset = offset;
}
