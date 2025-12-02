let timerInterval = null;
let startTime = 0;
let totalTime = 0;
let currentTime = 0;

const timerContainer = document.getElementById('pizza-timer');
const timerProgress = document.querySelector('.timer-progress');
const minutesDisplay = document.getElementById('timer-minutes');
const secondsDisplay = document.getElementById('timer-seconds');

// Add gradient definition to SVG
const svg = document.querySelector('.timer-svg');
const defs = document.createElementNS('http://www.w3.org/2000/svg', 'defs');
const gradient = document.createElementNS('http://www.w3.org/2000/svg', 'linearGradient');
gradient.setAttribute('id', 'gradient');
gradient.setAttribute('x1', '0%');
gradient.setAttribute('y1', '0%');
gradient.setAttribute('x2', '100%');
gradient.setAttribute('y2', '100%');

const stop1 = document.createElementNS('http://www.w3.org/2000/svg', 'stop');
stop1.setAttribute('offset', '0%');
stop1.setAttribute('stop-color', '#ff6b35');

const stop2 = document.createElementNS('http://www.w3.org/2000/svg', 'stop');
stop2.setAttribute('offset', '100%');
stop2.setAttribute('stop-color', '#f7931e');

gradient.appendChild(stop1);
gradient.appendChild(stop2);
defs.appendChild(gradient);
svg.insertBefore(defs, svg.firstChild);

// Circle circumference
const radius = 90;
const circumference = 2 * Math.PI * radius;

function updateTimer() {
    const elapsed = Date.now() - startTime;
    currentTime = totalTime - elapsed;

    if (currentTime <= 0) {
        currentTime = 0;
        stopTimer();
    }

    // Update display
    const minutes = Math.floor(currentTime / 60000);
    const seconds = Math.floor((currentTime % 60000) / 1000);

    minutesDisplay.textContent = minutes;
    secondsDisplay.textContent = seconds.toString().padStart(2, '0');

    // Update progress circle
    const progress = currentTime / totalTime;
    const offset = circumference * (1 - progress);
    timerProgress.style.strokeDashoffset = offset;

    // Update color based on time remaining
    timerProgress.classList.remove('warning', 'danger');
    if (progress < 0.25) {
        timerProgress.classList.add('danger');
    } else if (progress < 0.5) {
        timerProgress.classList.add('warning');
    }
}

function startTimer(duration) {
    totalTime = duration * 1000; // Convert to milliseconds
    startTime = Date.now();
    currentTime = totalTime;

    timerProgress.style.strokeDasharray = circumference;
    timerProgress.style.strokeDashoffset = 0;

    updateTimer();
    timerInterval = setInterval(updateTimer, 100);
}

function stopTimer() {
    if (timerInterval) {
        clearInterval(timerInterval);
        timerInterval = null;
    }

    // Если время истекло (currentTime = 0), показываем крышку
    if (currentTime <= 0) {
        timerContainer.classList.add('expired');
    }
}

function showTimer(duration) {
    timerContainer.classList.remove('hidden', 'expired');
    startTimer(duration);
}

function hideTimer() {
    stopTimer();
    timerContainer.classList.add('hidden');
    timerContainer.classList.remove('expired');
}

function getTimePercentage() {
    if (totalTime === 0) return 0;
    return (currentTime / totalTime) * 100;
}

// NUI Message Handler
window.addEventListener('message', (event) => {
    const data = event.data;

    switch (data.action) {
        case 'showTimer':
            showTimer(data.duration || 300); // Default 5 minutes
            break;

        case 'hideTimer':
            hideTimer();
            break;

        case 'getTimePercentage':
            // Send back to Lua
            fetch(`https://${GetParentResourceName()}/timerPercentage`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ percentage: getTimePercentage() })
            });
            break;
    }
});
