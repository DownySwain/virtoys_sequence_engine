// restrainedLife.lsl - Pass RLV commands to poseball.
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
list    notecardSeperators = ["  |  ","  | "," |  "," | "," |","| ","|"];
key     gTargetKey       = NULL_KEY;
key     gOperatorKey     = NULL_KEY;
string  gObjectName      = "";
string  gFolderName      = "~virtoys"; // default RLV folder
string  gSelectedFolder  = "~virtoys"; // default RLV folder
string  gSelectedAvatar  = "Barbie doll"; // default transformation

integer gPoseballChannel      = -89; // listen channel for ball commands.
integer gObjectChannel        = -88; // listen channel for machine commands.
integer gObjectListenHandle   = -1;
string  gListenName = "~ball";
string  gRlvCommand = ""; // llSay() command to ~ball
string  gCommand    = ""; // link_message() command from main
integer gTimerEnd   = 15; // seconds. 60 = 1 minute

default {
    state_entry() {
        gObjectListenHandle = llListen(gObjectChannel, gListenName, NULL_KEY, "");  // listen to ~ball commands.
    }

    link_message(integer sender_number, integer number, string message, key id) {
        if ( (string)id != "restrainedLife" ) {
            return;
        }
        gCommand = message;
        gRlvCommand = message;
        
        list ltmp = llParseString2List(message, notecardSeperators, []);
        string cmd = llList2String(ltmp,0);
        string cmdVal  = llList2String(ltmp,1);
        string cmdParam  = llList2String(ltmp,2);
        
        if ( cmd == "target_key" ) {
            gTargetKey = (key)cmdVal;
        }
            
        if ( cmd == "section_wear" ) {
            if ( gTargetKey == NULL_KEY ) {
                llMessageLinked(LINK_THIS, -1, gCommand + ", target_key not set", (key)"main");
                return;
            }
            gRlvCommand = message + " | " + gFolderName; // F.ex. section_wear | all | ~virToys
            llSay(gPoseballChannel, gRlvCommand );
            gObjectListenHandle = llListen(gObjectChannel, gListenName, NULL_KEY, "");  // listen to ~ball commands.
            llSetTimerEvent(gTimerEnd);
        }
        
        if ( cmd == "target_attach" ) {
            if ( gTargetKey == NULL_KEY ) {
                llMessageLinked(LINK_THIS, -1, gCommand + ", target_key not set", (key)"main");
                return;
            }
            gRlvCommand = message + " | " + gSelectedFolder; // Later program selected
            llSay(gPoseballChannel, gRlvCommand );
            gObjectListenHandle = llListen(gObjectChannel, gListenName, NULL_KEY, "");  // listen to ~ball commands.
            llSetTimerEvent(gTimerEnd);
        }
        
        if ( cmd == "selected_program" ) {
            if ( number == 1 ) {
                gSelectedAvatar = cmdVal;
                gSelectedFolder = cmdParam;
            }
        }
        
        if ( cmd == "rlv_command" ) {
            if ( gTargetKey == NULL_KEY ) {
                llMessageLinked(LINK_THIS, -1, message + ", target_key not set", (key)"main");
                return;
            }
            llSay(gPoseballChannel, gRlvCommand );
            gObjectListenHandle = llListen(gObjectChannel, gListenName, NULL_KEY, "");  // listen to ~ball commands.
            llSetTimerEvent(gTimerEnd);
        }

    }

    listen(integer channel, string name, key id, string message) { // listen on channel gObjectChannel (~ball)
        list ltmp      = llParseString2List(message, notecardSeperators, []);
        string cmd     = llList2String(ltmp,0);
        string cmdVal  = llList2String(ltmp,1);
        
        if ( message == gRlvCommand + " | 1" ) {
            llMessageLinked(LINK_THIS, 1, gCommand, (key)"main");
        }
        if ( message == gRlvCommand + " | -1" ) {
            llMessageLinked(LINK_THIS, -1, gCommand, (key)"main");
        }
        if ( message == gRlvCommand ) {
            llSetTimerEvent(0);
            gRlvCommand = "";
            gCommand = "";
        }
    }

    timer() {
        gCommand = "";
        gRlvCommand = "";
        llSetTimerEvent(0);
    }

}
