import { beforeAll, beforeEach, describe, expect, test } from "bun:test";
import { compile } from "./compile";
import { instantiate } from "./index";

interface Point {
  x: number;
  y: number;
}

function getPoints(memory: WebAssembly.Memory, count: number): Array<Point> {
  const coordinates = new Float64Array(memory.buffer, 0, 2 * count);
  const points: Array<Point> = [];
  for (let i = 0; i < count; i++) {
    points.push({
      x: coordinates[i * 2],
      y: coordinates[i * 2 + 1],
    });
  }
  return points;
}

beforeAll(async () => {
  await compile("main.wat", "main.wasm");
});

test("main returns 0", async () => {
  const wasm = await instantiate();
  expect(wasm.main()).toBe(0);
});

describe("initial point positions", async () => {
  test("number of points from memory", async () => {
    const wasm = await instantiate();
    wasm.main();
    const points = getPoints(wasm.memory, 3);
    expect(points.length).toBe(3);
  });

  test("point A", async () => {
    const wasm = await instantiate();
    wasm.main();
    const points = getPoints(wasm.memory, 3);
    expect(points[0].x).toBe(0.0);
    expect(points[0].y).toBe(0.0);
  });

  test("point H, y coordinate", async () => {
    const wasm = await instantiate();
    wasm.main();
    const points = getPoints(wasm.memory, 3);
    expect(points[1].y).toBeCloseTo(1252.0 - 1134.0);
  });
});

test("point F moved", async () => {
  const wasm = await instantiate();
  wasm.main();
  const points = getPoints(wasm.memory, 3);
  expect(points[2].x).toBeCloseTo(1194, 0);
  expect(points[2].y).toBeCloseTo(837, 0);
});

describe("pointsDistance()", async () => {
  test("3, 4 and 5 pythagorean triangle", async () => {
    const wasm = await instantiate();
    expect(wasm.testPythagoreanDist()).toBeCloseTo(5.0);
  });
});

test("testMultiVal()", async () => {
  const wasm = await instantiate();
  expect(wasm.testMultiVal()).toBe(8);
});
