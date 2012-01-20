SHELL = /bin/sh

BINDIR = $(DESTDIR)/usr/bin

default:
	echo No build needed

install:
	mkdir -p $(BINDIR)
	install -m 755 mer_verify_kernel_{config,spec} $(BINDIR)/
