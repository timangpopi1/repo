#!/usr/bin/env bash
git clone --quiet -j64 --depth=1 --single-branch https://github.com/fadlyas07/anykernel-3
git clone --quiet -j64 --single-branch https://github.com/greenforce-project/gcc-arm64 && cd gcc-arm64 && git reset --hard d27fab3a76d6b1d9f1e75f1bc44e2bdc7c9674c6 && cd ..
export ARCH=arm64 && export SUBARCH=arm64 && export kernel_defconfig=${1} && thread=$(nproc --all)
my_id="1201257517" && channel_id="-1001360920692" && token="1501859780:AAFrTzcshDwfA2x6Q0lhotZT2M-CMeiBJ1U"
export KBUILD_BUILD_USER="" && export KBUILD_BUILD_HOST="" && export PATH="$(pwd)/gcc-arm64/bin:$PATH"
BUILD_ENV="ARCH=arm64 CROSS_COMPILE=aarch64-elf-"
make -j${thread} -l${thread} -C $(pwd) O=$(pwd)/out $BUILD_ENV $kernel_defconfig || exit 1;
make -j${thread} -l${thread} -C $(pwd) O=$(pwd)/out $BUILD_ENV 2>&1| tee build.log
if [[ ! -f $(pwd)/out/arch/arm64/boot/Image ]] ; then
    curl -F document=@$(pwd)/build.log "https://api.telegram.org/bot${token}/sendDocument" -F chat_id=${my_id}
    curl -s -X POST "https://api.telegram.org/bot${token}/sendMessage" -d chat_id=${my_id} -d text="Build failed! at branch $(git rev-parse --abbrev-ref HEAD)"
  exit 1 ;
else
    if [[ -e $(pwd)/out/.config ]] ; then
        cp $(pwd)/out/.config regen_defconfig
        curl -F document=@$(pwd)/regen_defconfig "https://api.telegram.org/bot${token}/sendDocument" -F chat_id=${my_id}
    else
        echo "unfortunately .config not found"
    fi
fi
if [[ $codename == lavender ]] ; then
    export DEVICE="Redmi Note 7/7S"
elif [[ $codename == juice ]] ; then
    export DEVICE="POCO M3/Redmi 9T"
fi
mv $(pwd)/out/arch/arm64/boot/Image $(pwd)/anykernel-3
curl -F document=@$(pwd)/build.log "https://api.telegram.org/bot${token}/sendDocument" -F chat_id=${my_id}
cd $(pwd)/anykernel-3 && zip -r9q "${2}"-"${codename}"-"$(TZ=Asia/Jakarta date +'%H%M-%d%m%y')".zip *
cd .. && curl -F "disable_web_page_preview=true" -F "parse_mode=html" -F document=@$(echo $(pwd)/anykernel-3/*.zip) "https://api.telegram.org/bot${token}/sendDocument" -F caption="
New updates for <b>$DEVICE</b> based on Linux <b>$(cat $(pwd)/out/.config | grep Linux/arm64 | cut -d " " -f3)</b> at commit $(git log --pretty=format:"%h (\"%s\")" -1) | <b>SHA1:</b> $(sha1sum "$(echo $(pwd)/anykernel-3/*.zip)" | awk '{ print $1 }')" -F chat_id=${channel_id}
