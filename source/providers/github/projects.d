module providers.github.projects;

import std.json: parseJSON, JSONValue;
import tasks: List, Task;
import config: ConfigGroup;
import providers.github.base;
import util.hasher: Hasher;
import std.conv: to;

class GitHubProjectsTaskProvider : GitHubTaskProvider {

	private string repo;
	private string projectId;

	private Hasher hasher;

	this(ConfigGroup config) {
		super(config);
		this.projectId = config.setting("githubProjectId", null);
		this.repo = projectId != null ? config.setting("githubRepo", null) : config.setting("githubRepo");
		this.hasher = new Hasher();
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
			ulong id = to!ulong(issue["number"].toString()); // JSONValue.uinteger was causing problems
			if (!hasher.restrict(id))
				id = hasher.hash(to!string(id));

			task.id = to!string(id);
			task.humanId = task.id;
			task.name = issue["title"].str;
			task.desc = issue["body"].str;
			task.url = issue["html_url"].str;
		} else {
			task.humanId = to!string(hasher.hash(task.id));
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
			project = parseJSON(this.request("projects/" ~ projectId));
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
