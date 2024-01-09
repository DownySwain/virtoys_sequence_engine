// poseball.lsl - Pass commands to the poseball.
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

integer gPoseballChannel      = -89; // listen channel for ball commands.
integer gObjectChannel        = -88; // listen channel for machine commands.
integer gObjectListenHandle   = -1;
string  gListenName           = "~ball";
list    notecardSeperators = ["  |  ","  | "," |  "," | "," |","| ","|"];

default {

    state_entry() {
        gObjectListenHandle = llListen(gObjectChannel, gListenName, NULL_KEY, "");  // listen to ~ball commands.
    }

    listen(integer channel, string name, key id, string message) { // listen on channel gObjectChannel
        list ltmp      = llParseString2List(message, notecardSeperators, []);
        string cmd     = llList2String(ltmp,0);
        string cmdVal  = llList2String(ltmp,1);
        if ( cmd == "chains_on" && cmdVal == "1" )
            llMessageLinked(LINK_THIS, 1, "chains_on | " + cmdVal, (key)"main"); // success
        if ( cmd == "chains_off" && cmdVal == "1" )
            llMessageLinked(LINK_THIS, 1, "chains_off | " + cmdVal, (key)"main"); // success
        if ( cmd == "ball_unsit" && cmdVal == "1" )
            llMessageLinked(LINK_THIS, 1, "ball_unsit | " + cmdVal, (key)"main"); // success
        if ( cmd == "ball_velocity" && cmdVal == "1" )
            llMessageLinked(LINK_THIS, 1, "ball_velocity | " + cmdVal, (key)"main"); // success
        if ( cmd == "ball_move" && cmdVal == "1" )
            llMessageLinked(LINK_THIS, 1, "ball_move | " + cmdVal, (key)"main"); // success
        if ( cmd == "ball_rotate" && cmdVal == "1" )
            llMessageLinked(LINK_THIS, 1, "ball_rotate | " + cmdVal, (key)"main"); // success
        if ( cmd == "ball_offset" && cmdVal == "1" )
            llMessageLinked(LINK_THIS, 1, "ball_offset | " + cmdVal, (key)"main"); // success
        if ( cmd == "ball_anchor_positions" && cmdVal == "1" )
            llMessageLinked(LINK_THIS, 1, "ball_anchor_positions | " + cmdVal, (key)"main"); // success
    }

    link_message(integer sender_number, integer number, string message, key id) {
        if ( (string)id != "poseball" ) {
            return;
        }
        list ltmp = llParseString2List(message, notecardSeperators, []);
        string cmd = llList2String(ltmp,0);
        llSay(gPoseballChannel,message);
    }

}

