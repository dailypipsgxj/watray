NULL = 

AM_CPPFLAGS = \
	$(WATRAY_CFLAGS) \
	-DPACKAGE_DATADIR=\""$(pkgdatadir)"\" \
	-DPACKAGE_LIBDIR=\""$(libdir)"\" \
	-include $(CONFIG_HEADER) \
	$(NULL)

BUILT_SOURCES = watray.vala.stamp

bin_PROGRAMS = watray

watray_VALASOURCES = \
	watraydocumentspanel.vala \
	watraydocumentspanelinterface.vala \
	watraydocumentview.vala \
	watraymainwindow.vala \
	watraymainwindowinterface.vala \
	watrayproject.vala \
	watrayprojectspanel.vala \
	watrayprojectspanelinterface.vala \
	watrayplugin.vala \
	watrayplugininfo.vala \
	watrayplugininterface.vala \
	watraypluginmanager.vala \
	watraypluginmanagerview.vala \
	watraypreferencedialog.vala \
	watraypreferencemanager.vala \
	$(NULL)

watray_SOURCES = \
	$(watray_VALASOURCES:.vala=.c) \
	$(NULL)

watrayincludedir = $(includedir)/watray-1.0

watrayinclude_HEADERS = \
	watray.h \
	$(NULL)

watray.vala.stamp: $(watray_VALASOURCES)
	$(VALAC) -C --pkg gtk+-2.0 --pkg gdk-2.0 --pkg gmodule-2.0 --pkg config --pkg gconf-2.0 --pkg gee-1.0 --basedir $(top_srcdir) -H watray.h --library watray-1.0 --vapidir $(top_srcdir)/vapi $^
	touch $@

watray_LDADD = \
	$(WATRAY_LIBS) \
	$(NULL)

watrayvapidir = ${datadir}/vala/vapi
watrayvapi_DATA = watray-1.0.vapi

EXTRA_DIST = \
	$(watray_VALASOURCES) \
	watray.vala.stamp \
	watray-1.0.vapi \
	$(NULL)

DISTCLEANFILES = \
	$(NULL)

