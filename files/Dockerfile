FROM scratch
COPY . .
ARG ROOT_PW
RUN echo -e "${ROOT_PW}\n${ROOT_PW}" | passwd
RUN sed -i 's_downloads.openwrt.org_mirrors.tuna.tsinghua.edu.cn/openwrt_' /etc/opkg/distfeeds.conf
RUN mkdir -p /var/lock && opkg update
RUN opkg remove dnsmasq && opkg install iperf3 ip-full dnsmasq-full
RUN opkg install luci-i18n-base-zh-cn luci-i18n-firewall-zh-cn luci-theme-material
RUN opkg list-upgradable | awk '{print $1}' | xargs opkg upgrade

CMD [ "/sbin/init" ]