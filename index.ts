async function run() {
  const buffer = await Bun.file("main.wasm").arrayBuffer();
  const module = await WebAssembly.compile(buffer);
  const instance = await WebAssembly.instantiate(module);
  console.log(instance.exports.helloWorld());
}

run();