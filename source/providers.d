module providers;

import std.stdio;
import std.net.curl: get, HTTP;
import std.string: format;
import std.json: parseJSON;
import painlessjson: fromJSON;
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
                config.setting("apiKey"),
                config.setting("apiToken"),
                config.setting("boardId")
            );
        case "exec":
            auto command = executeShell(config.setting("command"));
            writeln(command.output);
            return null;
        default:
            throw new Exception("Cannot resolve config key ", config.key);
    }
}

struct CardSymbol {
    string id;
    string name;
}

struct List {
    string id;
    string name;
    CardSymbol[] cards;
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
    
    /**
     * Get an array of lists of the Trello board.
     */
    override List[] getLists() {
        char[] req = this.request("boards/" ~ boardId ~ "/lists?cards=all&card_fields=name,url&fields=name,url");
        List[] list = fromJSON!(List[])(parseJSON(req));
        return list;
    }
}
