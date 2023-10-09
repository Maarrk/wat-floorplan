export interface Main {
  memory: WebAssembly.Memory;
  main(): number;
  testPythagoreanDist(): number;
  testMultiVal(): number;
}
