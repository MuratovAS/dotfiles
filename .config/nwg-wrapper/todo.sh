#!/bin/bash
targetSearch="$HOME/.calendars/tasks/*"

vdirsyncer sync

text_color="#ffffffb1"
text_color_1="#ff9191bf"
text_color_5="#fff491bf"
text_color_9="#91d1ffbf"


echo '<span size="13000" face="monospace" foreground="'$text_color'">'
echo '<span size="20000" foreground="'$text_color'" face="sans-serif">    Todo list</span>'
for file in $targetSearch; do
	let "tmp=$(cat $file | grep 'COMPLETED:' | sed -n '/.*:/s///p'| grep -o '^[^T]*') + 0 "
	if [[ "$tmp" != "0" && "$(date '+%Y%m%d')" -gt "$tmp" ]];then
		continue
	fi

	printf "<span>"
	tmp=$(cat $file | grep "PRIORITY:" | sed -n '/.*:/s///p')
	if [ "$tmp" = "" ];then
	printf "0" 
	fi
	printf "%s" $tmp
	printf ";"
	
	printf "["
	tmp=$(cat $file | grep "STATUS:" | sed -n '/.*:/s///p')
	if [ "$tmp" = "" ];then
		printf " " 
	else
		printf "%s" $tmp
	fi
	printf "]"

	printf ";"
	if [[ $(cat $file | grep "RELATED-TO") != "" ]];then
		printf "= "
	fi
	printf "%s" "$(cat $file | grep 'SUMMARY:' | sed -n '/.*:/s///p')"
	printf '</span>'
	
	printf ";"
	tmp=$(cat $file | grep 'DESCRIPTION:' | sed -n '/.*:/s///p' | cut -c1-32)
	if [ "$tmp" != "" ];then
		printf "@@@<i>"
		if [[ $(cat $file | grep "RELATED-TO") != "" ]];then
			printf "  "
		fi 
		printf "+"
		printf "%s</i></span>" "$tmp"
	fi
	

	printf ";"
	tmp=$(cat $file | grep "CATEGORIES:" | sed -n '/.*:/s///p')
	if [ "$tmp" != "" ];then
		printf "@@@<i>"
		if [[ $(cat $file | grep "RELATED-TO") != "" ]];then
			printf "  "
		fi 
		printf '+ '
		printf "%s</i></span>" "$tmp"
	fi


	printf ";"
	let "tmp=$(cat $file | grep 'DUE' | sed -n '/.*:/s///p') + 0"
	if [[ "$tmp" != "0" ]];then
		printf "@@@<i>"
		if [[ "$(date '+%Y%m%d')" -ge "$tmp" ]];then
			printf "<b>"
		fi
		if [[ $(cat $file | grep "RELATED-TO") != "" ]];then
			printf "  "
		fi 
		printf "~"
		printf "%s" "$tmp"
		if [[ "$(date '+%Y%m%d')" -ge "$tmp" ]];then
			printf "</b>"
		fi
		printf "</i></span>"
	fi

	
	printf ";"
	printf "%s" $(cat $file | grep "RELATED-TO" | sed -n '/.*:/s///p')
	printf ";"
	printf "%s" $(cat $file | grep "UID:" | sed -n '/.*:/s///p')

	printf "\n"
done | sort  -t ";" -k7 -k6 -k1\
	 | sed 's/COMPLETED/X/' \
	 | sed 's/IN-PROCESS/%/' \
	 | sed 's/Дом//' \
	 | sed 's/Работа//' \
	 | sed 's/Отдых//' \
	 | sed 's/Проекты//' \
	 | sed 's/Учеба//' \
	 | cut -d ";" -f7,8 --complement \
	 | sed 's/@@@/\n<span>;;/g' \
	 | cut -d ";" -f4 --complement \
	 | column -t -s ";" -o " " \
	 | sed "s/<span>0/<span> /"\
	 | sed "s/<span>1/<span foreground=\"$text_color_1\"> /"\
	 | sed "s/<span>2/<span foreground=\"$text_color_1\"> /"\
	 | sed "s/<span>3/<span foreground=\"$text_color_1\"> /"\
	 | sed "s/<span>4/<span foreground=\"$text_color_1\"> /"\
	 | sed "s/<span>5/<span foreground=\"$text_color_5\"> /"\
	 | sed "s/<span>6/<span foreground=\"$text_color_5\"> /"\
	 | sed "s/<span>7/<span foreground=\"$text_color_5\"> /"\
	 | sed "s/<span>8/<span foreground=\"$text_color_5\"> /"\
	 | sed "s/<span>9/<span foreground=\"$text_color_9\"> /"
echo '</span>'
