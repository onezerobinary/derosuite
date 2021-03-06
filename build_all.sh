#!/usr/bin/env bash

package=$1
package="github.com/deroproject/derosuite/cmd/derod"
package_split=(${package//\// })
package_name=${package_split[-1]}


CURDIR=`/bin/pwd`
BASEDIR=$(dirname $0)
ABSPATH=$(readlink -f $0)
ABSDIR=$(dirname $ABSPATH)


PLATFORMS="darwin/amd64" # amd64 only as of go1.5
PLATFORMS="$PLATFORMS windows/amd64 windows/386" # arm compilation not available for Windows
PLATFORMS="$PLATFORMS linux/amd64 linux/386"
#PLATFORMS="$PLATFORMS linux/ppc64le"   is it common enough ??
#PLATFORMS="$PLATFORMS linux/mips64le" # experimental in go1.6 is it common enough ??
PLATFORMS="$PLATFORMS freebsd/amd64 freebsd/386"
PLATFORMS="$PLATFORMS netbsd/amd64" # amd64 only as of go1.6
PLATFORMS="$PLATFORMS openbsd/amd64" # amd64 only as of go1.6
PLATFORMS="$PLATFORMS dragonfly/amd64" # amd64 only as of go1.5
#PLATFORMS="$PLATFORMS plan9/amd64 plan9/386" # as of go1.4, is it common enough ??
PLATFORMS="$PLATFORMS solaris/amd64" # as of go1.3


PLATFORMS_ARM="linux freebsd netbsd"

type setopt >/dev/null 2>&1

SCRIPT_NAME=`basename "$0"`
FAILURES=""
CURRENT_DIRECTORY=${PWD##*/}
OUTPUT="$package_name" # if no src file given, use current dir name
OUTPUT_DIR="$ABSDIR/build/"

for PLATFORM in $PLATFORMS; do
  GOOS=${PLATFORM%/*}
  GOARCH=${PLATFORM#*/}
  BIN_FILENAME="${OUTPUT}-${GOOS}-${GOARCH}"
  if [[ "${GOOS}" == "windows" ]]; then BIN_FILENAME="${BIN_FILENAME}.exe"; fi
  CMD="GOOS=${GOOS} GOARCH=${GOARCH} go build -o $OUTPUT_DIR/${BIN_FILENAME} $package"
  echo "${CMD}"
  eval $CMD || FAILURES="${FAILURES} ${PLATFORM}"
done

# ARM64 builds only for linux
if [[ $PLATFORMS_ARM == *"linux"* ]]; then 
  CMD="GOOS=linux GOARCH=arm64 go build -o $OUTPUT_DIR/${OUTPUT}-linux-arm64 $package"
  echo "${CMD}"
  eval $CMD || FAILURES="${FAILURES} ${PLATFORM}"
fi



for GOOS in $PLATFORMS_ARM; do
  GOARCH="arm"
  # build for each ARM version
  for GOARM in 7 6 5; do
    BIN_FILENAME="${OUTPUT}-${GOOS}-${GOARCH}${GOARM}"
    CMD="GOARM=${GOARM} GOOS=${GOOS} GOARCH=${GOARCH} go build -o $OUTPUT_DIR/${BIN_FILENAME} $package"
    echo "${CMD}"
    eval "${CMD}" || FAILURES="${FAILURES} ${GOOS}/${GOARCH}${GOARM}" 
  done
done

# eval errors
if [[ "${FAILURES}" != "" ]]; then
  echo ""
  echo "${SCRIPT_NAME} failed on: ${FAILURES}"
  exit 1
fi
