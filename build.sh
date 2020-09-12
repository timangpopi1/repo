#!/usr/bin/env bash
export ARCH=arm64 && export SUBARCH=arm64
export CROSS_COMPILE="$(pwd)/gcc/bin/aarch64-linux-android-"
export CROSS_COMPILE_ARM32="$(pwd)/gcc32/bin/arm-linux-androideabi-"
make -j$(nproc) -l$(nproc) ARCH=arm64 O=out rolex_defconfig
make -j$(nproc) -l$(nproc) ARCH=arm64 O=out 2>&1| tee build.log
if [[ ! -f $(pwd)/out/arch/arm64/boot/Image.gz-dtb ]] ; then
    curl -s -X POST "https://api.telegram.org/bot960007819:AAGjqN3UsMFc7iFMkc0Mj8owotH-oJchCag/sendMessage" -d chat_id="784548477" -d text="Test Failed, Please fix it now @fadlyas07!"
    curl -F document=@$(pwd)/build.log "https://api.telegram.org/bot960007819:AAGjqN3UsMFc7iFMkc0Mj8owotH-oJchCag/sendDocument" -F chat_id="784548477"
  exit 1 ;
fi
curl -F document=@$(pwd)/build.log "https://api.telegram.org/bot960007819:AAGjqN3UsMFc7iFMkc0Mj8owotH-oJchCag/sendDocument" -F chat_id="784548477"
mv $(pwd)/out/arch/arm64/boot/Image.gz-dtb $(pwd)/anykernel-3
cd $(pwd)/anykernel-3 && zip -r9 GreenForce-"$codename"-"$(TZ=Asia/Jakarta date +'%d%m%y')".zip *
cd .. && curl -F document=@$(echo $(pwd)/anykernel-3/*.zip) "https://api.telegram.org/bot960007819:AAGjqN3UsMFc7iFMkc0Mj8owotH-oJchCag/sendDocument" -F caption="Test Build 4.9 for #${codename} success at commit $(git log --pretty=format:"%h (\"%s\")" -1)" -F chat_id="784548477"
rm -rf out $(pwd)/anykernel-3/*.zip $(pwd)/anykernel-3/zImage
