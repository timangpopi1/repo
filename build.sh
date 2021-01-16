#!/usr/bin/env bash
git clone --quiet --depth=1 https://github.com/fadlyas07/anykernel-3
export ARCH=arm64 && export SUBARCH=arm64
my_id="1201257517" && channel_id="1201257517" && token="1199423040:AAFES9WZoMa81J8MwA9C1B_F3wqpKByXFA0"
if [[ "$2" == "clang" ]] ; then
    git clone --quiet --depth=1 https://github.com/kdrag0n/proton-clang
    function build_now() {
        export PATH="$(pwd)/proton-clang/bin:$PATH"
        make -j$(nproc) -l$(nproc) ARCH=arm64 O=out \
        CC=clang AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump \
        CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_COMPAT=arm-linux-gnueabi- STRIP=llvm-strip
    }
elif [[ "$2" == "gcc" ]] ; then
    git clone --quiet --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9 -b lineage-17.1 gcc
    git clone --quiet --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9 -b lineage-17.1 gcc32
    function build_now() {
        export PATH="$(pwd)/gcc/bin:$(pwd)/gcc32/bin:$PATH"
        make -j$(nproc) -l$(nproc) ARCH=arm64 O=out CROSS_COMPILE=aarch64-linux-android- CROSS_COMPILE_ARM32=arm-linux-androideabi-
    }
else
    curl -s -X POST "https://api.telegram.org/bot${token}/sendMessage" -d chat_id=${my_id} -d text="Please set your toochains on args!"
  exit 1 ;
fi
export KBUILD_BUILD_USER=fadlyas07-yeetnosense && export KBUILD_BUILD_HOST=greenforce-project
make -j$(nproc) -l$(nproc) ARCH=arm64 O=out ${1} && build_now &> build.log
if [[ ! -f $(pwd)/out/arch/arm64/boot/Image.gz-dtb ]] ; then
    curl -F document=@$(pwd)/build.log "https://api.telegram.org/bot${token}/sendDocument" -F chat_id=${my_id}
    curl -s -X POST "https://api.telegram.org/bot${token}/sendMessage" -d chat_id=${my_id} -d text="Build failed! at branch $(git rev-parse --abbrev-ref HEAD)"
  exit 1 ;
fi
curl -F document=@$(pwd)/build.log "https://api.telegram.org/bot${token}/sendDocument" -F chat_id=${my_id}
mv $(pwd)/out/arch/arm64/boot/Image.gz-dtb $(pwd)/anykernel-3
cd $(pwd)/anykernel-3 && zip -r9q "${KBUILD_BUILD_HOST}"-"${codename}"-"$(TZ=Asia/Jakarta date +'%d%m%y')".zip *
cd .. && curl -F "disable_web_page_preview=true" -F "parse_mode=html" -F document=@$(echo $(pwd)/anykernel-3/*.zip) "https://api.telegram.org/bot${token}/sendDocument" -F caption="
New CI builds for #${codename} has been shipped, ($(cat $(pwd)/out/.config | grep Linux/arm64 | cut -d " " -f3), $(git rev-parse --abbrev-ref HEAD)) at commit $(git log --pretty=format:"%h (\"%s\")" -1)." -F chat_id=${channel_id}
rm -rf out $(pwd)/anykernel-3/*.zip $(pwd)/anykernel-3/zImage $(pwd)/*.log
