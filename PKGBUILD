# Maintainer: Sean Bailey <sean@theonesean.com>
# Contributor: James Fenn <me@jfenn.me>

pkgname=('aight')
pkgver=0.0.0
pkgrel=1
pkgdesc="A command-line tool for getting todo tasks quickly."
arch=('x86_64')
url="https://github.com/theonesean/AIGHT"
license=('GPL3')
depends=('libphobos' 'curl')
makedepends=('git' 'make' 'dmd' 'dub')
provides=('aight')
conflicts=('aight')

source=('git+https://github.com/theonesean/AIGHT')
sha256sums=('SKIP')

pkgver() {
    cd "$srcdir/AIGHT"
    git describe --long --tags | sed 's/^v//;s/\([^-]*-\)g/r\1/;s/-/./g;s/\.rc./rc/g'
}

build() {
    make -C "$srcdir/AIGHT"
}

package() {
    make -C "$srcdir/AIGHT" install DESTDIR="$pkgdir" USEINSTALL="true"
}
