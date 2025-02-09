// SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
// SPDX-License-Identifier: Apache-2.0

import './index.scss';

import { Terminal, create as createTerminal, stream as streamToTerminal, fromPre as terminalFromPre } from './terminal';
import { fromTextarea as editorFromTextarea, fromPre as editorFromPre } from './editor';
import { init as initPlayground } from './playground';
import { init as initRunPty } from './run-pty';

function setupTerminalsAndEditors() {
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
            terminalFromPre(pre);
        }
    });
}

async function init() {
    setupTerminalsAndEditors();

    if (document.querySelector("body.playground")) {
        initPlayground();
    } else if (document.querySelector("body.run-pty")) {
        initRunPty();
    }
}

document.addEventListener("DOMContentLoaded", init);

export { Terminal, createTerminal, initPlayground, initRunPty, streamToTerminal, editorFromTextarea, editorFromPre };