// practice how to parse .json

const json = '{"result":true, "count":42}';
const obj = JSON.parse(json);
console.log(obj.result);
console.log(obj.count);