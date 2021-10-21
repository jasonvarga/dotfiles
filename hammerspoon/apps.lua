-- Each app is defined by their name, and should contain a table with the following keys:
--   id: the bundle id which can be found by running `bundle-id appname`
--   key: the key to summon the app
--   position: the starting grid position
--   onShow: a function to be called when the app is shown or launched. useful for setting automated layouts.
--   onHide: a function to be called when the app is hidden or quit.
return {
    Code = {
        id = 'com.microsoft.VSCode',
        key = 'c',
        onShow = function()
            if isAppVisible('Ray') and isAppVisible('Safari') then setLayout('Code, Ray, Browser')
            elseif isAppVisible('Safari') then setLayout('Code and Browser') end
        end,
        onHide = function()
            local ray = getApp('Ray')
            if ray then
                if isAppOpen('Code') then ray:hide() else ray:kill() end
            end
            if isAppVisible('Safari') then setLayout('Browser') end
        end
    },
    Safari = {
        id = 'com.apple.Safari',
        key = 'b', -- browser
        onShow = function()
            if isAppVisible('Code') then
                if isAppVisible('Ray') then setLayout('Code, Ray, Browser')
                else setLayout('Code and Browser') end
            end
        end,
        onHide = function()
            if isAppVisible('Code') then
                if isAppVisible('Ray') then setLayout('Code and Ray')
                else setLayout('Code') end
            end
        end
    },
    Slack = {
        id = 'com.tinyspeck.slackmacgap',
        key = 's',
        position = positions.center.tiny,
    },
    Spotify = {
        id = 'com.spotify.client',
        key = 'm', -- music
        position = positions.center.tiny,
    },
    iTerm = {
        id = 'com.googlecode.iterm2',
        key = 'i',
        position = positions.center.tiny,
    },
    Tower = {
        id = 'com.fournova.Tower3',
        key = 'g', -- git
        position = positions.center.large,
    },
    Ray = {
        id = 'be.spatie.ray',
        key = 'r',
        onShow = function()
            if isAppClosed('Code') then getOrOpenApp('Code') end
            if isAppVisible('Safari') then setLayout('Code, Ray, Browser')
            else setLayout('Code and Ray') end
        end,
        onHide = function()
            if isAppVisible('Code') then
                if isAppVisible('Safari') then setLayout('Code and Browser')
                else setLayout('Code') end
            end
        end
    },
    Mimestream = {
        id = 'com.mimestream.Mimestream',
        key = 'e' -- email
    },
    Finder = {
        id = 'com.apple.finder',
        key = 'f'
    },
    Tinkerwell = {
        id = 'de.beyondco.tinkerwell',
        key = 't'
    },
    TablePlus = {
        id = 'com.tinyapp.TablePlus',
        key = 'd' -- database
    },
    Things = {
        id = 'com.culturedcode.ThingsMac',
        key = 'l' -- list
    },
    Messages = {
        position = positions.center.mini,
    },
    Bear = {
        id = 'net.shinyfrog.bear',
        key = 'n' -- notes
    }
}
