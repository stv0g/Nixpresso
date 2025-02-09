// SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
// SPDX-License-Identifier: Apache-2.0

import './index.scss';

import { EditorState } from '@codemirror/state';
import { keymap, EditorView } from '@codemirror/view';
import { nix } from "@replit/codemirror-lang-nix";
import { json } from "@codemirror/lang-json";
import { basicSetup } from 'codemirror';
import { solarizedLight } from '@uiw/codemirror-theme-solarized';
import { Terminal } from '@xterm/xterm';
import { FitAddon } from '@xterm/addon-fit';

function showTooltip(elm, timeout, message) {
    elm.setAttribute("data-tooltip", message);
    window.setTimeout(() => {
        elm.removeAttribute("data-tooltip");
    }, timeout);
}

function toggleClassVisibility(clsAll, cls) {
    const modeElms = document.getElementsByClassName(clsAll);
    for (let elm of modeElms) {
        if (elm.classList.contains(cls)) {
            elm.style.display = "block";
        } else {
            elm.style.display = "none";
        }
    }
}

function createTerminal(id, out) {
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

function terminalFromCode(elm) {
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

async function streamToTerminal(terminal, url) {
    const response = await fetch(url);
    
    terminal.reset();
    for await (const chunk of response.body) {
        terminal.write(chunk);
    }
}

function editorFromTextarea(elm) {
    let submitKey = keymap.of([
        {
            key: "Ctrl-Enter",
            run: () => {
                elm.value = view.state.doc.toString();
                elm.form.submit();
            },
        }
    ]);

    let view = new EditorView({
        doc: elm.value,
        extensions: [
            solarizedLight,
            basicSetup,
            nix(),
            ...elm.form ? [submitKey] : [],
        ],
    })

    elm.parentNode.insertBefore(view.dom, elm)
    elm.style.display = "none"

    elm.setValue = (value) => {
        elm.value = value;
        view.dispatch({
            changes: {
                from: 0,
                to: view.state.doc.length,
                insert: value
            }
        });
    }

    if (elm.form) {
        elm.form.addEventListener("submit", () => {
            elm.value = view.state.doc.toString()
        })
    }

    return view
}

function editorFromPre(elm) {
    let languageName = "nix";
    for (let cls of elm.classList) {
        if (cls.startsWith("language-")) {
            languageName = cls.replace("language-", "");
        }
    }

    let language;
    switch (languageName) {
        case "json":
            language = json();
            break;

        case "nix":
            language = nix();
            break;

        default:
            console.warn(`Unknown language: ${languageName}`);
            return;
    }


    let view = new EditorView({
        doc: elm.innerText,
        extensions: [
            EditorState.readOnly.of(true),
            EditorView.editable.of(false),
            solarizedLight,
            basicSetup,
            language,
        ]
    })

    elm.parentNode.insertBefore(view.dom, elm)
    elm.style.display = "none"

    elm.setValue = (value) => {
        elm.value = value;
        view.dispatch({
            changes: {
                from: 0,
                to: view.state.doc.length,
                insert: value
            }
        });
    }

    return view
}

async function fetchExamples() {
    const response = await fetch('examples.json');
    return await response.json();
}

async function copyPermalink(event) {
    try {
        await navigator.clipboard.writeText(windows.location);
        showTooltip(event.target, 1500, "Copied!");
    } catch (error) {
        console.error(error.message);
        showTooltip(event.target, 1500, "Failed to copy link to clipboard");
    }
}

async function initPlayground() {
    const form = document.getElementsByTagName('form')[0];
    const linkBtn = document.getElementById('permalink');

    if (linkBtn) {
        linkBtn.onclick = copyPermalink;
    }

    var examples = await fetchExamples();
    for (const [name, example] of Object.entries(examples)) {
        const option = document.createElement('option');
        option.value = name;
        option.text = example.description ? example.description : name;

        form.example.appendChild(option);
    }

    form.mode.onchange = () => {
        toggleClassVisibility("mode", "mode-" + form.mode.value);
    }

    form.example.onchange = () => {
        const example = examples[form.example.value];

        form.expression.setValue(example.code);

        if (example.mode !== undefined) {
            form.mode.value = example.mode;
        }

        if (example.raw !== undefined) {
            form.raw.checked = example.raw;
        }

        if (example.rebuild !== undefined) {
            form.rebuild.checked = example.rebuild;
        }

        if (example.recursive !== undefined) {
            form.recursive.checked = example.recursive;
        }

        if (example.stream !== undefined) {
            form.stream.checked = example.stream;
        }

        if (example.pty !== undefined) {
            form.pty.checked = example.pty;
        }

        if (example.output !== undefined) {
            form.output.value = example.output;
        }

        if (example.subPath !== undefined) {
            form.subPath.value = example.subPath;
        }

        if (example.env !== undefined) {
            let envLines = [];
            for (const [name, value] of Object.entries(example.env)) {
                envLines.push(`${name}=${value}`);
            }

            form.env.value = envLines.join("\n");
        }

        form.mode.dispatchEvent(new Event('change'));
    }

    if (form.expression.value == "") {
        form.example.selectedIndex = 1;
        form.example.dispatchEvent(new Event('change'));
    }

    form.mode.dispatchEvent(new Event('change'));
}

async function initRunPty() {
    const pre = document.getElementById('terminal');
    const response = await fetch('run');
    const out = await response.text();

    pre.terminal.reset();
    pre.terminal.write(out);
}

async function init() {
    let textareas = document.querySelectorAll("textarea");
    textareas.forEach(textarea => {
        if (textarea.classList.contains("editor")) {
            editorFromTextarea(textarea);
        }
    });

    let pres = document.querySelectorAll("pre");
    pres.forEach(pre => {
        if (pre.classList.contains("editor")) {
            editorFromPre(pre);
        } else if (pre.classList.contains("terminal")) {
            terminalFromCode(pre);
        }
    });

    console.log("Init finished");
}

document.addEventListener("DOMContentLoaded", init);

export { Terminal, createTerminal, initPlayground, initRunPty, streamToTerminal };