#!bin/bash
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

create_partition_efi () {
  echo "Setting disk partition"

  echo -e "\tcreating EFI partition"
  sudo parted -s /dev/sda mklabel gpt mkpart ESP fat32 1MiB 261MiB set 1 esp on

  echo -e "\tcreating root partition"
  sudo parted -s /dev/sda mkpart primary ext4 261MiB 20GiB

  echo -e "\tcreating swap partition"
  sudo parted -s /dev/sda mkpart primary linux-swap 20GiB 24GiB

  echo -e "\tcreating home partition"
  sudo parted -s /dev/sda mkpart primary ext4 24GiB 100%
}

format_partitions () {
  echo "Formating partitions"
  sudo mkfs.vfat -F 32 /dev/sda1
  sudo mkfs.ext4 -F /dev/sda2
  sudo mkfs.ext4 -F /dev/sda4
}

enable_swap_partition () {
  echo "Enable swap partition"
  sudo mkswap /dev/sda3
  sudo swapon /dev/sda3
}

mount_partitions () {
  echo "Mounting root partition"
  mount /dev/sda2 /mnt
  mkdir /mnt/boot
  mount /dev/sda1 /mnt/boot
}

reflector_install () {
  pacman -S reflector --noconfirm
  cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
  reflector -c "BR" -f 12 -l 10 -n 12 --save /etc/pacman.d/mirrorlist
}

linux_install () {
  echo "Install essentials packages"
  pacman -Syy
  reflector_install
  pacstrap /mnt base linux linux-firmware networkManager
}

fstab_generate () {
  echo "Fstab generate..."
  genfstab -U /mnt >> /mnt/etc/fstab
}

arch_chroot () {
  echo "Changing root"
  cp 02-archlinux-install.sh /mnt/home
  arch-chroot /mnt bash  /mnt/home/02-archlinux-install.sh $root_password $username $password
}

read_credentials () {
  printf "Digite o nome para usuário: "
  read username

  printf "Digite a senha para $username: "
  read password

  printf "Digite a senha para o root: "
  read root_password
}

main () {
  # MAIN
  echo "ArchLinux 64 installing..."

  read_credentials

  set_locale
  set_datetime
  create_partition_efi
  format_partitions
  enable_swap_partition
  mount_partitions
  linux_install
  fstab_generate
  arch_chroot
  reboot now
}

main
