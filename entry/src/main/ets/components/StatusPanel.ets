import { PlayerState } from '../player/PlayerState';

@Component
export struct StatusPanel {
  @ObjectLink playerState: PlayerState;

  build() {
    Column() {
      Column() {
        Row() {
          Row().dot('#5CE0B0')
          Text('Media source').secTitle()
          Blank()
          Text(this.playerState.takenOver ? 'LIVE' : 'IDLE')
            .fontSize(9)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.playerState.takenOver ? '#5CE0B0' : '#93A0AC')
            .backgroundColor(this.playerState.takenOver ? '#123A30' : '#232A31')
            .padding({ left: 7, right: 7, top: 2, bottom: 2 })
            .borderRadius(8)
        }.header()

        Row() {
          Text('source').kvLabel()
          Text(this.shortTail(this.playerState.source, 22)).kvValue()
        }.kvRow()
        Row() {
          Text('type').kvLabel()
          Text(this.playerState.sourceType || '—').kvValue()
        }.kvRow()
        Row() {
          Text('format').kvLabel()
          Text(this.playerState.sourceFormat || 'n/a').kvValue()
        }.kvRow()
        Row() {
          Text('surface').kvLabel()
          Text(this.shortTail(this.playerState.surfaceId, 10)).kvValue()
        }.kvRow()
        Row() {
          Text('rect').kvLabel()
          Text(this.rectText()).kvValue()
        }.kvRow()
      }
      .card()

      Column() {
        Row() {
          Row().dot('#5AB0E6')
          Text('Playback').secTitle()
        }.header()

        Row() {
          Text('status').kvLabel()
          Text(this.playerState.playbackStatus).kvValue()
        }.kvRow()
        Row() {
          Text('resolution').kvLabel()
          Text(this.playerState.videoWidth > 0
            ? `${this.playerState.videoWidth}×${this.playerState.videoHeight}`
            : '—').kvValue()
        }.kvRow()
        Row() {
          Text('time').kvLabel()
          Text(`${this.playerState.currentTime.toFixed(1)} / ${this.playerState.duration.toFixed(1)}s`).kvValue()
        }.kvRow()
        Row() {
          Text('buffered').kvLabel()
          Text(`${this.playerState.buffered.toFixed(1)}s`).kvValue()
        }.kvRow()
        Row() {
          Text('volume').kvLabel()
          Text(this.playerState.muted ? 'muted' : this.playerState.volume.toFixed(2)).kvValue()
        }.kvRow()
        Row() {
          Text('rate').kvLabel()
          Text(`${this.playerState.rate}×`).kvValue()
        }.kvRow()
      }
      .card()

      Column() {
        Row() {
          Row().dot('#F2C879')
          Text('Commands in').secTitle()
        }.header()
        if (this.playerState.commandLog.length === 0) {
          Text('—').logEmpty()
        } else {
          ForEach(this.playerState.commandLog, (item: string) => {
            Row() {
              Text('›').logMark()
              Text(item).logText()
            }.logRow()
          }, (item: string) => `${item}`)
        }
      }
      .card()

      Column() {
        Row() {
          Row().dot('#6FD3C4')
          Text('Status out').secTitle()
        }.header()
        if (this.playerState.statusLog.length === 0) {
          Text('—').logEmpty()
        } else {
          ForEach(this.playerState.statusLog, (item: string) => {
            Row() {
              Text('›').logMark()
              Text(item).logText()
            }.logRow()
          }, (item: string) => `${item}`)
        }
      }
      .card()

      Blank().height(18)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .padding({ left: 18, right: 18 })
  }

  private rectText(): string {
    const r = this.playerState.surfaceRect;
    return `${Math.round(r.x)},${Math.round(r.y)} · ${Math.round(r.w)}×${Math.round(r.h)}`;
  }

  private shortTail(value: string, keep: number): string {
    if (value.length === 0) {
      return '—';
    }
    return value.length > keep ? `…${value.substring(value.length - keep)}` : value;
  }
}

@Extend(Row)
function dot(color: string) {
  .width(6)
  .height(6)
  .borderRadius(3)
  .backgroundColor(color)
  .margin({ right: 7 })
}

@Extend(Row)
function header() {
  .width('100%')
  .alignItems(VerticalAlign.Center)
  .margin({ bottom: 7 })
}

@Extend(Text)
function secTitle() {
  .fontSize(12)
  .fontWeight(FontWeight.Bold)
  .fontColor('#DCE6EF')
}

@Extend(Row)
function kvRow() {
  .width('100%')
  .alignItems(VerticalAlign.Center)
  .margin({ top: 4 })
}

@Extend(Text)
function kvLabel() {
  .fontSize(10)
  .fontColor('#7E93A3')
  .width('36%')
  .textAlign(TextAlign.Start)
}

@Extend(Text)
function kvValue() {
  .fontSize(10)
  .fontColor('#EAF1F7')
  .layoutWeight(1)
  .textAlign(TextAlign.End)
  .maxLines(1)
  .textOverflow({ overflow: TextOverflow.Ellipsis })
}

@Extend(Row)
function logRow() {
  .width('100%')
  .alignItems(VerticalAlign.Top)
  .margin({ top: 3 })
}

@Extend(Text)
function logMark() {
  .fontSize(10)
  .fontColor('#5A6672')
  .margin({ right: 6 })
}

@Extend(Text)
function logText() {
  .fontSize(10)
  .fontColor('#C7D2DC')
  .layoutWeight(1)
  .textAlign(TextAlign.Start)
  .maxLines(1)
  .textOverflow({ overflow: TextOverflow.Ellipsis })
}

@Extend(Text)
function logEmpty() {
  .fontSize(10)
  .fontColor('#5E6A76')
  .width('100%')
  .textAlign(TextAlign.Start)
  .margin({ top: 3 })
}

@Extend(Column)
function card() {
  .width('100%')
  .alignItems(HorizontalAlign.Start)
  .padding({ left: 14, right: 14, top: 11, bottom: 11 })
  .margin({ top: 10 })
  .borderRadius(16)
  .backgroundColor('#131B24')
  .border({ width: 1, color: '#20303F' })
}
