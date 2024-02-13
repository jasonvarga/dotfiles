-- "Open in Discord" service
-- Allows you to right click a URL and go to "Services > Open in Discord"
--
-- 1. Open Automator.app
-- 2. Create a new "Quick Action"
-- 3. Workflow receieves current "URLs" in "any application" Input is "only URLs"
-- 4. Add a "Run AppleScript" action and paste the script below.
-- 5. Add a "Display Webpages" action
-- 6. Save as "Open in Discord"
--
-- To edit it, it's located in ~/Library/Services

on run {input, parameters}
	set input to input as string
	set input to text 2 thru -1 of input
	set input to "discord://" & input
	return input
end run
