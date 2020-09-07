#bin/bash
keyboard_layout_setting_br () {
  echo "Setting keyboard layout to br-abnt2"
  localectl set-x11-keymap br pc104 abnt2
}

set_locale () {
  echo "Setting locale to pt_BR.UTF-8"
  sed -i 's/#pt_BR.UTF-8 UTF-8/pt_BR.UTF-8 UTF-8/g' /etc/locale.gen
  locale-gen
  export LANG=pt_BR.UTF-8  

  echo "LANG=pt_BR.UTF-8" >> /etc/locale.conf
  echo "KEYMAP=br-abnt2" >> /etc/vconsole.conf
}

set_datetime () {
  echo "Setting date time"
  timedatectl set-ntp true
}

set_timezone () {
  echo "Setting timezone to America/Sao_Paulo"
  ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
  hwclock --systohc
}

set_hosts () {
  echo "Setting hosts"
  echo "archlinux" > /etc/hostname

  echo "127.0.0.1	localhost.localdomain	localhost" >> /etc/hosts
  echo "::1		localhost.localdomain	localhost" >> /etc/hosts
  echo "127.0.1.1	archlinux.localdomain	archlinux" >> /etc/hosts
}

mkinitcpio_set_hooks_keymap () {
  echo "Setting mkinitcpio.conf add HOOK keymap"
  sed -i 's/fsck)/fsck keymap)/g' /etc/mkinitcpio.conf
  mkinitcpio -P
}

sudo_install_user_add () {
  echo "Configure user"

  root_password=$1
  username=$2
  password=$3

  useradd -m $username

  pacman -S sudo --noconfirm
  echo "$username ALL=(ALL:ALL) ALL" >> /etc/sudoers
  visudo -c

  echo -e "$password\n$password" | (passwd $username)
  echo -e "$root_password\n$root_password" | (passwd root)
}

systemd_boot_uefi_intel_ucode () {
  echo "Setting boot UEFI with intel-ucode"

  bootctl install
  pacman -S intel-ucode --noconfirm

  echo "default  arch" > /boot/loader/loader.conf
  echo "timeout 4" >> /boot/loader/loader.conf

  rootPARTUUID=$(blkid /dev/sda2 -s PARTUUID -o value)
  echo "title Arch Linux" > /boot/loader/entries/arch.conf
  echo "linux /vmlinuz-linux" >> /boot/loader/entries/arch.conf
  echo "initrd /intel-ucode.img" >> /boot/loader/entries/arch.conf
  echo "initrd /initramfs-linux.img" >> /boot/loader/entries/arch.conf
  echo "options root=PARTUUID=$rootPARTUUID rw" >> /boot/loader/entries/arch.conf
}

desktopenviroment_install () {
  sudo pacman -S xorg-server xorg-xinit xf86-video-intel --noconfirm
  sudo pacman -S gnome gnome-control-center gnome-system-monitor --noconfirm
  #sudo pacman -S budgie-desktop budgie-extras --noconfirm
}

configure_displaymanager () {
  systemctl enable gdm.service
}

networkManager_configure () {
  systemctl enable NetworkManager.service
  nmcli device wifi connect $ssid password $passw
}

wifi_connect () {
  echo "Setting network wifi"
  printf "Typing your SSID: "
  read -r ssid
  printf "Typing your password: "
  read -r passw
  nmcli device wifi connect $ssid password $passw
}

check_network_configure () {
  if [ "`ping -c 1 www.google.com.br`" ]
    then
      return 0
    else
      networkManager_configure
      wifi_connect
   fi
}

reflector_install () {
  pacman -S reflector --noconfirm
  cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
  reflector -c "BR" -f 12 -l 10 -n 12 --save /etc/pacman.d/mirrorlist
}

install_driver_touchpad () {
  pacman -S xf86-input-libinput xorg-xinput --noconfirm
}

create_autostart_profile_settings () {
  username=$1

  echo "setxkbmap br" >> /home/$username/.profile_settings.sh
  echo "xinput set-prop 'ELAN1200:00 04F3:303E Touchpad' 'libinput Tapping Enabled' 1" >> /home/$username/.profile_settings.sh
  chmod +x /home/$username/.profile_settings.sh

  mkdir -p /home/$username/.config/autostart
  echo "[Desktop Entry]" >> /home/$username/.config/autostart/profile_settings.desktop
  echo "Type=Application" >> /home/$username/.config/autostart/profile_settings.desktop 
  echo "Exec=/home/$username/.profile_settings.sh" >> /home/$username/.config/autostart/profile_settings.desktop 
  echo "Hidden=false" >> /home/$username/.config/autostart/profile_settings.desktop 
  echo "Terminal=false" >> /home/$username/.config/autostart/profile_settings.desktop 
  echo "Name=Profile-Settings" >> /home/$username/.config/autostart/profile_settings.desktop
}

read_credentials () {
  printf "Digite o nome para usuário: "
  read username

  printf "Digite a senha para $username: "
  read password

  printf "Digite a senha para o root: "
  read root_password

  printf "Rede Wifi SSID: "
  read -r ssid
  printf "Senha Wifi: "
  read -r passw
}

main () {
  read_credentials

  check_network_configure
  reflector_install
  mkinitcpio_set_hooks_keymap
  systemd_boot_uefi_intel_ucode
  desktopenviroment_install
  configure_displaymanager
  sudo_install_user_add $root_password $username $password
  set_timezone
  set_locale
  set_hosts
  keyboard_layout_setting_br
  networkManager_configure
  reboot
}

main
