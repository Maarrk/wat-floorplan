import { beforeAll, beforeEach, expect, test } from "bun:test";
import { compile } from "./compile";

async function instantiate() {
  const buffer = await Bun.file("main.wasm").arrayBuffer();
  const module = await WebAssembly.compile(buffer);
  const instance = await WebAssembly.instantiate(module);
  return instance.exports;
}

beforeAll(async done => {
  await compile("main.wat", "main.wasm");
  done();
})

test("hello world returns 42", async done => {
  const wasm = await instantiate();
  expect(wasm.helloWorld()).toBe(42);
  done();
})