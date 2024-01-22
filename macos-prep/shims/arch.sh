#!/bin/bash
/usr/bin/arch "$@" | sed 's|x86_64|arm64|g' | sed 's|i386|arm64|g'
