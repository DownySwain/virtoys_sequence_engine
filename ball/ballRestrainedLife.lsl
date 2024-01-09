// ballRestrainedLife.lsl - Execute RLV commands.
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

integer gRlvChannel        = -1812221819; // relay listen channel.
integer gRlvListenHandle   = -1;
string  gRlvCommand        = "";
string  gCommand           = ""; // command from ballMain

integer gTimerEnd = 15;     // seconds. 60 = 1 minute

default {
    link_message(integer sender_number, integer number, string message, key id) {
        if ( (string)id != "restrainedLife" ) {
            return;
        }
        
        list ltmp = llParseString2List(message, notecardSeperators, []);
        string cmd = llList2String(ltmp,0);
        string cmdVal  = llList2String(ltmp,1);
        string cmdParam  = llList2String(ltmp,2);
        
        gCommand = message;
        
        if ( cmd == "target_key" ) {
            gTargetKey = (key)cmdVal;
        }
    
        if ( cmd == "rlv_capture" ) {
            gTargetKey = (key)cmdVal;
            if ( gTargetKey == NULL_KEY ) {
                llMessageLinked(LINK_THIS, -1, message + ", target_key not set", (key)"ballMain");
            }
            else {
                gRlvListenHandle = llListen(gRlvChannel, "", NULL_KEY, "");
                llSay(gRlvChannel, "ballCapture," + (string)gTargetKey + ",@sit:" + (string)llGetKey() + "=force");
            }
        }

        if ( cmd == "rlv_command" ) {
            gRlvCommand = cmdVal;
            if ( gTargetKey == NULL_KEY ) {
                llMessageLinked(LINK_THIS, -1, message + ", target_key not set", (key)"ballMain");
            }
            else {
                gRlvListenHandle = llListen(gRlvChannel, "", NULL_KEY, "");
                llSay(gRlvChannel, "rlvCommand," + (string)gTargetKey + "," + gRlvCommand);
                llSetTimerEvent(gTimerEnd);
            }
        }

    }

    listen(integer channel, string name, key id, string message) { // listen on channel gObjectChannel
    
        list ltmp      = llParseString2List(message, [","], []);
        string cmd_name     = llList2String(ltmp,0);
        string object_uuid  = llList2String(ltmp,1);
        string command      = llList2String(ltmp,2);
        string reply        = llList2String(ltmp,3);

        if ( message == "rlvCommand," + (string)llGetKey() + "," + gRlvCommand + ",ok" ) {
            llMessageLinked(LINK_THIS, 1, gCommand, (key)"ballMain");
            gRlvCommand = "";
            gCommand = "";
            llListenRemove(gRlvListenHandle);
        }
        
    }

    timer() {
        if ( gCommand != "" ) {
            llMessageLinked(LINK_THIS, -1, gCommand, (key)"ballMain");
        }
        gRlvCommand = "";
        gCommand = "";
        llSetTimerEvent(0);
        llListenRemove(gRlvListenHandle);
    }

}
