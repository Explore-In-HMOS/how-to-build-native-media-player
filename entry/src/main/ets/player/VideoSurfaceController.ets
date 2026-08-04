import { BuilderNode, FrameNode, NodeController, NodeRenderType, UIContext } from '@kit.ArkUI';
import { VideoTakeoverPlayer } from './VideoTakeoverPlayer';

interface VideoSurfaceParams {
  player: VideoTakeoverPlayer;
}

@Component
struct VideoSurfaceContent {
  params?: VideoSurfaceParams;
  private xcontroller: XComponentController = new XComponentController();

  build() {
    XComponent({ id: 'takeover_video', type: XComponentType.SURFACE, controller: this.xcontroller })
      .onLoad(() => {
        this.params?.player.setSurface(this.xcontroller.getXComponentSurfaceId());
      })
      .onAreaChange(() => {
        this.params?.player.refreshFrame();
      })
      .width('100%')
      .height('100%')
  }
}

@Builder
function videoSurfaceBuilder(params: VideoSurfaceParams) {
  VideoSurfaceContent({ params: params })
}

export class VideoSurfaceController extends NodeController {
  private rootNode?: BuilderNode<[VideoSurfaceParams]>;
  private player: VideoTakeoverPlayer;

  constructor(surfaceId: string, player: VideoTakeoverPlayer) {
    super();
    this.player = player;
    const uiContext = AppStorage.get<UIContext>('UIContext');
    this.rootNode = new BuilderNode(uiContext as UIContext,
      { surfaceId: surfaceId, type: NodeRenderType.RENDER_TYPE_TEXTURE });
  }

  makeNode(uiContext: UIContext): FrameNode | null {
    return this.rootNode ? this.rootNode.getFrameNode() : null;
  }

  build(): void {
    const params: VideoSurfaceParams = { player: this.player };
    this.rootNode?.build(wrapBuilder(videoSurfaceBuilder), params);
  }
}
