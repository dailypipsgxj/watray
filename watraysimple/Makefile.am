NULL = 

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
	$(NULL)

AM_CPPFLAGS = \
	$(WATRAYSIMPLE_CFLAGS) \
	-I$(top_srcdir)/watray \
	-DPACKAGE_DATADIR=\""$(pkgdatadir)"\" \
	-include $(CONFIG_HEADER) \
	$(NULL)

BUILT_SOURCES = libwatraysimple.vala.stamp

libwatraysimpledir = $(libdir)/watray/plugins

libwatraysimple_LTLIBRARIES = libwatraysimple.la


libwatraysimple_la_VALASOURCES = \
	simpleconfiguredialog.vala \
	simpleconfiguremanager.vala \
	simpleplugin.vala \
	simpledocumentmanager.vala \
	simpledocumentview.vala \
	$(NULL)


libwatraysimple_la_SOURCES = \
	$(libwatraysimple_la_VALASOURCES:.vala=.c) \
	$(NULL)

libwatraysimple.vala.stamp: $(libwatraysimple_la_VALASOURCES)
	$(VALAC) -C  --pkg config --pkg gtk+-2.0 --pkg gconf-2.0 --pkg watray-1.0 --pkg gee-1.0 --vapidir $(top_srcdir)/watray --vapidir $(top_srcdir)/vapi $^
	touch $@

libwatraysimple_la_LDFLAGS = \
	$(PLUGIN_LIBTOOL_FLAGS) \
	-module -avoid-version

libwatraysimple_la_LIBADD = \
	$(WATRAYSIMPLE_LIBS) \
	$(NULL)

libwatraysimple_DATA = \
	simple.watrayplugin \
	$(NULL)

EXTRA_DIST = \
	$(libwatraysimple_la_VALASOURCES) \
	libwatraysimple.vala.stamp \
	simple.watrayplugin
	$(NULL)

DISTCLEANFILES = \
	$(NULL)

