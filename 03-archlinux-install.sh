configure_keyboard_touchpad () {
  gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'br')]"

  gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
  gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true
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
  sudo pacman -S code vim tmux nano alacritty git curl docker --noconfirm

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

  install_apps_dev_snap

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
  configure_keyboard_touchpad
  install_apps
  install_apps_dev
  remove_apps_defaults_unnecessary
}

main
