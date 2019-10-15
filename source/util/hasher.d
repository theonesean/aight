module util.hasher;

import std.stdio: writeln;

class Hasher {

	private string[ulong] hashCodes;
	private ulong max = 9;

	ulong hash(string str) {
		if (this.hashCodes.length >= max)
			max = (max * 10) + 9;

		ulong num = (typeid(str).getHash(&str) % max) + 1;
		while ((num in this.hashCodes) !is null)
			num++;

		hashCodes[num] = str;
		return num;
	}

	bool restrict(ulong num) {
		if ((num in this.hashCodes) is null) {
			this.hashCodes[num] = "#";
			return true;
		} else return false;
	}

}

///
unittest {
	Hasher hasher = new Hasher();
	hasher.restrict(1);
	ulong a = hasher.hash("apple");
	ulong b = hasher.hash("banana");
	assert(a != b, "Hash nums shouldn't be duplicated.");
	assert(a != 1 && b != 1, "Restricted values should be respected.");

	writeln("util/hasher.d ----- CHECK");
}
