# AIGHT

AIGHT is a command-line tool for getting todo tasks quickly.

## Building

```bash
git clone https://github.com/theonesean/AIGHT.git
make && make install
```

## Configuration

The program looks for its config file in `~/.aight.conf`, `~/.config/aight.conf`, and `/etc/aight.conf`, in that order. It uses an [INI-like](https://github.com/FreeSlave/inilike) format, with each group representing a different project/task implementation (Trello, GitHub Projects, etc...).

### Trello

```ini
[trello]
apiKey=<a Trello API developer key>
apiToken=<your Trello token>
boardId=<the board to display>
```

## Improvements

* The path detection should be variablized.
* The Trello get should be abstracted.
* Control flow should be more customizable.
* Additional integrations with common task software.
* Maintain a list of common task apps and their open commands.

