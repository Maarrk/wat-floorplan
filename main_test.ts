import { beforeAll, beforeEach, describe, expect, test } from "bun:test";
import { compile } from "./compile";
import { Main } from "./main";

async function instantiate() {
  const buffer = await Bun.file("main.wasm").arrayBuffer();
  const module = await WebAssembly.compile(buffer);
  const instance = await WebAssembly.instantiate(module);
  return instance.exports as unknown as Main;
}

beforeAll(async () => {
  await compile("main.wat", "main.wasm");
});

test("main returns 0", async () => {
  const wasm = await instantiate();
  expect(wasm.main()).toBe(0);
});

describe("pointsDistance()", async () => {
  test("3, 4 and 5 pythagorean triangle", async () => {
    const wasm = await instantiate();
    expect(wasm.testPythagoreanDist()).toBeCloseTo(5.0);
  });
});
