// SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
// SPDX-License-Identifier: Apache-2.0

import resolve from "@rollup/plugin-node-resolve"
import babel from '@rollup/plugin-babel';
import commonjs from '@rollup/plugin-commonjs';
import serve from 'rollup-plugin-serve'
import sass from 'rollup-plugin-sass';

import * as sass_ from 'sass';

const extensions = [
    '.js', '.jsx', '.ts', '.tsx',
];

const shouldServe = process.env.SERVE === 'true';


export default {
    input: "src/index.mjs",
    output: {
        file: "dist/bundle.js",
        format: 'es',
        sourcemap: 'inline'
    },
    plugins: [
        resolve({ extensions }),
        commonjs(),
        babel({
            extensions,
            babelHelpers: 'bundled',
            exclude: 'node_modules/**'
        }),
        shouldServe && serve({
            open: true,
            contentBase: 'dist',
            port: 8080,
        }).filter(Boolean),
        sass({
            output: 'dist/bundle.css',
            includePaths: [ 'node_modules/' ],
            importer(path) {
                return { file: path[0] !== '~' ? path : path.slice(1) };
            }
        }),
    ],
}