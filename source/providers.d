module providers;

import std.stdio;
import std.net.curl: get, HTTP;
import std.string: format;
import std.json: parseJSON;
import painlessjson: fromJSON;
import config: ConfigGroup;
import std.process: executeShell;

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

    char[] request(string endpoint) {
        return get("https://api.trello.com/1/" ~ endpoint ~ "&key=" ~ key ~ "&token=" ~ token);
    }
    
    override List[] getLists() {
        char[] req = this.request("boards/" ~ boardId ~ "/lists?cards=all&card_fields=name,url&fields=name,url");
        List[] list = fromJSON!(List[])(parseJSON(req));
        return list;
    }
}
