AIGHT
[![Build status](https://github.com/theonesean/aight/workflows/Dlang%20Package/badge.svg)](https://github.com/theonesean/aight/actions)
=======

AIGHT is a command-line tool for getting todo tasks quickly.

## Building

Make sure you've installed the [dlang compiler](https://dlang.org/download.html) (dmd) on your system.

```bash
git clone https://github.com/theonesean/aight.git
sudo make install
```

## Configuration

The program looks for its config file in `~/.aight.conf`, `~/.config/aight.conf`, and `/etc/aight.conf`, in that order. It uses an [INI-like](https://github.com/FreeSlave/inilike) format, with each group representing a different project/task implementation (Trello, GitHub Projects, [etc...](https://github.com/theonesean/aight/issues?q=is%3Aopen+is%3Aissue+label%3Anew-provider)).

There are two "predefined" groups that can only exist once. These should appear at the start of your file. `[settings]` refers to global settings that affect the entire program, such as the table width or separation characters. The `[defaults]` group specifies default values for all of the groups that follow it. For instance, if you are defining many Trello configurations for the same account, you may not want to repeat the API key/token each time.

```ini
[settings]
listWidth=40
displayMode=table

[defaults]
trelloApiKey=a Trello API developer key
trelloApiToken=your Trello token
```

### Display Modes

By default, `aight` will attempt to display multiple task lists (for example, multiple lists within a single Trello board) in ASCII table format, using the `listWidth` and `border*` settings and your terminal window width. If you would prefer to have multiple lists displayed one after the other, set `displayMode=list`.

The border settings use unicode values by default. To change this behavior, specify three-character strings in your config file with each index representing the left, middle, and right char in the border.

```ini
borderTop=╔═╗
borderContent=║ ║
borderMiddle=╟─╢
borderBottom=╚═╝
```

**Note:** While in `displayMode=list`, by default, tasks in a list will not respect `listWidth`. To force a width in list mode, set `listModePreserveWidth=true`.

### Task Providers

Task providers are triggered based on a set of conditional attributes such as `matchDir` (to match the current working directory) or `matchRemote` (to match the upstream git URL). The first group to match the current conditions will be executed, and all others will be ignored. As an example, here is a group that will open a URL whenever `aight` is used in one of my repositories:

```ini
[exec]
matchRemote=git@github.com:theonesean/*
command=open https://youtu.be/dQw4w9WgXcQ
```

Here is a list of all implemented providers and their configuration values:

#### GitHub Issues

```ini
[github]
githubApiToken=a GitHub API token
githubRepo=the repository to fetch (optional, defaults to matched remote URL)
```

If the provider is matched by a remote URL of a GitHub repository (using `matchRemote`), the `githubRepo` value will default to its repository name if it is unset.

#### GitHub Projects

**Note:** because of various limitations, the GitHub Projects implementation is currently _very slow_. The API is also a developer preview, so it will likely change at some point in the future.

```ini
[github-projects]
githubApiToken=a GitHub API token
githubRepo=the repository to fetch (optional, defaults to matched remote URL)
githubProjectId=the project ID (optional, defaults to first project available)
```

#### Trello

See [trello.com/app-key](https://trello.com/app-key) to obtain an API key / token for this program to use.

```ini
[trello]
trelloApiKey=a Trello API developer key
trelloApiToken=your Trello token
trelloBoardId=the board to display
```

#### Shell Script

This just executes the given command.

```ini
[exec]
command=cat ./TODO.md
```
