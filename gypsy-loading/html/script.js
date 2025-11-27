let totalHandlers = 0;
let completedHandlers = 0;

const handlers = {
    startInitFunctionOrder(data) {
        totalHandlers += data.count;
        updateProgress();
    },

    initFunctionInvoking(data) {
        completedHandlers++;
        updateProgress();
    },

    startDataFileEntries(data) {
        totalHandlers += data.count;
        updateProgress();
    },

    performMapLoadFunction(data) {
        completedHandlers++;
        updateProgress();
    },

    onDataFileEntry(data) {
        completedHandlers++;
        updateProgress();
    },

    onLogLine(data) {
        // Optional: handle log lines
    }
};

function updateProgress() {
    const progressBar = document.querySelector('.progress-fill');

    if (progressBar) {
        let percentage = 0;

        if (totalHandlers > 0) {
            percentage = Math.min((completedHandlers / totalHandlers) * 95, 95);
        }

        progressBar.style.width = percentage + '%';
    }
}

window.addEventListener('message', function (e) {
    const handler = handlers[e.data.eventName];
    if (handler) {
        handler(e.data);
    }

    // When all loading is complete
    if (e.data.eventName === 'onClientGameTypeStart') {
        totalHandlers++;
        completedHandlers++;
        updateProgress();

        // Small delay then shutdown loading screen
        setTimeout(() => {
            if (window.invokeNative) {
                window.invokeNative('shutdown');
            }
        }, 500);
    }
});
