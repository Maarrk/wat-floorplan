import wabt from "wabt";

export async function compile(inputWat: string, outputWasm: string) {
  const wabtModule = await wabt();
  const wasmModule = wabtModule.parseWat(
    inputWat,
    await Bun.file(inputWat).text()
  );
  const { buffer } = wasmModule.toBinary({});

  await Bun.write(outputWasm, buffer);
}
