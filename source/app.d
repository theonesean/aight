import std.stdio: writeln;
import std.path: globMatch, expandTilde;
import std.file: getcwd;
import std.format: format;
import std.process: executeShell;
import std.algorithm.searching: canFind;
import std.regex;
import config: Config, ConfigGroup;
import tasks;
import print: Printer;

/**
 * Determines whether a particular ConfigGroup matches
 * the current conditions.
 *
 * @param group         The group to match.
 * @return True if the current conditions are matched.
 */
bool matches(ConfigGroup group) {
	string cwd = getcwd();
	string matchDir = group.setting("matchDir", null);
	string matchRemote = group.setting("matchRemote", null);

	// test working directory
	if (matchDir !is null && globMatch(cwd, matchDir))
		return true;

	// test git remote
	if (matchRemote !is null) {
		// TODO: replace with actual libgit2 binding
		auto command = executeShell("git ls-remote --get-url");
		if (command.status == 0 && globMatch(command.output, matchRemote)) {
			// capture github repo & provide default repo variable for issue/project boards
			auto capture = matchFirst(command.output[0 .. $-1], r"^(https|git)(:\/\/|@)(?:www\.)?([^\/:]+)\.([a-z]+)(\/|:)(.*?)(?:\.git)?$");
			if (capture)
				group.setDefault(capture[3] ~ "Repo", capture[6]);

			return true;
		}
	}

	return false;
}

void selectProvider(ConfigGroup[] services, void delegate(TaskProvider, ConfigGroup) run) {
	foreach (service; services) if (matches(service)) {
		try {
			run(getTaskProvider(service), service);
			return;
		} catch (Exception e) {
			if (service.isSetting("verbose"))
				writeln(e, "\n");

			continue;
		}
	}

	writeln();
	writeln("No matching configuration.");
	writeln();
	writeln("Specify configs in the ini-formatted file:");
	writeln("    ", expandTilde("~/.config/aight.conf"));
	writeln();
	writeln("See 'aight --help' for more information.");
	writeln();
}

void runDebugProviders(ConfigGroup[] services) {
	foreach (service; services) {
		writeln();

		bool isActive = matches(service);
		writeln(service.key, " - ",  isActive ? "active" : "inactive");

		// log settings values (only if active)
		if (isActive) foreach (setting; service.settings.byKeyValue()) {
			if (setting.key.length < 5 || setting.key[$-5 .. $] != "Token") // don't show tokens
				writeln("  ", setting.key, ": ", setting.value);
		}

		if (!isTaskProvider(service))
			continue;

		try {
			// execute task provider & check for errors
			getTaskProvider(service);
		} catch (Exception e) {
			if (service.isSetting("verbose"))
				writeln(e, "\n");
			else writeln("  Exception: ", e.msg);
		}
	}

	writeln();
}

void runMain(TaskProvider provider, ConfigGroup conf) {
	auto printer = new Printer(conf);
	foreach (str; printer.printLists(provider.getLists())) {
		writeln(str);
	}
}

void runList(TaskProvider provider, string listName, ConfigGroup conf) {
	List list;
	try {
		list = provider.getList(listName);
	} catch (Exception e) {
		writeln("Could not find list ", listName);
		return;
	}

	auto printer = new Printer(conf);
	foreach (str; printer.printList(list)) {
		writeln(str);
	}
}

void runShow(TaskProvider provider, string taskName) {
	Task task = provider.getTask(taskName);

	writeln();
	writeln("Task:");
	writeln("  ", task.name);
	if (task.desc !is null && task.desc.length > 0) {
		writeln();
		writeln(task.desc);
	}
	writeln();
	writeln(task.url);
	writeln();
}

void runClose(TaskProvider provider, string taskName) {
	Task task = provider.getTask(taskName);

	provider.closeTask(task);

	writeln();
	writeln("Yeeted task: " ~ task.name);
	writeln();
}

void main(string[] args) {
	Config conf = new Config(args);
	if (conf.helpWanted) {
		writeln();
		writeln("Usage: aight [command?] [options...]");
		writeln();
		writeln("aight yinz <name>    list the tasks in a category");
		writeln("aight show <task>    display the details of a task");
		writeln("aight peeps          debug config file & list active providers");
		writeln();
		writeln("Options:");
		writeln("  --set key=value    override global config options");
		writeln("  --verbose          show detailed error messages & logs");
		writeln();
		writeln("Specify providers in the ini-formatted file:");
		writeln("    ", expandTilde("~/.config/aight.conf"));
		writeln();
		writeln("aight@0.0.1 ", args[0]);
		writeln("    https://github.com/theonesean/aight");
		writeln();
		return;
	}

	auto run = (TaskProvider provider, ConfigGroup config) => runMain(provider, conf);

	if (args.length > 2 && args[1] == "show") {
		run = (TaskProvider provider, ConfigGroup config) => runShow(provider, args[2]);
	} else if (args.length > 2 && canFind(["list", "yinz", "yall", "yous"], args[1])) {
		run = (TaskProvider provider, ConfigGroup config) => runList(provider, args[2], conf);
	} else if (args.length > 1 && canFind(["list-providers", "peeps", "folx"], args[1])) {
		runDebugProviders(conf.services);
		return;
	} else if (args.length > 1 && canFind(["yeet"], args[1])) {
		run = (TaskProvider provider, ConfigGroup config) => runClose(provider, args[2]);
	}

	selectProvider(conf.services, run);
}
