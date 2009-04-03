# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/dmalloc/dmalloc-5.5.2-r2.ebuild,v 1.4 2009/03/03 14:22:46 jer Exp $

inherit autotools eutils multilib

DESCRIPTION="tcmalloc from Ruby Enterprise Edition"
HOMEPAGE="http://www.rubyenterpriseedition.com"
SRC_URI="http://rubyforge.org/frs/download.php/51100/ruby-enterprise-1.8.6-20090201.tar.gz"

LICENSE="Ruby"
SLOT="0"
KEYWORDS="amd64 x86"

DEPEND=""

src_unpack() {
	unpack ${A} &&
		mv ruby-enterprise-1.8.6-20090201/source/vendor/google-perftools-0.99.2 ${P} &&
		cd ${P} &&
		eautoconf
}

src_compile() {
	econf --disable-dependency-tracking || die "econf failed!"

	emake libtcmalloc_minimal.la || die "emake failed!"
}

src_install() {
	rm -f "${D}/usr/lib/libtcmalloc_minimal*.*"
	mkdir -p "${D}/usr/lib"
	cp -dpf .libs/libtcmalloc_minimal*.{so,a}* "${D}/usr/lib" || die "installation failed!"
}
