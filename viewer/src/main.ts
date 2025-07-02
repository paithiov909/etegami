import './style.css'
import type { NativeRasterInput } from 'etegami'
import { Recorder, RecorderStatus } from 'canvas-record'
// @ts-ignore
import DecodeWorker from './decode.worker.ts?worker'

const delay = parseInt(new URL(window.location.href).searchParams.get('delay') || '1000');
const idsParam = new URL(window.location.href).searchParams.get('id');
if (!idsParam) {
  throw new Error("No id parameter in URL.");
}

const baseNames = idsParam.split(',');
const fileNames = baseNames.map(name => `${name}.json`);

const inputs: NativeRasterInput[] = await Promise.all(
  fileNames.map(async (fname) => {
    const res = await fetch(fname);
    if (!res.ok) throw new Error(`Failed to fetch ${fname}`);
    return res.json() as Promise<NativeRasterInput>;
  })
);

const canvas = document.getElementById('c') as HTMLCanvasElement;
const ctx = canvas.getContext('2d');
if (!ctx) throw new Error("Canvas context could not be retrieved.");

/**
 * Recorder
 */
let recorder: Recorder | null = null;

const recBtn = document.getElementById('rec-btn') as HTMLButtonElement;

recBtn.addEventListener('click', async () => {
  if (recorder?.status === RecorderStatus.Recording) {
    recBtn.textContent = '⏺️ Record';
    await recorder.stop();
    recorder = null;
  } else {
    recBtn.textContent = '⏹️ Stop';
    recorder = new Recorder(ctx, {
      frameRate: 1000 / delay,
      duration: Infinity,
      download: true,
      extension: 'webm',
      encoderOptions: {
        // target: 'in-browser',
        extension: 'webm',
      },
    });
    await recorder.start();
  }
});

const worker = new DecodeWorker();

let frameIndex = 0;
worker.onmessage = async (e) => {
  const imgData = e.data as ImageData;
  canvas.width = imgData.width;
  canvas.height = imgData.height;
  ctx.putImageData(imgData, 0, 0);
  if (recorder?.status === RecorderStatus.Recording) {
    await recorder.step();
  }
};

/**
 * Play / Pause
 */
let timer: number | null = null;
let isPlaying = false;

function startPlayback() {
  if (isPlaying) return;
  isPlaying = true;
  timer = setInterval(() => {
    worker.postMessage(inputs[frameIndex]);
    frameIndex = (frameIndex + 1) % inputs.length;
  }, delay);
}

function stopPlayback() {
  if (!isPlaying) return;
  isPlaying = false;
  if (timer !== null) clearInterval(timer);
  timer = null;
}

const btn = document.getElementById('play-btn') as HTMLButtonElement;
btn.addEventListener('click', () => {
  if (isPlaying) {
    stopPlayback();
    btn.textContent = '▶️ Play';
  } else {
    startPlayback();
    btn.textContent = '⏸️ Pause';
  }
});

// Start playback
startPlayback();
