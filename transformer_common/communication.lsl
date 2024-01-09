// communication.lsl - Messages to user, or public.
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
string  gTargetName      = "";
string  gObjectName      = "";
string  gListenName      = "VirToys TFE";

main(string message, integer number) {
    list ltmp = llParseString2List(message, notecardSeperators, []);
    string cmd = llList2String(ltmp,0);
    string objectName = llGetObjectName();
    if ( cmd == "engine_name" ) {
        gObjectName = llList2String(ltmp,1);
    }
    if ( cmd == "target_key" ) {
        gTargetKey = (key)llList2String(ltmp,1);
    }
    if ( cmd == "operator_key" ) {
        gOperatorKey = (key)llList2String(ltmp,1);
    }
    if ( cmd == "target_say" ) {
        if ( gTargetKey != NULL_KEY ) {
            llSetObjectName(gObjectName);
            llInstantMessage(gTargetKey,llList2String(ltmp,1));
            llSetObjectName(objectName);
            llMessageLinked(LINK_THIS, 1, message, (key)"main"); // success!
        } else llMessageLinked(LINK_THIS, -1, message + " : No target set.", (key)"main"); // error!
    }
    if ( cmd == "operator_say" ) {
        if ( gOperatorKey != NULL_KEY ) {
            llSetObjectName(gObjectName);
            llInstantMessage(gOperatorKey,llList2String(ltmp,1));
            llSetObjectName(objectName);
            llMessageLinked(LINK_THIS, 1, message, (key)"main");
        } else llMessageLinked(LINK_THIS, -1, message + " : No operator set.", (key)"main"); // error!
    }
    if ( cmd == "section_say" ) {
        llSetObjectName(gObjectName);
        llSay(0,llList2String(ltmp,1));
        llSetObjectName(objectName);
        llMessageLinked(LINK_THIS, 1, message, (key)"main");
    }
    if ( cmd == "section_do" ) {
        llSetObjectName(gObjectName);
        llSay(0,"/me  " + llList2String(ltmp,1) );
        llSetObjectName(objectName);
        llMessageLinked(LINK_THIS, 1, message, (key)"main");
    }
    if ( cmd == "section_whisper" ) {
        llSetObjectName(gObjectName);
        llWhisper(0,llList2String(ltmp,1));
        llSetObjectName(objectName);
        llMessageLinked(LINK_THIS, 1, message, (key)"main");
    }
    
}


default {
    state_entry() {
        gObjectName = llGetObjectName(); // get section name
    }

    link_message(integer sender_number, integer number, string message, key id) {
        // llOwnerSay( "Link message (target): " + (string)sender_number + " + " + (string)number + " + " + message + " + " + (string)id );
        // list ltmp = llParseString2List(message, notecardSeperators, []);
        if ( (string)id == "communication" || (string)id == "all" )
            main(message,number);
    }
}
