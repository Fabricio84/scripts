#bin/bash
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

main () {
  #reflector_install
  #mkinitcpio_set_hooks_keymap
  #systemd_boot_uefi_intel_ucode
  #sudo_install_user_add $root_password $username $password

  #exit 0
}

main
