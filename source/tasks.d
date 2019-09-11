module tasks;

import std.stdio;
import config: ConfigGroup;
import std.process: executeShell;
import providers.trello;
import providers.github.issues;
import providers.github.projects;

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
            return providers.trello.construct(config);
        case "github":
            return providers.github.issues.construct(config);
        case "github-projects":
            return providers.github.projects.construct(config);
        case "exec":
            auto command = executeShell(config.setting("command"));
            writeln(command.output);
            return null;
        default:
            throw new Exception("Cannot resolve config key ", config.key);
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

interface TaskProvider {

    /**
     * Get an array of the task lists that are
     * able to be provided.
     */
    List[] getLists();
    
}
