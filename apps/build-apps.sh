#!/bin/bash

export ANDROID_SDK_ROOT=${ANDROID_SDK_ROOT:-$PWD/../android/android-sdk-linux}
ENVOY_URL=${1:-https://example.com/f/}
BUILD=${2:-release}

set -e

git checkout -- *.patch
#CronetNetworking.initializeCronetEngine(getApplicationContext(), ""); // set envoy url here
sed -i "s@, \"\"); // set envoy url here@, \"$ENVOY_URL\");@" ./*.patch

echo build apps-android-wikipedia ...
cd ../android || exit 1
# make it work with okhttp3
git checkout envoy
patch --forward --force -p1 --reject-file=- < envoy3.patch
bash build-envoy.sh "$BUILD"


cd ../apps || exit 2
[[ ! -d apps-android-wikipedia ]] && git clone https://github.com/wikimedia/apps-android-wikipedia
cd apps-android-wikipedia && git checkout 1067302cd39a4fc9228cc7b034488f2bda5202b7 && git checkout .
patch --forward --force -p1 --reject-file=- < ../apps-android-wikipedia.patch

mkdir -p app/libs/
cp "../../android/envoy/build/outputs/aar/envoy-$BUILD.aar" app/libs/envoy.aar
cp "../../android/cronet/cronet-$BUILD.aar" app/libs/cronet.aar
if [[ $BUILD == "debug" ]]; then
    ./gradlew assembleDevDebug
else
    mkdir -p ~/.sign
    ./gradlew assembleRelease || echo 'update values in ~/.sign/signing.properties, see app/signing.properties.sample'
fi
ls "$(pwd)"/app/build/outputs/apk/*/"$BUILD"/*.apk


cd .. || exit 3
[[ ! -d Android ]] && git clone https://github.com/duckduckgo/Android
cd Android && git checkout 2d2daa7d4fa89e405d9e726abf9908aa168f5166 && git checkout .
git submodule update --init
patch --forward --force -p1 --reject-file=- < ../DuckDuckGo-Android.patch

mkdir -p app/libs/
cp "../../android/envoy/build/outputs/aar/envoy-$BUILD.aar" app/libs/envoy.aar
cp "../../android/cronet/cronet-$BUILD.aar" app/libs/cronet.aar
if [[ $BUILD == "debug" ]]; then
    ./gradlew assembleDebug
else
    ./gradlew assembleRelease
fi
ls "$(pwd)/app/build/outputs/apk/$BUILD/duckduckgo-5.41.0-$BUILD.apk"
