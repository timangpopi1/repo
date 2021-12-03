#!/usr/bin/env bash
# Copyright (C) 2021 Muhammad Fadlyas (fadlyas07)
# SPDX-License-Identifier: GPL-3.0-or-later
git clone -j$(nproc --all) -b sapphire https://github.com/ThankYouMario/proprietary_vendor_qcom_sdclang clang --depth=1
git clone -j$(nproc --all) --single-branch https://github.com/arter97/arm64-gcc gcc --depth=1
git clone -j$(nproc --all) --single-branch https://github.com/fadlyas07/anykernel-3 --depth=1
export id=${1} && export token=${2} && export c_id=${3} && export KBUILD_BUILD_USER="yeetnozech4" && export KBUILD_BUILD_HOST="greenforce.project"
export PATH="$(pwd)/clang/compiler/bin:$(pwd)/gcc/bin:$PATH" && export export LD_LIBRARY_PATH="$(pwd)/clang/lib:$LD_LIBRARY_PATH"
main_env="ARCH=arm64 CC=clang CLANG_TRIPLE=aarch64-linux-gnu- CROSS_COMPILE=aarch64-elf-"
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
