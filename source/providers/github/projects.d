module providers.github.projects;

import std.json: parseJSON, JSONValue;
import tasks: List, Task;
import config: ConfigGroup;
import providers.github.base;

GitHubProjectsTaskProvider construct(ConfigGroup config) {
    return new GitHubProjectsTaskProvider(
        config.setting("githubApiToken"),
        config.setting("githubRepo"),
        config.setting("githubProjectId", null)
    );
}

class GitHubProjectsTaskProvider : GitHubTaskProvider {

    string repo;
    string projectId;

    this(string token, string repo, string projectId) {
        super(token);
        this.repo = repo;
        this.projectId = projectId;
    }

    Task parseCard(JSONValue cardJson) {
        Task task;
        task.id = cardJson["id"].toString();
        task.humanId = task.id;
        task.name = cardJson["note"].toString();
        task.desc = "";
        task.url = "";

        if (!task.name || task.name == "null" || task.name == "undefined") {
            auto issue = parseJSON(this.request(cardJson["content_url"].str));
            task.humanId = issue["number"].toString();
            task.name = issue["title"].str;
            task.desc = issue["body"].str;
            task.url = issue["html_url"].str;
        }

        return task;
    }

    List parseColumn(JSONValue columnJson) {
        auto cards = parseJSON(this.request(columnJson["cards_url"].str));

        Task[] tasks;
        foreach (card; cards.array) {
            tasks ~= parseCard(card);
        }

        List list;
        list.id = columnJson["id"].toString();
        list.name = columnJson["name"].str;
        list.tasks = tasks;
        return list;
    }

    override List[] getLists() {
        JSONValue project = null;
        if (this.projectId) {
            project = parseJSON(this.request("repos/" ~ repo ~ "/projects/" ~ projectId));
        } else {
            project = parseJSON(this.request("repos/" ~ repo ~ "/projects")).array[0];
        }
        
        auto columns = parseJSON(this.request(project["columns_url"].str));
        List[] lists;
        foreach (column; columns.array) {
            lists ~= parseColumn(column);
        }

        return lists;
    }

}
