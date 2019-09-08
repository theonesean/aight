module providers;

import std.stdio;
import std.net.curl: get, HTTP;
import std.string: format;
import std.json: parseJSON, JSONValue;
import config: ConfigGroup;
import std.process: executeShell;

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
            return new TrelloTaskProvider(
                config.setting("trelloApiKey"),
                config.setting("trelloApiToken"),
                config.setting("trelloBoardId")
            );
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

class TrelloTaskProvider : TaskProvider {

    private string key;
    private string token;
    private string boardId;

    this(string key, string token, string boardId) {
        this.key = key;
        this.token = token;
        this.boardId = boardId;
    }

    /**
     * Send an authenticated request to a particular
     * endpoint of the Trello API.
     * 
     * @param endpoint          The endpoint to send the request to.
     */
    char[] request(string endpoint) {
        return get("https://api.trello.com/1/" ~ endpoint ~ "&key=" ~ key ~ "&token=" ~ token);
    }

    Task parseTask(JSONValue taskJson) {
        Task task;
        task.id = taskJson["id"].str();
        task.humanId = taskJson["shortLink"].str();
        task.url = taskJson["shortUrl"].str();
        task.name = taskJson["name"].str();
        task.desc = taskJson["desc"].str();
        return task;
    }

    List parseList(JSONValue listJson) {
        Task[] tasks;
        foreach (taskJson; listJson["cards"].array()) {
            tasks ~= parseTask(taskJson);
        }

        List list;
        list.id = listJson["id"].str();
        list.name = listJson["name"].str();
        list.tasks = tasks;
        return list;
    }
    
    /**
     * Get an array of lists of the Trello board.
     */
    override List[] getLists() {
        char[] req = this.request("boards/" ~ boardId ~ "/lists?cards=all&card_fields=name,shortUrl,shortLink,desc&fields=name");

        List[] lists;
        foreach (listJson; parseJSON(req).array()) {
            lists ~= parseList(listJson);
        }

        return lists;
    }
}
