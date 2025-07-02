import { decodeNativeRaster, NativeRasterInput } from './decode';

export async function renderNativeRasterToCanvas(
  input: NativeRasterInput,
  canvas?: HTMLCanvasElement
): Promise<HTMLCanvasElement> {
  const imgData = await decodeNativeRaster(input);
  const cnv = canvas || document.createElement('canvas');
  cnv.width = imgData.width;
  cnv.height = imgData.height;
  cnv.getContext('2d')?.putImageData(imgData, 0, 0);
  return cnv;
}

export async function loadAndRenderRasterFromURL(
  url: string,
  canvas?: HTMLCanvasElement
): Promise<HTMLCanvasElement> {
  const res = await fetch(url);
  const json = await res.json() as NativeRasterInput;
  return renderNativeRasterToCanvas(json, canvas);
}
