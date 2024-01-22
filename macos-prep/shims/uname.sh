#!/bin/bash
/usr/bin/uname "$@" | sed 's|x86_64|arm64|g' | sed 's|i386|arm|g'
