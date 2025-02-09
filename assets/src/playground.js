// SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
// SPDX-License-Identifier: Apache-2.0

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

async function init() {
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

export { init };