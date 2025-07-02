import { inflate } from 'pako';

export interface NativeRasterInput {
  width: number;
  height: number;
  data_b64: string;
  id?: string;
}

export async function decodeNativeRaster(input: NativeRasterInput): Promise<ImageData> {
  const compressed = Uint8Array.from(atob(input.data_b64), c => c.charCodeAt(0));
  const jsonStr = new TextDecoder().decode(inflate(compressed));
  const intArray = JSON.parse(jsonStr) as number[];

  const rgba = new Uint8ClampedArray(intArray.length * 4);
  for (let i = 0; i < intArray.length; i++) {
    const val = intArray[i] >>> 0;
    rgba[i * 4 + 0] = (val) & 0xff;
    rgba[i * 4 + 1] = (val >>> 8) & 0xff;
    rgba[i * 4 + 2] = (val >>> 16) & 0xff;
    rgba[i * 4 + 3] = (val >>> 24) & 0xff;
  }

  return new ImageData(rgba, input.width, input.height);
}
