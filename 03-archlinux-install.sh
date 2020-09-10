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

desktopenviroment_install () {
  sudo pacman -S xf86-video-intel gnome --noconfirm
}

configure_displaymanager () {
  systemctl enable gdm.service
}

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

configure_keyboard_touchpad () {
  gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'br')]"

  gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
  gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true
}

networkManager_configure () {
  systemctl enable NetworkManager.service
  systemctl start NetworkManager.service
  nmcli device wifi connect $ssid password $passw
}

package_manager_install () {
  sudo pacman -S git --noconfirm

  cd /tmp
  # install asdf
  # to update asdf with (asdf update)
  git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.7.8
  echo -e "\n. $HOME/.asdf/asdf.sh" >> ~/.bashrc
  echo -e "\n. $HOME/.asdf/completions/asdf.bash" >> ~/.bashrc

  asdf update

  git clone https://aur.archlinux.org/snapd.git
  cd snapd
  makepkg -si --noconfirm
  sudo systemctl enable --now snapd.socket
  sudo ln -s /var/lib/snapd/snap /snap
}

install_apps () {
  sudo pacman -S firefox libreoffice-still --noconfirm
  install_app_google_chrome
}

install_app_google_chrome () {
  cd /tmp
  git clone https://aur.archlinux.org/google-chrome.git
  cd google-chrome
  makepkg -s
  packagename=$(ls | grep pkg.tar)
  sudo pacman -U $packagename --noconfirm
  cd ~
}

install_apps_dev () {
  sudo pacman -S code vim tmux nano alacritty git curl wget docker --noconfirm

  #git configure
  git config --global user.name "Fabricio Souza"
  git config --global user.email "fabricio.abner@gmail.com"

  #docker configure
  sudo usermod -aG docker $USER

  # install asdf-nodejs
  # to update plugins with (asdf plugin-update --all)
  asdf plugin-add nodejs https://github.com/asdf-vm/asdf-nodejs.git
  bash -c '${ASDF_DATA_DIR:=$HOME/.asdf}/plugins/nodejs/bin/import-release-team-keyring'

  asdf plugin-update --all

  # install nodejs 12.18.2 by asdf
  asdf install nodejs 12.18.2
  asdf global nodejs 12.18.2
  # inside folder can i?
  #asdf local nodejs [other version]

  sudo pacman -S yarn --noconfirm

  sudo snap install insomnia
}

remove_apps_defaults_unnecessary () {
  sudo pacman -R epiphany totem gnome-books gnome-boxes gnome-contacts gnome-documents gnome-maps gnome-photos gnome-music gnome-terminal gnome-weather orca simple-scan vino gnome-software gnome-calendar
}

create_ssh_key () {
  echo "SSH-KEY generate..."
  echo -e "$passphrase\n$passphrase" | (ssh-keygen -o -a 100 -t ed25519 -f ~/.ssh/id_ed25519 -C $key_comment)

  echo -e "\t add SSH-KEY to ssh-agent"
  echo -e "$passphrase" | (ssh-add ~/.ssh/id_ed25519)
}

main () {
  read_credentials
  desktopenviroment_install
  configure_displaymanager
  set_timezone
  set_locale
  set_hosts
  #keyboard_layout_setting_br
  networkManager_configure
  package_manager_install

  configure_keyboard_touchpad
  install_apps
  install_apps_dev
  remove_apps_defaults_unnecessary
}

main
