import { decodeNativeRaster } from 'etegami'
import type { NativeRasterInput } from 'etegami'

self.onmessage = async (e: MessageEvent) => {
  const input = e.data as NativeRasterInput;
  const imageData = await decodeNativeRaster(input);
  self.postMessage(imageData, [imageData.data.buffer]);
};
