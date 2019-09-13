module providers.github.base;

import std.net.curl: get, HTTP;
import std.stdio;
import tasks;

abstract class GitHubTaskProvider : TaskProvider {
    string token;

    this(string token) {
        this.token = token;
    }

    /**
     * Send an authenticated request to a particular
     * endpoint of the GitHub API.
     * 
     * @param endpoint          The endpoint to send the request to.
     */
    char[] request(string endpoint) {
        auto client = HTTP();
        client.addRequestHeader("Authorization", "bearer " ~ this.token);
        client.addRequestHeader("Accept", "application/vnd.github.inertia-preview+json");

        if (endpoint[0 .. 4] != "http")
            endpoint = "https://api.github.com/" ~ endpoint;

        char[] str = get(endpoint, client);
        return str;
    }

    override abstract List[] getLists();
}
