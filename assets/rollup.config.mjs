// SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
// SPDX-License-Identifier: Apache-2.0

import nodeResolve from "@rollup/plugin-node-resolve"
import babel from '@rollup/plugin-babel';
import commonjs from '@rollup/plugin-commonjs';
import serve from 'rollup-plugin-serve'
import sass from 'rollup-plugin-sass';
import copy from 'rollup-plugin-copy'


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
        nodeResolve({
            extensions,
        }),
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
            },
        }),
        copy({
            targets: [
                { src: 'node_modules/@mdi/font/fonts/*', dest: 'dist/fonts' },
                { src: 'assets/*.txt', dest: 'dist' },
                { src: 'assets/images/**/*', dest: 'dist/images' },
            ]
        })
    ],
}