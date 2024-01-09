// initialize.lsl - Determine which program to run.
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
list    keywordSeperators  = ["  ;  ","  ; "," ;  "," ; "," ;","; ",";"];
key     gTargetKey       = NULL_KEY;
key     gOperatorKey     = NULL_KEY;
string  gObjectName      = "";
string  gFolderName      = "~virtoys"; // if RLV
string  gDefaultName      = "Default";

integer gPoseballChannel      = -89; // listen channel for commands to ball.
integer gObjectChannel        = -88; // listen channel for  commands to machine.
integer gObjectListenHandle   = -1;
integer gViewerChannel        = 12345678; // listen channel for viewer RLV messages.
integer gViewerListenHandle   = -1;
string  gListenName           = "~ball";
integer gTimerEnd = 120;     // seconds. 60 = 1 minute

integer gSetupListLineNumber = 0;
list    setupList = []; // 

list    gKeywordLines = []; // ex. Barbie doll | Barbie doll; Barbie avatar; Barbie av
integer gKeywordLineNumber = 0;
integer gKeywordNumber = 0; // position in list. Ex. 0:Barbie doll, 1:Barbie avatar, 2:Barbie av
string  gKeyword = ""; // default ex. Barbie doll
list    gConfirmedFolders = []; // list of RLV replies from viewer.
string  gSelectedFolder = ""; // ex. Barbie doll | avatars/dolls/Barbie doll

string  gRLV_version = "";
string  gSL_version = "";
string  gRlvCommand = "";
integer gRLVinit = 0;
integer gSetupEnd = 0;


init() {
    gObjectListenHandle = llListen(gObjectChannel, gListenName, NULL_KEY, "");  // listen to ~ball commands.
    gViewerChannel      = 12345678;
    gViewerListenHandle = llListen(gViewerChannel, "", NULL_KEY, "");  // listen to viewer RLV reply
    gSetupListLineNumber = 0;
    gKeywordLines = [];
    gKeywordLineNumber = 0;
    gKeywordNumber = 0;
    gKeyword = "";
    gConfirmedFolders = [];
    gSelectedFolder = "";
    gRLVinit = 0;
    gSetupEnd = 0;
    llMessageLinked(LINK_THIS, 0, "keywords", (key)"settings");
    llSetTimerEvent(gTimerEnd);
}

next_init() {
    // run version checking etc. first.
    if ( gSetupListLineNumber < llGetListLength(setupList) ) {
        gRlvCommand = llList2String(setupList,gSetupListLineNumber);
        llSay(gPoseballChannel, "rlv_command | " + gRlvCommand );
        gSetupListLineNumber++;
    } else {
        next_keyword();
    }
}

next_keyword() {
    // find RLV folder to transform to
    // note: to do: optional check? - to see if hits are in a folder named "VirToys", "avatars" or "dolls"? -> should rank higher
    if ( gKeywordLineNumber < llGetListLength(gKeywordLines) ) {
        string keywordLine = llList2String(gKeywordLines,gKeywordLineNumber); // ex. Barbie doll | Barbie doll; Barbie avatar; Barbie av
        list   ltmp = llParseString2List( keywordLine, notecardSeperators, []);
        gKeyword = llList2String(ltmp,0); // ex. Barbie doll
        string keywords = llList2String(ltmp,1); // ex. Barbie doll; Barbie avatar; Barbie av
        list   keywordList = llParseString2List(keywords, keywordSeperators, []);
        if ( gKeywordNumber < llGetListLength(keywordList) ) {
            gViewerChannel++;
            gViewerListenHandle = llListen(gViewerChannel, "", NULL_KEY, "");  // listen to viewer RLV reply
            gRlvCommand = "@findfolder:"+str_replace( llList2String(keywordList,gKeywordNumber), " ", "&&")+"="+(string)gViewerChannel;
            llSay(gPoseballChannel, "rlv_command | " + gRlvCommand );
            gKeywordNumber++;
            if ( gKeywordNumber == llGetListLength(keywordList) ) {
                gKeywordNumber = 0;
                gKeywordLineNumber++;
            }
        }
    } else {
        gConfirmedFolders = llListRandomize(gConfirmedFolders,1);
        gSelectedFolder = llList2String(gConfirmedFolders,0);
        if ( gSelectedFolder == "" )
            gSelectedFolder = gDefaultName + " | " + gFolderName;
        llSay( 0, "Checking inventory list for back orders. Stand by." );
        llSay( 0, "Program selected: " + gSelectedFolder );
        gSetupEnd = 1;
    }
}

clean_up() {
    llListenRemove(gObjectListenHandle);
    llListenRemove(gViewerListenHandle);
    llSetTimerEvent(0);
}

string str_replace(string src, string from, string to) { //replaces all occurrences of 'from' with 'to' in 'src'.
    integer len = (~-(llStringLength(from)));
    if(~len) {
        string  buffer = src;
        integer b_pos = -1;
        integer to_len = (~-(llStringLength(to)));
        @loop;//instead of a while loop, saves 5 bytes (and run faster).
        integer to_pos = ~llSubStringIndex(buffer, from);
        if(to_pos) {
            buffer = llGetSubString(src = llInsertString(llDeleteSubString(src, b_pos -= to_pos, b_pos + len), b_pos, to), (-~(b_pos += to_len)), 0x8000);
            jump loop;
        } 
    }
    return src;
}

default {
    state_entry() {
        init();
    }

    link_message(integer sender_number, integer number, string message, key id) {
        if ( (string)id != "initialize" ) {
            return;
        }
        list ltmp = llParseString2List(message, notecardSeperators, []);
        string cmd = llList2String(ltmp,0); 
        string cmdVal  = llList2String(ltmp,1);
        string cmdParam  = llList2String(ltmp,2);
        if ( cmd == "RLV_keywords" ) {
            if ( number == 1 ) {
                gKeywordLines += cmdVal + " | " + cmdParam; // ex. Barbie doll | Barbie doll; Barbie avatar; Barbie av
            } else {
                next_init();
            }
        }
        if ( cmd == "initialize_start" ) {
            init();
        }
    }

    listen(integer channel, string name, key id, string message) { // listen on channel gObjectChannel (~ball)
        list ltmp = llParseString2List(message, notecardSeperators, []);
        string cmd     = llList2String(ltmp,0);
        string cmdVal  = llList2String(ltmp,1);

        if ( channel == gViewerChannel ) {
            if ( message != "" && gKeyword != "" ) {
                string rlv_folder = gKeyword + " | " + llToLower(message);
                integer x;
                integer listLength = llGetListLength(gConfirmedFolders);
                integer is_in_list = FALSE;
                for ( x = 0; x < listLength; x++ ) {
                    if ( llList2String(gConfirmedFolders,x) == rlv_folder )
                        is_in_list = TRUE;
                }
                if ( is_in_list == FALSE ) {
                    gConfirmedFolders += gKeyword + " | " + llToLower(message); // RLV viewer reply in lowercase on @attachall
                }
            }
            llListenRemove(gViewerListenHandle);
            next_init();
            
        }
        
        if ( channel == gObjectChannel ) {
            if ( cmd == "target_key" ) {
                gTargetKey = (key)cmdVal;
            }
            // from poseball, after rlv_init
            if ( cmd == "RLV_init" ) {
                if ( cmdVal == "1" ) {
                    gRLVinit = 1;
                }
                else {
                    gRLVinit = -1;
                }
            }
            
        }
        
        if ( gRLVinit == 1 && gSetupEnd == 1 ) {
            if ( gSelectedFolder != "" ) {
                llMessageLinked(LINK_THIS, 1, "selected_program | " + gSelectedFolder, (key)"main");
                llMessageLinked(LINK_THIS, 1, "selected_program | " + gSelectedFolder, (key)"restrainedLife");
            } else {
                llMessageLinked(LINK_THIS, -1, "selected_program", (key)"main");
                llMessageLinked(LINK_THIS, -1, "selected_program", (key)"restrainedLife");
            }
            llMessageLinked(LINK_THIS, 1, "initialize_end", (key)"main");
            clean_up();
        }
        if ( gRLVinit == -1) {
            llMessageLinked(LINK_THIS, -1, "initialize_end", (key)"main");
            clean_up();
        }
    }

    timer() {
        gRlvCommand = "";
        clean_up();
    }

}
