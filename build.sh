#!/usr/bin/env bash
git clone --quiet --depth=1 https://github.com/fadlyas07/anykernel-3
export ARCH=arm64 && export SUBARCH=arm64
my_id="1201257517" && channel_id="-1001407534543" && token="1199423040:AAFES9WZoMa81J8MwA9C1B_F3wqpKByXFA0"
if [[ "$2" == "clang" ]] ; then
    git clone --quiet --depth=1 https://github.com/ThankYouMario/proprietary_vendor_qcom_sdclang-8.0_linux-x86 -b quartz quartz
    git clone --quiet --depth=1 https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 -b android-9.0.0_r50 gcc
    git clone --quiet --depth=1 https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9 -b android-9.0.0_r50 gcc32
    function build_now() {
        export PATH="$(pwd)/quartz/bin:$(pwd)/gcc/bin:$(pwd)/gcc32/bin:$PATH"
        export LD_LIBRARY_PATH="$(pwd)/quartz/lib:$LD_LIBRARY_PATH"
        make -j$(nproc) -l$(nproc) ARCH=arm64 O=out \
        CC=clang CLANG_TRIPLE=aarch64-linux-gnu- \
        CROSS_COMPILE=aarch64-linux-android- CROSS_COMPILE_ARM32=arm-linux-androideabi-
    }
elif [[ "$2" == "gcc" ]] ; then
    git clone --quiet --depth=1 https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 -b android-9.0.0_r55 gcc
    function build_now() {
        export PATH="$(pwd)/gcc/bin:$PATH"
        make -j$(nproc) -l$(nproc) ARCH=arm64 O=out CROSS_COMPILE=aarch64-linux-android-
    }
else
    curl -s -X POST "https://api.telegram.org/bot${token}/sendMessage" -d chat_id=${my_id} -d text="Please set your toochains on args!"
  exit 1 ;
fi
export KBUILD_BUILD_USER=greenforce && export KBUILD_BUILD_HOST=nightly
make -j$(nproc) -l$(nproc) ARCH=arm64 O=out ${1} && build_now &> build.log
if [[ ! -f $(pwd)/out/arch/arm64/boot/Image.gz-dtb ]] ; then
    curl -F document=@$(pwd)/build.log "https://api.telegram.org/bot${token}/sendDocument" -F chat_id=${my_id}
    curl -s -X POST "https://api.telegram.org/bot${token}/sendMessage" -d chat_id=${my_id} -d text="Build failed! at branch $(git rev-parse --abbrev-ref HEAD)"
  exit 1 ;
fi
curl -F document=@$(pwd)/build.log "https://api.telegram.org/bot${token}/sendDocument" -F chat_id=${my_id}
mv $(pwd)/out/arch/arm64/boot/Image.gz-dtb $(pwd)/anykernel-3
cd $(pwd)/anykernel-3 && zip -r9q "${KBUILD_BUILD_USER}"-"${KBUILD_BUILD_HOST}"-"${codename}"-"$(TZ=Asia/Jakarta date +'%d%m%y')".zip *
cd .. && curl -F "disable_web_page_preview=true" -F "parse_mode=html" -F document=@$(echo $(pwd)/anykernel-3/*.zip) "https://api.telegram.org/bot${token}/sendDocument" -F caption="
New #${codename} build is available! ($(cat $(pwd)/out/.config | grep Linux/arm64 | cut -d " " -f3)) at commit $(git log --pretty=format:"%h (\"%s\")" -1) | <b>SHA1:</b> <code>$(sha1sum $(echo $(pwd)/anykernel-3/*.zip) | awk '{ print $1 }')</code>." -F chat_id=${channel_id}
rm -rf out $(pwd)/anykernel-3/*.zip $(pwd)/anykernel-3/zImage $(pwd)/*.log
