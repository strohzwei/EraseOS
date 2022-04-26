BUILDROOT="https://buildroot.org/downloads/buildroot-2022.02.1.tar.gz"
WORKSPACE="workspace"

test -f "buildroot-"*".gz" || wget $BUILDROOT || exit 1
test -d "$WORKSPACE" || mkdir $WORKSPACE && tar xf buildroot-2022.02.1.tar.gz -C $WORKSPACE --strip-components=1 || exit 1

cd "$WORKSPACE" || exit 1


cp ../buildroot.conf ./.config

make -j$(nproc --all)
