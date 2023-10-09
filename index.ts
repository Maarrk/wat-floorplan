import { instantiate } from "./compile";

const wasm = await instantiate();
wasm.main();
console.log(new Int32Array(wasm.memory.buffer));
console.log("points", new Float64Array(wasm.memory.buffer, 0, 40));
console.log("gradients", new Float64Array(wasm.memory.buffer, 8 * 40, 40));
