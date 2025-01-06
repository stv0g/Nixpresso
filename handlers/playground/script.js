// SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
// SPDX-License-Identifier: Apache-2.0

// async function fetchExamples() {
//     const response = await fetch('examples.json');
//     return await response.json();
// }

// async function copyPermalink() {
//     let url = new URL(window.location);
//     url.search = '${query.encode { e = exprString; }}';

//     try {
//         await navigator.clipboard.writeText(url.href);
//     } catch (error) {
//         console.error(error.message);
//     }

//     window.location = url;
// }

// async function loaded() {
//     const linkBtn = document.getElementById('permalink');
//     if (linkBtn) {
//         linkBtn.onclick = copyPermalink;
//     }

//     const examplesSelect = document.getElementById('examples');
//     if (examplesSelect) {
//         examplesSelect.onchange = function () {
//             const code = examplesSelect.value;
//             const editor = document.getElementById('expression');

//             editor.value = code;
//         };

//         const examples = await fetchExamples();
//         for (const [name, code] of Object.entries(examples)) {
//             const option = document.createElement('option');
//             option.value = code;
//             option.text = name;

//             examplesSelect.appendChild(option);
//         }
//     }
// }

// document.addEventListener('DOMContentLoaded', loaded);