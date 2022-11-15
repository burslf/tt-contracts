function getTimestampForOption(d) {
    const date = Date.now() / 1000;
    const result = date + (60 * 60 * d)
    console.log(Math.floor(result));
}

function getTimeStamp(d) {
    const date = Date.parse(d);
    console.log(Math.floor(date) / 1000);
}

getTimeStamp("2012-02-18 14:28:32 GMT");

module.exports = { getTimestampForOption, getTimeStamp };