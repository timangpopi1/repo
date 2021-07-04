#!/usr/bin/env bash
git clone --quiet -j64 --depth=1 https://github.com/fadlyas07/anykernel-3
export ARCH=arm64 && export SUBARCH=arm64 && export kernel_defconfig=${1}
my_id="1201257517" && channel_id="-1001360920692" && token="1501859780:AAFrTzcshDwfA2x6Q0lhotZT2M-CMeiBJ1U"
export KBUILD_BUILD_USER=fadlyas07 && export KBUILD_BUILD_HOST=greenforce-project
build_kernel() {
    git clone --quiet -j64 --depth=1 --single-branch https://github.com/kdrag0n/proton-clang
    export PATH="$(pwd)/proton-clang/bin:$PATH"
    make -j$(nproc --all) -l$(nproc --all) ARCH=arm64 O=out CC=clang AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy \
    OBJDUMP=llvm-objdump STRIP=llvm-strip CROSS_COMPILE=aarch64-linux-gnu- LD=ld.lld
}
make -j$(nproc) -l$(nproc) ARCH=arm64 O=out $kernel_defconfig
rm -rf $(pwd)/out/.config && cp $(pwd)/arch/arm64/configs/$kernel_defconfig $(pwd)/out/.config
build_kernel 2>&1| tee build.log
if [[ ! -f $(pwd)/out/arch/arm64/boot/Image.gz-dtb ]] ; then
    curl -F document=@$(pwd)/build.log "https://api.telegram.org/bot${token}/sendDocument" -F chat_id=${my_id}
    curl -s -X POST "https://api.telegram.org/bot${token}/sendMessage" -d chat_id=${my_id} -d text="Build failed! at branch $(git rev-parse --abbrev-ref HEAD)"
  exit 1 ;
fi
if [[ $codename == lavender ]] ; then
    export DEVICE="Redmi Note 7/7S"
elif [[ $codename == juice ]] ; then
    export DEVICE="POCO M3/Redmi 9T"
fi
curl -F document=@$(pwd)/build.log "https://api.telegram.org/bot${token}/sendDocument" -F chat_id=${my_id}
mv $(pwd)/out/arch/arm64/boot/Image $(pwd)/anykernel-3
curl -F document=@$(pwd)/build.log "https://api.telegram.org/bot${token}/sendDocument" -F chat_id=${my_id}
cd $(pwd)/anykernel-3 && zip -r9q "${2}"-"${codename}"-"$(TZ=Asia/Jakarta date +'%d%m%y')".zip *
cd .. && curl -F "disable_web_page_preview=true" -F "parse_mode=html" -F document=@$(echo $(pwd)/anykernel-3/*.zip) "https://api.telegram.org/bot${token}/sendDocument" -F caption="
New updates for <b>$DEVICE</b> based on Linux <b>$(cat $(pwd)/out/.config | grep Linux/arm64 | cut -d " " -f3)</b> at commit $(git log --pretty=format:"%h (\"%s\")" -1) | <b>SHA1:</b> $(sha1sum "$(echo $(pwd)/anykernel-3/*.zip)" | awk '{ print $1 }')" -F chat_id=${channel_id}
rm -rf out $(pwd)/anykernel-3/*.zip $(pwd)/anykernel-3/zImage $(pwd)/*.log
