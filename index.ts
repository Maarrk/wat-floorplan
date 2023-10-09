import { compile, instantiate } from "./compile";

await compile("main.wat", "main.wasm");
const wasm = await instantiate();
wasm.main();

const points = new Float64Array(wasm.memory.buffer, 0, 40);
const pointNames = ["A", "B", "C", "F", "G", "H", "A'", "B'", "C'", "G'"];

console.log("name\tx\ty");
for (let i = 0; i < pointNames.length; i++) {
  const name = pointNames[i];
  console.log(
    `${name}\t${points[i * 2].toFixed(1)}\t${points[i * 2 + 1].toFixed(1)}`
  );
}
