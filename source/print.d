module print;

import config;
import tasks;
import std.format;
import std.array;
import std.string;
import std.conv;

class Printer {

	ConfigGroup conf;

	dstring borderTop;
	dstring borderContent;
	dstring borderMiddle;
	dstring borderBottom;

	int listWidth;

	string displayMode;

	this(ConfigGroup conf) {
		this.conf = conf;

		this.borderTop = to!dstring(conf.setting("borderTop", "╔═╗"));
		this.borderContent = to!dstring(conf.setting("borderContent", "║ ║"));
		this.borderMiddle = to!dstring(conf.setting("borderMiddle", "╟─╢"));
		this.borderBottom = to!dstring(conf.setting("borderBottom", "╚═╝"));

		this.listWidth = to!int(conf.setting("listWidth", "40"));

		this.displayMode = conf.setting("displayMode", "table");
	}

	dstring dreplicate(immutable(dchar) str, int num) {
		return to!dstring(replicate(to!string(str), num));
	}

	///
	unittest {
		// setup environment
		string[string] settings;
		Printer prtr = new Printer(new ConfigGroup("h", settings));

		// tests
		dstring str = prtr.dreplicate('-', 5);
		assert(str == "-----");
	}

	/**
	 * Get the string to represent an outer row.
	 *
	 * @param width         The width of the table.
	 */
	dstring getRowOuter(int width, bool bottom) {
		if (bottom)
			return this.borderBottom[0] ~ dreplicate(this.borderBottom[1], width - 2) ~ this.borderBottom[2];
		else return this.borderTop[0] ~ dreplicate(this.borderTop[1], width - 2) ~ this.borderTop[2];
	}

	///
	unittest {
		// setup environment
		string[string] settings;
		settings["borderTop"] = ",-.";
		settings["borderBottom"] = "`-'";
		Printer prtr = new Printer(new ConfigGroup("h", settings));

		// tests
		dstring str = prtr.getRowOuter(5, false);
		assert(str == ",---.", "Outer/top row chars");
		str = prtr.getRowOuter(8, true);
		assert(str == "`------'", "Outer/bottom row chars");

		// setup environment
		settings["borderTop"] = "╔═╗";
		settings["borderBottom"] = "╚═╝";
		prtr = new Printer(new ConfigGroup("h", settings));

		// tests
		str = prtr.getRowOuter(5, false);
		assert(str == "╔═══╗", "Unicode outer/top row chars");
		str = prtr.getRowOuter(8, true);
		assert(str == "╚══════╝", "Unicode outer/bottom row chars");
	}

	/**
	 * Get the string to represent an inner row.
	 *
	 * @param width         The width of the table.
	 */
	dstring getRowInner(int width) {
		return this.borderMiddle[0] ~ dreplicate(this.borderMiddle[1], width - 2) ~ this.borderMiddle[2];
	}

	///
	unittest {
		// setup environment
		string[string] settings;
		settings["borderMiddle"] = "|-|";
		Printer prtr = new Printer(new ConfigGroup("h", settings));

		// tests
		dstring str = prtr.getRowInner(5);
		assert(str == "|---|", "Middle row chars");
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
			content = format("%-.*s…", width - 5, content);

		return format("%s %-*s %s", to!string(borderContent[0]), width - 4, content, to!string(borderContent[2]));
	}

	string[] printList(List list) {
		return printList(list, list.tasks.length);
	}

	string[] printList(List list, ulong height) {
		return ("list" == this.displayMode)
			? this.printListWithoutTable(list)
			: this.printListWithTable(list, height);
	}

	/**
	 * Format a list to a given height to be
	 * printed in a table.
	 *
	 * @param list          The List to be formatted.
	 * @param height        The height of the table.
	 */
	string[] printListWithTable(List list, ulong height) {
		string[] render;
		render ~= to!string(getRowOuter(listWidth, false));
		render ~= format("%s   %-*s %s", to!string(borderContent[0]), listWidth - 6, list.name, to!string(borderContent[2]));
		render ~= to!string(getRowInner(listWidth));

		for (int i = 0; i < list.tasks.length || i < height; i++) {
			if (i < list.tasks.length) {
				Task task = list.tasks[i];
				render ~= getRowContent(listWidth, format("%03d: %s", parse!int(task.humanId), task.name));
			} else {
				render ~= getRowContent(listWidth, " ");
			}
		}

		render ~= to!string(getRowOuter(listWidth, true));
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
		render ~= replicate(to!string(borderMiddle[1]), this.listWidth);
		foreach (task; list.tasks) {
			render ~= format("%03d: %s", parse!int(task.humanId), task.name); // TODO: implement listModePreserveWidth checking
		}                                                        // possibly look at D string formatting functionality
		render ~= " ";

		return render;
	}

	string[] printLists(List[] lists) {
		const bool isList = ("list" == this.displayMode);

		int size = 0;
		foreach (list; lists) {
			if (list.tasks.length > size)
				size = to!int(list.tasks.length);
		}

		string[] print;

		foreach (x, list; lists) {
			string[] rows = printList(list, size);

			if (lists.length == 1) {
				print = rows;
			} else if (isList) {
				print ~= rows;
			} else {
				print.length = rows.length;
				for (int i = 0; i < rows.length; i++) {
	  				print[i] ~= rows[i][(x > 0 ? to!string(this.borderTop[0]).length : 0) .. $];
	  			}
			}
		}

		return print;
	}
}
