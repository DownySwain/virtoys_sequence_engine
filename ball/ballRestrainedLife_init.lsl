// ballRestrainedLife_init.lsl - Check the user's RLV setup, and RLV lock
// all layers and attachment points.
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

key     gBallUUID          = NULL_KEY;
integer gRlvChannel        = -1812221819; // relay listen channel.
integer gRlvListenHandle   = -1;

string  gRlvCommand        = "";
string  gCommand           = ""; // command from ballMain

string  gFolderName      = "~virtoys"; // if RLV. section folder.
integer gInit = FALSE;

list    setupList = ["@unsit=n"]; // "!implversion"??
list    gAttachmentPoints = ["chest","skull","left shoulder","right shoulder","left hand",
            "right hand","left foot","right foot","spine","pelvis","mouth","chin","left ear","right ear",
            "left eyeball","right eyeball","nose","r upper arm","r forearm","l upper arm",
            "l forearm","right hip","r upper leg","r lower leg","left hip","l upper leg",
            "l lower leg","stomach","left pec","right pec","center 2","top right",
            "top","top left","center","bottom left","bottom","bottom right", "neck", "root"
        ];
list    gLayers = [
            "gloves","jacket","pants","shirt","shoes","skirt","socks","underpants","undershirt",
            "skin","eyes","hair","shape","alpha","tattoo", "physics"
        ];
integer gSetupListLineNumber = 0;
integer gTimerEnd = 10;     // seconds. 60 = 1 minute


next_init() {
    // RLV lock every attackment point and layer on initialization.
    if ( gSetupListLineNumber >= llGetListLength(setupList) ) {
        llSay(gRlvChannel, "rlvVersion," + (string)gTargetKey + "," + "!version"); // next line
        llMessageLinked(LINK_THIS, 1, "RLV_init | ok", (key)"ballMain");
    } else {
        gRlvCommand = llList2String(setupList,gSetupListLineNumber);
        gRlvListenHandle = llListen(gRlvChannel, "", NULL_KEY, "");
        llSay(gRlvChannel, "rlvInit," + (string)gTargetKey + "," + gRlvCommand); // next line
        llSetTimerEvent(gTimerEnd);
        gSetupListLineNumber++;
        gInit = TRUE;
    }
}


default {
    state_entry() {
        integer n;
        for ( n=0; n < llGetListLength(gLayers); n++ ) {
            setupList += "@addoutfit:"+llList2String(gLayers,n)+"=n";
        }
        for ( n=0; n < llGetListLength(gAttachmentPoints); n++ ) {
            setupList +=  "@detach:"+llList2String(gAttachmentPoints,n)+"=n";
        }
    }
    
    on_rez(integer start_param) {
        gBallUUID = llGetKey();
    }

    link_message(integer sender_number, integer number, string message, key id) {
        if ( (string)id != "restrainedLife_init" ) {
            return;
        }
        
        list ltmp = llParseString2List(message, notecardSeperators, []);
        string cmd = llList2String(ltmp,0);
        string cmdVal  = llList2String(ltmp,1);
        string cmdParam  = llList2String(ltmp,2);
        
        if ( cmd == "start_RLV" ) {
            if ( cmdVal == "" || (key)cmdVal == NULL_KEY )
                llMessageLinked(LINK_THIS, -1, "start_RLV | no target", (key)"ballMain");
            else {
                gTargetKey = (key)cmdVal;
                next_init();
            }
        }

    }

    listen(integer channel, string name, key id, string message) { // listen on channel gObjectChannel
    
        list ltmp      = llParseString2List(message, [","], []);
        string cmd_name     = llList2String(ltmp,0);
        string object_uuid  = llList2String(ltmp,1);
        string command      = llList2String(ltmp,2);
        string reply        = llList2String(ltmp,3);

        if ( channel == gRlvChannel ) {
            
            if ( cmd_name == "rlvVersion" && object_uuid == (string)gBallUUID && command == "!implversion" && reply != "ko" ) {
                llListenRemove(gRlvListenHandle);
                llSetTimerEvent(0);
                return;
            } else if ( cmd_name == "rlvVersion" && object_uuid == (string)gBallUUID && command == "!version" && reply != "ko" ) {
                llListenRemove(gRlvListenHandle);
                llSetTimerEvent(0);
                return;
            } else if ( cmd_name == "rlvInit" && object_uuid == (string)gBallUUID && command == gRlvCommand && reply == "ok" ) {
                next_init();
                return;
            }
            if ( cmd_name == "rlvInit" && object_uuid == (string)gBallUUID && command == gRlvCommand && reply != "ok" ) {
                gInit = FALSE;
                llListenRemove(gRlvListenHandle);
                llSetTimerEvent(0);
                gRlvCommand = "";
                llOwnerSay( "Listen (restrainedLife_init): Error: " +  message );
            }
            
        }
        
    }

    timer() {
        llSetTimerEvent(0);
        llListenRemove(gRlvListenHandle);
    }

}
