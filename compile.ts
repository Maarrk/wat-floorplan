import wabt from "wabt";
const wabtModule = await wabt()

const inputWat = "main.wat";
const outputWasm = "main.wasm";

const wasmModule = wabtModule.parseWat(inputWat, await Bun.file(inputWat).text());
const { buffer } = wasmModule.toBinary({});

Bun.write(outputWasm, buffer);