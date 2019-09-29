module providers.trello;

import std.json: parseJSON, JSONValue;
import std.net.curl: get;
import tasks;
import config;
import util.hasher: Hasher;
import std.conv: to;

class TrelloTaskProvider : TaskProvider {

    private string key;
    private string token;
    private string boardId;

    private Hasher hasher;

    this(ConfigGroup config) {
        super(config);
        this.key = config.setting("trelloApiKey");
        this.token = config.setting("trelloApiToken");
        this.boardId = config.setting("trelloBoardId");
        this.hasher = new Hasher();
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
        task.humanId = to!string(hasher.hash(task.id));
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
