# how to build, you need XCode installed
Open recording-app.xcodeproj and run it locally

# how to recording
1. Local build and run, on the right-top corner, setting and start recording
Or
2. Run prebuilt 'recording-app-ui.app', first run need to 'Cmd+Right Click' to open developer's build then setting and run
Or
3. Use recording.sh to send tcp command, you need launch app first and check it work properly
./recording.sh start -rect=200:200:500:380 -file=/path/to/output.mp4

# how to stop
1. Click 'Stop' button on the menu
Or
2. Use recording.sh to send tcp command
./recording.sh stop

# user permissions
make sure app has "Screen & System Audio Recording" permissions
check at "System Settings" --> "Privacy & Security" --> "Screen & System Audio Recording"
