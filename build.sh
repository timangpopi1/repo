#!/usr/bin/env bash
# Copyright (C) 2021 Muhammad Fadlyas (fadlyas07)
# SPDX-License-Identifier: GPL-3.0-or-later
apt-get update && \
apt-get install -y && \
clang llvm lld binutils-aarch64-linux-gnu gcc-aarch64-linux-gnu binutils-arm-linux-gnueabi gcc-arm-linux-gnueabi \
libncurses-dev flex bison openssl libssl-dev dkms libelf-dev libudev-dev libpci-dev libiberty-dev autoconfa &>/dev/null
git clone -q -j$(nproc --all) --single-branch https://github.com/fadlyas07/anykernel-3 --depth=1
export id=${1} && export token=${2} && export c_id=${3} && export KBUILD_BUILD_USER="Y.Z" && export KBUILD_BUILD_HOST=""
BUILD_ENV="ARCH=arm64 CC=clang CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_COMPAT=arm-linux-gnueabi- CLANG_TRIPLE=aarch64-linux-gnu-"
BUILD_ENV="$BUILD_ENV target_defconfig=${4}"
make -j$(nproc --all) -C $(pwd) O=out $BUILD_ENV $target_defconfig || exit 1
make -j$(nproc --all) -C $(pwd) O=out $BUILD_ENV 2>&1| tee build.log
if ! [[ ( -f $(pwd)/out/arch/arm64/boot/Image || $(pwd)/out/arch/arm64/boot/Image.gz-dtb ) ]] ; then
    curl -F document=@$(pwd)/build.log "https://api.telegram.org/bot$token/sendDocument" -F chat_id=$id
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" -d chat_id=$id -d text="Build for $(git rev-parse --abbrev-ref HEAD) failed!"
  exit 1 ;
else
    if [[ -e $(pwd)/out/.config ]] ; then
        cp $(pwd)/out/.config regen_defconfig
        curl -F document=@$(pwd)/regen_defconfig "https://api.telegram.org/bot$token/sendDocument" -F chat_id=$id
    else
        echo "unfortunately .config not found"
    fi
fi
mv $(pwd)/out/arch/arm64/boot/Image $(pwd)/anykernel-3
curl -F document=@$(pwd)/build.log "https://api.telegram.org/bot$token/sendDocument" -F chat_id=$id
cd $(pwd)/anykernel-3 && zip -r9q "GF."${6}"."$(TZ=Asia/Jakarta date +'%d%m%y')".zip *
cd .. && curl -F "disable_web_page_preview=true" -F "parse_mode=html" -F document=@$(echo $(pwd)/anykernel-3/*.zip) "https://api.telegram.org/bot$token/sendDocument" -F caption="
New update available for <b>${5}</b> based on Linux <b>$(cat $(pwd)/out/.config | grep Linux/arm64 | cut -d " " -f3)</b> at commit $(git log --pretty=format:"%h (\"%s\")" -1) | <b>SHA1:</b> $(sha1sum $(echo $(pwd)/anykernel-3/*.zip) | awk '{ print $1 }')" -F chat_id=$c_id
