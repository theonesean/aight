import std.stdio: writeln;
import std.path: globMatch;
import std.file: getcwd;
import std.process: executeShell;
import config: Config, ConfigGroup;
import providers: List, TaskProvider, getTaskProvider;
import print: Printer;

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
		writeln(command.output);
		if (command.status == 0 && globMatch(command.output, matchRemote))
			return true;
	}

	return false;
}

void main(string[] args) {
	Config conf = new Config(args);
	Printer printer = new Printer(conf);
	
	foreach (service; conf.services) {
		if (!matches(service))
			continue;

		TaskProvider provider = getTaskProvider(service);
		List[] lists = provider.getLists();
		
		foreach (str; printer.printLists(lists)) {
    		writeln(str);
    	}

		break;
	}
}
