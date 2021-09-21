<?php

$windows = json_decode(shell_exec('/opt/homebrew/bin/yabai -m query --windows'));
$windows = array_filter($windows, fn ($window) => $window->floating);
$windows = array_map(fn ($window) => $window->id, $windows);

foreach ($windows as $id) {
    shell_exec("/opt/homebrew/bin/yabai -m window $id --minimize");
}
