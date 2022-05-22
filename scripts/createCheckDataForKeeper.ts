import { defaultAbiCoder } from "ethers/lib/utils";

const abiCoder = defaultAbiCoder;
const hexParams = abiCoder.encode(["uint", "int"], [1, 2]);
console.log(`Params for keeper: ${hexParams}`);
