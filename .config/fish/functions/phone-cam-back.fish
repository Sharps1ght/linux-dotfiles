function phone-cam-back --wraps="scrcpy -e --video-source=camera --camera-id=0 --camera-size=1920x1080 --camera-fps=60 --no-audio -b 5M --no-playback"
    set -l v4l2_dev ""
    for v in /dev/video*
        if v4l2-ctl -D -d "$v" 2>/dev/null | grep -q "v4l2 loopback"
            set v4l2_dev "$v"
            break
        end
    end

    if test -z "$v4l2_dev"
        echo "No v4l2loopback device found, creating one..."
        sudo modprobe -r v4l2loopback 2>/dev/null
        and sudo modprobe v4l2loopback video_nr=2 exclusive_caps=1
        set v4l2_dev /dev/video2
        set -l tries 0
        while test ! -c "$v4l2_dev"; and test $tries -lt 50
            sleep 0.05
            set tries (math $tries + 1)
        end
    end

    if test ! -c "$v4l2_dev"
        echo "Error: could not find or create v4l2loopback device" >&2
        return 1
    end

    scrcpy -e --no-window --video-source=camera --camera-id=0 --camera-size=1920x1080 --camera-fps=60 --no-audio -b 5M --no-playback --capture-orientation=flip180 --v4l2-sink="$v4l2_dev" $argv
end
