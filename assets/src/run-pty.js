import { stream} from './terminal';

async function init() {
    const url = new URL(window.location.href);
    url.pathname += "run";
    
    const terminal = document.getElementById('terminal');
    await stream(terminal.terminal, url.href);
}

export { init };