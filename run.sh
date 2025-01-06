#!/bin/env bash

nix build \
    --print-build-logs \
    --print-out-paths \
    --arg count 2 \
    --json \
    --option sandbox relaxed \
    --file expression.nix \
    drv.body