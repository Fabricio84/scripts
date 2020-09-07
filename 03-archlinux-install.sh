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

main () {
    install_apps
    install_apps_dev
}