module config;

import std.getopt: getopt;
import std.exception;
import std.stdio;
import std.path: expandTilde;
import inilike.file;

class Config {

    string[string] settings;
    bool helpWanted;

    this(string[] args) {
        this.initConfigFiles([
            expandTilde("~/.aight.conf"), 
            expandTilde("~/.config/aight.conf"), 
            "/etc/aight.conf"
        ]);
        this.initArguments(args);
    }

    void initArguments(string[] args) {
        auto helpInfo = getopt(
            args,
            "set", &(this.settings)
        );

        this.helpWanted = helpInfo.helpWanted;
    }

    void initConfigFiles(string[] locations) {
        foreach (location; locations) {
            try {
                this.initConfigFile(location);
                break;
            } catch (ErrnoException e) {
                continue;
            }
        }
    }

    void initConfigFile(string location) {
        IniLikeFile file = new IniLikeFile(location);
        foreach (tuple; file.group("settings").byKeyValue()) {
            settings[tuple.key] = tuple.value;
        }
    }

    bool isSetting(string key) {
        return ((key in settings) !is null) && (settings[key] == "true");
    }
}
