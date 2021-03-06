#!/usr/bin/env bash

function usage {
  echo "Usage: $0 [chrome|chromium|firefox|opera|vivaldi]

  Options:
    -h, --help     Show this message"
}

INSTALL_TYPE="source"
PLATFORM="$(uname | cut -d _ -f 1 | tr '[:upper:]' '[:lower:]')"

if [[ "$(uname -v)" == *"Microsoft"* ]]; then
    PLATFORM="winBash"
    echo "while bash for windows should essentially work, there has no installer been implemented yet."
    echo "try using the install_host_app.bat from bash for windows, that might work, although it is designed for MYSY2/Cygwin"
    #TODO
    exit
fi

if [ "$PLATFORM" == 'darwin' ]; then
  TARGET_DIR_CHROME="$HOME/Library/Application Support/Google/Chrome/NativeMessagingHosts"
  TARGET_DIR_CHROMIUM="$HOME/Library/Application Support/Chromium/NativeMessagingHosts"
  TARGET_DIR_FIREFOX="$HOME/Library/Application Support/Mozilla/NativeMessagingHosts"
  TARGET_DIR_VIVALDI="$HOME/Library/Application Support/Vivaldi/NativeMessagingHosts"
else
  TARGET_DIR_CHROME="$HOME/.config/google-chrome/NativeMessagingHosts"
  TARGET_DIR_CHROMIUM="$HOME/.config/chromium/NativeMessagingHosts"
  TARGET_DIR_FIREFOX="$HOME/.mozilla/native-messaging-hosts"
  TARGET_DIR_VIVALDI="$HOME/.config/vivaldi/NativeMessagingHosts"
fi

while [[ $# -gt 0 ]]; do
  case $1 in
    chrome)
      TARGET_DIR="$TARGET_DIR_CHROME"
      ;;
    chromium)
      TARGET_DIR="$TARGET_DIR_CHROMIUM"
      ;;
    firefox)
      TARGET_DIR="$TARGET_DIR_FIREFOX"
      ;;
    opera)
      TARGET_DIR="$TARGET_DIR_VIVALDI"
      ;;
    vivaldi)
      TARGET_DIR="$TARGET_DIR_VIVALDI"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage
      exit 1
      ;;
  esac
  shift
done

if [ -z "$TARGET_DIR" ]; then
    usage
    exit 1
fi

APP_NAME="passb"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
APP_DIR="${TARGET_DIR}/${APP_NAME}"
ORIGIN_MAINFEST="${DIR}/${APP_NAME}.json"
HOST_MANIFEST_FULL="${TARGET_DIR}/${APP_NAME}.json"
HOST_STARTER_FULL="${TARGET_DIR}/${APP_NAME}.sh"

echo "installing to ${TARGET_DIR} ..."

mkdir -p "${TARGET_DIR}"
mkdir -p "${APP_DIR}"

if [ "$INSTALL_TYPE" == "source" ]; then
    cp "${DIR}/package.json" "${DIR}/yarn.lock" "${APP_DIR}"
    (cd "${APP_DIR}"; yarn install || npm install ) || {
        echo 'Tried "yarn install" and "npm install", but none of them worked. Do you have those tools installed?'
        exit 1;
    }
    SCRIPT_NAME="index.js"
elif [ "$INSTALL_TYPE" == "binary" ]; then
    SCRIPT_NAME="index"
fi

HOST_SCRIPT_FULL="${APP_DIR}/${SCRIPT_NAME}"
cp "${DIR}/${SCRIPT_NAME}" "${HOST_SCRIPT_FULL}"
chmod +x "${HOST_SCRIPT_FULL}"

echo "#!/usr/bin/env bash" > "${HOST_STARTER_FULL}"
for env in "PATH" "HOME" "GNUPGHOME" "PASSWORD_STORE_DIR" "PASSWORD_STORE_GPG_OPTS" "PASSWORD_STORE_ENABLE_EXTENSIONS"; do
[ -z "${!env}" ] || echo "export ${env}=\"${!env}\"" >> "${HOST_STARTER_FULL}"
done
if [ "$INSTALL_TYPE" == "source" ]; then
    echo "node \"${HOST_SCRIPT_FULL}\"" >> "${HOST_STARTER_FULL}"
else
    echo "\"${HOST_SCRIPT_FULL}\"" >> "${HOST_STARTER_FULL}"
fi
chmod +x "${HOST_STARTER_FULL}"
cat "${HOST_STARTER_FULL}"

sed "s/PLACEHOLDER/${HOST_STARTER_FULL////\\/}/" "${ORIGIN_MAINFEST}" > "${HOST_MANIFEST_FULL}"