// program.lsl - Read the program from the .program notecard.
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

//Notecard Reading template
//Copyright 2007, Gigs Taggart
//Released under BSD license
//http://www.opensource.org/licenses/bsd-license.php

key     gSetupQueryId;
integer gSetupNotecardLine = 0;
string  gSetupNotecardName = ".program";
list    notecardSeperators = ["  |  ","  | "," |  "," | "," |","| ","|"];
// list    chatSeperators     = ["  :  ","  : "," :  "," : "," :",": ",":"];

string  gSuffix;
list    gSetupList = [];
integer gSetupListLineNumber = 0;


// Load the settings from a notecard
loadNoteCard( string i_notecardName ) {
    // Faster events while processing our notecard
    llMinEventDelay(0);
    if ( llGetInventoryKey(i_notecardName) == NULL_KEY ) {
        llOwnerSay( "Notecard '" + i_notecardName + "' does not exist." );
        return;
    }
    llOwnerSay( "Loading notecard '" + i_notecardName + "'..." );
    gSetupQueryId = llGetNotecardLine(i_notecardName,0); // Start reading the data
}

main(string message, integer number) {
    if ( message == "program_start" ) {
        gSetupListLineNumber = 0;
        llMessageLinked(LINK_SET, 0, llList2String(gSetupList,gSetupListLineNumber), (key)"main");
    }
    string progLine = llList2String(gSetupList,gSetupListLineNumber);
    list   ltmp = llParseString2List(progLine, notecardSeperators, []);
    string cmd = llList2String(ltmp,0);
    if ( message == cmd ) {
        if ( number == 1 ) {
            gSetupListLineNumber++;
            llMessageLinked(LINK_SET, 0, llList2String(gSetupList,gSetupListLineNumber), (key)"main");
        }
    }
}


default {

    state_entry() {
        list ltmp = llParseString2List(llGetScriptName(), ["."], []);
        gSuffix = llList2String(ltmp,1);
        if ( gSuffix != "" ) gSuffix = "." + gSuffix;
        loadNoteCard( gSetupNotecardName + gSuffix); 
    }

    dataserver(key queryId, string data) {
        if ( queryId == gSetupQueryId ) {
            integer i;
            if ( data != EOF )  {
                //remove comments
                i = llSubStringIndex(data,"//");
                if (i != -1) {
                    if (i == 0) data = "";
                    else data = llGetSubString(data, 0, i - 1);
                }
                // remove spaces from end
                while (llGetSubString(data, -1, -1) == " ") data = llDeleteSubString(data, -1, -1); 
                // add data
                if ( data != "" )
                    gSetupList += data;
                // read next line of menuitems notecard
                gSetupQueryId = llGetNotecardLine(gSetupNotecardName + gSuffix,++gSetupNotecardLine); 
            } else {
                llOwnerSay( "Finished reading notecard '" + gSetupNotecardName + gSuffix +"'." );
            }
        }
    }

    changed(integer change) {
        if ( change & CHANGED_OWNER )
            llResetScript();
        if ( change & CHANGED_INVENTORY )
            llResetScript();
    }

    link_message(integer sender_number, integer number, string message, key id) {
        if ( (string)id == llGetScriptName() || (string)id == "all" )
            main(message,number);
    }

}

