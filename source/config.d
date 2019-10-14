module config;

import std.getopt: getopt;
import std.exception;
import std.stdio;
import std.path: expandTilde;
import inilike.file;

class ConfigGroup {
	
	string key;
	string[string] settings;

	/**
	 * A generic group of configuration settings.
	 *
	 * @param key           The group key/id.
	 * @param settings      The current setting values.
	 */
	this(string key, string[string] settings) {
		this.key = key;
		this.settings = settings;
	}

	/**
	 * Determine if a setting exists.
	 *
	 * @param id            The id/key of the setting.
	 * @return True if the setting exists.
	 */
	bool hasSetting(string id) {
		return (id in settings) !is null;
	}

	/**
	 * Determine if a setting is "true".
	 *
	 * @param id            The id/key of the setting.
	 * @return True if the setting exists and is "true".
	 */
	bool isSetting(string id) {
		return this.hasSetting(id) && this.settings[id] == "true";
	}

	/**
	 * Get the value of a setting.
	 *
	 * @param id            The id/key of the setting.
	 * @return The value of the setting.
	 * @throws Exception if the setting does not exist.
	 */
	string setting(string id) {
		if ((id in this.settings) !is null) {
			return this.settings[id];
		} else {
			throw new Exception("Failed to find setting " ~ id ~ " in group " ~ key);
		}
	}

	/**
	 * Get the value of a setting.
	 *
	 * @param id            The id/key of the setting.
	 * @param unset         The value to return if the
	 *                      setting does not exist.
	 * @return The value of the setting.
	 */
	string setting(string id, string unset) {
		try {
			return this.setting(id);
		} catch (Exception e) {
			return unset;
		}
	}

	void setDefault(string id, string value) {
		if (!this.hasSetting(id))
			this.settings[id] = value;
	}

}

class Config : ConfigGroup {

	ConfigGroup[] services;
	bool helpWanted;

	this(string[] args) {
		super("config", this.settings);
		this.initArguments(args);
		this.initConfigFiles([
			expandTilde("~/.aight.conf"), 
			expandTilde("~/.config/aight.conf"), 
			"/etc/aight.conf"
		]);
	}

	void initArguments(string[] args) {
		bool verbose = false;

		auto helpInfo = getopt(
			args,
			"set", &(this.settings),
			"verbose|v", &verbose
		);

		if (verbose)
			this.settings["verbose"] = "true";
		
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
	    IniLikeFile file = new IniLikeFile(location,
			// preserve duplicate groups in config file
			// ref: https://github.com/FreeSlave/inilike/blob/c1e5a6b2b6a858259fe4b298e8ac3da74e048e64/source/inilike/file.d#L1427
			IniLikeFile.ReadOptions(IniLikeFile.DuplicateGroupPolicy.preserve));

		foreach (group; file.byGroup()) {
			string[string] groupRef;

			// initialize default (global) settings
			foreach (tuple; this.settings.byKeyValue()) {
				groupRef[tuple.key] = tuple.value;
			}

			// overwrite with specific group settings
			foreach (tuple; group.byKeyValue()) {
				groupRef[tuple.key] = tuple.value;
			}

			if (group.groupName() == "settings") {
				this.settings = groupRef;
			} else if (group.groupName() == "defaults") {
				this.settings = groupRef;
			} else {
				services ~= new ConfigGroup(group.groupName(), groupRef);
			}
		}
	}
}
