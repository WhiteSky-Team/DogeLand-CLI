
# CLI和二进制文件路径

#export TOOLKIT=$({TOOLKIT})

# 二级数据路径

#export DATA2_DIR="/$SDCARD_PATH/Android/data/$PACKAGE_NAME/"

# 配置文件路径

#export CONFIG_DIR="$DATA2_DIR/config/"

# CPU架构

#export platform=$(sh $TOOLKIT/cli.sh platform)

# 设置环境

#export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$TOOLKIT/lib/$platform/"
#export PATH="$PATH:$TOOLKIT"

# PRoot相关设置

#export PROOT_TMP_DIR="$DATA2_DIR/cache/"

#非必须
#export PROOT_LOADER="$TOOLKIT/lib/$platform/lib_loader.so"

# x64架构判断(可去除)

#if [[ "$platform" != "x86_64" ]]
#then
#export PROOT_LOADER_32="$TOOLKIT/lib/$platform/lib_loader32.so"
#fi

# 加载配置文件

#export confid="$(cat $CONFIG_DIR/.id.conf)"
#export cmd=$(cat $CONFIG_DIR/$confid/cmd.conf)
#export rootfs=$(cat $CONFIG_DIR/$confid/rootfs.conf)

# 使用CLI
# (CLI至少需要一个可用的busybox和附带的PRoot相关文件才能保证完整运行)
# PRoot相关文件附带在lib文件夹
sh cli.sh