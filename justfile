set dotenv-load

default: run

gradle := "JAVA_HOME=/opt/android-studio/jbr ./android/gradlew -p android"

run:
    adb install -r $({{gradle}} :app:assembleDebug -q > /dev/null && find android/app/build/outputs -name "*.apk" | head -1)

build-release:
    {{gradle}} :app:assembleRelease

install-release:
    adb install -r $({{gradle}} :app:assembleRelease -q > /dev/null && find android/app/build/outputs -name "*release*.apk" | head -1)

deploy: build-release
    cp $(find android/app/build/outputs -name "*release*.apk" | head -1) ~/pCloudDrive/android-apps/coach/
