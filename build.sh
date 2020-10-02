#!/usr/bin/env bash
git clone --quiet --depth=1 ${target_repo} -b ${target_branch} kernel && cd kernel
git clone --quiet --depth=1 https://github.com/fadlyas07/anykernel-3
git clone --quiet --depth=1 https://github.com/timangpopi1/arm64-gcc gcc
git clone --quiet --depth=1 https://github.com/timangpopi1/arm32-gcc gcc32
export ARCH=arm64 && export SUBARCH=arm64
trigger_sha="$(git rev-parse HEAD)" && commit_msg="$(git log --pretty=format:'%s' -1)"
my_id="1385092591" && channel_id="-1001482549527" && token="1355238694:AAElWMuJhDKoE9Ci6INuD86RXwpo84uTt7c"
function build_now() {
    export KBUILD_BUILD_USER=greenforce && export KBUILD_BUILD_HOST=nightly
    export PATH="$(pwd)/gcc/bin:$(pwd)/gcc32/bin:$PATH"
    make -j$(nproc) -l$(nproc) ARCH=arm64 O=out \
    CROSS_COMPILE=aarch64-elf- CROSS_COMPILE_ARM32=arm-eabi- >> build.log
}
case ${codename} in
*whyred*)
        git apply ./80mv_uv.patch
        if [[ ${codename} = "whyred-newcam" ]] ; then
            git apply ./campatch.patch
        fi
        ;;
esac
make -j$(nproc) -l$(nproc) ARCH=arm64 O=out ${1} && build_now
if [[ ! -f $(pwd)/out/arch/arm64/boot/Image.gz-dtb ]] ; then
    curl -F document=@$(pwd)/build.log "https://api.telegram.org/bot${token}/sendDocument" -F chat_id=${my_id}
    curl -s -X POST "https://api.telegram.org/bot${token}/sendMessage" -d chat_id=${my_id} -d text="Build failed! at branch $(git rev-parse --abbrev-ref HEAD)"
  exit 1 ;
fi
curl -F document=@$(pwd)/build.log "https://api.telegram.org/bot${token}/sendDocument" -F chat_id=${my_id}
mv $(pwd)/out/arch/arm64/boot/Image.gz-dtb $(pwd)/anykernel-3
cd $(pwd)/anykernel-3 && zip -r9 greenforce-Nightly-"$codename"-"$(TZ=Asia/Jakarta date +'%d%m%y')".zip *
cd .. && curl -F "disable_web_page_preview=true" -F "parse_mode=markdown" -F document=@$(echo $(pwd)/anykernel-3/*.zip) "https://api.telegram.org/bot${token}/sendDocument" -F caption="
New #${codename} build ($(cat $(pwd)/out/.config | grep Linux/arm64 | cut -d " " -f3)) success at commit \`$(echo ${trigger_sha} | cut -c 1-8)\` (\"[${commit_msg}](${target_repo}/commit/${trigger_sha})\") | \**SHA1:\** \`$(sha1sum $(echo $(pwd)/anykernel-3/*.zip ) | awk '{ print $1 }').\`"  -F chat_id=${channel_id}
rm -rf out $(pwd)/anykernel-3/*.zip $(pwd)/anykernel-3/zImage
