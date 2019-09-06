# AIGHT

AIGHT is a command-line tool for getting todo tasks quickly. It's currently very basic.

**To use Trello integration**, set the following environment variables:

* `$TRELLO_KEY` - your Trello API developer key
* `$TRELLO_TOKEN` - your invididual account's Trello token

`todolist` and `doinglist` in the script are the boards that the script grabs from, by default. 

**Default behaviour** opens [Things](https://culturedcode.com), my Mac task app of choice, using Mac's very handy `open` command and an X-Callback-URL to open the "Today" pane.

## Improvements

* The path detection should be variablized.
* The Trello get should be abstracted.
* Control flow should be more customizable.
* Additional integrations with common task software.
* Customization of app opening protocol.

