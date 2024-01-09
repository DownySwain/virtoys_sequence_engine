// ballMain.lsl - Listen for commands on the poseball channel, and execute or relay them.
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
integer gPoseballListenHandle = -1;

list    notecardSeperators = ["  |  ","  | "," |  "," | "," |","| ","|"];

vector  gRotation   = <0.0,0.0,90.0>;     // Euler in degrees (like the edit box) 
string  gAnimation  = "factory_doll_sit"; // Put the name of the pose/animation here! 
vector  gBallOffset = <0.0,0.0,1>;        // offset from root;
vector  gOffset     = <0.25,0.0,-0.35>;   // You can play with these numbers to adjust how far the person sits from the ball. ( <X,Y,Z> ) 
float   gVelocity   = 0.01;               // ball speed 
vector  gBallPosition;                    // offset from root;
string  gNewAnimation = "";

key     gTarget = NULL_KEY; 
string  gCommand = ""; // command from ballMain

string  gTitle = "";
integer visible = TRUE; 
float   base_alpha = 1.0; 
key     avatar; 
key     trigger; 

integer moveSwitch = 1;
key dataserver_key = NULL_KEY; 

init() { 
    llSetText(gTitle, <1,1,1>,1);
    if ( llGetInventoryNumber(INVENTORY_ANIMATION) == 0 ) {     //Make sure we actually got something to pose with. 
        gAnimation = "sit"; 
    }
    else {
        if ( llGetInventoryType(gAnimation) == INVENTORY_NONE ) {
            gAnimation = llGetInventoryName(INVENTORY_ANIMATION,0); 
        }
    }
}

show() { 
    visible = TRUE; 
    llSetText(gTitle, <1,1,1>,1);         
    llSetAlpha(base_alpha, ALL_SIDES); 
} 

hide() { 
    visible = FALSE; 
    llSetText("", <1,1,1>,1);
    llSetAlpha(0, ALL_SIDES); 
} 

set_animation(string newAnimation) {
    
    integer perm = llGetPermissions();
    if ( perm & PERMISSION_TRIGGER_ANIMATION ) {
        list anims = llGetAnimationList(llGetPermissionsKey());        // get list of animations
        integer len = llGetListLength(anims);
        integer i;
        
        for (i = 0; i < len; ++i) llStopAnimation(llList2Key(anims, i));
        if ( llGetInventoryType(newAnimation) == INVENTORY_ANIMATION ) {
            llStartAnimation(newAnimation); 
            gAnimation == newAnimation;
            llSay(gObjectChannel,"target_animation | 1");
        }
        else {
            llSay(gObjectChannel,"target_animation | -1");
            llOwnerSay("Listen (~ball): target_animation | -1 ERROR. Animation not found: " + newAnimation);
        }
    }
    
}

object_move_to(vector position) {
    if ( moveSwitch == -1 ) {
        llMessageLinked(LINK_THIS, 0, (string)position, (key)"ballMove1");
    }
    if ( moveSwitch == 1 ) {
        llMessageLinked(LINK_THIS, 0, (string)position, (key)"ballMove2");
    }
    moveSwitch == moveSwitch*-1;
}

ball_move(vector position) { // gBallOffset + section_position;
    vector current = llGetPos();
    position.z = current.z;
    if ( current == position ) {
        return;
    }
    float distance = llVecDist(current,position);
    float intervals = distance/gVelocity;
    vector move = ( position - current ) / intervals;
    integer n = 0;
    for ( n = 0; n < intervals; n++ ) {
        current = current+move;
        object_move_to(current);
    }
    object_move_to(position);
}

ball_offset(string pos) { // section_position;
    vector position = llGetPos() + (vector)pos * llGetRot();
    vector current = llGetPos();
    if ( current == position ) {
        return;
    }
    float distance = llVecDist(current,position);
    float intervals = distance/gVelocity;
    vector move = ( position - current ) / intervals;
    integer n = 0;
    for ( n = 0; n < intervals; n++ ) {
        current = current+move;
        object_move_to(current);
    }
    object_move_to(position);
}

ball_rotate(vector rot) {
    rot = rot * llGetRot();
    rotation x = llEuler2Rot( <rot.x*DEG_TO_RAD, rot.y*DEG_TO_RAD, rot.z*DEG_TO_RAD> );
    rotation new_rot = llGetRot()*x;  // compute global rotation
    llSetRot(new_rot);                // orient the object accordingly            
}

ball_anchor_positions(vector leftwrist, vector rightwrist, vector leftankle, vector rightankle ) {
    vector position = llGetPos();
    vector newPos = position + leftwrist;
    llMessageLinked(LINK_ALL_OTHERS, 0, (string)leftwrist, (key)"leftwrist");
    newPos = position + rightwrist;
    llMessageLinked(LINK_ALL_OTHERS, 0, (string)rightwrist, (key)"rightwrist");
    newPos = position + leftankle;
    llMessageLinked(LINK_ALL_OTHERS, 0, (string)leftankle, (key)"leftankle");
    newPos = position + rightankle;
    llMessageLinked(LINK_ALL_OTHERS, 0, (string)rightankle, (key)"rightankle");
    llSay(gObjectChannel,"ball_anchor_positions | 1");
}

default { 
    state_entry() { 
        gPoseballListenHandle = llListen(gPoseballChannel, "", NULL_KEY, "");  // listen on channel gObjectChannel for ball/machine commands.
        llSitTarget(gOffset, llEuler2Rot(gRotation * DEG_TO_RAD)); 
        init(); 
    }
    
    on_rez(integer start_param) {
        // llSay(gObjectChannel,"ball_uuid | " + (string)llGetKey());
    }

    changed(integer change) { 
        if ( change & CHANGED_LINK ) { 
            avatar = llAvatarOnSitTarget(); 
            if ( avatar != NULL_KEY ) { 
                gTarget = avatar;
                hide(); 
                llSay(gObjectChannel,"target_key | " + (string)gTarget);
                llRequestPermissions(gTarget, PERMISSION_TRIGGER_ANIMATION); 
                llMessageLinked(LINK_ALL_OTHERS, 0, "lockguard_on", gTarget);
                llMessageLinked(LINK_THIS, 0, "target_key | "+(string)gTarget, (key)"restrainedLife");
                llMessageLinked(LINK_THIS, 0, "start_RLV | " + (string)gTarget, (key)"restrainedLife_init"); // lock attachment points, unsit=n, etc
            }
            else { 
                gTarget = NULL_KEY; 
                if ( llKey2Name(llGetPermissionsKey()) != "" && trigger == llGetPermissionsKey() ) { 
                    llStopAnimation(gAnimation); 
                    trigger = NULL_KEY; 
                } 
                llDie();
            } 
        } 
        if ( change & CHANGED_INVENTORY ) { 
            init(); 
        } 
    } 
     
    run_time_permissions(integer perm) { 
        avatar = llAvatarOnSitTarget(); 
        if ( perm & PERMISSION_TRIGGER_ANIMATION && llKey2Name(avatar) != "" && avatar == llGetPermissionsKey() ) { 
            trigger = avatar; 
            llStopAnimation("sit"); 
            llStartAnimation(gAnimation); 
            if ( visible == TRUE ) {
                base_alpha = llGetAlpha(ALL_SIDES); 
            }
            else {
                base_alpha = 1.0; 
            }
            llSetAlpha(0.0,ALL_SIDES); 
        } 
    } 

    link_message(integer sender_number, integer number, string message, key id) {
        
        if ( (string)id != "ballMain" ) {
            return;
        }
        
        list ltmp = llParseString2List(message, notecardSeperators, []);
        string cmd = llList2String(ltmp,0);
        string cmdVal  = llList2String(ltmp,1);
        
        if ( cmd == "RLV_init" ) {
            if ( number == 1 ) {
                llSay(gObjectChannel, "RLV_init | 1");
            }
            if ( number == -1 ) {
                llSay(gObjectChannel, "RLV_init | -1");
                llOwnerSay( "Link message (main): RLV init failed." );
            }
        }
        
        if ( message == gCommand && number == 1 ) {
            llSay(gObjectChannel,gCommand + " | 1");
        }
 
        if ( message == gCommand && number == -1 ) {
            llSay(gObjectChannel,gCommand + " | -1");
        }
 
        gCommand = "";
        
    }

    listen(integer channel, string name, key id, string message) { 
        list ltmp = llParseString2List(message, notecardSeperators, []);
        string cmd     = llList2String(ltmp,0);
        string cmdVal  = llList2String(ltmp,1);

        gCommand = message; // command from section
        
        if ( cmd == "ball_ping" ) { // from capture
            llSay(gObjectChannel,"ball_pong");
        }
        
        if ( cmd == "rlv_capture" ) {
            llMessageLinked(LINK_THIS, 0, message, (key)"restrainedLife");
        }
        
        if ( cmd == "rlv_command" ) {
            llMessageLinked(LINK_THIS, 0, message, (key)"restrainedLife");
        }
        
        if ( cmd == "section_wear" ) { // section_wear | all | ~virToys
            llMessageLinked(LINK_THIS, 0, message + " | " + (string)gTarget, (key)"ballRLV_wear");
        }
        
        if ( cmd == "target_attach" ) { // target_attach | all | ~virToyss
            llMessageLinked(LINK_THIS, 0, message + " | " + (string)gTarget, (key)"ballRLV_wear");
        }
        
        if ( cmd == "section_position" ) {
            gBallPosition = gBallOffset + (vector)cmdVal;
        }
        
        if ( cmd == "ball_move" ) {
            ball_move(gBallPosition);
            llSay(gObjectChannel,"ball_move | 1");
        }
        
        if ( cmd == "ball_velocity" ) {
            gVelocity = (float)cmdVal;
            if ( gVelocity == 0 ) gVelocity = 0.01;
            llSay(gObjectChannel,"ball_velocity | 1");
        }
        
        if ( cmd == "ball_rotate" ) {
            ball_rotate((vector)cmdVal);
            llSay(gObjectChannel,"ball_rotate | 1");
        }
        
        if ( cmd == "ball_offset" ) {
            ball_offset(cmdVal);
            llSay(gObjectChannel,"ball_offset | 1");
        }
        
        if ( cmd == "ball_anchor_positions" ) {
            ball_anchor_positions( (vector)cmdVal, (vector)llList2String(ltmp,2), (vector)llList2String(ltmp,3), (vector)llList2String(ltmp,4));
        }
        
        if ( cmd == "target_animation" ) {
            gNewAnimation = cmdVal;
            set_animation(gNewAnimation);
        }
        
        if ( cmd == "ball_unsit" ) {
            llMessageLinked(LINK_ALL_OTHERS, 0, "", (key)"lockguard_off");
            llSleep(0.2);
            llMessageLinked(LINK_THIS, 0, "rlv_command | !release", (key)"restrainedLife");
            llUnSit(llAvatarOnSitTarget()); // unsit target
            llSay(gObjectChannel,"ball_unsit | 1");
        }
        
        // Plugin commands
        if ( cmd == "hide_undercarriage" ) {
            llMessageLinked(LINK_ALL_OTHERS, 0, "hide", (key)"show_hide");
        }
        if ( cmd == "hide_frame" ) {
            llMessageLinked(LINK_ALL_OTHERS, 0, "hide frame", (key)"show_hide_frame");
        }
        if ( cmd == "show_frame" ) {
            llMessageLinked(LINK_ALL_OTHERS, 0, "show frame", (key)"show_hide_frame");
        }
        if ( cmd == "chains_on" ) {
            llMessageLinked(LINK_ALL_OTHERS, 0, "lockguard_on", avatar);
            llSay(gObjectChannel,"chains_on | 1");
        }
        if ( cmd == "chains_off" ) {
            llMessageLinked(LINK_ALL_OTHERS, 0, "lockguard_off", avatar);
            llSay(gObjectChannel,"chains_off | 1");
        }

    } 
     
}  