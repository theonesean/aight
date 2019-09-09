module providers.trello;

import std.json: parseJSON, JSONValue;
import std.net.curl: get;
import tasks;
import config;

TrelloTaskProvider construct(ConfigGroup config) {
    return new TrelloTaskProvider(
        config.setting("trelloApiKey"),
        config.setting("trelloApiToken"),
        config.setting("trelloBoardId")
    );
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
