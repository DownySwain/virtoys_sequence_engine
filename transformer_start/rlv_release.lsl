// rlv_release.lsl - Nice to have when testing, and get stuck ;-P

integer gPoseballChannel      = -89; // listen channel for ball commands.

default {
    touch_start(integer total_number) {
        llSay(gPoseballChannel, "rlv_command | !release" );
    }
}
