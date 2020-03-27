#! /bin/bash -e

# Remove stable updates (optional).
sed -i '/jessie-updates/d' /etc/apt/sources.list

apt-get update
apt-get install -yq \
    bash-completion \
    bcc \
    bin86 \
    build-essential \
    byobu \
    ca-certificates \
    chrpath \
    coreutils \
    cpio \
    curl \
    cvs \
    desktop-file-utils \
    diffstat \
    docbook-utils \
    dosfstools \
    file \
    g++ \
    gawk \
    gcc \
    genisoimage \
    git-core \
    guilt \
    help2man \
    iasl \
    iputils-ping \
    libc6-dev-i386 \
    libelf-dev \
    libncurses5-dev \
    libsdl1.2-dev \
    liburi-perl \
    locales \
    make \
    man \
    mtools \
    openssh-server \
    openssl \
    policycoreutils \
    python-pysqlite2 \
    python3 \
    quilt \
    rpm \
    screen \
    sed \
    subversion \
    sudo \
    texi2html \
    texinfo \
    unzip \
    vim \
    wget \
    xorriso

# Remove packages lists.
rm -rf "/var/lib/apt-lists/"*

# Change default shell to bash.
echo "dash dash/sh boolean false" | debconf-set-selections
DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash

# Make sure "en_US.UTF-8" locale is available.
echo "locales locales/locales_to_be_generated multiselect en_US.UTF-8 UTF-8" | debconf-set-selections
echo "locales locales/default_environment_locale select en_US.UTF-8" | debconf-set-selections
sed -i 's|# en_US.UTF-8 UTF-8|en_US.UTF-8 UTF-8|' /etc/locale.gen
DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales

# Install GHC6 prerequisites.
mkdir -p "/tmp/ghc-prereq"
cd "/tmp/ghc-prereq"
wget "http://archive.debian.org/debian/pool/main/g/gmp/libgmpxx4ldbl_4.3.2+dfsg-1_amd64.deb"
wget "http://archive.debian.org/debian/pool/main/g/gmp/libgmp3c2_4.3.2+dfsg-1_amd64.deb"
wget "http://archive.debian.org/debian/pool/main/g/gmp/libgmp3-dev_4.3.2+dfsg-1_amd64.deb"
dpkg -i \
    "libgmp3-dev_4.3.2+dfsg-1_amd64.deb" \
    "libgmp3c2_4.3.2+dfsg-1_amd64.deb" \
    "libgmpxx4ldbl_4.3.2+dfsg-1_amd64.deb"
cd "/tmp"
rm -rf "/tmp/ghc-prereq"

# Install GHC6.
cd "/tmp"
wget "https://downloads.haskell.org/~ghc/6.12.3/ghc-6.12.3-x86_64-unknown-linux-n.tar.bz2"
tar jxf "ghc-6.12.3-x86_64-unknown-linux-n.tar.bz2"
rm "ghc-6.12.3-x86_64-unknown-linux-n.tar.bz2"
cd "ghc-6.12.3"
./configure --prefix="/usr"
make install
cd /tmp
rm -rf "ghc-6.12.3"

# Get Google Repo.
curl "http://storage.googleapis.com/git-repo-downloads/repo" > /usr/local/bin/repo
chmod a+x "/usr/local/bin/repo"

# Quirk for ocaml-native from meta-openxt-ocaml-platform
# Error: ocaml-4.04.2/config/auto-aux/tst: No such file or directory
ln -s /lib64/ld-linux-x86-64.so.2 /lib/
