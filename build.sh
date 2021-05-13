#!/usr/bin/env bash
git clone --quiet --depth=1 https://github.com/fadlyas07/anykernel-3
export ARCH=arm64 && export SUBARCH=arm64
my_id="1201257517" && channel_id="-1001360920692" && token="1501859780:AAFrTzcshDwfA2x6Q0lhotZT2M-CMeiBJ1U"
export KBUILD_BUILD_USER=Source.$(git rev-parse --abbrev-ref HEAD) && export KBUILD_BUILD_HOST=$(git log --pretty=format:'%T' -1 | cut -b 1-16)
build_clang() {
    git clone --quiet -j64 https://github.com/greenforce-project/clang-llvm
    cd clang-llvm && git reset --hard 05cedc1abf5cb4920b8a7ac6143a5ca8e7a3d7c4 && cd ..
    export PATH="$(pwd)/clang-llvm/bin:$PATH" && export LD_LIBRARY_PATH="$(pwd)/clang-llvm/lib:$LD_LIBRARY_PATH"
    make -j$(nproc) -l$(nproc) ARCH=arm64 O=out CC=clang AR=llvm-ar NM=llvm-nm CLANG_TRIPLE=aarch64-linux-gnu- \
    CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi-
}
make -j$(nproc) -l$(nproc) ARCH=arm64 O=out ${1} && build_clang 2>&1| tee build.log
if [[ ! -f $(pwd)/out/arch/arm64/boot/Image.gz-dtb ]] ; then
    curl -F document=@$(pwd)/build.log "https://api.telegram.org/bot${token}/sendDocument" -F chat_id=${my_id}
    curl -s -X POST "https://api.telegram.org/bot${token}/sendMessage" -d chat_id=${my_id} -d text="Build failed! at branch $(git rev-parse --abbrev-ref HEAD)"
  exit 1 ;
fi
if [[ $codename == lavender ]] ; then
    export DEVICE="Xiaomi Redmi Note 7/7S"
elif [[ $codename == citrus ]] ; then
    export DEVICE="POCO M3"
fi
curl -F document=@$(pwd)/build.log "https://api.telegram.org/bot${token}/sendDocument" -F chat_id=${my_id}
mv $(pwd)/out/arch/arm64/boot/Image.gz-dtb $(pwd)/anykernel-3
cd $(pwd)/anykernel-3 && zip -r9q "${2}"-"${codename}"-"$(TZ=Asia/Jakarta date +'%d%m%y')".zip *
cd .. && curl -F "disable_web_page_preview=true" -F "parse_mode=html" -F document=@$(echo $(pwd)/anykernel-3/*.zip) "https://api.telegram.org/bot${token}/sendDocument" -F caption="
New updates for <b>$DEVICE</b> based on Linux <b>$(cat $(pwd)/out/.config | grep Linux/arm64 | cut -d " " -f3)</b> at commit $(git log --pretty=format:"%h (\"%s\")" -1) | <b>SHA1:</b> $(sha1sum "$(echo $(pwd)/anykernel-3/*.zip)" | awk '{ print $1 }')" -F chat_id=${channel_id}
rm -rf out $(pwd)/anykernel-3/*.zip $(pwd)/anykernel-3/zImage $(pwd)/*.log
