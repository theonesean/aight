import std.stdio;
import std.array;
import std.string;
import std.conv;
import config;
import providers;
import print;

void main(string[] args) {
	Config conf = new Config(args);
	Printer printer = new Printer(conf);
	
	foreach (service; conf.services) {
		TaskProvider provider = getTaskProvider(service);
		List[] lists = provider.getLists();
		
		foreach (str; printer.printLists(lists)) {
    		writeln(str);
    	}
	}
}
