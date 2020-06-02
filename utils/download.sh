#!/bin/bash
set -e

for utility in 'update.backend.sh' 'update.frontend.sh'; do
	curl -sS -o "$HOME/$utility" "https://raw.githubusercontent.com/dot-cafe/beam.cafe.sh/master/utils/$utility"
	chmod +x "$HOME/$utility"
	printf 'Downloaded %s!' $utility
done
