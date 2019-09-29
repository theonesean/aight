module print;

import config;
import tasks;
import std.format;
import std.array;
import std.string;
import std.conv;

class Printer {

    ConfigGroup conf;

    string bchar;
    string hbchar;
    string vbchar;

    int listWidth;

    string displayMode;

    this(ConfigGroup conf) {
        this.conf = conf;

        this.bchar = conf.setting("borderChar", "*");
        this.hbchar = conf.setting("borderCharHorizontal", "-");
        this.vbchar = conf.setting("borderCharVertical", "|");

        this.listWidth = to!int(conf.setting("listWidth", "40"));

        this.displayMode = conf.setting("displayMode", "table");
    }

    /**
     * Get the string to represent an outer row.
     *
     * @param width         The width of the table.
     */
    string getRowOuter(int width) {
        return replicate(this.hbchar, width);
    }

    /**
     * Get the string to represent an inner row.
     *
     * @param width         The width of the table.
     */
    string getRowInner(int width) {
        return this.vbchar ~ replicate(this.hbchar, width - 2) ~ this.vbchar;
    }

    /**
     * Get the string to represent a row with content.
     *
     * If the content is too large for the row, it will
     * be truncated to fit.
     *
     * @param width         The width of the content.
     * @param content       The content of the row.
     */
    string getRowContent(int width, string content) {
        if (content.length > width - 4)
            content = format("%-.*s...", width - 7, content);

        return format("%s %-*s %s", vbchar, width - 4, content, vbchar);
    }

    string[] printList(List list) {

      if ("list" == this.displayMode) {
        return this.printListWithoutTable(list);
      } else {
        return this.printList(list, this.listWidth * 2);
      }

    }

    /**
     * Format a list to a given height to be
     * printed in a table.
     *
     * @param list          The List to be formatted.
     * @param height        The height of the table.
     */
    string[] printList(List list, int height) {
	    string[] render;
	    render ~= getRowOuter(listWidth);
	    render ~= format("%s   %-*s %s", vbchar, listWidth - 6, list.name, vbchar);
	    render ~= getRowInner(listWidth);

	    for (int i = 0; i < list.tasks.length || i < height; i++) {
	    	if (i < list.tasks.length) {
	    		Task task = list.tasks[i];
	    		render ~= getRowContent(listWidth, format("%s: %s", task.humanId, task.name));
	    	} else {
	    		render ~= getRowContent(listWidth, " ");
	    	}
	    }

	    render ~= getRowOuter(listWidth);
	    return render;
    }

    /**
     * Formats a list for display
     * without table formatting.
     *
     * @param list          The List to be formatted.
     */
    string[] printListWithoutTable(List list) {
      string[] render;
      render ~= list.name;
      render ~= getRowOuter(listWidth);
      foreach (task; list.tasks) {
        render ~= format("%s: %s", task.humanId, task.name); // TODO: implement listModePreserveWidth checking
      }                                                      // possibly look at D string formatting functionality
      render ~= " ";

      return render;
    }

    string[] printLists(List[] lists) {
      bool isList = (0 == cmp(this.displayMode, "list"));

    	int size = 0;
    	foreach (list; lists) {
    		if (list.tasks.length > size)
    			size = to!int(list.tasks.length);
    	}

    	string[] print;

    	foreach (x, list; lists) {
        string[] rows = isList ? printList(list) : printList(list, size);

    		if (lists.length == 1) {
    			print = rows;
        } else if (0 == cmp(this.displayMode, "list")) {
          print ~= rows;
        } else {
          for (int i = 0; i < rows.length; i++) {
      			print[i] ~= rows[i][1 .. $];
      		}
        }
    	}

    	return print;
    }
}
