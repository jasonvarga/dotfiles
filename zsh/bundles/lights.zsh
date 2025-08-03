backlight() {
    color=$1

    case $color in
        red)
            backlight_rgb 255 0 0
            ;;
        green)
            backlight_rgb 0 255 0
            ;;
        blue)
            backlight_rgb 0 0 255
            ;;
        purple)
            backlight_rgb 102 0 204
            ;;
        white)
            backlight_rgb 255 255 255
            ;;
        normal)
            backlight purple
            ;;
        on)
            backlight_on
            ;;
        off)
            backlight_off
            ;;
        *)
            echo "Unknown color: $color"
            ;;
    esac
}

backlight_rgb() {
    r=$1
    g=$2
    b=$3
    device="C0:30:D8:39:32:37:38:3D"
    model=H6056

    curl --silent \
     --request PUT \
     --url https://developer-api.govee.com/v1/devices/control \
     --header "Govee-API-Key: $GOVEE_API_KEY" \
     --header 'accept: application/json' \
     --header 'content-type: application/json' \
     --data "
        {
            \"device\": \"$device\",
            \"model\": \"$model\",
            \"cmd\": {
                \"name\": \"color\",
                \"value\": {
                    \"name\": \"Color\",
                    \"r\": $r,
                    \"g\": $g,
                    \"b\": $b
                }
            }
        }
    " > /dev/null
}

backlight_on() {
    device="C0:30:D8:39:32:37:38:3D"
    model=H6056

    curl --silent \
     --request PUT \
     --url https://developer-api.govee.com/v1/devices/control \
     --header "Govee-API-Key: $GOVEE_API_KEY" \
     --header 'accept: application/json' \
     --header 'content-type: application/json' \
     --data "
        {
            \"device\": \"$device\",
            \"model\": \"$model\",
            \"cmd\": {
                \"name\": \"turn\",
                \"value\": \"on\"
            }
        }
    " > /dev/null
}

backlight_off() {
    device="C0:30:D8:39:32:37:38:3D"
    model=H6056

    curl --silent \
     --request PUT \
     --url https://developer-api.govee.com/v1/devices/control \
     --header "Govee-API-Key: $GOVEE_API_KEY" \
     --header 'accept: application/json' \
     --header 'content-type: application/json' \
     --data "
        {
            \"device\": \"$device\",
            \"model\": \"$model\",
            \"cmd\": {
                \"name\": \"turn\",
                \"value\": \"off\"
            }
        }
    " > /dev/null
}

_backlight_for_exit() {
  [ $? -eq 0 ] && backlight green || backlight red
}

backlit() {
  backlight blue
  "$@"
  _backlight_for_exit

  # Restore
  $(
    sleep 2
    backlight normal
  ) &
}
