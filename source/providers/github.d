module providers.github;

import std.json: parseJSON, JSONValue;
import std.net.curl: get, HTTP;
import std.stdio;
import tasks;
import config;

GitHubTaskProvider construct(ConfigGroup config) {
    GitHubTaskProvider provider = new GitHubTaskProvider(config.setting("githubApiToken"));

    string githubRepo = config.setting("githubRepo", null);
    if (githubRepo !is null)
        provider.setRepo(githubRepo);

    string githubOrg = config.setting("githubOrg", null);
    if (githubOrg !is null)
        provider.setOrg(githubOrg);

    return provider;
}

class GitHubTaskProvider : TaskProvider {

    private string token;
    private string entity;
    private string name;

    this(string token) {
        this.token = token;
        this.entity = "user";
    }

    void setRepo(string repo) {
        this.entity = "repos/" ~ repo;
        this.name = repo;
    }

    void setOrg(string org) {
        this.entity = "orgs/" ~ org;
        this.name = '@' ~ org;
    }

    /**
     * Send an authenticated request to a particular
     * endpoint of the GitHub API.
     * 
     * @param endpoint          The endpoint to send the request to.
     */
    char[] request(string endpoint) {
        writeln(endpoint);
        auto client = HTTP();
        client.addRequestHeader("Authorization", "bearer " ~ this.token);
        //client.addRequestHeader("Accept", "application/vnd.github.inertia-preview+json");

        return get("https://api.github.com/" ~ endpoint, client);
    }

    Task parseIssue(JSONValue taskJson) {
        Task task;
        task.id = taskJson["id"].str();
        task.humanId = '#' ~ taskJson["id"].str();
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
        if (entity == "user" && this.name is null) {
            JSONValue user = parseJSON(this.request("user"));
            this.name = '@' ~ user["login"].str();
        }

        char[] req = this.request(this.entity ~ "/issues");
        return [parseIssues(parseJSON(req), this.name)];
    }

}
