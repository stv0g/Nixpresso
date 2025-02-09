import { Terminal } from '@xterm/xterm';
import { FitAddon } from '@xterm/addon-fit';

function create(id, out) {
    const elm = document.getElementById(id);

    let terminal = new Terminal({
        cols: 160,
        rows: 40,
        disableStdin: true,
        convertEol: true,
        scrollback: 0,
    });

    terminal.open(elm);

    const fitAddon = new FitAddon();
    terminal.loadAddon(fitAddon);
    fitAddon.fit();

    terminal.write(out);
}

function fromPre(elm) {
    const div = document.createElement("div");

    elm.parentNode.insertBefore(div, elm)
    elm.style.display = "none"

    let terminal = new Terminal({
        cols: 160,
        rows: 40,
        disableStdin: true,
        convertEol: true
    });

    terminal.open(div);

    const fitAddon = new FitAddon();
    terminal.loadAddon(fitAddon);
    fitAddon.fit();

    terminal.write(elm.innerText);

    elm.terminal = terminal;
}

async function stream(terminal, url) {
    const response = await fetch(url);
    
    terminal.reset();
    for await (const chunk of response.body) {
        terminal.write(chunk);
    }
}

export { Terminal, create, stream, fromPre };