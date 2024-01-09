// ballRLV_wear.lsl - RLV force wear one or more layers or attachment points.
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
// Locking a single attachment point:
// 1. lock everything as part of the initialization
// 2. unlock attachment point
// 3. force wear target folder
// 4. lock everything again

list    notecardSeperators    = ["  |  ","  | "," |  "," | "," |","| ","|"];
list    attachmentsSeperators = ["  ,  ","  , "," ,  "," , "," ,",", ",","];
key     gTargetKey       = NULL_KEY;
key     gOperatorKey     = NULL_KEY;

key     gBallUUID          = NULL_KEY;
integer gRlvChannel        = -1812221819; // relay listen channel.
integer gRlvListenHandle   = -1;

string  gRlvCommand        = "";
string  gCommand           = ""; // command from ballMain

string  gFolderName      = "~virtoys"; // if RLV. section folder.

list    gAttachmentPoints = ["chest","skull",
            "left shoulder","right shoulder","left hand","right hand","left foot",
            "right foot","spine","pelvis","mouth","chin","left ear","right ear",
            "left eyeball","right eyeball","nose","r upper arm","r forearm","l upper arm",
            "l forearm","right hip","r upper leg","r lower leg","left hip","l upper leg",
            "l lower leg","stomach","left pec","right pec","center 2","top right",
            "top","top left","center","bottom left","bottom","bottom right","neck", "root"
        ];
list    gLayers = [
            "gloves","jacket","pants","shirt","shoes","skirt","socks",
            "underpants","undershirt","skin","eyes","hair","shape","alpha","tattoo", "physics"
        ];

list    setupList = ["!implversion","!version","@unsit=n","@addoutfit=n","@detach:chest=n",
        "@detach:skull=n", "@detach:left shoulder=n","@detach:right shoulder=n",
        "@detach:left hand=n","@detach:right hand=n","@detach:left foot=n",
        "@detach:right foot=n","@detach:spine=n","@detach:pelvis=n","@detach:mouth=n",
        "@detach:chin=n","@detach:left ear=n","@detach:right ear=n", "@detach:left eyeball=n",
        "@detach:right eyeball=n","@detach:nose=n","@detach:r upper arm=n","@detach:r forearm=n",
        "@detach:l upper arm=n", "@detach:l forearm=n","@detach:right hip=n",
        "@detach:r upper leg=n","@detach:r lower leg=n","@detach:left hip=n","@detach:l upper leg=n",
        "@detach:l lower leg=n","@detach:stomach=n","@detach:left pec=n","@detach:right pec=n",
        "@detach:center 2=n","@detach:top right=n", "@detach:top=n","@detach:top left=n",
        "@detach:center=n","@detach:bottom left=n","@detach:bottom=n","@detach:bottom right=n",
        "@detach:neck=n","@detach:root=n"
        ];
integer gSetupListLineNumber = 0;

list    gAttachList = [];
integer glistLineNumber = 0;

integer gTimerEnd = 5;     // seconds. 60 = 1 minute

start_attach(string attachments, string folder) { // make list of RLV commands
    glistLineNumber = 0;
    gAttachList = [];
    if ( attachments == "all" ) {
        //
    } else {
        list ltmp = llParseString2List(attachments, attachmentsSeperators, []);
        integer n=0;
        for ( n=0; n<llGetListLength(ltmp); n++ )
            gAttachList += "@addoutfit:"+ llList2String(ltmp,n) +"=y";
        for ( n=0; n<llGetListLength(ltmp); n++ )
            gAttachList += "@detach:"+ llList2String(ltmp,n) +"=y";
        gAttachList += "@attachall:"+folder+"=force";
    }
}
target_attach() {
    if ( glistLineNumber >= llGetListLength(gAttachList) ) {
        llListenRemove(gRlvListenHandle);
        llSetTimerEvent(0);
        llMessageLinked(LINK_THIS, 1, gCommand, (key)"ballMain");
        glistLineNumber = 0;
    } else {
        gRlvCommand = llList2String(gAttachList,glistLineNumber);
        gRlvListenHandle = llListen(gRlvChannel, "", NULL_KEY, "");
        llSay(gRlvChannel, "rlvAttach," + (string)gTargetKey + "," + gRlvCommand); // next line
        llSetTimerEvent(gTimerEnd);
        glistLineNumber++;
    }
}


default {

    on_rez(integer start_param) {
        gBallUUID = llGetKey();
    }

    link_message(integer sender_number, integer number, string message, key id) {
        if ( (string)id != "ballRLV_wear" ) {
            return;
        }

        list ltmp = llParseString2List(message, notecardSeperators, []);
        string cmd      = llList2String(ltmp,0);
        string cmdVal   = llList2String(ltmp,1);
        string cmdParam = llList2String(ltmp,2);
        gTargetKey      = (key)llList2String(ltmp,3);

        gCommand = cmd + " | " + cmdVal;
        if ( cmdParam != "" ) {
            gCommand += " | " + cmdParam;
        }

        if ( cmd == "section_wear" ) { // F.ex. section_wear | all
            if ( gTargetKey == NULL_KEY ) {
                llMessageLinked(LINK_THIS, -1, message + ", target_key not set", (key)"ballMain");
            }
            else {
                start_attach(cmdVal, cmdParam);
                target_attach();
            }
        }

        if ( cmd == "target_attach" ) { // F.ex. target_attach | all | ~virToys
            if ( gTargetKey == NULL_KEY ) {
                llMessageLinked(LINK_THIS, -1, message + ", target_key not set", (key)"ballMain");
            }
            else {
                start_attach(cmdVal, cmdParam);
                target_attach();
            }
        }

    }

    listen(integer channel, string name, key id, string message) { // listen on channel gObjectChannel

        list ltmp      = llParseString2List(message, [","], []);
        string cmd_name     = llList2String(ltmp,0);
        string object_uuid  = llList2String(ltmp,1);
        string command      = llList2String(ltmp,2);
        string reply        = llList2String(ltmp,3);

        if ( cmd_name == "rlvAttach" && object_uuid == (string)gBallUUID && command == gRlvCommand && reply == "ok" ) {
            llListenRemove(gRlvListenHandle);
            llSetTimerEvent(0);
            gRlvCommand = "";
            target_attach();
        }

    }

    timer() {
        if ( gRlvCommand != "" ) {
            llMessageLinked(LINK_THIS, -1, gCommand, (key)"ballMain");
        }
        gRlvCommand = "";
        llSetTimerEvent(0);
        llListenRemove(gRlvListenHandle);
    }

}
