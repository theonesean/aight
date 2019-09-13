module util.hasher;

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
