.PHONY: download build run clean install uninstall

include openwrt.conf
export

download:
	mkdir -p build
	wget -q https://mirrors.bfsu.edu.cn/openwrt/releases/${OPENWRT_VER}/targets/brcm2708/bcm2710/openwrt-${OPENWRT_VER}-brcm2708-bcm2710-rpi-3-ext4-factory.img.gz \
	    -O build/openwrt-${OPENWRT_VER}-brcm2708-bcm2710-rpi-3-ext4-factory.img.gz
	gzip -d build/openwrt*.img.gz

build:
	files/build.sh build/openwrt-${OPENWRT_VER}-brcm2708-bcm2710-rpi-3-ext4-factory.img

run:
	sh -x files/openwrt-run.sh

clean:
	docker rm ${CONTAINER} || true

install:
	install -Dm644 files/openwrt.service /usr/lib/systemd/system/openwrt.service
	sed -i -E "s#(ExecStart=).*#\1`pwd`/files/openwrt-run.sh#g" /usr/lib/systemd/system/openwrt.service
	systemctl daemon-reload
	systemctl enable openwrt.service
	@echo "OpenWRT service installed and will be started on next boot automatically."
	@echo "To start it now, run 'systemctl start openwrt.service'."

uninstall:
	systemctl stop openwrt.service
	systemctl disable openwrt.service
	rm /usr/lib/systemd/system/openwrt.service
	systemctl daemon-reload
