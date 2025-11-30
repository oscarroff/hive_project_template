#!/bin/bash

if [ -z "$WDIR" ]; then
	echo "WDIR not set" >&2
	return 2 2>/dev/null || exit 2
fi

if [ ! -d "$WDIR/template" ]; then
	echo "No such directory: $WDIR/template" >&2
	return 2 2>/dev/null || exit 2
fi

SRC="$(cd "$WDIR/template" && pwd -P)" || { echo "Error: cannot fetch paths" >&2; exit 2; }
PWD_REAL="$(pwd -P)" || { echo "Error: cannot fetch paths" >&2; exit 2; }
EXCLUDE="new_project.sh"

if [[ "$PWD_REAL" == "$SRC"* ]]; then
	echo "Project creation not possible inside template directory!"
	exit 1
fi

echo -n "Please enter a project name: "
read -r project_name
if [ -z "$project_name" ]; then
	echo "Error: Project name cannot be empty" >&2
	return 1 2>/dev/null || exit 1
fi
echo -n "Please enter a GitHub repo (leave blank for local): "
read -r git_hub_origin

if [ -e "$PWD/${project_name}" ]; then
    echo "Error: Project '${project_name}' already exists!" >&2
    exit 1
fi
DST="$PWD/${project_name}/${project_name}_public"
mkdir -p -- "$DST"

for f in "$SRC"/*; do
	[ "$(basename -- "$f")" = "$EXCLUDE" ] && continue
	cp -a -v -i "$f" "$DST/"
done

grep -rlI 'template' "$DST" | xargs perl -pi -e "
	s|template|${project_name}|g;
	s|TEMPLATE|\U${project_name}\E|g;
	"
( cd "$DST/src" && for f in template.*; do [ -e "$f" ] && mv "$f" "${f/template/$project_name}"; done )
( cd "$DST/inc" && for f in template.*; do [ -e "$f" ] && mv "$f" "${f/template/$project_name}"; done )

cd $DST

if [ -n "$git_hub_origin" ]; then
  (
	git init
	git add .
	git commit -m "1st commit"
	git branch -M main
	git remote add origin "$git_hub_origin" || true
	git push
  )
fi

if [[ ! -f "$DST/$project_name" ]]; then
	bmake
fi
nvim -c "lua vim.defer_fn(function() vim.cmd('Neotree $WDIR reveal_file=$DST/Makefile') end, 100)"
