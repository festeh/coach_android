set dotenv-load

default: run

gradle := "JAVA_HOME=/opt/android-studio/jbr WEBSOCKET_URL=$WEBSOCKET_URL ./android/gradlew -p android"

run:
    {{gradle}} :app:assembleDebug
    adb install -r $(find build/app/outputs -name "*.apk" | head -1)

build-release:
    {{gradle}} :app:assembleRelease

install-release:
    {{gradle}} :app:assembleRelease
    adb install -r $(find build/app/outputs -name "*release*.apk" | head -1)

deploy: build-release
    cp $(find build/app/outputs -name "*release*.apk" | head -1) ~/pCloudDrive/android-apps/coach/
