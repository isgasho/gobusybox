#!/bin/bash
set -eux

cd src/cmd/makebb

go generate
go build

# This uses the go.mod in src/
GO111MODULE=on ./makebb ../../../modtest/cmd/dmesg ../../../modtest/cmd/strace
GO111MODULE=auto ./makebb ../../../modtest/cmd/dmesg ../../../modtest/cmd/strace
GO111MODULE=off ./makebb ../../../vendortest/cmd/dmesg ../../../vendortest/cmd/strace

# This has no go.mod!
cd ../../..
GO111MODULE=on ./src/cmd/makebb/makebb modtest/cmd/dmesg modtest/cmd/strace
GO111MODULE=auto ./src/cmd/makebb/makebb modtest/cmd/dmesg modtest/cmd/strace
GO111MODULE=off ./src/cmd/makebb/makebb vendortest/cmd/dmesg vendortest/cmd/strace

TMPDIR=$(mktemp -d)

function ctrl_c() {
  rm -rf $TMPDIR
}
trap ctrl_c INT

(cd $TMPDIR && git clone https://github.com/u-root/u-root)

# Make u-root have modules.
(cd $TMPDIR/u-root && go mod init github.com/u-root/u-root && go mod vendor)
GO111MODULE=auto ./src/cmd/makebb/makebb $TMPDIR/u-root/cmds/*/*

# Disarm vendor directory.
(cd $TMPDIR/u-root && mv vendor vendor2)
GO111MODULE=on ./src/cmd/makebb/makebb $TMPDIR/u-root/cmds/*/*

# This should work as is, too.
GO111MODULE=on ./src/cmd/makebb/makebb github.com/u-root/u-root/cmds/...
rm -rf $TMPDIR


GOPATH_TMPDIR=$(mktemp -d)
function ctrl_c() {
  rm -rf $GOPATH_TMPDIR
}
trap ctrl_c INT

(cd $GOPATH_TMPDIR && GOPATH=$GOPATH_TMPDIR GO111MODULE=off go get -u github.com/u-root/u-root)
GOPATH=$GOPATH_TMPDIR GO111MODULE=off ./src/cmd/makebb/makebb github.com/u-root/u-root/cmds/...
rm -rf $GOPATH_TMPDIR

# try bazel build
(cd src && bazel build :model_bb)