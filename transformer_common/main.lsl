// main.lsl - Main script for sections: Get program from notecard, and pass
// commands to poseball or custom scripts. Then pass control to next section. 
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
key     gOperatorKey     = NULL_KEY;
string  gOperatorName    = "";
string  gEngineName      = "";
string  gSectionNext     = "";
integer gIsRLV           = FALSE; // RestrainedLife viewer / relay check. From capture script
key     gballUUID        = NULL_KEY;

integer gPoseballChannel      = -89; // listen channel for ball commands.
integer gObjectChannel        = -88; // listen channel for machine commands.
integer gObjectListenHandle   = -1;

list    notecardSeperators = ["  |  ","  | "," |  "," | "," |","| ","|"];

string  gCurrentCommand = "";
float   gProgramStopTimer = 30.0; // timeout for liked script to respond

string  gSelectedAvatar = "";
string  gFolderName = "~virtoys";
string  gProgramSuffix = "";

target_key (string targetKey) {
    gTargetKey = (key)targetKey;
    llMessageLinked(LINK_THIS, 0, "target_key | "+targetKey, (key)"restrainedLife");
    llMessageLinked(LINK_THIS, 0, "target_key | "+targetKey, (key)"communication");
    llMessageLinked(LINK_THIS, 0, "target_key | "+targetKey, (key)"inventory");
}

operator_key (string operatorKey) {
    gOperatorKey = (key)operatorKey;
    llMessageLinked(LINK_THIS, 0, "operator_key | "+operatorKey, (key)"communication");
    llMessageLinked(LINK_THIS, 0, "operator_key | "+operatorKey, (key)"inventory");
}

engine_name(string cmdVal) {
    gEngineName = cmdVal;
    llMessageLinked(LINK_THIS, 0, "engine_name | "+gEngineName, (key)"communication");
}

program_end() {
    if ( gIsRLV ) {
        llMessageLinked(LINK_THIS, 0, "rlv_command | !release", (key)"restrainedLife");
    }
    llSay(gPoseballChannel,"ball_unsit");
}

section_next() {
    llSay(gObjectChannel, "selected_program | " + gSelectedAvatar + " | " + gFolderName);
    llSay(gObjectChannel, "engine_name | " + gEngineName);
    llSay(gObjectChannel, "target_key | " + (string)gTargetKey);
    llSay(gObjectChannel, "operator_key | " + (string)gOperatorKey);
    llSay(gObjectChannel, "section_next | " + gSectionNext);
    llSay(gObjectChannel, "Is_RLV       | " + (string)gIsRLV);
}

selected_program(string cmdVal,string cmdParam) {
    gSelectedAvatar = cmdVal;
    gFolderName = cmdParam;
    llMessageLinked(LINK_THIS, 1, "selected_program | "+gSelectedAvatar+"|"+gFolderName, (key)"restrainedLife");
}

default {

    state_entry() {
        gTargetKey      = NULL_KEY;
        gTargetName     = "";
        gOperatorKey    = NULL_KEY;
        gOperatorName   = "";
        gSectionNext    = "";
        gIsRLV          = FALSE;
        gballUUID       = NULL_KEY;
        gEngineName     = llGetObjectName(); // default engine name. Set in settings
        gObjectListenHandle = llListen(gObjectChannel, "", NULL_KEY, "");  // listen on channel gObjectChannel for ball/machine commands.
        gSelectedAvatar = "";
        gFolderName = "~virtoys";
    }

    listen(integer channel, string name, key id, string message) { // listen on channel gObjectChannel
        list ltmp = llParseString2List(message, notecardSeperators, []);
        string cmd       = llList2String(ltmp,0);
        string cmdVal    = llList2String(ltmp,1);
        string cmdParam  = llList2String(ltmp,2);
        // from previous section
        if ( cmd == "engine_name" ) {
            engine_name(cmdVal);
        }
        if ( cmd == "section_next" && cmdVal == llGetObjectName() ) {
            state running;
        }
        // from  previous section
        if ( cmd == "target_key" ) { // from poseball, when sat on
            target_key(cmdVal);
        }
        // from control panel, or previous section
        if ( cmd == "operator_key" ) {
            operator_key(cmdVal);
        }
        if ( cmd == "selected_program" ) {
            selected_program(cmdVal,cmdParam);
        }
    }

    link_message(integer sender_number, integer number, string message, key id) {
        if ( (string)id != "main" ) {
            return;
        }
        list ltmp  = llParseString2List(message, notecardSeperators, []);
        string cmd = llList2String(ltmp,0);
        string cmdVal  = llList2String(ltmp,1);
        // capture
        if ( cmd == "capture_start" ) {
            target_key(cmdVal);
            llMessageLinked(LINK_THIS, 0, "rlv_check", (key)"rlv_check");
        }
        // from rlv_check
        if ( message == "rlv_check" ) {
            if ( number == 1 ) {
                state initialize;
                gIsRLV = TRUE;
            }
            if ( number == -1 ) {
                program_end();
                state default;
            }
        }
    }
    
    state_exit() {
        llListenRemove(gObjectListenHandle);
    }

}


state initialize {

    state_entry() {
        llMessageLinked(LINK_THIS, 0, "initialize_start", (key)"initialize");
        llSetTimerEvent(120.0);
    }

    listen(integer channel, string name, key id, string message) { // listen on channel gObjectChannel
    }

    link_message(integer sender_number, integer number, string message, key id) {
        if ( (string)id != "main" ) {
            return;
        }
            
        list ltmp = llParseString2List(message, notecardSeperators, []);
        string cmd     = llList2String(ltmp,0);
        string cmdVal  = llList2String(ltmp,1);
        string cmdParam  = llList2String(ltmp,2);
        // from initialize
        if ( message == "initialize_end" ) {
            if ( number == 1 ) {
                state running;
            } else {
                llOwnerSay("Listen (main, initialize): initialize failed : " + message);
                program_end();
                state default;
            }
        }
        if ( cmd == "selected_program" ) {
            if ( number == 1 ) {
                gSelectedAvatar = cmdVal;
                gFolderName = cmdParam;
            } else {
                // use default program + folder.
            }
        }
    }
    
    timer() {
        program_end();
        state default;
    }
    
    state_exit() {
        llSetTimerEvent(0);
    }

}

state running {
    
    state_entry() {
        gObjectListenHandle = llListen(gObjectChannel, "", NULL_KEY, "");  // listen on channel gObjectChannel for ball/machine commands.
        llSay( gPoseballChannel, "section_position|"+(string)llGetPos() );
        llMessageLinked(LINK_THIS, 0, "program_start", (key)"settings");
        if ( gSelectedAvatar != "" ) {
            gProgramSuffix = "." + gSelectedAvatar;
        }
        integer programCheck = llGetInventoryType("program"+gProgramSuffix);
        if ( programCheck == INVENTORY_NONE ) {
            gProgramSuffix = ""; // use deault program instead
        }
        llMessageLinked(LINK_THIS, 0, "program_start", (key)("program"+gProgramSuffix));
    }

    listen(integer channel, string name, key id, string message) { // listen on channel gObjectChannel
        list ltmp = llParseString2List(message, notecardSeperators, []);
        string cmd     = llList2String(ltmp,0);
        string cmdVal  = llList2String(ltmp,1);
        if ( cmd == "operator_key" ) {
            if ( (key)cmdVal == gTargetKey ) {
                if ( gTargetKey != NULL_KEY ) {
                    llMessageLinked(LINK_THIS, 0, "target_say | You can't quiet reach the control panel", (key)"communication");
                }
            }
            else {
                operator_key(cmdVal);
            }
        }
    }
    
    link_message(integer sender_number, integer number, string message, key id) {
        if ( (string)id != "main" && (string)id != "all" ) {
            return;
        }
        list ltmp     = llParseString2List(message, notecardSeperators, []);
        string cmd    = llList2String(ltmp,0);
        string cmdVal = llList2String(ltmp,1);
        if ( number == 0 ) {
            gCurrentCommand = message;
            // capture
            if ( cmd == "program_end" ) {
                state default;
            }
            if ( cmd == "RLV_on" ) {
                gIsRLV = TRUE;
            }
            if ( cmd == "engine_name" ) {
                gEngineName = cmdVal;
            }
            // program
            if ( cmd == "section_next" ) {
                gSectionNext = cmdVal;
                section_next();
                state default;
            }
            // plugin_command
            if ( cmd == "plugin_command" ) {
                string pluginName    = llList2String(ltmp,1);
                llMessageLinked(LINK_THIS, 0, message, (key)pluginName);
            }
            // poseball
            if ( cmd == "ball_velocity" ) {
                llMessageLinked(LINK_THIS, 0, message, (key)"poseball");
            }
            if ( cmd == "ball_move" ) {
                llMessageLinked(LINK_THIS, 0, message, (key)"poseball");
            }
            if ( cmd == "ball_rotate" ) {
                llMessageLinked(LINK_THIS, 0, message, (key)"poseball");
            }
            if ( cmd == "ball_offset" ) {
                llMessageLinked(LINK_THIS, 0, message, (key)"poseball");
            }
            if ( cmd == "ball_anchor_positions" ) {
                llMessageLinked(LINK_THIS, 0, message, (key)"poseball");
            }
            if ( cmd == "chains_on" ) {
                llMessageLinked(LINK_THIS, 0, message, (key)"poseball");
            }
            if ( cmd == "chains_off" ) {
                llMessageLinked(LINK_THIS, 0, message, (key)"poseball");
            }
            // animation
            if ( cmd == "target_animation" ) {
                llMessageLinked(LINK_THIS, 0, message, (key)"animation");
            }
            // rlv_command
            if ( cmd == "rlv_command" || cmd == "section_wear" || cmd == "target_attach" ) {
                llMessageLinked(LINK_THIS, 0, message, (key)"restrainedLife");
            }
            // communication
            if ( cmd == "target_say" ) {
                llMessageLinked(LINK_THIS, 0, message, (key)"communication");
            }
            if ( cmd == "operator_say" ) {
                llMessageLinked(LINK_THIS, 0, message, (key)"communication");
            }
            if ( cmd == "section_say" ) {
                llMessageLinked(LINK_THIS, 0, message, (key)"communication");
            }
            if ( cmd == "section_do" ) {
                llMessageLinked(LINK_THIS, 0, message, (key)"communication");
            }
            if ( cmd == "section_whisper" ) {
                llMessageLinked(LINK_THIS, 0, message, (key)"communication");
            }
            // inventory
            if ( cmd == "target_give" ) {
                llMessageLinked(LINK_THIS, 0, message, (key)"inventory");
            }
            if ( cmd == "operator_give" ) {
                llMessageLinked(LINK_THIS, 0, message, (key)"inventory");
            }
            // sound
            if ( cmd == "play_sound" ) {
                llMessageLinked(LINK_THIS, 0, message, (key)"sound");
            }
            if ( cmd == "sound_repeat" ) {
                llMessageLinked(LINK_THIS, 0, message, (key)"sound");
            }
            if ( cmd == "sound_off" ) {
                llMessageLinked(LINK_THIS, 0, message, (key)"sound");
            }
            // SLS functions
            if ( cmd == "wait_time" ) {
                llSleep( (float)llList2String(ltmp,1) );
                llMessageLinked(LINK_THIS, 1, cmd, (key)("program"+gProgramSuffix));
            }
            llSetTimerEvent(gProgramStopTimer); // timeout for liked script to respond
            // program_end
            if ( cmd == "ball_unsit" ) {
                program_end();
                state default;
            }
        }
        
        if ( number == 1 ) { // success. Get next command. 
            llMessageLinked(LINK_THIS, 1, cmd, (key)("program"+gProgramSuffix));
            llSetTimerEvent(0.0);
            gCurrentCommand = "";
        }
        
        if ( number == -1 ) { // error
            llOwnerSay("Error in program on line : " + message);
            llMessageLinked(LINK_THIS, 1, cmd, (key)("program"+gProgramSuffix));
            llSetTimerEvent(0.0);
            gCurrentCommand = "";
        }
        
        
    }
    
    timer() {
        gCurrentCommand = "";
        llSetTimerEvent(0.0);
        program_end();
        state default;
    }
        
    state_exit() {
        llSetTimerEvent(0.0);
        llListenRemove(gObjectListenHandle);
    }
    
}
