import std.stdio: writeln;
import std.path: globMatch, expandTilde;
import std.file: getcwd;
import std.format: format;
import std.process: executeShell;
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
			auto capture = matchFirst(command.output[0 .. $-1], r"^(https|git)(:\/\/|@)([^\/:]+)\.([a-z]+)(\/|:)(.*?)(?:\.git)?$");
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

void runMain(TaskProvider provider, ConfigGroup conf) {
	auto printer = new Printer(conf);
	foreach (str; printer.printLists(provider.getLists())) {
		writeln(str);
	}
}

void runList(TaskProvider provider, string listName) {
	List list;
	try {
		list = provider.getList(listName);
	} catch (Exception e) {
		writeln("Could not find list ", listName);
		return;
	}

	writeln();
	writeln("List:");
	writeln("  ", list.name);
	writeln();
	foreach(task; list.tasks) {
		writeln(format("%s: %s", task.humanId, task.name));
	}
	writeln();
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

void main(string[] args) {
	Config conf = new Config(args);
	if (conf.helpWanted) {
		writeln();
		writeln("Usage: aight");
		writeln();
		writeln("aight list <name>    list the tasks in a category");
		writeln("aight show <task>    display the details of a task");
		writeln();
		writeln("Specify configs in the ini-formatted file:");
		writeln("    ", expandTilde("~/.config/aight.conf"));
		writeln();
		writeln("aight@0.0.1 ", args[0]);
		writeln("    https://github.com/theonesean/AIGHT");
		writeln();
		return;
	}

	auto run = (TaskProvider provider, ConfigGroup config) => runMain(provider, conf);

	if (args.length >= 3 && args[1] == "show") {
		run = (TaskProvider provider, ConfigGroup config) => runShow(provider, args[2]);
	} else if (args.length >= 3 && args[1] == "list") {
		run = (TaskProvider provider, ConfigGroup config) => runList(provider, args[2]);
	}

	selectProvider(conf.services, run);
}
