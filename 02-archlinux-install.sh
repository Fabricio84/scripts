#bin/bash
keyboard_layout_setting_br () {
  echo "Setting keyboard layout to br-abnt2"
  loadkeys br-abnt2
  setxkbmap -model abnt2 -layout br
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

desktopenviroment_bugdie_install () {
  sudo pacman -S xorg-server xterm xorg-xinit xf86-video-intel --noconfirm
  sudo pacman -S budgie-desktop budgie-extras --noconfirm
}

displaymanager_gdm_install () {
  pacman -S gdm --noconfirm
  systemctl enable gdm.service
}

networkManager_configure () {
  systemctl enable networkManager.service
  systemctl restart networkManager.service
}

install_apps () {
  pacman -S pantheon-files firefox libreoffice-still --noconfirm
  install_app_google_chrome
}

install_app_google_chrome () {
  cd /tmp
  git clone https://aur.archlinux.org/google-chrome.git
  cd google-chrome
  makepkg -s
  packagename=$(ls | grep pkg.tar)
  pacman -U $packagename --noconfirm
  cd ~
}

install_apps_dev () {
  pacman -S code vim tmux nano alacritty git curl docker yarn --noconfirm

  #git configure
  git config --global user.name "Fabricio Souza"
  git config --global user.email "fabricio.abner@gmail.com"

  #docker configure
  sudo usermod -aG docker $USER

  # install asdf
  # to update asdf with (asdf update)
  git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.7.8
  echo -e "\n. $HOME/.asdf/asdf.sh" >> ~/.bashrc
  echo -e "\n. $HOME/.asdf/completions/asdf.bash" >> ~/.bashrc

  # install asdf-nodejs
  # to update plugins with (asdf plugin-update --all)
  asdf plugin-add nodejs https://github.com/asdf-vm/asdf-nodejs.git
  bash -c '${ASDF_DATA_DIR:=$HOME/.asdf}/plugins/nodejs/bin/import-release-team-keyring'

  # install nodejs 12.18.2 by asdf
  asdf install nodejs 12.18.2
  asdf global nodejs 12.18.2
  # inside folder can i?
  #asdf local nodejs [other version]

  install_apps_dev_snap

  sudo snap install insomnia
}

install_apps_dev_snap () {
  cd /tmp
  git clone https://aur.archlinux.org/snapd.git
  cd snapd
  makepkg -si --noconfirm
  sudo systemctl enable --now snapd.socket
  sudo ln -s /var/lib/snapd/snap /snap
}

create_ssh_key () {
  echo "SSH-KEY generate..."
  echo -e "$passphrase\n$passphrase" | (ssh-keygen -o -a 100 -t ed25519 -f ~/.ssh/id_ed25519 -C $key_comment)

  echo -e "\t add SSH-KEY to ssh-agent"
  echo -e "$passphrase" | (ssh-add ~/.ssh/id_ed25519)
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
  check_network_configure
  reflector_install
  set_timezone
  set_locale
  set_hosts
  keyboard_layout_setting_br
  mkinitcpio_set_hooks_keymap
  systemd_boot_uefi_intel_ucode
  desktopenviroment_bugdie_install
  displaymanager_gdm_install
  term_alacritty_install_settings
  sudo_install_user_add $1 $2 $3
  install_driver_touchpad
  create_autostart_profile_settings $2
  install_apps_dev
  install_apps
  networkManager_configure
  wifi_connect
  reboot
}

main $1 $2 $3

