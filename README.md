# AIGHT

AIGHT is a command-line tool for getting todo tasks quickly.

## Building

```bash
git clone https://github.com/theonesean/AIGHT.git
make && make install
```

## Configuration

The program looks for its config file in `~/.aight.conf`, `~/.config/aight.conf`, and `/etc/aight.conf`, in that order. It uses an [INI-like](https://github.com/FreeSlave/inilike) format, with each group representing a different project/task implementation (Trello, GitHub Projects, etc...).

There are two "predefined" groups that can only exist once. These should appear at the start of your file. `[settings]` refers to global settings that affect the entire program, such as the table width or separation characters. The `[defaults]` group specifies default values for all of the groups that follow it. For instance, if you are defining many Trello configurations for the same account, you may not want to repeat the API key/token each time.

```ini
[settings]
listWidth=40
borderCharHorizontal=-
borderCharVertical=|

[defaults]
trelloApiKey=<a Trello API developer key>
trelloApiToken=<your Trello token>
```

### Task Providers

Task providers are triggered based on a set of conditional attributes such as `matchDir` (to match the current working directory) or `matchRemote` (to match the upstream git URL). The first group to match the current conditions will be executed, and all others will be ignored. As an example, here is a group that will open a URL whenever `aight` is used in one of my repositories:

```ini
[exec]
matchRemote=git@github.com:theonesean/*
command=open https://youtu.be/dQw4w9WgXcQ
```

Here is a list of all implemented providers and their configuration values:

#### Trello

See [trello.com/app-key](https://trello.com/app-key) to obtain an API key / token for this program to use.

```ini
[trello]
trelloApiKey=<a Trello API developer key>
trelloApiToken=<your Trello token>
trelloBoardId=<the board to display>
```

#### Shell Script

This just executes the given command.

```ini
[exec]
command=cat ./TODO.md
```

## Improvements

* Integration with GitHub Projects
* Ability to filter cards by tag / status

