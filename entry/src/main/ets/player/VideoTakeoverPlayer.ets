import { media } from '@kit.MediaKit';
import { BusinessError } from '@kit.BasicServicesKit';

export interface VideoPlayerListener {
  onPlaying(): void;
  onPaused(): void;
  onEnded(): void;
  onPrepared(width: number, height: number, durationSec: number): void;
  onVideoSize(width: number, height: number): void;
  onTimeUpdate(timeSec: number): void;
  onError(message: string): void;
  onReleased(): void;
}

export class VideoTakeoverPlayer {
  private avPlayer?: media.AVPlayer;
  private listener?: VideoPlayerListener;
  private surfaceId?: string;
  private reachedInitialized: boolean = false;
  private prepared: boolean = false;
  private currentVolume: number = 1;
  private avState: string = 'idle';
  private commands: Array<() => void> = [];

  setListener(listener: VideoPlayerListener): void {
    this.listener = listener;
  }

  async init(source: string, headers?: Record<string, string>): Promise<void> {
    try {
      this.avPlayer = await media.createAVPlayer();
      this.registerCallbacks(this.avPlayer);
      const mediaSource: media.MediaSource = media.createMediaSourceWithUrl(source, headers);
      this.avPlayer.setMediaSource(mediaSource);
    } catch (err) {
      this.listener?.onError((err as BusinessError).message);
    }
  }

  setSurface(surfaceId: string): void {
    this.surfaceId = surfaceId;
    this.applySurfaceAndPrepare();
  }

  private applySurfaceAndPrepare(): void {
    if (this.avPlayer && this.reachedInitialized && this.surfaceId && !this.prepared) {
      try {
        this.avPlayer.surfaceId = this.surfaceId;
        this.avPlayer.prepare();
      } catch (err) {
        this.listener?.onError((err as BusinessError).message);
      }
    }
  }

  play(): void {
    this.enqueue(() => {
      if (this.avState === 'completed') {
        this.avPlayer?.seek(0);
      }
      this.avPlayer?.play();
    });
  }

  pause(): void {
    this.enqueue(() => {
      if (this.avState === 'playing') {
        this.avPlayer?.pause();
      }
    });
  }

  seek(seconds: number): void {
    this.enqueue(() => this.avPlayer?.seek(Math.round(seconds * 1000)));
  }

  setVolume(volume: number): void {
    this.currentVolume = volume;
    this.enqueue(() => this.avPlayer?.setVolume(volume));
  }

  setMuted(muted: boolean): void {
    this.enqueue(() => this.avPlayer?.setVolume(muted ? 0 : this.currentVolume));
  }

  release(): void {
    try {
      this.avPlayer?.release();
    } catch (err) {
      this.listener?.onError((err as BusinessError).message);
    }
  }

  // Paused surface keeps its old frame after a resize; re-seek forces a fresh one.
  refreshFrame(): void {
    try {
      if (this.avPlayer && this.prepared) {
        this.avPlayer.seek(this.avPlayer.currentTime);
      }
    } catch (err) {
      this.listener?.onError((err as BusinessError).message);
    }
  }

  private enqueue(command: () => void): void {
    this.commands.push(command);
    this.flush();
  }

  private flush(): void {
    if (!this.prepared || !this.avPlayer) {
      return;
    }
    while (this.commands.length > 0) {
      const command = this.commands.shift();
      if (command) {
        command();
      }
    }
  }

  private registerCallbacks(avPlayer: media.AVPlayer): void {
    avPlayer.on('stateChange', (state: string) => {
      this.avState = state;
      switch (state) {
        case 'initialized':
          this.reachedInitialized = true;
          this.applySurfaceAndPrepare();
          break;
        case 'prepared':
          this.prepared = true;
          this.listener?.onPrepared(avPlayer.width, avPlayer.height, avPlayer.duration / 1000);
          this.flush();
          break;
        case 'playing':
          this.listener?.onPlaying();
          break;
        case 'paused':
          this.listener?.onPaused();
          break;
        case 'completed':
          this.listener?.onEnded();
          break;
        case 'released':
          this.prepared = false;
          this.reachedInitialized = false;
          this.listener?.onReleased();
          break;
        default:
          break;
      }
    });
    avPlayer.on('audioInterrupt', (event: audio.InterruptEvent) => {
    })
    avPlayer.on('audioOutputDeviceChangeWithInfo', (info: audio.AudioStreamDeviceChangeInfo) => {
    })
    avPlayer.on('videoSizeChange', (width: number, height: number) => {
      this.listener?.onVideoSize(width, height);
    });
    avPlayer.on('timeUpdate', (time: number) => {
      this.listener?.onTimeUpdate(time / 1000);
    });
    avPlayer.on('error', (err: BusinessError) => {
      this.listener?.onError(err.message);
      avPlayer.reset();
    });
  }
}
