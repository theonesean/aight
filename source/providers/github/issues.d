module providers.github.issues;

import std.json: parseJSON, JSONValue;
import tasks: List, Task;
import config: ConfigGroup;
import providers.github.base;

GitHubTaskProvider construct(ConfigGroup config) {
    return new GitHubIssuesTaskProvider(
        config.setting("githubApiToken"),
        config.setting("githubRepo")
    );
}

class GitHubIssuesTaskProvider : GitHubTaskProvider {

    private string repo;

    this(string token, string repo) {
        super(token);
        this.repo = repo;
    }

    Task parseIssue(JSONValue taskJson) {
        Task task;
        task.id = taskJson["id"].toString();
        task.humanId = taskJson["number"].toString();
        task.url = taskJson["html_url"].str();
        task.name = taskJson["title"].str();
        task.desc = taskJson["body"].str();
        return task;
    }

    List parseIssues(JSONValue listJson, string repo) {
        Task[] tasks;
        foreach (taskJson; listJson.array()) {
            tasks ~= parseIssue(taskJson);
        }

        List list;
        list.id = repo;
        list.name = repo;
        list.tasks = tasks;
        return list;
    }

    override List[] getLists() {
        char[] req = this.request("repos/" ~ this.repo ~ "/issues");
        return [parseIssues(parseJSON(req), this.repo)];
    }

}
