#!/usr/bin/env bash
CON="tat-diag"
sock="/tmp/tmate_$CON.sock"

# create tmate server and publish ssh url to upfile.sh
# -> returns unique ID part of url
# Provide the shown ID as parameter to fetch the full url and connect

server() {
	tmate -S $sock new-session -d
	tmate -S $sock wait tmate-ready
	t_ssh="$(tmate -S $sock display -p '#{tmate_ssh}')"
	t_web="$(tmate -S $sock display -p '#{tmate_web}')"
	res="$(curl -H "Max-Days: 1" --upload-file <(echo -e "$t_ssh\n$t_web") "https://upfile.sh/$CON")"
	id="$(echo "$res" | sed 's/.*dow":"\([^"]*\)".*/\1/' | cut -d/ -f4)"
	echo "$res"
	echo "t_ssh: $t_ssh"
	echo "t_web: $t_web"
	echo "ID: $id"
	read -p "Press any key to exit..."
}

client() { 
	id="$1"
	res="$(curl "https://upfile.sh/$id/$CON")"
	t_ssh="$(echo "$res" | grep "^ssh")"
	echo "$res"
	echo "t_ssh: $t_ssh"
	read -p "Press any key to connect now..."
	eval "$t_ssh"
}

if [ -z "$1" ]; then
	server
else
	client "$1"
fi
