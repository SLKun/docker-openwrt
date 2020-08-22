FROM scratch
COPY . .
ARG ROOT_PW
RUN echo -e "${ROOT_PW}\n${ROOT_PW}" | passwd
RUN sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
    && sed -i 's!/bin/ash!/usr/bin/zsh!g' /etc/passwd
RUN sed -i 's_downloads.openwrt.org_mirrors.tuna.tsinghua.edu.cn/openwrt_' /etc/opkg/distfeeds.conf
RUN echo "untrusted comment: public key 5c42250627d305bc\nRWRcQiUGJ9MFvK9/3ma8yAZebnrCfGvZJN/qbjaVozu6Ey9+Ihgnggae" > openwrt-dist.pub \
    && opkg-key add openwrt-dist.pub && rm openwrt-dist.pub
RUN echo "src/gz openwrt_dist http://openwrt-dist.sourceforge.net/packages/base/aarch64_cortex-a53" >>  /etc/opkg/customfeeds.conf \
    && echo "src/gz openwrt_dist_luci http://openwrt-dist.sourceforge.net/packages/luci" >>  /etc/opkg/customfeeds.conf
RUN mkdir -p /var/lock && opkg update
RUN opkg remove dnsmasq && opkg install ipset iperf3 ip-full dnsmasq-full
RUN opkg install luci-compat luci-mod-failsafe luci-ssl-openssl \
    luci-i18n-base-zh-cn luci-i18n-firewall-zh-cn luci-theme-material luci-theme-openwrt 
RUN opkg install libustream-openssl curl wget zsh git git-http vim-full 
RUN opkg install luci-i18n-aria2-zh-cn openvpn-openssl openvpn-easy-rsa luci-i18n-openvpn-zh-cn luci-i18n-privoxy-zh-cn \ 
    luci-i18n-qos-zh-cn collectd-mod-ping luci-i18n-statistics-zh-cn luci-app-unbound luci-i18n-upnp-zh-cn 
RUN opkg install iptables-mod-tproxy shadowsocks-libev simple-obfs luci-app-shadowsocks ChinaDNS luci-app-chinadns dns-forwarder luci-app-dns-forwarder
RUN opkg list-upgradable | awk '{print $1}' | xargs opkg upgrade

CMD [ "/sbin/init" ]