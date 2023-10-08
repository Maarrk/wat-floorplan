import { watch } from "fs";

function spawnTest() {
  return Bun.spawn(["bun", "test", "--watch"]);
}

var proc = spawnTest()

watch('.', (eventType, filename) => {
  if (filename?.toString().endsWith('.wat')) {
    proc.kill();
    proc = spawnTest();
  }
});