# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-lang/ruby/ruby-1.8.6_p287-r12.ebuild,v 1.4 2009/03/20 05:00:41 josejx Exp $

inherit autotools eutils flag-o-matic multilib versionator

DESCRIPTION="Ruby Enterprise Edition"
HOMEPAGE="http://www.rubyenterpriseedition.com"
SRC_URI="http://rubyforge.org/frs/download.php/51100/ruby-enterprise-1.8.6-20090201.tar.gz"

LICENSE="Ruby"
SLOT="0"
KEYWORDS="amd64 x86"

IUSE="berkdb debug doc emacs examples gdbm ipv6 rubytests socks5 ssl xemacs"

RDEPEND="
	berkdb? ( sys-libs/db )
	gdbm? ( sys-libs/gdbm )
	ssl? ( dev-libs/openssl )
	socks5? ( >=net-proxy/dante-1.1.13 )
	app-admin/eselect-ruby
	!=dev-lang/ruby-cvs-${SLOT}*
	!dev-ruby/rdoc
	!dev-ruby/rexml"
DEPEND="${RDEPEND}
	dev-libs/tcmalloc-ruby-enterprise"
PDEPEND="emacs? ( app-emacs/ruby-mode )
	xemacs? ( app-xemacs/ruby-modes )"

PROVIDE="virtual/ruby"

WANT_AUTOCONF="latest"
WANT_AUTOMAKE="latest"

#MY_P="${PN}-$(replace_version_separator 3 '-')"
#S=${WORKDIR}/${MY_P}

SLOT=$(get_version_component_range 1-2)
MY_SUFFIX=$(delete_version_separator 1 ${SLOT})


src_unpack() {
	unpack ${A} &&
		mv ruby-enterprise-1.8.6-20090201/source ${S} &&
		cd ${S}

	# Fix a hardcoded lib path in configure script
	sed -i -e "s:\(RUBY_LIB_PREFIX=\"\${prefix}/\)lib:\1$(get_libdir):" \
		configure.in || die "sed failed"

	eautoreconf
}

src_compile() {
	# -fomit-frame-pointer makes ruby segfault, see bug #150413.
	filter-flags -fomit-frame-pointer

	# In many places aliasing rules are broken; play it safe
	# as it's risky with newer compilers to leave it as it is.
	append-flags -fno-strict-aliasing

	# Socks support via dante
	if use socks5 ; then
		# Socks support can't be disabled as long as SOCKS_SERVER is
		# set and socks library is present, so need to unset
		# SOCKS_SERVER in that case.
		unset SOCKS_SERVER
	fi

	# Increase GC_MALLOC_LIMIT if set (default is 8000000)
	if [ -n "${RUBY_GC_MALLOC_LIMIT}" ] ; then
		append-flags "-DGC_MALLOC_LIMIT=${RUBY_GC_MALLOC_LIMIT}"
	fi

	econf --program-suffix=$MY_SUFFIX --enable-shared \
		$(use_enable socks5 socks) \
		$(use_enable doc install-doc) \
		$(use_enable ipv6) \
		$(use_enable debug) \
		$(use_with berkdb dbm) \
		$(use_with gdbm) \
		$(use_with ssl openssl) \
		$(use_with tk) \
		${myconf} \
		--with-sitedir=/usr/$(get_libdir)/ruby/site_ruby \
		--enable-option-checking=no \
		|| die "econf failed"

	mkdir -p .ext/common

	if ! grep '\$(PRELIBS)' Makefile; then
		sed -e 's/^LIBS = \(.*\)$/LIBS = $(PRELIBS) \1/g' -i Makefile
	fi

	epatch "${FILESDIR}/ruby-enterprise-1.8.6-20090113-build_fixes.patch"

	emake EXTLDFLAGS="${LDFLAGS}" PRELIBS="-ltcmalloc_minimal" || die "emake failed"
}

src_test() {
	emake -j1 test || die "make test failed"

	elog "Ruby's make test has been run. Ruby also ships with a make check"
	elog "that cannot be run until after ruby has been installed."
	elog
	if use rubytests; then
		elog "You have enabled rubytests, so they will be installed to"
		elog "/usr/share/${PN}-${SLOT}/test. To run them you must be a user other"
		elog "than root, and you must place them into a writeable directory."
		elog "Then call: "
		elog
		elog "ruby -C /location/of/tests runner.rb"
	else
		elog "Enable the rubytests USE flag to install the make check tests"
	fi
}

src_install() {
	LD_LIBRARY_PATH="${D}/usr/$(get_libdir)"
	RUBYLIB="${S}:${D}/usr/$(get_libdir)/ruby/${SLOT}"
	for d in $(find "${S}/ext" -type d) ; do
		RUBYLIB="${RUBYLIB}:$d"
	done
	export LD_LIBRARY_PATH RUBYLIB

	emake DESTDIR="${D}" install || die "make install failed"

	MINIRUBY=$(echo -e 'include Makefile\ngetminiruby:\n\t@echo $(MINIRUBY)'|make -f - getminiruby)
	keepdir $(${MINIRUBY} -rrbconfig -e "print Config::CONFIG['sitelibdir']")
	keepdir $(${MINIRUBY} -rrbconfig -e "print Config::CONFIG['sitearchdir']")

	if use doc; then
		make DESTDIR="${D}" install-doc || die "make install-doc failed"
	fi

	if use examples; then
		dodir /usr/share/doc/${PF}
		cp -pPR sample "${D}/usr/share/doc/${PF}"
	fi

	dosym libruby$MY_SUFFIX$(get_libname ${PV%_*}) /usr/$(get_libdir)/libruby$(get_libname ${PV%.*})
	dosym libruby$MY_SUFFIX$(get_libname ${PV%_*}) /usr/$(get_libdir)/libruby$(get_libname ${PV%_*})

	dodoc ChangeLog NEWS README* ToDo

	if use rubytests; then
		dodir /usr/share/${PN}-${SLOT}
		cp -pPR test "${D}/usr/share/${PN}-${SLOT}"
	fi
}

pkg_postinst() {
	if [[ ! -n $(readlink "${ROOT}"usr/bin/ruby) ]] ; then
		eselect ruby set ruby${MY_SUFFIX}
	fi

	elog
	elog "This ebuild is compatible to eselect-ruby"
	elog "To switch between available Ruby profiles, execute as root:"
	elog "\teselect ruby set ruby(18|19|...)"
	elog
}

pkg_postrm() {
	if [[ ! -n $(readlink "${ROOT}"usr/bin/ruby) ]] ; then
		eselect ruby set ruby${MY_SUFFIX}
	fi
}
