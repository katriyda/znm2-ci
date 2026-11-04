rm -rf package/emortal/luci-app-athena-led
git clone --depth=1 https://github.com/NONGFAH/luci-app-athena-led package/luci-app-athena-led
chmod +x package/luci-app-athena-led/root/etc/init.d/athena_led package/luci-app-athena-led/root/usr/sbin/athena-led
# 修改默认管理地址为 10.10.10.1（LAN 10.10.10.0/24）
sed -i 's/192.168.1.1/10.10.10.1/g' package/base-files/files/bin/config_generate
# 设备名称 LibWrt 改为 ZN-M2
sed -i "s/hostname='LibWrt'/hostname='ZN-M2'/g" package/base-files/files/bin/config_generate
# 默认中文语言
sed -i "s/option lang auto/option lang zh_cn/g" feeds/luci/modules/luci-base/root/etc/config/luci
# 默认 argon 主题
sed -i "s#option mediaurlbase /luci-static/bootstrap#option mediaurlbase /luci-static/argon#g" feeds/luci/modules/luci-base/root/etc/config/luci

# ---- 自定义 feed：mimic ----
# 源追加到 feeds.conf.default 后单独 update+install（workflow 的 feeds update -a 早于本脚本执行）
# 注：momo（nikkinikki-org/OpenWrt-momo）已于 2026-11-05 移除——feed 能正常 update/install，
# 但 make defconfig 仍会把 momo / luci-app-momo 丢掉，断言必挂（run #2–#9 全部卡在这一步）。
# 之前"mimic 先装、momo 最后装"的顺序调整并不能解决，说明不是 feed 安装顺序问题。

# mimic feed：hack3ric/mimic（eBPF 把 UDP 伪装成 TCP；hysteria2 ≥2.12 内置集成）
# 是否编译由 .config 的 CONFIG_PACKAGE_mimic / kmod-mimic 决定
echo "src-git mimic https://github.com/hack3ric/mimic;openwrt" >> feeds.conf.default
./scripts/feeds update mimic
./scripts/feeds install -a -p mimic

# ---- 断言：自定义 feed 的包必须真的被 make defconfig 保留 ----
# 不满足就让整轮在几分钟内失败，而不是跑到产物阶段才发现包缺失
make defconfig >/dev/null 2>&1 || { echo "FATAL: make defconfig failed" >&2; exit 1; }
for sym in PACKAGE_mimic PACKAGE_kmod-mimic; do
    grep -qx "CONFIG_${sym}=y" .config || { echo "FATAL: CONFIG_${sym} not selected after defconfig (feed link lost?)" >&2; exit 1; }
done
echo "custom package check: OK"
