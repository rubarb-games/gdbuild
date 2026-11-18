#!/usr/bin/env bash

set -e

odin run src/ -- \
    -script_path:./scripts/main.lua \
    -version:"0.4.320" \
    -build_type:full \
    -build_mode:dev \
    -platforms:"win,linux"
