# Dotfiles
В этом репозитории вы найдете мой набор конфигураций `sway` и `artix`. Скорее это все одна большая инструкция по сборки системы, подобной моей.
Из основных преимуществ своей системы отмечу минималистичность, тривиальность в функционировании. А что касается моей реализации конфига sway, это возможность изменять глобальную цветовую тему и выверенное сочетание компонентов :)

![Альтернативный текст](/design/scr.png)

# Установка Artix (OpenRC) + Sway WN

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
mkfs.btrfs /dev/sda2

mkswap /dev/sda3 -L "swap" 
swapon /dev/sda3
```

Могут возникнуть проблемы с монтированием `btrfs`, для этого необходимо установить пакет
```bash
pacman -Syu btrfs-progs
```

Монтируем рабочие разделы
```bash
mount /dev/sda2 /mnt 
mkdir -p /mnt/boot/EFI
mount /dev/sda1 /mnt/boot/EFI
```

## Установка базовой системы

В качестве системы используем `OpenRC`, а так же `LTS` ядро.
В качестве системы управления сеансами будет использоваться `elogind`, можно заменить его на `seatd`. Стоит отметить `seatd` не поддерживает `polkit`, это может стать серьезной проблемой при запуске GUI приложений требующих привилегированного доступа. В таком случае придется запускать GUI приложения от `root`, что не безопасно и неудобно.
В зависимости от архитектуры целевой машины выберите `ucode`.
```bash
basestrap /mnt base base-devel openrc 
basestrap /mnt btrfs-progs linux-lts linux-lts-headers linux-firmware

basestrap /mnt intel-ucode iucode-tool
#basestrap /mnt amd-ucode iucode-tool

basestrap /mnt elogind elogind-openrc polkit-elogind
#basestrap /mnt seatd seatd-openrc #NOT support polkit
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
ln -sf /usr/share/zoneinfo/Asia/ГОРОД /etc/localtime
hwclock --systohc
```

Установим базовое ПО (необязательно)
```bash
pacman -S nano htop mc
```

Установим пакеты для управления сетевым соединением
```bash
pacman -S dhcpcd dhclient networkmanager networkmanager-openrc
```

Настройка языковых пакетов
```bash
sed '/en_US\.UTF-8/s/^#//' -i /etc/locale.gen
sed '/ru_RU\.UTF-8/s/^#//' -i /etc/locale.gen
echo "LANG=ru_RU.UTF-8" > /etc/locale.conf
locale-gen
```

Установка шрифта для tty, необходима для вывода кириллицы.
```bash
pacman -S terminus-font
echo -e '\nconsolefont="ter-v20b"' > /etc/conf.d/consolefont
rc-update add consolefont boot
```

Определение сетевого имени машины
```bash
echo "ИМЯХОСТА" > /etc/hostname
echo "127.0.0.1 localhost" > /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 ИМЯХОСТА.localdomine ИМЯХОСТА" >> /etc/hosts
```

## Настройка репозиториев

Установим поддержку `ArchLinux` репозиториев и AUR.
```bash
pacman -S artix-archlinux-support yay
```

Пропишешь в конфигурации `pacman` новые репозитории
```bash
echo "\n\
# Arch\n\
[extra]\n\
Include = /etc/pacman.d/mirrorlist-arch\n\
\n\
[community]\n\
Include = /etc/pacman.d/mirrorlist-arch\n\
\n\
[multilib]\n\
Include = /etc/pacman.d/mirrorlist-arch\n\
\n\
# Artix\n\
[universe]\n\
Server = https://universe.artixlinux.org/$arch\n\
Server = https://mirror1.artixlinux.org/universe/$arch\n\
Server = https://mirror.pascalpuffke.de/artix-universe/$arch\n\
Server = https://artixlinux.qontinuum.space:4443/artixlinux/universe/os/$arch\n\
Server = https://mirror1.cl.netactuate.com/artix/universe/$arch\n\
Server = https://ftp.crifo.org/artix-universe/\n\
" >> /etc/pacman.conf
```

Вот теперь нам понадобятся файлы из `xfce` редакции. Необходимо выйти из `chroot`.
```bash
exit
cp -r /etc/pacman.d/mirrorlist-arch /mnt/etc/pacman.d/mirrorlist-arch
```

Вернемся в окружение устанавливаемой системы
```bash
artix-chroot /mnt

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
pacman -S grub os-prober efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot/EFI --bootloader-id=grub  --removable
grub-mkconfig -o /boot/grub/grub.cfg
```


### Hibernation

1. A swap partition, say `/dev/sda...`
2. Add `resume` to HOOKS in `/etc/mkinitcpio.conf`
3. Add `resume=/dev/sda...SWAP` to GRUB_CMDLINE_LINUX in `/etc/default/grub`
4. Re-create initrd and grub.cfg: `grub-mkconfig -o /boot/grub/grub.cfg && mkinitcpio -p linux-lts`

Example:
```text
GRUB_CMDLINE_LINUX_DEFAULT="apparmor=1 security=apparmor resume=UUID=e862ad16-1d9d-4dde-9a21-50bc7ade0ea2 udev.log_priority=3 quiet"
```
Вам потребуется `UUID` его можно подсмотреть в `/etc/fstab` для вашего `swap`

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
echo -e '## Same thing without a password\n%wheel ALL=(ALL:ALL) NOPASSWD: /usr/bin/openrc-shutdown' >> /etc/profile
#echo -e '%wheel ALL=(ALL:ALL) NOPASSWD: /usr/bin/VBoxService' >> /etc/profile
```

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
sudo rc-update add elogind
sudo rc-service elogind start
#sudo rc-update add seatd
#sudo rc-service seatd start
#sudo usermod -aG seat ИМЯ
#sudo usermod -aG video ИМЯ
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
sudo pacman -S htop curl jq
```

Далее необходимо произвести распаковку ваших или моих `dotfiles` в домашнюю папку пользователя.
```bash
git clone https://github.com/MuratovAS/dotfiles.git
cp -r dotfiles/* ~/ && rm -rf ~/.git ~/design
```


Установим утилиты `xdg`, это позволит обеспечить ассоциацию файлов и добавить поддержку ярлыков. Пакет `xdg-user-dirs` необходим некоторым приложениям для доступа к стандартным каталогом. От него можно отказаться, вручную создав каталоги.
```bash
sudo pacman -S xdg-utils xdg-user-dirs
mkdir ~/Share ~/Download ~/Documents ~/Media
xdg-user-dirs-update --set DESKTOP ~/Media
xdg-user-dirs-update --set DOCUMENTS ~/Documents
xdg-user-dirs-update --set DOWNLOAD ~/Download
xdg-user-dirs-update --set MUSIC ~/Media
xdg-user-dirs-update --set PICTURES ~/Media
xdg-user-dirs-update --set PUBLICSHARE ~/Share
xdg-user-dirs-update --set TEMPLATES ~/Media
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
sudo pacman -S wqy-microhei ttf-nerd-font-symbols ttf-carlito ttf-caladea ttf-liberation ttf-roboto ttf-roboto-mono
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
sudo sudo pacman -S poweralertd # Уведомляет о состоянии питания

sudo pacman -S tlp tlp-openrc   # менеджер питания
sudo rc-service tlp restart
sudo rc-update add tlp 

#sudo pacman -S blueberry       # GUI bluetooth скорее всего нужно еще какой то демон запустить
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
echo "server 192.168.10.10 iburst" >> /etc/chrony.conf
sudo chronyc tracking
sudo chronyc sources
```

## Дополнительные пакеты

Данные пакеты используются в текущей конфигурации `sway`, но установка не обязательна
```bash
sudo pacman -S playerctl                # Управление медиа плиром из waybar
sudo pacman -S wf-recorder slurp grim   # Инструменты для снимков экрана
yay -S sway-xkb-switcher                # Позволяет сохранять раскладку каждого окна
yay -S sworkstyle                       # Отображает логотипы приложений открытых в WS
yay -S wlsunset                         # Ночный режим, фильтр синего цвета
sudo pacman -S khal                     # Календарь
khal configure
```

## Менеджеры тем

Большинство приложений реализуют интерфейс по средствам `qt` и `gtk`, данный набор пакетов позволяет глобально переключать цветовую гамму приложений
```bash
sudo pacman -S qt5-wayland
sudo pacman -S qt5ct kvantum xcursor-breeze
yay -S gtk3-nocsd matcha-gtk-theme kvantum-theme-matcha
```

Возможно вы будите использовать приложения на основе `electron`. Большинство приложений по умолчанию работают через `xwayland`, что не очень правильно. Так же это ограничивает разрешения изображения, и на HiDPI мониторе будет выглядеть печально. Данную проблему можно исправить файлом конфигурации, принудительно запускающий `wayland` версию приложения. В некоторых случаях требуется вручную создать файл для вашей версии `electron`.
```bash
ln -s ~/.config/electron-flags.conf ~/.config/electronXX-flags.conf
```

## ZSH как альтернатива BASH

Установка `zsh`
```bash
sudo pacman -Syu zsh
chsh -s $(which zsh)
```

Настройка `zsh` (выполнять не требуется, если скопировали мой dotfiles)
```bash
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
```
```bash
mv ~/.oh-my-zsh ~/.config/oh-my-zsh
sed -i 's@\.oh-my-zsh@\.config/oh-my-zsh@g' ~/.zshrc
sed -i 's@plugins=(git)@plugins=(git zsh-autosuggestions zsh-syntax-highlighting)@g' ~/.zshrc
sed -i 's@robbyrussell@agnoster@g' ~/.zshrc
sed -i '/mode disabled/s/^#//' ~/.zshrc
sed -i '/ prompt_context/s/^/#\ /' ~/.config/oh-my-zsh/themes/agnoster.zsh-theme
```

## Поддержка appimage

По моим предположениям AppImage должен работать из коробки, но встречаются случае когда приложение не запускается. У меня решилась проблема установкой недостающих компонентов `fuse`.
```bash
sudo pacman -S fuse-common fuse3 fuse2
```

## Немного о ПО

Полезные GUI приложения
```bash
sudo pacman -S pamac
sudo pacman -S gnome-disk-utility
sudo pacman -S nautilus
sudo pacman -S file-roller
yay -S timeshift
```

Полезные TUI приложения
```bash
sudo pacman -S micro 
sudo pacman -S mc
```

Набор приложений для просмотра медиа файлов
```bash
sudo pacman -S mpv imv zathura
sudo pacman -S zathura-pdf-poppler zathura-djvu
#sudo pacman -S ffmpeg ffmpegthumbnailer
```

Расширение поддержки устройств и форматов файлов
```bash
sudo pacman -S p7zip unrar
sudo pacman -S gvfs-mtp exfat-utils
```

Весьма специфичное ПО. В мой конфигурации используется файловый менеджер lf, с возможностью предпросмотр текстовых файлов. Устанавливается так:
```bash
sudo pacman -S lf bat glow
```

Мы используем терминал `foot` а он умеет выводить изображения. В некоторых случаях может быть полезным.
```bash
yay -S libsixel
```


## Что насчет принтера

В случае использования сетевого принтера достаточно установить `cups`, в случае использования usb принтера смотрите `archwiki`
```bash
sudo pacman -S avahi cups cups-pdf cups-openrc
sudo rc-service cupsd restart
sudo rc-update add cupsd 
```

К сожалению в зависимостях `cups` есть `avahi`, данный сервис позволяет искать устройства в локальной сети, в том числе принтеры. Раз он у нас уже установлен, можно его запустить :)
```bash
#sudo rc-service avahi-daemon restart
#sudo rc-update add avahi-daemon
```

Так же распространённый компонент `avahi` это `mdns`, вроде бы он используется при подключении к публичным Wifi. Я все же не рекомендую его ставить, это может снижать безопасность системы.
```bash
#sudo pacman -S nss-mdns
```

## Заметки

В процессе вы будите устанавливать приложения не совместимые с `OpenRC`, вам придется написать свои конфигурации для системы инициализации. В качестве примера можно использовать конфигурации `systemd`. Найти их можно тут:
```text
/usr/lib/systemd/
```