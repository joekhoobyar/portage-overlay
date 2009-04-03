# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/mysql-ruby/mysql-ruby-2.7.5.ebuild,v 1.9 2008/09/18 20:08:09 maekke Exp $

inherit ruby

DESCRIPTION="A Ruby DNS library"
HOMEPAGE="http://net-dns.rubyforge.org/"
SRC_URI="mirror://rubyforge/${PN}/${P}.tgz"

LICENSE="Ruby"
SLOT="0"
KEYWORDS="alpha amd64 hppa ia64 ~mips ppc ppc64 sparc x86"
IUSE=""

USE_RUBY="ruby18"
DEPEND="virtual/ruby"

src_unpack() {
	unpack ${A}
	cd ${S}
	epatch "${FILESDIR}/${P}-darwin_not_windows.patch"
	epatch "${FILESDIR}/${P}-notify_and_update.patch"
}

src_compile() {
	ruby setup.rb config || die
	ruby setup.rb setup || die
}

src_install() {
	ruby setup.rb install --prefix="${D}" || die
}
