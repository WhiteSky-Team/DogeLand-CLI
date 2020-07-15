# DogeLand CLI
# v2.1.1
# 
# license: GPL-v2.0
#
VERSION=2.1.1_BETA
#
# Common
#
msg()
{
    echo "$@"
}
platform()
{
    local arch="$1"
    if [ -z "${arch}" ]; then
        arch=$(uname -m)
    fi
    case "${arch}" in
    arm64|aarch64)
        msg "arm_64"
    ;;
    arm*)
        msg "arm"
    ;;
    x86_64|amd64)
        msg "x86_64"
    ;;
    i[3-6]86|x86)
        msg "x86"
    ;;
    *)
        msg "unknown" && exit 255
    ;;
    esac
}
selinux_inactive()
{
    if [ -e "/sys/fs/selinux/enforce" ]; then
        return $(cat /sys/fs/selinux/enforce)
    else
        return 0
    fi
}
loop_support() {
    if [ -n "$(losetup -f)" ]; then
        return 1
    else
        return 0
    fi
}
#
# Core
#
check_rootfs(){
if [ -d "$rootfs" ];then
  msg "">/dev/null
  else
  msg "- / ...fail "
  exit 255
fi
}
# mount
mount_part(){
if [ -d "$rootfs/proc/1/" ];then
 msg "">/dev/null
  else
 msg "- /proc ..."
   mount -o bind /proc $rootfs/proc
fi
if [ -d "$rootfs/sys/kernel/" ];then
 msg "">/dev/null
  else
 msg "- /sys ..."
  mount -o bind /sys $rootfs/sys
fi
if [ -d "$rootfs/sdcard/" ];then
  msg "">/dev/null
  else
  msg "- /sdcard ..."
  mount -o bind $SDCARD_PATH $rootfs/mnt
fi
if [ -d "$rootfs/dev/block/" ];then
  msg "">/dev/null
  else
  msg "- /dev ..."
  mount -o bind /dev/ $rootfs/dev
fi
msg "- /dev/shm ..."
mount -o bind /dev/shm $rootfs/dev/shm
msg "- /dev/pts ..."
mount -o bind /dev/pts $rootfs/dev/pts

if [ ! -e "/dev/tty0" ]; then
  msg "">/dev/null
  else
  msg "- /dev/tty ... "
  ln -s /dev/null /dev/tty0
fi

}

# umount
umount_part(){
umount $rootfs/proc
umount $rootfs/sys
umount $rootfs/dev/pts
umount $rootfs/dev/shm
umount $rootfs/dev
umount $rootfs/mnt
}
# loop

#
# Loader
#
set_env(){
unset TMP TEMP TMPDIR LD_PRELOAD LD_DEBUG
HOME=/root
LANG=C.UTF-8
PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/games:/usr/local/games
PATH=$PATH:$addpath
}

start_chroot(){
check_rootfs
mount_part
set_env
$TOOLKIT/busybox chroot $addcmd $rootfs $cmd
msg "- All Done"
sleep 1
}

start_auto(){
check_rootfs
msg
if [ `id -u` -eq 0 ];then
   start_chroot
   exit
else
   msg "">/dev/null
fi
if [ -f "/data/data/com.termux/files/usr/bin/proot" ];then
  start_proot_termux
  exit
  else
  start_proot
  exit
fi
sleep 1
}

start_proot(){
check_rootfs
set_env
$TOOLKIT/proot $addcmd -0 -r $rootfs -b /dev -b /proc -b /sys -b /sdcard -b $rootfs/root:/dev/shm  -w /root $cmd 
msg "- Done"
sleep 1
}

start_proot_termux(){
check_rootfs
if [ -f "/data/data/com.termux/files/usr/bin/proot" ];then
  msg ""
  else
  msg "- 不支持的操作"
  exit 255
fi
set_env
/data/data/com.termux/files/usr/bin/proot $addcmd -0 -r $rootfs -b /dev -b /proc -b /sys -b /sdcard -b $rootfs/root:/dev/shm  -w /root $cmd 
msg "- Done"
sleep 1
}

stop_rootfs(){
pkill sshd
pkill proot
pkill busybox
pkill bash
pkill sh
}
#
# Linux Exec
#

exec_chroot(){
check_rootfs
mount_part
set_env
msg "- Pushing"
msg "$cmd2">$rootfs/runcmd.sh
chmod 0777 $rootfs/runcmd.sh
msg
msg
msg "- Running"
msg
msg
if [ -f "$rootfs/bin/su" ];then
$TOOLKIT/chroot "$rootfs" /bin/su -c $userid /runcmd.sh
else
if [ -f "$rootfs/bin/sh" ];then
$TOOLKIT/chroot "$rootfs" /bin/sh /runcmd.sh
else
if [ -f "$rootfs/bin/ash" ];then
$TOOLKIT/chroot "$rootfs" /bin/ash /runcmd.sh
else
if [ -f "$rootfs/bin/bash" ];then
$TOOLKIT/chroot "$rootfs" /bin/bash /runcmd.sh
else
msg "不支持的操作"
msg
fi
msg
fi
msg
fi
msg
fi
msg
msg "- Cleaning"
rm $rootfs/runcmd.sh
}

exec_auto(){
msg
check_rootfs
if [ `id -u` -eq 0 ];then
   exec_chroot
   exit
else
   msg "">/dev/null
fi
if [ -f "/data/data/com.termux/files/usr/bin/" ];then
  exec_proot_termux
  exit
  else
  exec_proot
  exit
fi
sleep 1
}

exec_proot(){
check_rootfs
set_env
msg
msg "- Running"
msg ""
$TOOLKIT/proot -0 -r $rootfs -b /dev -b /proc -b /sys -b /sdcard -b $rootfs/root:/dev/shm  -w /root $cmd2
msg
}

exec_proot_termux(){
check_rootfs
if [ -f "/data/data/com.termux/files/usr/bin/proot" ];then
  msg ""
  else
  msg "- 不支持的操作"
  exit 255
fi
set_env
msg "- Pushing"
msg "$cmd2">$rootfs/runcmd.sh
chmod 755 $rootfs/runcmd.sh
msg
msg "- Running"
msg ""
/data/data/com.termux/files/usr/bin/proot -0 -r $rootfs -b /dev -b /proc -b /sys -b /sdcard -b $rootfs/root:/dev/shm  -w /root /bin/su -c $userid /runcmd.sh
msg
msg "- Cleaning"
rm $rootfs/runcmd.sh
}

exec_localshell(){
msg
$cmd2
}
#
# Other
#
deploy_linux(){

}

rm_rootfsdir() {
msg "- 正在取消挂载"
umount
msg "- 正在删除"
rm -rf $rootfs/*
msg "- 删除完成"
}

help() {
cat <<HELP

USAGE:
   service.sh COMMAND ...

COMMANDS:
   [...] 
   
   start_chroot: 使用chroot启动Linux
   start_proot: 使用proot启动Linux
   
   exec_chroot: 使用chroot运行Linux命令
   exec_proot: 使用proot运行Linux命令
   
   set_env: 设置Linux运行环境
   
HELP
}

about()
{
cat <<ABOUT

DogeLand Service
版本: $VERSION

本应用程序安装指定的 GNU / Linux 发行版 , 并在chroot或proot容器中运行.

 https://github.com/Flytreels/LinuxLoader

license: GPL-v2

ABOUT
}

#
# Linux
#

#
# sshd
#
sshd_start()
{
msg "- sshd::start..."
if [ $(ls "/etc/ssh/" | grep -c key) -eq 0 ]; then
   ssh-keygen -A >/dev/null
fi
rm -rf /run/sshd
rm -rf /var/run/sshd
mkdir /run/sshd /var/run/sshd
ssh-keygen -A
/usr/sbin/sshd -p 22
}

sshd_stop()
{
msg "- sshd::stop..."
kill -9 /run/sshd.pid /var/run/sshd.pid
pkill sshd
}

sshd_config()
{
msg
}


#
# Config
#
set_tempdir() {
    if [ ! -n "$Input" ]; then
    msg "- 检测到没有输入内容,取消更改."
    else
    msg "- 正在更改"
    sleep 1
    rm -rf $CONFIG_DIR/$confid/tmpdir.conf
    msg "$Input">$CONFIG_DIR/$confid/tmpdir.conf
    msg "- 完成"
    sleep 1
    exit
fi
}

set_rootfsdir() {
if [ ! -n "$Input" ]; then
msg "- 检测到没有输入内容,取消更改."
    else
    msg "- 正在修改Rootfs路径"
    rm -rf $CONFIG_DIR/$confid/rootfs.conf
    msg "$Input">$CONFIG_DIR/$confid/rootfs.conf
    msg "- 完成,已设置 $Input"
    fi
}

set_initcmd() {
if [ ! -n "$Input" ]; then
 msg "- 检测到没有输入内容,取消更改."
else
 msg "- 正在修改"
 rm -rf $CONFIG_DIR/$confid/cmd.conf
 msg "$Input">$CONFIG_DIR/$confid/cmd.conf
 msg "- 完成,已修改 $Input"
fi
}

mk_conf() {
if [ -d "$CONFIG_DIR/" ];then
  msg
  else
  mkdir $CONFIG_DIR
fi
msg "- 正在创建配置 $mkconf"
mkdir $CONFIG_DIR/$mkconf/
msg "/data/cache/linux">$CONFIG_DIR/$mkconf/rootfs.conf
msg "/bin/sh">$CONFIG_DIR/$mkconf/cmd.conf
msg "- 正在切换配置 $mkconf"
rm $CONFIG_DIR/.id.conf
msg "$mkconf">$CONFIG_DIR/.id.conf
msg '- 完成,已创建 $mkconf'
exit
}

del_conf() {
if [ ! -n "$delconf" ]; then
  msg "- 检测到没有输入内容,取消更改."
else
  msg "- 正在删除配置 $delconf"
  sleep 1
  rm -rf $CONFIG_DIR/$delconf
  msg "- 完成,已删除 $delconf"
  sleep 1
  exit
fi
}

sw_conf() {
if [ ! -n "$swconf" ]; then
  msg "- 检测到没有输入内容,取消更改."
else
  msg "- 正在切换配置 $swconf"
  sleep 1
  rm -rf $CONFIG_DIR/.id.conf
  msg "$swconf">$CONFIG_DIR/.id.conf
  msg "- 完成,已切换 $swconf"
  sleep 1
  exit
fi
}
#
# Other
#

env_info() {
    model=$(getprop ro.product.model)
    if [ -n "$model" ]; then
        msg -n "设备: "
        msg "$model"
    fi
    android_version=$(getprop ro.build.version.release)
    if [ -n "$android_version" ]; then
        msg -n "安卓版本: "
        msg "Android $android_version"
    fi

    msg -n "容器已安装操作系统:"
    if [ -f "$rootfs/etc/issue" ];then
    export linux_version=$(cat $rootfs/etc/issue)
    else
    export linux_version="  未安装或无法识别"
    fi
    msg "$linux_version"

    msg -n "CPU架构: "
    msg "$(uname -m)"

    msg -n "内核版本: "
    msg "$(uname -r)"

    msg -n "内存: "
    mem_status=$(sed -n '1,p' /proc/meminfo)
    msg "$mem_status"

    msg -n "SELinux: "
    selinux_inactive && msg "关闭" || msg "开启"

    msg -n "支持 Loop:"
    loop_support && msg "是" || msg "否"

    msg "文件系统支持:"
    supported_fs=$(cat /proc/filesystems)
    msg "$supported_fs"
    
    msg '当前busybox版本:'
    busybox | grep BusyBox

    msg "当前运行路径:"
    pwd
    
    msg ""
    msg "CLI版本:"
    sh $TOOLKIT/cli.sh about

    msg "PRoot版本:"
    $TOOLKIT/proot -V

    msg "chroot状态:"
    $TOOLKIT/busybox chroot
}

# Run Command

export platform=$(platform)
if [ ! -n "${1}" ]; then
  about
  help
  exit
fi
umask 000
${1}