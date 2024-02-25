const pako = require("pako");

const compressed = pako.deflateRaw(new Uint8Array(Buffer.from(process.argv[2], 'hex')), { level: 9 });

console.log(Buffer.from(compressed).toString('hex'));
