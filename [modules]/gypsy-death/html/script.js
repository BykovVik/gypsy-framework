window.addEventListener('message', function (event) {
    if (event.data.action === "open") {
        document.getElementById('death-container').style.display = 'block';
        document.getElementById('timer').innerText = event.data.time;
        document.getElementById('respawn-msg').style.display = 'none';
    } else if (event.data.action === "close") {
        document.getElementById('death-container').style.display = 'none';
    } else if (event.data.action === "updateTime") {
        document.getElementById('timer').innerText = event.data.time;
        if (event.data.time <= 0) {
            document.getElementById('respawn-msg').style.display = 'block';
        }
    }
});
