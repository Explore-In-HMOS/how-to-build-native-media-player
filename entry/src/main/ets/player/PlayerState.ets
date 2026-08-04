const LOG_CAP: number = 20;

export class SurfaceRect {
  x: number = 0;
  y: number = 0;
  w: number = 0;
  h: number = 0;

  constructor(x: number = 0, y: number = 0, w: number = 0, h: number = 0) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
  }
}

// Single source of truth shared by the takeover UI and the NativeMediaPlayerBridge.
// The bridge writes command/status traffic here; the UI binds to it via @ObjectLink.
@Observed
export class PlayerState {
  takenOver: boolean = false;
  source: string = '';
  sourceType: string = '';
  sourceFormat: string = '';
  surfaceId: string = '';
  surfaceRect: SurfaceRect = new SurfaceRect();

  playbackStatus: string = 'idle';
  currentTime: number = 0;
  duration: number = 0;
  videoWidth: number = 0;
  videoHeight: number = 0;
  buffered: number = 0;
  volume: number = 1;
  muted: boolean = false;
  rate: number = 1;
  readyState: string = '';
  networkState: string = '';
  fullscreen: boolean = false;

  lastCaptureDecision: string = '';
  captureOrigin: string = '';

  commandLog: string[] = [];
  statusLog: string[] = [];

  setSurfaceRect(x: number, y: number, w: number, h: number): void {
    this.surfaceRect = new SurfaceRect(x, y, w, h);
  }

  noteCommand(text: string): void {
    this.commandLog.push(text);
    if (this.commandLog.length > LOG_CAP) {
      this.commandLog.shift();
    }
  }

  noteStatus(text: string): void {
    this.statusLog.push(text);
    if (this.statusLog.length > LOG_CAP) {
      this.statusLog.shift();
    }
  }
}
