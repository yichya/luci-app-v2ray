include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-v2ray
PKG_VERSION:=v4.25.0
PKG_RELEASE:=1

PKG_LICENSE:=GPLv3
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=MoeGrid <1065380934@qq.com>

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=Custom
	CATEGORY:=Extra packages
	TITLE:=LuCI Support for v2ray-core
	DEPENDS:=+iptables +ca-bundle +luci-compat
endef

define Package/$(PKG_NAME)/description
	LuCI Support for v2ray-core.
endef

define Package/$(PKG_NAME)/config
menu "V2Ray Configuration"
	depends on PACKAGE_$(PKG_NAME)

config PACKAGE_V2RAY_INCLUDE_V2RAY
	bool "Include v2ray"
	default y

config PACKAGE_V2RAY_SOFTFLOAT
	bool "Use soft-float binaries (mips/mipsle only)"
	depends on mipsel || mips || mips64el || mips64
	default n

config PACKAGE_V2RAY_INCLUDE_V2CTL
	bool "Include v2ctl"
	depends on PACKAGE_V2RAY_INCLUDE_V2RAY
	default y

config PACKAGE_V2RAY_INCLUDE_GEOIP
	bool "Include geoip.dat"
	depends on PACKAGE_V2RAY_INCLUDE_V2CTL
	default n

config PACKAGE_V2RAY_INCLUDE_GEOSITE
	bool "Include geosite.dat"
	depends on PACKAGE_V2RAY_INCLUDE_V2CTL
	default n

endmenu
endef

ifeq ($(ARCH),x86_64)
	PKG_ARCH_V2RAY:=linux-64
endif
ifeq ($(ARCH),mipsel)
	PKG_ARCH_V2RAY:=linux-mipsle
endif
ifeq ($(ARCH),mips)
	PKG_ARCH_V2RAY:=linux-mips
endif
ifeq ($(ARCH),i386)
	PKG_ARCH_V2RAY:=linux-32
endif
ifeq ($(ARCH),arm)
	PKG_ARCH_V2RAY:=linux-arm
endif
ifeq ($(ARCH),aarch64)
	PKG_ARCH_V2RAY:=linux-arm64
endif

V2RAY_BIN:=v2ray
V2CTL_BIN:=v2ctl

ifeq ($(ARCH),arm)
	ifneq ($(BOARD),bcm53xx)
		V2RAY_BIN:=v2ray_armv7
		V2CTL_BIN:=v2ctl_armv7
	endif
endif

ifdef CONFIG_PACKAGE_V2RAY_SOFTFLOAT
	V2RAY_BIN:=v2ray_softfloat
	V2CTL_BIN:=v2ctl_softfloat
endif

define Build/Prepare
	$(foreach po,$(wildcard ${CURDIR}/files/luci/i18n/*.po), po2lmo $(po) $(PKG_BUILD_DIR)/$(patsubst %.po,%.lmo,$(notdir $(po)));)
	[ ! -f $(PKG_BUILD_DIR)/v2ray-$(PKG_VERSION)-$(PKG_ARCH_V2RAY).zip ] && wget https://github.com/v2ray/v2ray-core/releases/download/$(PKG_VERSION)/v2ray-$(PKG_ARCH_V2RAY).zip -O $(PKG_BUILD_DIR)/v2ray-$(PKG_VERSION)-$(PKG_ARCH_V2RAY).zip
	unzip -o $(PKG_BUILD_DIR)/v2ray-$(PKG_VERSION)-$(PKG_ARCH_V2RAY).zip -d $(PKG_BUILD_DIR)
	wget https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat -O $(PKG_BUILD_DIR)/geoip.dat
	wget https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat -O $(PKG_BUILD_DIR)/geosite.dat
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
if [[ -z "$${IPKG_INSTROOT}" ]]; then
	if [[ -f /etc/uci-defaults/luci-v2ray ]]; then
		( . /etc/uci-defaults/luci-v2ray ) && \
		rm -f /etc/uci-defaults/luci-v2ray
	fi
	rm -rf /tmp/luci-indexcache /tmp/luci-modulecache
fi
exit 0
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/v2ray
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/share/v2ray
	$(INSTALL_DIR) $(1)/usr/bin
ifdef CONFIG_PACKAGE_V2RAY_INCLUDE_V2RAY
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/$(V2RAY_BIN) $(1)/usr/bin/v2ray
endif
ifdef CONFIG_PACKAGE_V2RAY_INCLUDE_V2CTL
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/$(V2CTL_BIN) $(1)/usr/bin/v2ctl
endif
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/v2ray.*.lmo $(1)/usr/lib/lua/luci/i18n/
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DATA) ./files/luci/controller/*.lua $(1)/usr/lib/lua/luci/controller/
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi/v2ray
	$(INSTALL_DATA) ./files/luci/model/cbi/v2ray/*.lua $(1)/usr/lib/lua/luci/model/cbi/v2ray/
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view/v2ray
	$(INSTALL_DATA) ./files/luci/view/v2ray/*.htm $(1)/usr/lib/lua/luci/view/v2ray/
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) ./files/root/etc/config/v2ray $(1)/etc/config/v2ray
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/root/etc/init.d/v2ray $(1)/etc/init.d/v2ray
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/root/etc/uci-defaults/luci-v2ray $(1)/etc/uci-defaults/luci-v2ray
	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DATA) ./files/root/usr/share/rpcd/acl.d/luci-app-v2ray.json $(1)/usr/share/rpcd/acl.d/luci-app-v2ray.json
	$(INSTALL_DIR) $(1)/usr/share/v2ray
ifdef CONFIG_PACKAGE_V2RAY_INCLUDE_GEOIP
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/geoip.dat $(1)/usr/share/v2ray/
endif
ifdef CONFIG_PACKAGE_V2RAY_INCLUDE_GEOSITE
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/geosite.dat $(1)/usr/share/v2ray/
endif
	$(INSTALL_BIN) ./files/root/usr/share/v2ray/gen_config.lua $(1)/usr/share/v2ray/gen_config.lua
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
