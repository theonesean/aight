import std.stdio;
import config;
import providers;

void main(string[] args) {
	Config conf = new Config(args);
	writeln(conf.settings["something"]);
	writeln(conf.isLogging());
}
