// SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
// SPDX-License-Identifier: Apache-2.0

import './index.scss';

import { EditorState } from '@codemirror/state';
import { keymap, EditorView } from '@codemirror/view';
import { nix } from "@replit/codemirror-lang-nix";
import { basicSetup } from 'codemirror';
import { solarizedLight } from '@uiw/codemirror-theme-solarized';
import { Terminal } from '@xterm/xterm';

function createTerminal(id, out) {
    let terminal = new Terminal({
        cols: 80,
        rows: 40,
        disableStdin: true,
        scrollback: 0,
    });

    let elm = document.getElementById(id);

    terminal.open(elm);

    terminal.write(out);
}

function terminalFromCode(elm) {
    let div = document.createElement("div");

    elm.parentNode.insertBefore(div, elm)
    elm.style.display = "none"

    let terminal = new Terminal({
        cols: 160,
        rows: 40,
        disableStdin: true,
        convertEol: true
    });

    elm.terminal = terminal;

    terminal.open(div);
    terminal.write(elm.innerText);

    console.log("Terminal created")
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

    elm.onchange = () => {
        view.dispatch({
            changes: {
                from: 0,
                to: view.state.doc.length,
                insert: elm.value
            }
        });
    };

    if (elm.form) {
        elm.form.addEventListener("submit", () => {
            elm.value = view.state.doc.toString()
        })
    }

    return view
}

function readOnlyEditorFromPre(elm) {
    let view = new EditorView({
        doc: elm.innerText,
        extensions: [
            EditorState.readOnly.of(true),
            EditorView.editable.of(false),
            solarizedLight,
            basicSetup,
            nix(),
        ]
    })

    elm.parentNode.insertBefore(view.dom, elm)
    elm.style.display = "none"

    return view
}

function init() {
    let textareas = document.querySelectorAll("textarea");
    textareas.forEach(textarea => {
        if (textarea.classList.contains("editor")) {
            editorFromTextarea(textarea);
        }
    });

    let pres = document.querySelectorAll("pre");
    pres.forEach(pre => {
        if (pre.classList.contains("editor")) {
            readOnlyEditorFromPre(pre);
        } else if (pre.classList.contains("terminal")) {
            terminalFromCode(pre);
        }
    });
}

document.addEventListener("DOMContentLoaded", init);

export { Terminal, createTerminal };