const fs = require("fs");

let rawData = fs.readFileSync("/Users/apple/Archive/dump.json");
let dump = JSON.parse(rawData);
rawData = fs.readFileSync("/Users/apple/Archive/dump_get.json");
let dumpBasicInfo = JSON.parse(rawData);
let info = dumpBasicInfo.info;

let keys = "'(";
for (let key in info) {
    if (!(key in dump)) {
        console.log(key, "is not in dump");
        keys += key + " ";
    }
}
keys = keys.substr(0, keys.length - 1);
keys += ")";
console.log(keys);
