#!/usr/bin/env bash
export token="1355238694:AAElWMuJhDKoE9Ci6INuD86RXwpo84uTt7c"
git clone --depth=1 -q https://github.com/crdroidmod/android_prebuilts_clang_host_linux-x86_clang-5799447 push
git clone --depth=1 https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 -b android-9.0.0_r50 gcc
git clone --depth=1 https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9 -b android-9.0.0_r50 gcc32
export KBUILD_BUILD_USER=fadlyas07
export ARCH=arm64 && export SUBARCH=arm64
export PATH="$(pwd)/push/bin:$(pwd)/gcc/bin:$(pwd)/gcc32/bin:$PATH"
export LD_LIBRARY_PATH="$(pwd)/push/lib:$LD_LIBRARY_PATH"
make -j$(nproc) -l$(nproc) ARCH=arm64 O=out ${1}
make -j$(nproc) -l$(nproc) ARCH=arm64 O=out \
CC=clang CLANG_TRIPLE=aarch64-linux-gnu- \
CROSS_COMPILE=aarch64-linux-android- CROSS_COMPILE_ARM32=arm-linux-androideabi- 2>&1| tee build.log
if [[ ! -f $(pwd)/out/arch/arm64/boot/Image.gz-dtb ]] ; then
    curl -s -X POST "https://api.telegram.org/bot${token}/sendMessage" -d chat_id="1385092591" -d text="Test Failed, Please fix it now @fadlyas07!"
    curl -F document=@$(pwd)/build.log "https://api.telegram.org/bot${token}/sendDocument" -F chat_id="1385092591"
  exit 1 ;
fi
curl -F document=@$(pwd)/build.log "https://api.telegram.org/bot${token}/sendDocument" -F chat_id="1385092591"
mv $(pwd)/out/arch/arm64/boot/Image.gz-dtb $(pwd)/anykernel-3
cd $(pwd)/anykernel-3 && zip -r9 GreenForce-"$codename"-"$(TZ=Asia/Jakarta date +'%d%m%y')".zip *
cd .. && curl -F document=@$(echo $(pwd)/anykernel-3/*.zip) "https://api.telegram.org/bot${token}/sendDocument" -F caption="Test Build $(cat $(pwd)/out/.config | grep Linux/arm64 | cut -d " " -f3) for #${codename} success at commit $(git log --pretty=format:"%h (\"%s\")" -1)" -F chat_id="1385092591"
rm -rf out $(pwd)/anykernel-3/*.zip $(pwd)/anykernel-3/zImage
