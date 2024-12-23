sudo dd if=/dev/zero of=/swapfile bs=1MiB count=25KiB
sudo chmod 0600 /swapfile
sudo mkswap /swapfile
echo "/swapfile swap swap defaults 0 0" | sudo tee -a /etc/fstab
sudo swapon -a
free -g
sudo lsblk
sudo mkfs.ext4 -m 0 -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/sdb
sudo mkdir -p /mnt/disks/chaindata-disk
sudo mount -o discard,defaults /dev/sdb /mnt/disks/chaindata-disk
sudo chmod a+w /mnt/disks/chaindata-disk
sudo blkid /dev/sdb
export DISK_UUID=$(findmnt -n -o UUID /dev/sdb)
echo "UUID=$DISK_UUID /mnt/disks/chaindata-disk ext4 discard,defaults,nofail 0 2" | sudo tee -a /etc/fstab
df -h

sudo useradd -m ethereum
sudo usermod -aG sudo ethereum
sudo usermod -aG google-sudoers ethereum
