// rlv_check.lsl - Check the user's RLV version. If no RLV, or a too low 
// RLV version, unsit the user and reset.
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

integer gPoseballChannel      = -89; // listen channel for commands to ball.
integer gViewerChannel        = 123456789; // listen channel for viewer RLV messages.
integer gViewerListenHandle   = -1;
integer gTimerEnd = 5;     // seconds. 60 = 1 minute

string  gRLV_version = "";
string  gSL_version = "";

clean_up() {
    llListenRemove(gViewerListenHandle);
    llSetTimerEvent(0);
}


default {
    state_entry() {
    }

    link_message(integer sender_number, integer number, string message, key id) {
        if ( (string)id != "rlv_check" ) {
            return;
        }
        gViewerListenHandle = llListen(gViewerChannel, "", NULL_KEY, "");  // listen to viewer RLV reply
        llSay(gPoseballChannel, "rlv_command | @version=" + (string)gViewerChannel );
        llSetTimerEvent(gTimerEnd);
    }

    listen(integer channel, string name, key id, string message) { // listen on channel gObjectChannel (~ball)
        list seperators = ["RestrainedLife viewer v"," (","(",")"];
        list RVLtmp = llParseString2List( message, seperators, []);
        gRLV_version = llList2String(RVLtmp,0);
        gSL_version = llList2String(RVLtmp,1);
        float rlv_tmp_val = (float)gRLV_version;
        if ( (float)gRLV_version < 1.2 ) {
            llSay(0,"This machine requires RestrainedLife viewer v1.20 or newer. You'll need to update your viewer in order to use it.");
            llSay(0,"Detected viewer: " + message);
            llSay(gPoseballChannel,"ball_unsit");
            llMessageLinked(LINK_THIS, -1, "rlv_check", (key)"main");
        } else {
            llMessageLinked(LINK_THIS, 1, "rlv_check", (key)"main");
        }
        clean_up();
        
    }

    timer() {
        llSay(0,"This machine requires the RestrainedLife viewer. You'll need to install it first (see http://realrestraint.blogspot.com/).");
        llSay(gPoseballChannel,"ball_unsit");
        clean_up();
    }

}
