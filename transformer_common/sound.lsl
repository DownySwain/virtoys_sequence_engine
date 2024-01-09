// sound.lsl - Play (and stop) sounds.
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
// Minimum amount of time (in seconds) between sounds.
float min = 0;
// Maximum amount of time (in seconds) between sounds.
float max = 0;
// This is the volume at which the sound will play.  0 = Inaudible
// Valid values are between 0.0 - 1.0
float vol = 1.0;
// Sound to play.
key sound = "startrekdoor";

main(string message, integer number) {
    list ltmp = llParseString2List(message, notecardSeperators, []);
    string cmd = llList2String(ltmp,0);
    if ( cmd == "play_sound" ) {
        key play_sound = llList2String(ltmp,1);
        llPlaySound(play_sound, vol);
        llMessageLinked(LINK_THIS, 1, message, (key)"main"); // success!
    }
    if ( cmd == "sound_repeat" ) {
        key sound = llList2String(ltmp,1);
        llLoopSound(sound,vol);
        llMessageLinked(LINK_THIS, 1, message, (key)"main"); // success!
    }
    if ( cmd == "sound_off" ) {
        llStopSound();
        llMessageLinked(LINK_THIS, 1, message, (key)"main"); // success!
    }
}

default {
    state_entry() {}

    timer() {
        // Play the sound once
        llPlaySound(sound, vol);    
        // Randomly select the next time (in seconds) to play the sound.
        float time = min + llFrand(max - min);
        llSetTimerEvent(time);
    }

    link_message(integer sender_number, integer number, string message, key id) {
        if ( (string)id == "sound" || (string)id == "all" ) {
            main(message,number);
        }
    }
}

