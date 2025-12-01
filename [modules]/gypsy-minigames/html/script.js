let currentGame = null;

// Skill Check
function startSkillCheck(difficulty) {
    const container = document.getElementById('skillcheck-container');
    const bar = document.getElementById('skillcheck-bar');
    const target = document.getElementById('skillcheck-target');
    
    container.classList.remove('hidden');
    
    // Установить позицию цели случайно
    const targetAngle = Math.random() * 360;
    target.style.transform = `translate(-50%, -100%) rotate(${targetAngle}deg)`;
    
    // Настроить сложность (скорость вращения)
    const speed = 2 - (difficulty * 0.2); // 1.8s - 1.0s
    bar.style.animationDuration = `${speed}s`;
    
    // Размер цели зависит от сложности
    const targetSize = 80 - (difficulty * 10); // 70deg - 30deg
    target.style.width = `${targetSize}px`;
    
    currentGame = {
        type: 'skillcheck',
        targetAngle: targetAngle,
        targetSize: targetSize,
        speed: speed
    };
}

// Обработка нажатия клавиши
document.addEventListener('keydown', (e) => {
    if (!currentGame) return;
    
    if (e.code === 'Space') {
        e.preventDefault();
        
        if (currentGame.type === 'skillcheck') {
            checkSkillCheckSuccess();
        }
    } else if (e.code === 'Escape') {
        e.preventDefault();
        closeMinigame();
    }
});

function checkSkillCheckSuccess() {
    const bar = document.getElementById('skillcheck-bar');
    const computedStyle = window.getComputedStyle(bar);
    const transform = computedStyle.getPropertyValue('transform');
    
    // Получить текущий угол вращения
    const matrix = transform.match(/matrix\(([^)]+)\)/);
    if (!matrix) return;
    
    const values = matrix[1].split(', ');
    const a = parseFloat(values[0]);
    const b = parseFloat(values[1]);
    let currentAngle = Math.atan2(b, a) * (180 / Math.PI);
    if (currentAngle < 0) currentAngle += 360;
    
    // Проверить попадание в цель
    const targetAngle = currentGame.targetAngle;
    const targetSize = currentGame.targetSize;
    const halfSize = (targetSize / 300) * 180; // Конвертация в градусы
    
    let angleDiff = Math.abs(currentAngle - targetAngle);
    if (angleDiff > 180) angleDiff = 360 - angleDiff;
    
    const success = angleDiff <= halfSize;
    
    // Отправить результат
    $.post('https://gypsy-minigames/skillCheckResult', JSON.stringify({
        success: success
    }));
    
    closeMinigame();
}

function closeMinigame() {
    const container = document.getElementById('skillcheck-container');
    container.classList.add('hidden');
    currentGame = null;
    
    $.post('https://gypsy-minigames/closeMinigame', JSON.stringify({}));
}

// Слушать сообщения от Lua
window.addEventListener('message', (event) => {
    const data = event.data;
    
    if (data.action === 'startSkillCheck') {
        startSkillCheck(data.difficulty || 3);
    }
});
