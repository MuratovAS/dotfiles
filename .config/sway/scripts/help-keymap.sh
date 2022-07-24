#!/bin/bash
targetSearch="
$HOME/.config/sway/modes/
$HOME/.config/sway/definitions"

grep -h -r "bindsym" $targetSearch \
	| grep '###' \
	| grep -v 'unbindsym' \
	| sed 's/\$bindsym/bindsym --to-code/g' \
	| sed 's/^\s*//' \
	| sed 's/\$mod/Win/g' \
	| sed 's/Left/←/' \
	| sed 's/Right/→/' \
	| sed 's/Down/↓/' \
	| sed 's/Up/↑/' \
	| sed '$a bindsym' \
	| while read line; do
	description_new=$(echo $line | grep -o '###.*$' |  tr -d "###")	
	combination_new=$(echo $line | grep -o -e "\-\-to\-code [^ ]*" | sed 's/--to-code//' | sed 's/^ *//')
	
	if [[ "$description_new" = "$description" && "$description_new" != "" ]]
	then 
		combination=$(echo $combination $combination_new \
		| sed 's/+/\n/g' | sed 's/ /\n@\n/g' \
		| awk '!($0 in a)||/@/ {a[$0];print}' \
		| xargs | sed 's/ /+/g' | sed 's/+@+//g'\
		)
	else
		
		printf "@@@%s " "$combination" "$description"
		printf "\n"
		combination=$combination_new
		description=$description_new
	fi
done | column -t -o "" -s "@@@"

read