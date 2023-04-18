#!/bin/bash
set -euxo pipefail

user=alex
useradd -m "$user"
usermod -s /bin/bash "$user"
usermod -aG sudo "$user"
sed -i 's/%sudo.*ALL=(ALL:ALL) ALL/%sudo  ALL=(ALL:ALL) NOPASSWD:ALL/g' /etc/sudoers

mkdir /home/"$user"/.ssh
chmod 0700 /home/"$user"/.ssh
cat << EOF > /home/"$user"/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA4SsAHSYyz7NtTxf60uGmeG/vevxuVKgToEvoUwwy7kw1CU5qF8xUXsns8/ty8KbDuW1EXMTfjmm0ZRR5LAlxxDgAuZhK/hpyut5R+M0n/J36LzTMBcFn4KtDOF5CmODgkeP6T4n0m8wfFNzFyGIA6sX64s/ej70SKGFR0Qc0T0HGNea2Lt3H6oU4Mfh4DieM537/gqiDYgqD5ylQYRS1daiXbt2POpyuFjzIJiNq571UzPqt5HynHWXcoCwwblzCPit60Ioof+YsJ+D4TSfLLk3ALXf38MZBzaLFa6Mc3tmae/zYO9cLTg7edoX58VVrzIXQiBx+jDuJ6J81wwedAQ==
EOF

chmod 0644 /home/"$user"/.ssh/authorized_keys
chown -R "${user}":"${user}" /home/"$user"/.ssh

setup_basic_dotfiles() {
  if [[ "$1" == 'root' ]]; then
    path=/root
  else
    path=/home/"$1"
  fi

  cp /etc/skel/.bashrc "$path"/
  chown "${1}":"${1}" "$path"/.bashrc
  cat << EOF >> "$path"/.bashrc
  export EDITOR=/usr/bin/vim
EOF

  if [[ "$1" == 'root' ]]; then
    sed -i 's|32m|31m|g' "$path"/.bashrc 
  fi

  cat << EOF >> "$path"/.bash_aliases
  alias ll='ls -l'
EOF

  chown "${1}":"${1}" "$path"/.bash_aliases
  
  cat << EOF > "$path"/.vimrc
  syntax on
  set background=light
  set nohlsearch
  set ignorecase
  set expandtab
  set softtabstop=2
  set shiftwidth=2
EOF

  chown "${1}":"${1}" "$path"/.vimrc
  
}

setup_basic_dotfiles "$user"
setup_basic_dotfiles root

update_sshd_conf() {
  config_name="${1% *}"
  grep -q "$config_name" /etc/ssh/sshd_config && sed -i "s/[#]\?${config_name}.*//g" /etc/ssh/sshd_config
  echo "$1" >> /etc/ssh/sshd_config 
}

update_sshd_conf 'PubkeyAuthentication yes'
update_sshd_conf 'PasswordAuthentication no'
update_sshd_conf 'AllowTcpForwarding yes'
update_sshd_conf 'PermitRootLogin no'
update_sshd_conf 'AllowAgentForwarding yes'
systemctl reload sshd

> /etc/motd
