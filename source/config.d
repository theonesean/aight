module config;

import std.getopt: getopt;
import std.exception;
import std.stdio;
import std.path: expandTilde;
import inilike.file;

class ConfigGroup {
    
    string key;
    string[string] settings;

    this(string key, string[string] settings) {
        this.key = key;
        this.settings = settings;
    }

    bool hasSetting(string id) {
        return (id in settings) !is null;
    }

    bool isSetting(string id) {
        return this.hasSetting(id) && this.settings[id] == "true";
    }

    string setting(string id) {
        if ((id in this.settings) !is null) {
            return this.settings[id];
        } else {
            throw new Exception("Failed to find setting " ~ id ~ " in group " ~ key);
        }
    }

    string setting(string id, string unset) {
        try {
            return this.setting(id);
        } catch (Exception e) {
            return unset;
        }
    }

}

class Config : ConfigGroup {

    ConfigGroup[] services;
    bool helpWanted;

    this(string[] args) {
        super("config", this.settings);
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
        foreach (group; file.byGroup()) {
            string[string] groupRef;

            foreach (tuple; group.byKeyValue()) {
                groupRef[tuple.key] = tuple.value;
            }

            if (group.groupName() == "settings") {
                this.settings = groupRef;
            } else {
                services ~= new ConfigGroup(group.groupName(), groupRef);
            }
        }
    }
}
