// capture.lsl - Capture target using RLV and the collision event.
// Copyright (C) 2024  Downy Swain

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, version 3.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

key     gTargetKey       = NULL_KEY;
string  gTargetName      = "";

integer gPoseballChannel      = -89; // listen channel for ball commands.
integer gObjectChannel        = -88; // listen channel for machine commands.
integer gObjectListenHandle   = -1;
string  gListenName           = "~ball";

list    notecardSeperators = ["  |  ","  | "," |  "," | "," |","| ","|"];

integer gRlvChannel        = -1812221819; // relay listen channel.
integer gRlvListenHandle   = -1;
float   gTimerEnd          = 2.0;     // seconds. 60 = 1 minutes

key     gOwnerKey = NULL_KEY;

rotation  sectionRotation;
vector    rezPosition = <0, 0, 1.408>;
vector    rezRotation = ZERO_VECTOR; 

default {

    state_entry() {
        gObjectListenHandle = llListen(gObjectChannel, gListenName, NULL_KEY, "");  // listen to ~ball commands.
    }

    collision_start(integer num_detected) {
        if ( llDetectedKey(0) != gTargetKey ) {
            gTargetKey = llDetectedKey(0);
            llSay(gPoseballChannel,"ball_ping");
            llSetTimerEvent(gTimerEnd);
        }
    }

    collision_end(integer num_detected) {
        gTargetKey = NULL_KEY;
    }

    listen(integer channel, string name, key id, string message) { // listen on channel gObjectChannel
        list ltmp      = llParseString2List(message, notecardSeperators, []);
        string cmd     = llList2String(ltmp,0);
        string cmdVal  = llList2String(ltmp,1);
        if ( channel == gObjectChannel ) {
            if ( cmd == "ball_pong" ) { // from poseball, if rezzed
                llSetTimerEvent(0);
                if ( gTargetKey != NULL_KEY ) {
                    llSay(gPoseballChannel, "rlv_capture | " + (string)gTargetKey);
                }
            }
            if ( cmd == "target_key" ) { // from poseball, when sat on
                if ( (key)cmdVal == NULL_KEY || ( gOwnerKey != NULL_KEY && (key)cmdVal != gOwnerKey ) ) {
                    llMessageLinked(LINK_THIS, 0, "capture_end", (key)"main");
                }
                else { // someone's being processed
                    llMessageLinked(LINK_THIS, 0, "capture_start | " + cmdVal, (key)"main");
                }
            }
        }
    }

    timer() {
        // Rez ~ball
        llSetTimerEvent(0);
        sectionRotation =  llGetRot();
        llRezAtRoot("~ball",   llGetPos() + rezPosition*sectionRotation, ZERO_VECTOR, (llEuler2Rot(rezRotation * DEG_TO_RAD)*sectionRotation), 42); 
        llSleep(1.0);
        if ( gTargetKey != NULL_KEY ) {
            llSay(gPoseballChannel, "rlv_capture | " + (string)gTargetKey);
        }
    }

}
