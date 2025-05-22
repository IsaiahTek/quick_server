const log = document.getElementById('log');
const socket = new WebSocket(`ws://${location.host}/ws`);

socket.addEventListener('open', () => {
    log.textContent += 'Connected to WebSocket server\n';
});

socket.addEventListener('message', (event) => {
    log.textContent += `Received: ${event.data}\n`;
});

socket.addEventListener('close', () => {
    log.textContent += 'Connection closed\n';
});

socket.addEventListener('error', (err) => {
    log.textContent += `Error: ${err.message}\n`;
});

function sendMessage() {
    const input = document.getElementById('message');
    const message = input.value;
    socket.send(message);
    log.textContent += `Sent: ${message}\n`;
    input.value = '';
}