// SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
// SPDX-License-Identifier: Apache-2.0

import { EditorState } from '@codemirror/state';
import { keymap, EditorView } from '@codemirror/view';
import { nix } from "@replit/codemirror-lang-nix";
import { json } from "@codemirror/lang-json";
import { basicSetup } from 'codemirror';
import { solarizedLight } from '@uiw/codemirror-theme-solarized';

function fromTextarea(elm) {
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

function fromPre(elm) {
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

export { fromTextarea, fromPre };