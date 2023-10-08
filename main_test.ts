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

describe("invSqrt()", async () => {
  const precisionDigits = 3;
  test("1 over sqrt of 9", async () => {
    const wasm = await instantiate();
    expect(wasm.invSqrt(9)).toBeCloseTo(0.333, precisionDigits);
  });
  test("1 over sqrt of 1/4", async () => {
    const wasm = await instantiate();
    expect(wasm.invSqrt(0.25)).toBeCloseTo(2.0, precisionDigits);
  });
});
