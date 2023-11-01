DD_DVB_TAR := $(DD_DVB_VERSION).tar.gz
DD_DVB_DIR := dddvb-$(DD_DVB_VERSION)

DD_DVB_MODULE_TARGET := $(DD_DVB_DIR)/dvb-core/dvb-core.ko

GCC := $(CROSS_COMPILE)gcc
TARGET_TRIPLE := $(shell echo $(CROSS_COMPILE)|cut -f4 -d/ -)

ROOT_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

all: $(DD_DVB_MODULE_TARGET)

# Download DD DVB source tarball
$(DD_DVB_TAR):
	wget https://github.com/DigitalDevices/dddvb/archive/refs/tags/$(DD_DVB_TAR)

# Unpack DD DVB source tarball.
$(DD_DVB_DIR)/Makefile: $(DD_DVB_TAR)
	tar -xf $(DD_DVB_TAR)
	patch $(DD_DVB_DIR)/Makefile $(ROOT_DIR)/patch/makefile.patch

# Build kernel modules
$(DD_DVB_MODULE_TARGET): $(DD_DVB_DIR)/Makefile
	mkdir -p $(DESTDIR)/dddvb/
	make -C $(DD_DVB_DIR) install ARCH=$(ARCH) KDIR=$(KSRC) kernelver=$(KVER) MDIR=$(DESTDIR)/dddvb/

install: all

clean:
	rm -rf $(DD_DVB_TAR) $(DD_DVB_DIR)
