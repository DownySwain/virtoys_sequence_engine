// DeleteTimer.lsl - Delete poseball after unsit.
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

integer  timerEnd = 1800; // seconds. 600 = 10 minutes

default {
    state_entry()    {
        llSetTimerEvent(timerEnd);
    }

    on_rez(integer start_param) {
        llSetTimerEvent(timerEnd);
    } 

    changed(integer change) { 
        if (change & CHANGED_LINK) { 
            if (llAvatarOnSitTarget() != NULL_KEY) { 
                llSetTimerEvent(0);
            } else {
                llSetTimerEvent(timerEnd);
            }
        }
        if ( change & CHANGED_OWNER ) {
            llResetScript();
        }
        if ( change & CHANGED_INVENTORY ) {
            llResetScript();
        }
    }

    timer() {
        // delete ball
        llDie();
    }

}
