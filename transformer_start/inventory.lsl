// inventory.lsl - Give user a #RLV folder with the items specified in the .settings notecard.
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
list    listSeperators     = ["  ,  ","  , "," ,  "," , "," ,",", ",","];
key     gTargetKey       = NULL_KEY;
key     gOperatorKey     = NULL_KEY;
string  gTargetName      = "";
string  gFolderName      = "~virtoys";

give_inventory(key target, list items, string message) {
    integer x;
    integer y;
    list inventory;
    integer itemLength = llGetListLength(items);
    for ( y=1; y<itemLength; y++ ) { // list[0] is cmd
        integer itemFound = FALSE;
        for ( x=0; x<llGetInventoryNumber(INVENTORY_ALL); x++ ) {
            if ( llGetInventoryName(INVENTORY_ALL, x) == llList2String(items,y) ) {
                inventory += [llGetInventoryName(INVENTORY_ALL, x)];
                itemFound = TRUE;
            }
        }
        if ( itemFound == FALSE ) {
            llOwnerSay( llList2String(items,y) + " not found in inventory.");
        }
    }
    integer listLength = llGetListLength(inventory);
    if ( listLength > 0 ) {
        llGiveInventoryList(target, "#RLV/" + gFolderName, inventory);
        llMessageLinked(LINK_THIS, 1, message, (key)"main"); // success!
    } else {
        llMessageLinked(LINK_THIS, -1, message + " : No items found.", (key)"main"); // error!
    }
}

default {

    link_message(integer sender_number, integer number, string message, key id) {
        if ( (string)id != "inventory" ) {
            return;
        }
        list ltmp = llParseString2List(message, notecardSeperators, []);
        string cmd = llList2String(ltmp,0);
        if ( cmd == "target_key" ) {
            gTargetKey = (key)llList2String(ltmp,1);
        }
        if ( cmd == "operator_key" ) {
            gOperatorKey = (key)llList2String(ltmp,1);
        }
        if ( cmd == "target_give" ) {
            if ( gTargetKey != NULL_KEY ) {
                list gList = llParseString2List(message, notecardSeperators, []);
                give_inventory(gTargetKey, gList, message);
            } else llMessageLinked(LINK_THIS, -1, message + " : No target set.", (key)"main"); // error!
        }
        if ( cmd == "operator_give" ) {
            if ( gOperatorKey != NULL_KEY ) {
                list gList = llParseString2List(message, notecardSeperators, []);
                give_inventory(gOperatorKey, gList, message);
            }
        }
    }
}
