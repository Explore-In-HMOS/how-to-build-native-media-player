import { webview } from '@kit.ArkWeb';
import { VideoPlayerListener, VideoTakeoverPlayer } from './VideoTakeoverPlayer';
import { PlayerState } from './PlayerState';

class VideoListener implements VideoPlayerListener {
  private handler: webview.NativeMediaPlayerHandler;
  private state: PlayerState;

  constructor(handler: webview.NativeMediaPlayerHandler, state: PlayerState) {
    this.handler = handler;
    this.state = state;
  }

  onPlaying(): void {
    this.handler.handleStatusChanged(webview.PlaybackStatus.PLAYING);
    this.state.playbackStatus = 'playing';
    this.state.noteStatus('status: playing');
  }

  onPaused(): void {
    this.handler.handleStatusChanged(webview.PlaybackStatus.PAUSED);
    this.state.playbackStatus = 'paused';
    this.state.noteStatus('status: paused');
  }

  onEnded(): void {
    this.handler.handleEnded();
    this.state.playbackStatus = 'ended';
    this.state.noteStatus('ended');
  }

  onPrepared(width: number, height: number, durationSec: number): void {
    this.handler.handleDurationChanged(durationSec);
    this.state.duration = durationSec;
    this.state.videoWidth = width;
    this.state.videoHeight = height;
    this.state.noteStatus(`prepared ${width}x${height} ${durationSec.toFixed(1)}s`);
  }

  onVideoSize(width: number, height: number): void {
    this.state.videoWidth = width;
    this.state.videoHeight = height;
    this.state.noteStatus(`video size ${width}x${height}`);
  }

  onTimeUpdate(timeSec: number): void {
    this.handler.handleTimeUpdate(timeSec);
    this.state.currentTime = timeSec;
  }

  onError(message: string): void {
    this.handler.handleError(webview.MediaError.NETWORK_ERROR, message);
    this.state.noteStatus(`error: ${message}`);
  }

  onReleased(): void {
    this.state.noteStatus('player released');
  }
}

export class VideoBridge implements webview.NativeMediaPlayerBridge {
  player: VideoTakeoverPlayer;
  private handler: webview.NativeMediaPlayerHandler;
  private state: PlayerState;
  private onReleased?: () => void;

  constructor(handler: webview.NativeMediaPlayerHandler, mediaInfo: webview.MediaInfo,
    state: PlayerState, onReleased?: () => void) {
    this.handler = handler;
    this.state = state;
    this.onReleased = onReleased;

    const first: webview.MediaSourceInfo | undefined =
      mediaInfo.mediaSrcList.length > 0 ? mediaInfo.mediaSrcList[0] : undefined;
    const source: string = first ? first.source : '';
    const surface: webview.NativeMediaPlayerSurfaceInfo = mediaInfo.surfaceInfo;

    state.takenOver = true;
    state.source = source;
    state.sourceType = first && first.type === webview.SourceType.MSE ? 'MSE (blob)' : 'URL';
    state.sourceFormat = first ? first.format : '';
    state.surfaceId = surface.id;
    state.setSurfaceRect(surface.rect.x, surface.rect.y, surface.rect.width, surface.rect.height);
    state.noteCommand(`took over: ${source}`);

    this.player = new VideoTakeoverPlayer();
    this.player.setListener(new VideoListener(handler, state));
    this.player.init(source, mediaInfo.headers);
  }

  updateRect(x: number, y: number, width: number, height: number): void {
    this.state.setSurfaceRect(x, y, width, height);
    this.state.noteCommand(`updateRect(${x}, ${y}, ${width}, ${height})`);
  }

  play(): void {
    this.player.play();
    this.state.noteCommand('play');
  }

  pause(): void {
    this.player.pause();
    this.state.noteCommand('pause');
  }

  seek(targetTime: number): void {
    this.handler.handleSeeking();
    this.player.seek(targetTime);
    this.state.noteCommand(`seek(${targetTime.toFixed(1)}s)`);
  }

  setVolume(volume: number): void {
    this.player.setVolume(volume);
    this.state.volume = volume;
    this.handler.handleVolumeChanged(volume);
    this.state.noteCommand(`setVolume(${volume.toFixed(2)})`);
  }

  setMuted(muted: boolean): void {
    this.player.setMuted(muted);
    this.state.muted = muted;
    this.handler.handleMutedChanged(muted);
    this.state.noteCommand(`setMuted(${muted})`);
  }

  setPlaybackRate(playbackRate: number): void {
    this.state.rate = playbackRate;
    this.handler.handlePlaybackRateChanged(playbackRate);
    this.state.noteCommand(`setPlaybackRate(${playbackRate})`);
  }

  release(): void {
    this.player.release();
    this.state.takenOver = false;
    this.state.noteCommand('release');
    this.onReleased?.();
  }

  enterFullscreen(): void {
    this.state.fullscreen = true;
    this.handler.handleFullscreenChanged(true);
    this.state.noteCommand('enterFullscreen');
  }

  exitFullscreen(): void {
    this.state.fullscreen = false;
    this.handler.handleFullscreenChanged(false);
    this.state.noteCommand('exitFullscreen');
  }
}
