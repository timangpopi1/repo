#!/usr/bin/env bash
git clone --quiet --depth=1 https://github.com/fadlyas07/anykernel-3
export ARCH=arm64 && export SUBARCH=arm64
trigger_sha="$(git rev-parse HEAD)" && commit_msg="$(git log --pretty=format:'%s' -1)"
my_id="1385092591" && channel_id="-1001482549527" && token="1355238694:AAElWMuJhDKoE9Ci6INuD86RXwpo84uTt7c"
if [[ "$2" == "clang" ]] ; then
    git clone --quiet --depth=1 https://github.com/greenforce-project/clang-11.0.0 proton-clang
    function build_now() {
        export PATH="$(pwd)/proton-clang/bin:$PATH"
        export LD_LIBRARY_PATH="$(pwd)/proton-clang/lib:$LD_LIBRARY_PATH"
        export CCV="$(proton-clang/bin/clang --version | head -n 1)"
        export LDV="$(proton-clang/bin/ld.lld --version | head -n 1 | perl -pe 's/\(git.*?\)//gs' | sed 's/(compatible with [^)]*)//' | sed 's/[[:space:]]*$//')"
        export KBUILD_COMPILER_STRING="${CCV} with ${LDV}"
        make -j$(nproc) -l$(nproc) ARCH=arm64 O=out \
        CC=clang AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump \
        CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- STRIP=llvm-strip
    }
elif [[ "$2" == "gcc" ]] ; then
    git clone --quiet --depth=1 https://github.com/chips-project/aarch64-linux-gnu gcc
    git clone --quiet --depth=1 https://github.com/chips-project/arm-linux-gnueabi gcc32
    function build_now() {
        export PATH="$(pwd)/gcc/bin:$(pwd)/gcc32/bin:$PATH"
        make -j$(nproc) -l$(nproc) ARCH=arm64 O=out \
        CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi-
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
New build for #${codename} + $(cat $(pwd)/out/.config | grep Linux/arm64 | cut -d " " -f3) success at commit $(echo ${trigger_sha} | cut -c 1-8) (\"<a href='${my_project}/${target_repo}/commit/${trigger_sha}'>${commit_msg}</a>\") | <b>SHA1:</b> <code>$(sha1sum $(echo $(pwd)/anykernel-3/*.zip ) | awk '{ print $1 }')</code>." -F chat_id=${channel_id}
rm -rf out $(pwd)/anykernel-3/*.zip $(pwd)/anykernel-3/zImage $(pwd)/*.log
