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
			auto gitreg = ctRegex!(`^(https|git)(:\/\/|@)([^\/:]+)\.([a-z]+)(\/|:)(.+)(\.git|\s)$`);
			auto capture = matchFirst(command.output, gitreg);
			if (capture)
				group.setDefault(capture[3] ~ "Repo", capture[6]);

			return true;
		}
	}

	return false;
}

TaskProvider selectProvider(ConfigGroup[] services) {
	foreach (service; services) {
		if (matches(service))
			return getTaskProvider(service);
	}

	writeln();
	writeln("No matching configuration.");
	writeln();
	writeln("Specify configs in the ini-formatted file:");
	writeln("    ", expandTilde("~/.config/aight.conf"));
	writeln();
	writeln("See 'aight --help' for more information.");
	writeln();
	return null;
}

List getNamedList(List[] lists, string name) {
	foreach (list; lists) {
		if (list.name == name)
			return list;
	}

	throw new Exception("Couldn't find named list.");
}

Task getNamedTask(Task[] tasks, string name) {
	foreach (task; tasks) {
		if (task.humanId[0 .. name.length] == name)
			return task;
	}

	throw new Exception("Couldn't find named task");
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
	
	TaskProvider provider = selectProvider(conf.services);
	if (provider is null)
		return;

	Printer printer = new Printer(conf);
	if (args.length <= 1) {
		foreach (str; printer.printLists(provider.getLists())) {
			writeln(str);
		}
	} else if (args.length == 3 && args[1] == "list") {
		List list;
		try {
			list = getNamedList(provider.getLists(), args[2]);
		} catch (Exception e) {
			writeln("Could not find list ", args[2]);
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
	} else if (args.length == 3 && args[1] == "show") {
		Task[] tasks;
		foreach (list; provider.getLists()) {
			tasks ~= list.tasks;
		}

		Task task;
		try {
			task = getNamedTask(tasks, args[2]);
		} catch (Exception e) {
			writeln("Could not find task ", args[2]);
			return;
		}

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
}
