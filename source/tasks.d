module tasks;

import std.stdio;
import config: ConfigGroup;
import std.process: executeShell;
import providers.trello;
import providers.github.issues;
import providers.github.projects;

bool isTaskProvider(ConfigGroup config) {
	return config.key != "exec";
}

/**
 * Get the task provider that matches a specific
 * configuration.
 *
 * Certain configurations (such as "exec") may have
 * their own configurations that do not fit into a
 * TaskProvider instance; in this case, they will
 * execute immediately and this function will return
 * null.
 *
 * @param config            The config of the task.
 * @return The created task provider, or null.
 * @throws Exception if the configuration is incomplete.
 */
TaskProvider getTaskProvider(ConfigGroup config) {
	switch (config.key) {
		case "trello":
			return new TrelloTaskProvider(config);
		case "github":
			return new GitHubIssuesTaskProvider(config);
		case "github-projects":
			return new GitHubProjectsTaskProvider(config);
		case "exec":
			auto command = executeShell(config.setting("command"));
			writeln(command.output);
			return null;
		default:
			throw new Exception("Cannot resolve group key ", config.key);
	}
}

struct Task {
	string id;
	string humanId;
	string url;
	string name;
	string desc;
}

struct List {
	string id;
	string name;
	Task[] tasks;
}

abstract class TaskProvider {

	ConfigGroup config;

	this(ConfigGroup config) {
		this.config = config;
	}

	/**
	 * Get an array of the task lists that are
	 * able to be provided.
	 */
	abstract List[] getLists();

	List getList(string name) {
		foreach (list; this.getLists()) {
			if (list.name == name)
				return list;
		}

		throw new Exception("Couldn't resolve list: " ~ name);
	}

	Task getTask(string id) {
		foreach (list; this.getLists()) {
			foreach (task; list.tasks) {
				if (task.humanId == id)
					return task;
			}
		}

		throw new Exception("Couldn't resolve task: " ~ id);
	}
	
}
