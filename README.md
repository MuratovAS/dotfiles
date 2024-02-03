# Dotfiles
В этом репозитории вы найдете мой набор конфигураций `sway` и `artix`. Скорее это все одна большая инструкция по сборки системы, подобной моей.
Из основных преимуществ своей системы отмечу минималистичность, тривиальность в функционировании. А что касается моей реализации конфига sway, это возможность изменять глобальную цветовую тему и выверенное сочетание компонентов :)

![Альтернативный текст](./design/scr.png)

Автор в какой-то момент ~~поплыл кукухой,~~ начал использовать `dwl`. Информацию можно найти в [branch dwl](https://github.com/MuratovAS/dotfiles/tree/artix-dwl).

# Установка Artix (OpenRC) + Sway WM

Для установки системы нам потребуется USB накопитель с предварительно записанным artix linux xfce4. Редакция с графическим интерфейсом упростит дальнейшую работу, позволит использовать буфер обмена и GUI для проверки корректности разметки диска.

После загрузки с USB откроем терминал и перейдем под ROOT

```bash
sudo su
```

## Разметка диска

В первую очередь необходимо создать разметку ФС (в нашем случае `GPT`).
Установку системы будем производить на ssd, в качестве корневой системы будим использовать `btrfs`, позволяющую использовать снепшоты.
Ориентировочная структура разделов:

```text
0. efi     = 512M
1. /       = main
2. swap    = RAM + 1-4Gb
3. free    = 5% disk size
```

Для создания разметки воспользуемся командой
```bash
cfdisk /dev/sda
```

Форматируем разделы, создаем файл подкачки
```bash
mkfs.vfat /dev/sda1

mkswap /dev/sda3 -L "swap" 
swapon /dev/sda3

mkfs.btrfs /dev/sda2
mount /dev/sda2 /mnt
cd /mnt
btrfs subvolume create _active
btrfs subvolume create _active/rootvol
btrfs subvolume create _active/homevol
#btrfs subvolume create _active/docker
#btrfs subvolume create _active/libvirt
btrfs subvolume create _snapshots
```

Монтируем рабочие разделы
```bash
cd ..
umount /mnt
mount -o subvol=_active/rootvol /dev/sda2 /mnt
mkdir /mnt/{home,boot,var}
mkdir /mnt/boot/efi
#mkdir /mnt/var/lib/docker
#mkdir /mnt/var/lib/libvirt
mkdir /mnt/mnt/defvol
mount /dev/sda1 /mnt/boot/efi
#mount -o subvol=_active/docker /dev/sda2 /mnt/var/lib/docker
#mount -o subvol=_active/libvirt /dev/sda2 /mnt/var/lib/libvirt
mount -o subvol=_active/homevol /dev/sda2 /mnt/home
mount -o subvol=/ /dev/sda2 /mnt/mnt/defvol
```

<details>
<summary>Альтернативная разметка</summary>
Данная разметка должна поддерживаться timeshift. Не проверял.

Форматируем разделы, создаем файл подкачки
```bash
mkfs.vfat /dev/sda1

mkswap /dev/sda3 -L "swap" 
swapon /dev/sda3

mkfs.btrfs /dev/sda2
mount /dev/sda2 /mnt
cd /mnt
btrfs subvolume create @
btrfs subvolume create @home
btrfs subvolume create @log
btrfs subvolume create @cache
```

Монтируем рабочие разделы
```bash
cd ..
umount /mnt
mount -o subvol=@ /dev/sda2 /mnt
mkdir /mnt/{home,boot,var}
mkdir /mnt/boot/efi
mkdir /mnt/var/cache
mkdir /mnt/var/log
mount /dev/sda1 /mnt/boot/efi
mount -o subvol=/@ /dev/sda2 /mnt/
mount -o subvol=/@home /dev/sda2 /mnt/home
mount -o subvol=/@log /dev/sda2 /mnt/var/log
mount -o subvol=/@cache /dev/sda2 /mnt/var/cache
```
</details>

## Установка базовой системы

В качестве системы используем `OpenRC`, а так же `LTS` ядро.
В качестве системы управления сеансами будет использоваться `elogind`, можно заменить его на `seatd`. Стоит отметить `seatd` не поддерживает `polkit`, это может стать серьезной проблемой при запуске GUI приложений требующих привилегированного доступа. В таком случае придется запускать GUI приложения от `root`, что не безопасно и неудобно.
В зависимости от архитектуры целевой машины выберите `ucode`.
```bash
basestrap /mnt base base-devel openrc 
# elogind-openrc polkit polkit-qt5 polkit-gnome
# seatd-openrc #NOT support polkit
basestrap /mnt btrfs-progs linux-lts linux-lts-headers linux-firmware

#basestrap /mnt intel-ucode iucode-tool
basestrap /mnt amd-ucode iucode-tool

basestrap /mnt vulkan-radeon radeontop

```

Создание файла с информацией о разделах
```bash
fstabgen -U /mnt >> /mnt/etc/fstab
```

## Настройка базовой системы

Перейдем в корневой каталог будущей нашей системы
```bash
artix-chroot /mnt
```

Конфигурация часового пояса.
В данном примере `hwclock` позволит установить время по аппаратным часам
```bash
ln -sf /usr/share/zoneinfo/Asia/ГОРОД /etc/timezone
hwclock --systohc
```

Установим базовое ПО (необязательно)
```bash
pacman -S nano htop
```

Установим пакеты для управления сетевым соединением
```bash
pacman -S dhcpcd dhclient networkmanager networkmanager-openrc
```

Настройка языковых пакетов
```bash
#sed '/en_US\.UTF-8/s/^#//' -i /etc/locale.gen
sed '/ru_RU\.UTF-8/s/^#//' -i /etc/locale.gen
echo "LANG=ru_RU.UTF-8" > /etc/locale.conf
locale-gen
```

Установка шрифта для tty, необходима для вывода кириллицы.
```bash
pacman -S terminus-font
echo -e '\nconsolefont="ter-v20b"' > /etc/conf.d/consolefont
#sudo rc-update add consolefont boot
```

Определение сетевого имени машины
```bash
echo "ИМЯХОСТА" > /etc/hostname
echo "127.0.0.1 localhost" > /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 ИМЯХОСТА.localdomine ИМЯХОСТА" >> /etc/hosts
```

## Настройка репозиториев

Пропишешь в конфигурации `pacman` новые репозитории. Добавить в /etc/pacman.conf
```bash
# Artix
[universe]
Server = https://universe.artixlinux.org/\$arch
Server = https://mirror1.artixlinux.org/universe/\$arch
Server = https://mirror.pascalpuffke.de/artix-universe/\$arch
Server = https://artixlinux.qontinuum.space:4443/artixlinux/universe/os/\$arch
Server = https://mirror1.cl.netactuate.com/artix/universe/\$arch
Server = https://ftp.crifo.org/artix-universe/
```

Установим поддержку `ArchLinux` репозиториев и AUR.
```bash
pacman -S artix-archlinux-support yay
```

Пропишешь в конфигурации `pacman` новые репозитории. Добавить в /etc/pacman.conf
```bash
# Arch
[extra]
Include = /etc/pacman.d/mirrorlist-arch

[community]
Include = /etc/pacman.d/mirrorlist-arch

[multilib]
Include = /etc/pacman.d/mirrorlist-arch
```

Обновим репозитории
```bash
pacman -Sy archlinux-keyring artix-keyring
rm -r /etc/pacman.d/gnupg
pacman-key --init
pacman-key --populate archlinux artix
pacman -Scc
pacman -Syyu
```
Так же данными командами можно исправить ошибку `Invalid or corrupted packages (PGP signature)`

## Установка загрузчика

### GRUB

```bash
mkinitcpio -p linux-lts
pacman -S grub os-prober efibootmgr grub-btrf
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=grub  --removable
grub-mkconfig -o /boot/grub/grub.cfg
```

Установка темы
```bash
git clone https://github.com/vinceliuice/grub2-themes.git
cd grub2-themes
sudo ./install.sh -b -t tela -i white -s 1080p
cd .. && rm -rf grub2-themes
```

## Настройка пользователя

Не забываем задать пароль `root`
```bash
passwd
```

Создаем пользователя
```bash
useradd -m -G wheel -s /bin/bash ИМЯ
passwd ИМЯ
```

Отключаем пароль sudo для `wheel`. А так же отключи запрос пароля для `openrc-shutdown` это позволит управлять питанием из WM
```bash
sed '/%wheel ALL=(ALL:ALL) ALL/s/^#//' -i /etc/sudoers
echo -e '## Same thing without a password\n%wheel ALL=(ALL:ALL) NOPASSWD: /usr/bin/openrc-shutdown' >> /etc/sudoers
echo -e '%wheel ALL=(ALL:ALL) NOPASSWD: /usr/bin/rc-service' >> /etc/sudoers
echo -e '%wheel ALL=(ALL:ALL) NOPASSWD: /usr/bin/libinput' >> /etc/sudoers
#echo -e '%wheel ALL=(ALL:ALL) NOPASSWD: /usr/bin/VBoxService' >> /etc/sudoers
```

### Hibernation

1. A swap partition, say `/dev/sda...`
2. Add `resume` to HOOKS in `/etc/mkinitcpio.conf`
3. Add `resume=/dev/sda... SWAP` to GRUB_CMDLINE_LINUX in `/etc/default/grub`
4. Re-create initrd and grub.cfg: `grub-mkconfig -o /boot/grub/grub.cfg && mkinitcpio -p linux-lts`

Example:
```text
GRUB_CMDLINE_LINUX_DEFAULT="apparmor=1 security=apparmor resume=UUID=e862ad16-1d9d-4dde-9a21-50bc7ade0ea2 udev.log_priority=3 quiet"
```
Вам потребуется `UUID` его можно подсмотреть в `/etc/fstab` для вашего `swap`

## Завершение установки базового образа

На данном этапе можно считать установку оконченной. Далее завершаем работу, перезагружаемся в установленную систему.
```bash
exit
umount -R /mnt
reboot
```

## Подготовка рабочего окружения

Запустим сервис обеспечивающий авторизацию в системе
```bash
#elogind
sudo rc-update add elogind
sudo rc-service elogind start

#нужен для упровления подсветкой
sudo usermod -aG video ИМЯ

#seatd
#sudo rc-update add seatd
#sudo rc-service seatd start
#sudo usermod -aG seat ИМЯ
```

Пропишем в системный `enviroment` выбранный в прошлом пункте LM
```bash
echo "LIBSEAT_BACKEND=logind" >> /etc/enviroment
```

Добавим возможность использовать `.profile` для пользовательских `env`. А так же возможность добавлять пользовательские бинарные приложения.
```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' > /etc/profile.d/home-local-bin.sh
echo -e '# Load profile from home\n[[ -f $HOME/.profile ]] && . $HOME/.profile' >> /etc/profile
```

## Установка Sway

Установим `sway` и терминал `foot`
Стоит отметить что `jq` используется в некоторых скриптах WM, по этой причине он внесет список необходимых.
```bash
sudo pacman -S foot
sudo pacman -S sway swaybg waybar swayidle mako wl-clipboard wofi
sudo yay -S swaylock-effects-git 
```

Для функционирования и настройки WM нам потребуются
```bash
sudo pacman -S curl jq git
```

Далее необходимо произвести распаковку ваших или моих `dotfiles` в домашнюю папку пользователя.
```bash
git clone https://github.com/MuratovAS/dotfiles.git
cp -r dotfiles/* ~/ && rm -rf ~/.git ~/design
```


Установим утилиты `xdg`, это позволит обеспечить ассоциацию файлов и добавить поддержку ярлыков. Пакет `xdg-user-dirs` необходим некоторым приложениям для доступа к стандартным каталогом. От него можно отказаться, вручную создав каталоги.
```bash
sudo pacman -S xdg-utils xdg-user-dirs
mkdir ~/Share ~/Download ~/Documents ~/Media ~/Templates
xdg-user-dirs-update --set DESKTOP ~/Media
xdg-user-dirs-update --set DOCUMENTS ~/Documents
xdg-user-dirs-update --set DOWNLOAD ~/Download
xdg-user-dirs-update --set MUSIC ~/Media
xdg-user-dirs-update --set PICTURES ~/Media
xdg-user-dirs-update --set PUBLICSHARE ~/Share
xdg-user-dirs-update --set TEMPLATES ~/Templates
xdg-user-dirs-update --set VIDEOS ~/Media
```

## Установка pipewire

Установим `pipewire` с базовыми дополнениями и TUI менеджер `pulsemixer`
```bash
sudo pacman -S pipewire-alsa pipewire pipewire-jack pipewire-pulse pipewire-media-session pamixer pulsemixer
```

## Поддержка xwayland

Если вам требуется поддержка `xorg` приложений. Удалить ее будет невозможно!
```bash
sudo pacman -S xorg-xwayland
sed '/xwayland/s/^/#\ /' -i ~/.config/sway/config
```

## Поддержка screancast

```bash
sudo pacman -S xdg-desktop-portal xdg-desktop-portal-wlr
```

## Шрифты

```bash
sudo pacman -S ttf-nerd-fonts-symbols wqy-microhei ttf-carlito ttf-caladea ttf-liberation ttf-roboto ttf-roboto-mono
yay -S ttf-material-design-icons-webfont 
```
Обновление кэша шрифтов
```bash
fc-cache -f -v
fc-list
```

## Все что может пригодиться на ноутбуке

```bash
sudo pacman -S light            # Управляет подсветкой
yay -S poweralertd              # Уведомляет о состоянии питания
sudo pacman -S tlp tlp-openrc   # менеджер питания
yay -S tlpui
sudo rc-service tlp restart
sudo rc-update add tlp 

sudo pacman -S libinput         # Автоматизация клавиш мыши 

sudo pacman -S bluez bluez-utils
sudo pacman -S bluetuith  # TUI bluetooth
#sudo pacman -S blueberry  # GUI bluetooth
sudo usermod -aG rfkill ИМЯ
sudo usermod -aG lp ИМЯ
sudo rc-service bluetoothd restart
sudo rc-update add bluetoothd
```

### Синхронизация времени и даты

Установка `chrony`, позволит синхронизировать время с NTP сервером
```bash
sudo pacman -S chrony chrony-openrc
sudo rc-service chrony restart
sudo rc-update add chrony 
```

По необходимости можно добавить свой сервер и проверить работоспособность
```bash
echo "server ntp.local iburst" >> /etc/chrony.conf
chronyc tracking
chronyc sources
```

## Дополнительные пакеты

Данные пакеты используются в текущей конфигурации `sway`, но установка не обязательна
```bash
sudo pacman -S playerctl                        # Управление медиа плиром из waybar
sudo pacman -S wf-recorder slurp grim swappy    # Инструменты для снимков экрана
yay -S sway-xkb-switcher                        # Позволяет сохранять раскладку каждого окна
yay -S sworkstyle                               # Отображает логотипы приложений открытых в WS
yay -S wlsunset                                 # Ночный режим, фильтр синего цвета
sudo pacman -S khal                             # Календарь
sudo pacman -S gnome-keyring                    # Систума управления ключами (необходима для многих приложений)
khal configure
```

## Менеджеры тем

Большинство приложений реализуют интерфейс по средствам `qt` и `gtk`, данный набор пакетов позволяет глобально переключать цветовую гамму приложений
```bash
sudo pacman -S qt5-wayland
sudo pacman -S qt5ct kvantum xcursor-breeze
yay -S gtk3-nocsd matcha-gtk-theme kvantum-theme-matcha # (НЕ kvantum-theme-matcha-git)
```

Возможно вы будите использовать приложения на основе `electron`. Большинство приложений по умолчанию работают через `xwayland`, что не очень правильно. Так же это ограничивает разрешения изображения, и на HiDPI мониторе будет выглядеть печально. Данную проблему можно исправить файлом конфигурации, принудительно запускающий `wayland` версию приложения. В некоторых случаях требуется вручную создать файл для вашей версии `electron`.
```bash
ln -s ~/.config/electron-flags.conf ~/.config/electron12-flags.conf
ln -s ~/.config/electron-flags.conf ~/.config/electron13-flags.conf
ln -s ~/.config/electron-flags.conf ~/.config/electron18-flags.conf
```

## ZSH как альтернатива BASH

Установка `zsh`
```bash
sudo pacman -Syu zsh
chsh -s $(which zsh)
```

Настройка `zsh` (выполнять не требуется, если скопировали мой dotfiles)
```bash
mv ~/.oh-my-zsh ~/.config/oh-my-zsh
sed -i 's@\.oh-my-zsh@\.config/oh-my-zsh@g' ~/.zshrc
sed -i 's@plugins=(git)@plugins=(git zsh-autosuggestions zsh-syntax-highlighting)@g' ~/.zshrc
sed -i 's@robbyrussell@agnoster@g' ~/.zshrc
sed -i '/mode disabled/s/^#//' ~/.zshrc
sed -i '/ prompt_context/s/^/#\ /' ~/.config/oh-my-zsh/themes/agnoster.zsh-theme
```

```bash
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-.config/oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-.config/oh-my-zsh/custom}/plugins/zsh-autosuggestions
```

## Поддержка appimage

По моим предположениям AppImage должен работать из коробки, но встречаются случаи когда приложение не запускается. У меня решилась проблема установкой недостающих компонентов `fuse`.
```bash
sudo pacman -S fuse-common fuse3 fuse2
```

## Немного о ПО

Полезные GUI приложения
```bash
sudo pacman -S pamac
sudo pacman -S gnome-disk-utility
sudo pacman -S nautilus
yay -S nautilus-open-any-terminal
sudo pacman -S file-roller
yay -S buttermanager
```

Полезные TUI приложения
```bash
sudo pacman -S micro mc
```

Набор приложений для просмотра медиа файлов
```bash
sudo pacman -S mpv imv zathura f3d
sudo pacman -S zathura-pdf-poppler zathura-djvu
#sudo pacman -S ffmpeg ffmpegthumbnailer
```

Расширение поддержки устройств и форматов файлов
```bash
sudo pacman -S ntfs-3g
sudo pacman -S p7zip unrar
sudo pacman -S gvfs-mtp exfat-utils
```

Весьма специфичное ПО. В мой конфигурации используется файловый менеджер lf, с возможностью предпросмотр текстовых файлов. Устанавливается так:
```bash
sudo pacman -S bat glow chafa
yay -S lf-sixel-git
```

## Что насчет принтера

В случае использования сетевого принтера достаточно установить `cups`, в случае использования usb принтера смотрите `archwiki`
```bash
sudo pacman -S avahi cups cups-pdf cups-openrc
sudo rc-service cupsd restart
sudo rc-update add cupsd 
```

Так же распространённый компонент `avahi` это `mdns`, вроде бы он используется при подключении к публичным Wifi. Я все же не рекомендую его ставить, это может снижать безопасность системы.
```bash
#sudo pacman -S nss-mdns
```

В случае проблем с доступом к домену *.local, необходимо убрать `[NOTFOUND=return]` в `/etc/nsswitch.conf `


## Заметки

В процессе вы будите устанавливать приложения не совместимые с `OpenRC`, вам придется написать свои конфигурации для системы инициализации. В качестве примера можно использовать конфигурации `systemd`. Найти их можно тут:
```text
/usr/lib/systemd/
```

### Проброс настроек пользователя в root

```bash
rm -r /root/.config/mc
ln -s /home/muratovas/.config/mc /root/.config/mc

rm -r /root/.config/micro
ln -s /home/muratovas/.config/micro /root/.config/micro
```

### Проблемы с запуском приложений через wofi

Ярлыки ака. `.desktop` можно найти в каталоге:
```bash
/usr/share/applications/NAME.desktop 
~/.local/share/applications/NAME.desktop 
```

По умолчанию wofi не умеет запускать терминальные приложения, исправить это можно удалением опции `Terminal=true`.
А так же потребуется указать терминал `Exec=foot APP`

### agetty autologin 

`/etc/conf.d/agetty.tty1`

```bash
agetty_options="-J -a ИМЯ"
```

### Disconnect CPU Boost AMD

`/etc/init.d/tlp`

```
start()   { echo "passive" > /sys/devices/system/cpu/amd_pstate/status; echo 0 > /sys/devices/system/cpu/cpufreq/boost; /usr/bin/tlp init start; }
```

### Running GUI applications as root

A more versatile —though much less secure— workaround is to use xhost to temporarily allow the root user to access the local user's X session[5]. To do so, execute the following command as the current (unprivileged) user: 

```bash
xhost si:localuser:root
```
To remove this access after the application has been closed: 

```bash
xhost -si:localuser:root
```

### gtk themes

В недавнее время было замечено, что gtk4 не применяет установленную тему через `.config/gtk-4.0`. Решением было прописывать ее в `.profile`. 

Наблюдаются проблемы с применением темы курсора, решения не нашел.

