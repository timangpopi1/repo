#!/usr/bin/env bash
# Copyright (C) 2021 Muhammad Fadlyas (fadlyas07)
# SPDX-License-Identifier: GPL-3.0-or-later
git clone -q -j$(nproc --all) --single-branch https://github.com/crdroidandroid/android_prebuilts_clang_host_linux-x86_clang-6032204 clang --depth=1
git clone -q -j$(nproc --all) --single-branch https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9 gcc --depth=1
git clone -q -j$(nproc --all) --single-branch https://github.com/fadlyas07/anykernel-3 --depth=1
export id=${1} && export token=${2} && export c_id=${3} && export KBUILD_BUILD_USER="Y.Z" && export KBUILD_BUILD_HOST="$(TZ=Asia/Jakarta date +'%H%M.%d%m%y')"
export PATH="$(pwd)/clang/bin:$(pwd)/gcc/bin:$PATH" && export export LD_LIBRARY_PATH="$(pwd)/clang/lib:$LD_LIBRARY_PATH"
main_env="ARCH=arm64 CC=clang CLANG_TRIPLE=aarch64-linux-gnu- CROSS_COMPILE=aarch64-linux-android-"
make -j$(nproc --all) -l$(nproc --all) -C $(pwd) O=out $main_env ${4}|| echo "fail to regen defconfig, maybe you put the wrong name of your defconfig!"
make -j$(nproc --all) -l$(nproc --all) -C $(pwd) O=out $main_env 2>&1| tee build.log
if ! [[ -f $(pwd)/out/arch/arm64/boot/Image ]] ; then
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
cd $(pwd)/anykernel-3 && zip -r9q GF-${5}-$(TZ=Asia/Jakarta date +'%H%M-%d%m%y').zip *
cd .. && curl -F "disable_web_page_preview=true" -F "parse_mode=html" -F document=@$(echo $(pwd)/anykernel-3/*.zip) "https://api.telegram.org/bot$token/sendDocument" -F caption="
New update available for <b>${6}</b> based on Linux <b>$(cat $(pwd)/out/.config | grep Linux/arm64 | cut -d " " -f3)</b> at commit $(git log --pretty=format:"%h (\"%s\")" -1) | <b>SHA1:</b> $(sha1sum $(echo $(pwd)/anykernel-3/*.zip) | awk '{ print $1 }')" -F chat_id=$c_id
