#!/bin/bash

# run this on macOS
PLATFORM="${TEXTURE_BUILD_PLATFORM:-platform=macOS,name=MacBook Pro}"
SDK="${TEXTURE_BUILD_SDK:-macosx}"
DERIVED_DATA_PATH="$HOME/ASDKDerivedData"

# It is pitch black.
set -e
function trap_handler {
    echo -e "\n\nOh no! You walked directly into the slavering fangs of a lurking grue!"
    echo "**** You have died ****"
    exit 255
}
trap trap_handler INT TERM EXIT

# Derived data handling
if [ ! -d "$DERIVED_DATA_PATH" ]; then
    mkdir -p "$DERIVED_DATA_PATH"
fi

function clean_derived_data {
    find "$DERIVED_DATA_PATH" -mindepth 1 -delete
}

# Build example
function build_example {
    example="$1"

    clean_derived_data

    if [ -f "${example}/Podfile" ]; then
        echo "Using CocoaPods"
        pod install --project-directory="$example"
        
        workspace=$(ls -d "${example}"/*.xcworkspace)
        filename=$(basename -- "$workspace")
        scheme="${filename%.*}"
        
        set -o pipefail && xcodebuild \
            -workspace "${workspace}" \
            -scheme "$scheme" \
            -sdk "$SDK" \
            -derivedDataPath "$DERIVED_DATA_PATH" \
            build
    elif [ -f "${example}/Cartfile" ]; then
        echo "Using Carthage"
        local_repo="$(pwd)"
        current_branch=$(git rev-parse --abbrev-ref HEAD)
        cd "$example"

        echo "git \"file://${local_repo}\" \"${current_branch}\"" > "Cartfile"
        carthage update --no-use-binaries --no-build --platform macOS
        carthage build --no-skip-current --use-xcframeworks

        set -o pipefail && xcodebuild \
            -project "Sample.xcodeproj" \
            -scheme Sample \
            -sdk "$SDK" \
            build

        cd ../..
     else
        echo "Seems like there are no Cartfile or Podfile in the ${example}"
        echo "Build will be skipped."
    fi
}

function cleanup {
    # remove all Pods directories
    find . -name Pods -type d -exec rm -rf {} +
    find . -name Podfile.lock -type f -delete
}

MODE="$1"

cleanup

case "$MODE" in

examples|all)
    echo "Verifying that all AsyncDisplayKit examples compile."
    for example in examples/*/; do
        echo "Building (examples) $example."

        build_example "$example"
    done
    success="1"
    ;;

examples-pt1)
    echo "Verifying that all AsyncDisplayKit examples compile."
    for example in $(find ./examples -type d -maxdepth 1 ! -iname ".*" | head -6); do
        echo "Building (examples-pt1) $example"

        build_example "$example"
    done
    success="1"
    ;;

examples-pt2)
    echo "Verifying that all AsyncDisplayKit examples compile."
    for example in $(find ./examples -type d -maxdepth 1 ! -iname ".*" | head -11 | tail -5); do
        echo "Building (examples-pt2) $example"

        build_example "$example"
    done
    success="1"
    ;;

examples-pt3)
    echo "Verifying that all AsyncDisplayKit examples compile."
    for example in $(find ./examples -type d -maxdepth 1 ! -iname ".*" | head -16 | tail -5); do
        echo "Building (examples-pt3) $example"

        build_example "$example"
    done
    success="1"
    ;;

examples-pt4)
    echo "Verifying that all AsyncDisplayKit examples compile."
    for example in $(find ./examples -type d -maxdepth 1 ! -iname ".*" | tail -n +17); do
        echo "Building (examples-pt4) $example"

        build_example "$example"
    done
    success="1"
    ;;

examples-extras)
    echo "Verifying that all AsyncDisplayKit examples extras compile."
    for example in $(find ./examples_extra -type d -maxdepth 1 ! -iname ".*"); do
        echo "Building (examples-extra) $example"

        build_example "$example"
    done
    success="1"
    ;;

examples-extra-pt1)
    echo "Verifying that all AsyncDisplayKit examples compile."
    for example in $(find ./examples_extra -type d -maxdepth 1 ! -iname ".*" | head -6); do
        echo "Building (examples-extra-pt1) $example"

        build_example "$example"
    done
    success="1"
    ;;

examples-extra-pt2)
    echo "Verifying that all AsyncDisplayKit examples compile."
    for example in $(find ./examples_extra -type d -maxdepth 1 ! -iname ".*" | head -11 | tail -5); do
        echo "Building (examples-extra-pt2) $example"

        build_example "$example"
    done
    success="1"
    ;;

examples-extra-pt3)
    echo "Verifying that all AsyncDisplayKit examples compile."
    for example in $(find ./examples_extra -type d -maxdepth 1 ! -iname ".*" | tail -n +12); do
        echo "Building (examples-extra-pt3) $example"

        build_example "$example"
    done
    success="1"
    ;;

example)
    # Support building a specific example: sh build.sh example examples/ASDKLayoutTransition
    echo "Verifying $2 compiles."
    build_example "$2"
    success="1"
    ;;

life-without-cocoapods|all)
    echo "Verifying that AsyncDisplayKit functions as a static library."

    set -o pipefail && xcodebuild \
        -workspace "smoke-tests/Life Without CocoaPods/Life Without CocoaPods.xcworkspace" \
        -scheme "Life Without CocoaPods" \
        -sdk "$SDK" \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        build
    success="1"
    ;;

framework|all)
    echo "Verifying that AsyncDisplayKit functions as a dynamic framework (for Swift/Carthage users)."

    set -o pipefail && xcodebuild \
        -project "smoke-tests/Framework/Sample.xcodeproj" \
        -scheme Sample \
        -sdk "$SDK" \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        build
    success="1"
    ;;

carthage|all)
    echo "Verifying carthage works."
    # carthage workaround to slip spm based project
    spm_example_project="examples/ASIGListKitSPM/Sample.xcodeproj"
    carthge_example_project_workaround="examples/ASIGListKitSPM/Sample.carthageSkip"

    set -o pipefail && carthage update --no-use-binaries --no-build && carthage build --no-skip-current --use-xcframeworks
    success="1"
    ;;

*)
    echo "Unrecognized mode '$MODE'."
    ;;
esac

if [ "$success" = "1" ]; then
  trap - EXIT
  exit 0
fi
