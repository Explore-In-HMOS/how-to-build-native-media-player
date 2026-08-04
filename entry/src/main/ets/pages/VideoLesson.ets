import { webview } from '@kit.ArkWeb';
import { display } from '@kit.ArkUI';
import { VideoBridge } from '../player/VideoBridge';
import { VideoSurfaceController } from '../player/VideoSurfaceController';
import { PlayerState } from '../player/PlayerState';
import { StatusPanel } from '../components/StatusPanel';

@Entry
@Component
struct VideoLesson {
  private controller: webview.WebviewController = new webview.WebviewController();
  @State state: PlayerState = new PlayerState();
  @State surfaceController: VideoSurfaceController | undefined = undefined;
  @State showSurface: boolean = false;
  @State fsMode: boolean = false;
  @State capturePending: boolean = false;
  @State private screenVp: number = 233;
  private scroller: Scroller = new Scroller();
  private fsHandler: FullScreenExitHandler | undefined = undefined;
  private captureHandler: ScreenCaptureHandler | undefined = undefined;

  aboutToAppear(): void {
    try {
      const d = display.getDefaultDisplaySync();
      this.screenVp = d.height / d.densityPixels;
    } catch (err) {
    }
  }

  private registerTakeover(): void {
    this.controller.onCreateNativeMediaPlayer(
      (handler: webview.NativeMediaPlayerHandler, mediaInfo: webview.MediaInfo) => {
        this.state.noteStatus(`onCreate fired: type=${mediaInfo.mediaType}`);
        const bridge: VideoBridge =
          new VideoBridge(handler, mediaInfo, this.state, () => { this.showSurface = false; });
        const ctrl = new VideoSurfaceController(mediaInfo.surfaceInfo.id, bridge.player);
        ctrl.build();
        this.surfaceController = ctrl;
        this.showSurface = true;
        return bridge;
      });
  }

  private onFullScreenEnter(event: FullScreenEnterEvent): void {
    this.fsHandler = event.handler;
    this.fsMode = true;
    this.state.fullscreen = true;
    this.state.noteStatus('fullscreen enter');
    this.scroller.scrollEdge(Edge.Top);
  }

  private onFullScreenExit(): void {
    this.fsHandler = undefined;
    this.fsMode = false;
    this.state.fullscreen = false;
    this.state.noteStatus('fullscreen exit');
  }

  private requestCapture(): void {
    try {
      this.controller.runJavaScript('navigator.mediaDevices.getDisplayMedia({ video: true })');
      this.state.noteStatus('capture requested');
    } catch (err) {
      this.state.noteStatus('capture request failed');
    }
  }

  private onCaptureRequest(handler: ScreenCaptureHandler): void {
    this.captureHandler = handler;
    this.state.captureOrigin = handler.getOrigin();
    this.capturePending = true;
    this.state.noteStatus(`capture request: ${this.state.captureOrigin}`);
  }

  private grantCapture(): void {
    this.captureHandler?.grant({ captureMode: WebCaptureMode.HOME_SCREEN });
    this.state.lastCaptureDecision = 'granted';
    this.state.noteStatus('capture granted');
    this.capturePending = false;
  }

  private denyCapture(): void {
    this.captureHandler?.deny();
    this.state.lastCaptureDecision = 'denied';
    this.state.noteStatus('capture denied');
    this.capturePending = false;
  }

  build() {
    Scroll(this.scroller) {
      Column() {
        Text('Video Takeover')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#7FD1C4')
          .textAlign(TextAlign.Center)
          .width('100%')
          .margin({ top: 6, bottom: 4 })
          .visibility(this.fsMode ? Visibility.None : Visibility.Visible)

        Stack({ alignContent: Alignment.TopStart }) {
          if (this.showSurface && this.surfaceController !== undefined) {
            NodeContainer(this.surfaceController)
              .width('100%')
              .height('100%')
              .backgroundColor(Color.Transparent)
          }

          Web({ src: $rawfile('video.html'), controller: this.controller })
            .geolocationAccess(false)
            .fileAccess(true)
            .enableNativeMediaPlayer({ enable: true, shouldOverlay: false })
            .onPageBegin(() => this.registerTakeover())
            .onFullScreenEnter((event) => this.onFullScreenEnter(event))
            .onFullScreenExit(() => this.onFullScreenExit())
            .onScreenCaptureRequest((event) => {
              if (event) {
                this.onCaptureRequest(event.handler);
              }
            })
            .overScrollMode(OverScrollMode.NEVER)
            .width('100%')
            .height('100%')
            .backgroundColor(Color.Transparent)

          if (this.fsMode) {
            Row() {
              Text('✕ Exit fullscreen')
                .fontSize(12)
                .fontColor('#FFFFFF')
                .padding({ left: 14, right: 14, top: 7, bottom: 7 })
                .backgroundColor('#B3000000')
                .borderRadius(16)
                .onClick(() => this.fsHandler?.exitFullScreen())
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .margin({ top: 24 })
          }
        }
        .width('100%')
        .height(this.fsMode ? this.screenVp : 150)

        StatusPanel({ playerState: this.state })
          .visibility(this.fsMode ? Visibility.None : Visibility.Visible)

        Column() {
          Column() {
            Row() {
              Row().capDot()
              Text('Screen capture').capTitle()
            }.capHeader()

            Row() {
              Text('origin').capLabel()
              Text(this.state.captureOrigin || '—').capValue()
            }.capRow()
            Row() {
              Text('decision').capLabel()
              Text(this.state.lastCaptureDecision || '—').capValue()
            }.capRow()

            if (this.capturePending) {
              Row() {
                Text('Grant').capBtn('#123A30', '#5CE0B0')
                  .layoutWeight(1)
                  .margin({ right: 8 })
                  .onClick(() => this.grantCapture())
                Text('Deny').capBtn('#3A1F22', '#F0888E')
                  .layoutWeight(1)
                  .onClick(() => this.denyCapture())
              }
              .width('100%')
              .margin({ top: 12 })
            } else {
              Text('Request capture').capBtn('#26203C', '#B79CFF')
                .width('100%')
                .margin({ top: 12 })
                .onClick(() => this.requestCapture())
            }
          }
          .capCard()
        }
        .width('100%')
        .padding({ left: 18, right: 18 })
        .visibility(this.fsMode ? Visibility.None : Visibility.Visible)

        Blank().height(16)
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .align(Alignment.Top)
  }
}

@Extend(Row)
function capDot() {
  .width(6)
  .height(6)
  .borderRadius(3)
  .backgroundColor('#B79CFF')
  .margin({ right: 7 })
}

@Extend(Row)
function capHeader() {
  .width('100%')
  .alignItems(VerticalAlign.Center)
  .margin({ bottom: 7 })
}

@Extend(Text)
function capTitle() {
  .fontSize(12)
  .fontWeight(FontWeight.Bold)
  .fontColor('#DCE6EF')
}

@Extend(Text)
function capLabel() {
  .fontSize(10)
  .fontColor('#7E93A3')
  .width('36%')
  .textAlign(TextAlign.Start)
}

@Extend(Text)
function capValue() {
  .fontSize(10)
  .fontColor('#EAF1F7')
  .layoutWeight(1)
  .textAlign(TextAlign.End)
  .maxLines(1)
  .textOverflow({ overflow: TextOverflow.Ellipsis })
}

@Extend(Row)
function capRow() {
  .width('100%')
  .alignItems(VerticalAlign.Center)
  .margin({ top: 4 })
}

@Extend(Text)
function capBtn(bg: string, fg: string) {
  .fontSize(11)
  .fontWeight(FontWeight.Medium)
  .fontColor(fg)
  .textAlign(TextAlign.Center)
  .padding({ top: 8, bottom: 8 })
  .backgroundColor(bg)
  .borderRadius(12)
}

@Extend(Column)
function capCard() {
  .width('100%')
  .alignItems(HorizontalAlign.Start)
  .padding({ left: 14, right: 14, top: 11, bottom: 11 })
  .borderRadius(16)
  .backgroundColor('#131B24')
  .border({ width: 1, color: '#20303F' })
}
