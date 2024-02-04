# copy local/src and config/wbg

WORKDIR :=  $(shell pwd)
HOME := $(shell cd ../../ && pwd)
XDG_CONFIG_HOME := $(shell cd ../../ && pwd)/.config
PATH := $(shell echo $(HOME)/.local/bin | sed 's/ /:/g'):$(PATH)

all: mkdir dwl dwlb someblocks wbg dmenu-wayland noticat
	
mkdir: 
	mkdir -p ${HOME}/.local
	mkdir -p ${HOME}/.local/bin

dwl:
	cd dwl && make
	cp -f dwl/dwl ${HOME}/.local/bin/

dwlb:
	cd dwlb && make
	cp -f dwlb/dwlb ${HOME}/.local/bin/

someblocks:
	cd someblocks && make
	cp -f someblocks/someblocks ${HOME}/.local/bin/

wbg:
	cd wbg && meson --buildtype=release build && ninja -C build
	cp -f wbg/build/wbg ${HOME}/.local/bin/

dmenu-wayland:
	cd dmenu-wayland && meson --buildtype=release build && ninja -C build
	cp -f dmenu-wayland/build/dmenu-wl ${HOME}/.local/bin/
	cp -f dmenu-wayland/build/dmenu-wl_path ${HOME}/.local/bin/

noticat:
	cd noticat && DWLB_STRLEN=64 make
	cp -f noticat/noticat ${HOME}/.local/bin/
	
clean:
	rm -rf ${HOME}/.local/bin/dwl
	rm -rf ${HOME}/.local/bin/dwlb
	rm -rf ${HOME}/.local/bin/someblocks
	rm -rf ${HOME}/.local/bin/wbg
	rm -rf ${HOME}/.local/bin/dmenu-wl
	rm -rf ${HOME}/.local/bin/dmenu-wl_path
	rm -rf ${HOME}/.local/bin/noticat
	cd dwl && make clean
	cd dwlb && make clean
	cd someblocks && make clean
	rm -rf wbg/build
	rm -rf dmenu-wayland/build
	cd noticat && make clean

# init
pull: 
	ls -d */ | xargs -I {} bash -c "cd '{}' && git pull"

clone:
	git clone https://github.com/MuratovAS/dmenu-wayland
	git clone https://github.com/MuratovAS/dwl.git
	git clone https://github.com/MuratovAS/dwlb.git
	git clone https://github.com/MuratovAS/noticat
	git clone https://github.com/MuratovAS/someblocks
	git clone https://codeberg.org/dnkl/wbg

# debug
killall:
	killall dwl wbg dwlb someblocks noticat; echo "killall"

run:
#	make killall
	cd ${HOME}; dwl;

.SECONDARY:
.PHONY: mkdir dwl dwlb someblocks wbg dmenu-wayland noticat