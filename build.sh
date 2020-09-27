#!/usr/bin/env bash
#git clone --depth=1 https://github.com/GreenForce-project-repositories/clang-11.0.0 push
git clone --depth=1 https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 -b android-9.0.0_r60 gcc
git clone --depth=1 https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9 -b android-9.0.0_r60 gcc32
#export codename=whyred-newcam
export codename=whyred-oldcam
export KBUILD_BUILD_USER=fadlyas07
export KBUILD_BUILD_HOST=mwuehehehe
export ARCH=arm64 && export SUBARCH=arm64
export PATH="$(pwd)/gcc/bin:$(pwd)/gcc32/bin:$PATH"
#export PATH="$(pwd)/push/bin:$PATH"
#export LD_LIBRARY_PATH=$(pwd)/push/lib:$LD_LIBRARY_PATH
#export CCV=$(push/bin/clang --version | head -n 1)
#export LDV=$(push/bin/ld.lld --version | head -n 1 | perl -pe 's/\(git.*?\)//gs' | sed 's/(compatible with [^)]*)//' | sed 's/[[:space:]]*$//')
#export KBUILD_COMPILER_STRING="${CCV} with ${LDV}"
if [[ ${codename} = "whyred-newcam" ]] ; then
    git apply ./campatch.patch
fi
make -j$(nproc) -l$(nproc) ARCH=arm64 O=out ${1}
#make -j$(nproc) -l$(nproc) ARCH=arm64 O=out \
#CC=clang AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy \
#CROSS_COMPILE=aarch64-linux-gnu- OBJDUMP=llvm-objdump \
#STRIP=llvm-strip CROSS_COMPILE_ARM32=arm-linux-gnueabi- 2>&1| tee build.log
make -j$(nproc) -l$(nproc) ARCH=arm64 O=out \
CROSS_COMPILE=aarch64-linux-android- \
CROSS_COMPILE_ARM32=arm-linux-androideabi- 2>&1| tee build.log
if [[ ! -f $(pwd)/out/arch/arm64/boot/Image.gz-dtb ]] ; then
    curl -s -X POST "https://api.telegram.org/bot960007819:AAGjqN3UsMFc7iFMkc0Mj8owotH-oJchCag/sendMessage" -d chat_id="784548477" -d text="Test Failed, Please fix it now @fadlyas07!"
    curl -F document=@$(pwd)/build.log "https://api.telegram.org/bot960007819:AAGjqN3UsMFc7iFMkc0Mj8owotH-oJchCag/sendDocument" -F chat_id="784548477"
  exit 1 ;
fi
curl -F document=@$(pwd)/build.log "https://api.telegram.org/bot960007819:AAGjqN3UsMFc7iFMkc0Mj8owotH-oJchCag/sendDocument" -F chat_id="784548477"
mv $(pwd)/out/arch/arm64/boot/Image.gz-dtb $(pwd)/anykernel-3
cd $(pwd)/anykernel-3 && zip -r9 GreenForce-"$codename"-"$(TZ=Asia/Jakarta date +'%d%m%y')".zip *
cd .. && curl -F document=@$(echo $(pwd)/anykernel-3/*.zip) "https://api.telegram.org/bot960007819:AAGjqN3UsMFc7iFMkc0Mj8owotH-oJchCag/sendDocument" -F caption="Test Build $(cat $(pwd)/out/.config | grep Linux/arm64 | cut -d " " -f3) for #${codename} success at commit $(git log --pretty=format:"%h (\"%s\")" -1)" -F chat_id="784548477"
rm -rf out $(pwd)/anykernel-3/*.zip $(pwd)/anykernel-3/zImage
