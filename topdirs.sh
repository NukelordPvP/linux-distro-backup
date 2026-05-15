#!/usr/bin/env bash

sudo du -ahx / 2>/dev/null | sort -rh | head -20
