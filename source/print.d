module print;

import config;
import providers;
import std.format;
import std.array;
import std.string;
import std.conv;

class Printer {

    Config conf;
    
    string bchar;
    string hbchar;
    string vbchar;

    int listWidth;

    this(Config conf) {
        this.conf = conf;

        this.bchar = conf.setting("borderChar", "*");
        this.hbchar = conf.setting("borderCharHorizontal", "-");
        this.vbchar = conf.setting("borderCharVertical", "|");

        this.listWidth = to!int(conf.setting("listWidth", "40"));
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

    string[] printList(List list, int height) {
	    string[] render;
	    render ~= getRowOuter(listWidth);
	    render ~= format("%s   %-*s %s", vbchar, listWidth - 6, list.name, vbchar);
	    render ~= getRowInner(listWidth);

	    for (int i = 0; i < list.cards.length || i < height; i++) {
	    	if (i < list.cards.length) {
	    		CardSymbol card = list.cards[i];
	    		render ~= getRowContent(listWidth, format("%s: %s", card.id[$-5 .. $], card.name));
	    	} else {
	    		render ~= getRowContent(listWidth, " ");
	    	}
	    }

	    render ~= getRowOuter(listWidth);
	    return render;
    }

    string[] printLists(List[] lists) {
    	int size = 0;
    	foreach (list; lists) {
    		if (list.cards.length > size)
    			size = to!int(list.cards.length);
    	}

    	string[] print;
    	foreach (list; lists) {
    		string[] rows = printList(list, size);
    		if (print.length == 0)
    			print = rows;
            else for (int i = 0; i < rows.length; i++) {
    			print[i] ~= rows[i][1 .. $];
    		}
    	}

    	return print;
    }
}
