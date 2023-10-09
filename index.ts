import { Main } from "./main";

export async function instantiate() {
  const buffer = await Bun.file("main.wasm").arrayBuffer();
  const module = await WebAssembly.compile(buffer);
  const instance = await WebAssembly.instantiate(module);
  return instance.exports as unknown as Main;
}

const wasm = await instantiate();
wasm.main();
console.log(new Int32Array(wasm.memory.buffer));
console.log("points", new Float64Array(wasm.memory.buffer, 0, 40));
console.log("gradients", new Float64Array(wasm.memory.buffer, 8 * 40, 40));
