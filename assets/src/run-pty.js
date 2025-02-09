async function init() {
    const pre = document.getElementById('terminal');
    const response = await fetch('run');
    const out = await response.text();

    pre.terminal.reset();
    pre.terminal.write(out);
}

export { init };