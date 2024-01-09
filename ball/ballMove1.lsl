// ballMove1.lsl - move the poseball.
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

// Having two ballMove scripts is an attempt to get a more fluid movement

default {
    link_message(integer sender_number, integer number, string message, key id) {
        if ( (string)id != "ballMove1" ) {
            return;
        }
        vector position = (vector)message;
        vector last;
        do {
            last = llGetPos();
            llSetPos(position);  
        } while ((llVecDist(llGetPos(),position) > 0.001) && (llGetPos() != last) );

    }
}
