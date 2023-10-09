import wabt from "wabt";
import { Main } from "./main";

export async function compile(inputWat: string, outputWasm: string) {
  const wabtModule = await wabt();
  const wasmModule = wabtModule.parseWat(
    inputWat,
    await Bun.file(inputWat).text()
  );
  const { buffer } = wasmModule.toBinary({});

  await Bun.write(outputWasm, buffer);
}

export async function instantiate() {
  const buffer = await Bun.file("main.wasm").arrayBuffer();
  const module = await WebAssembly.compile(buffer);
  const instance = await WebAssembly.instantiate(module);
  return instance.exports as unknown as Main;
}
