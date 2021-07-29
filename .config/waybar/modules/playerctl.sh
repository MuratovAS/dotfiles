#!/bin/sh
class=$(playerctl status)

printf '{"alt":"%s"}\n' "$class"
