// plugin_example.lsl

// Absolutely free, it's just an example.
// In fact, this is how you'd make most (if not all!) of your own build.
// This is how you rez objects, pass commands to them.
// Or, for example, start/stop conveyor belts,.

rotation  sectionRotation;
integer gPoseballChannel      = -89; // listen channel for ball commands.
integer gObjectChannel        = -88; // listen channel for machine commands.
integer gObjectListenHandle   = -1;
string  gListenName           = "~ball";

list    notecardSeperators = ["  |  ","  | "," |  "," | "," |","| ","|"];

main(string message, integer number) {
    list ltmp = llParseString2List(message, notecardSeperators, []);
    string cmd = llList2String(ltmp,0); // = "plugin_command"
    string pluginName    = llList2String(ltmp,1);
    string pluginCommand = llList2String(ltmp,2);
    sectionRotation =  llGetRot();
    if ( pluginCommand == "command_example" ) {
        // do something. F.ex.: Send command to ~ball.
        llSay(gPoseballChannel,"hide_something");
        llSay(0, "This is <command_example> in <plugin_example>");
        // End by reporting back to main script.
        llMessageLinked(LINK_THIS, 1, message, (key)"main"); // success!
    } else if ( pluginCommand == "rez_something" ) {
        // Or rez something, f.ex.like this:
        llRezObject("some_object", llGetPos() + <0, 0, 0.8>*sectionRotation, ZERO_VECTOR, llEuler2Rot(<0,0,90> * DEG_TO_RAD)*sectionRotation, 42);
        llMessageLinked(LINK_THIS, 1, message, (key)"main"); // success!
    } else {
        llMessageLinked(LINK_THIS, -1, message + "plugin command not found", (key)"main"); // fail!
    }
}

default {
    link_message(integer sender_number, integer number, string message, key id) {
        if ( (string)id == llGetScriptName() ) {
            main(message,number);
        }
    }
}

