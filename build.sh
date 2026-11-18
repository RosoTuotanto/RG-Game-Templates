#!/bin/sh
set -eu
cd "$(dirname "$0")"

# Copies each game/ and developmentFiles/ folder of src/core and then src/templates/<name> on top of it into dst/<name>.
build() {
	target="dst/$1"
	template="src/templates/$1"

	rm -rf "$target"
	mkdir -p "$target/game" "$target/developmentFiles"

	cp -R src/core/game/. "$target/game/"
	cp -R "$template/game/." "$target/game/"

	cp -R src/core/developmentFiles/. "$target/developmentFiles/"

	if [ -d "$template/developmentFiles" ]; then
		cp -R "$template/developmentFiles/." "$target/developmentFiles/"
	fi

	echo "Built $target"
}

while true; do
	echo ""
	echo "RG Game Templates: build into dst/"
	echo ""
	echo "  [1] All templates"
	echo "  [2] visual-novel"
	echo "  [3] platformer"
	echo "  [4] top-down"
	echo "  [5] Exit"
	echo ""
	printf "Type a number and press Enter: "

	# read fails when the input ends, such as a closed terminal or a piped list of answers.
	read -r choice || exit 0

	case "$choice" in
		1)
			build visual-novel
			build platformer
			build top-down
			;;

		2) build visual-novel ;;

		3) build platformer ;;

		4) build top-down ;;

		5) exit 0 ;;

		*) echo "Type a number from 1 to 5." ;;
	esac
done
