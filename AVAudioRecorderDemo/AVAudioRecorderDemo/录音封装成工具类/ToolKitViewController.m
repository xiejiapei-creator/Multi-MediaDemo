//
//  ToolKitViewController.m
//  AVAudioRecorderDemo
//
//  Created by 谢佳培 on 2020/8/28.
//  Copyright © 2020 xiejiapei. All rights reserved.
//

#import "ToolKitViewController.h"
#import "RecorderKit.h"
#import "TalkingRecordView.h"

@interface ToolKitViewController ()<TalkingRecordViewDelegate, AudioPlayerDelegate>

@property (strong, nonatomic) TalkingRecordView *recordView;// 录音视图
@property (strong, nonatomic) UIButton *playPictureButton;// 录音完成播放按钮
@property (strong, nonatomic) UILabel *tipLabel;// 提示语
@property (assign, nonatomic) AudioType audioType;// 想要转化为的音频类型
@property (copy, nonatomic) NSString *audioPath;// 音频文件所在路径

@end

@implementation ToolKitViewController

#pragma mark - Life Circle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self createSubViews];
}

#pragma mark - 手势

// 查看沙盒目录中文件列表
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) firstObject];
    NSFileManager *manager = [NSFileManager defaultManager];
    // 获得当前文件的所有子文件:subpathsAtPath:
    NSArray *pathList = [manager subpathsAtPath:path];

    NSMutableArray *audioPathList = [NSMutableArray array];
    // 遍历这个文件夹下面的子文件，只获得录音文件
    for (NSString *audioPath in pathList)
    {
        // 通过对比文件的延展名（扩展名、尾缀）来区分是不是录音文件
        if ([audioPath.pathExtension isEqualToString:@"caf"])
        {
            //把筛选出来的文件放到数组中 -> 得到所有的音频文件
            [audioPathList addObject:audioPath];
        }
    }
    
    NSLog(@"获得当前文件的所有子文件:%@",pathList);
    NSLog(@"所有的音频文件:%@",audioPathList);
}

// 按下说话按钮
- (void)holdTalkButtonTouchDown
{
    NSLog(@"按下说话按钮");
    [self talkStateChanged:TalkStateTalking];
}

// 在按钮范围内仍进行录音
- (void)holdTalkButtonMoveIn
{
    NSLog(@"在按钮范围内仍进行录音");
    [self talkStateChanged:TalkStateTalking];
}

// 移出按钮取消录音
- (void)holdTalkButtonMoveOut
{
    NSLog(@"移出按钮");
    [self talkStateChanged:TalkStateCanceling];
}

// 在按钮范围内抬起手指，录音完成
- (void)holdTalkButtonTouchUpInside
{
    NSLog(@"抬起手指，录音完成");
    [self talkFinished];
}

// 在按钮范围外抬起手指，未录音
- (void)holdTalkButtonTouchUpOutside
{
    NSLog(@"在按钮范围外抬起手指，未录音");
    [self talkStateChanged:TalkStateNone];
}

// 录音状态改变时录音视图和播放按钮的出现隐藏
- (void)talkStateChanged:(TalkState)talkState
{
    if (talkState == TalkStateTalking)
    {
        // 正在录音时展示录音视图，隐藏播放按钮
        self.recordView.hidden = NO;
        self.playPictureButton.hidden = YES;
    }
    else if (talkState == TalkStateCanceling)
    {
        // 取消录音时隐藏录音视图
        self.recordView.hidden = NO;
    }
    else
    {
        // 录音完成和未录音时候，隐藏录音视图并取消录音
        self.recordView.hidden = YES;
        [self.recordView cancelRecord];
    }
    // 录音状态改变
    self.recordView.talkState = talkState;
    // 提示语和播放按钮一起隐藏/展现
    self.tipLabel.hidden = self.playPictureButton.hidden;
}

// 录音完成
- (void)talkFinished
{
    // 隐藏录音视图并结束录音
    self.recordView.hidden = YES;
    [self.recordView endRecord];
}

// 播放录音
- (void)playTalk
{
    if (self.audioType == AudioTypeMP3)// 播放MP3
    {
        // initWithDelegate 和单例不相容
        AudioPlayerTool *audioMP3Player = [[AudioPlayerTool alloc] initWithDelegate:self];
        [audioMP3Player playAtPath:self.audioPath isMP3Audio:YES];
    }
    else if(self.audioType == AudioTypeAMR)// 播放AMR
    {
        // initWithDelegate 和单例不相容
        AudioPlayerTool *audioAmrPlayer = [[AudioPlayerTool alloc] initWithDelegate:self];
        [audioAmrPlayer  playAtPath:self.audioPath isMP3Audio:NO];
    }
}

#pragma mark - 音频录制

// 开始录音
-(void)startRecordClick
{
    NSLog(@"点击了开始录音按钮");
    
    // 不同的文件格式，存放不同的编码数据
    // 这里存放以caf为后缀的文件
    // 基本上可以存放任何苹果支持的编码格式
    [[AudioTool shareAudioTool] beginRecordWithRecordName:@"xiejiapei" withRecordType:@"caf" withIsConventToMp3:YES];
    
}

// 暂停录音
-(void)suspendRecordClick
{
    NSLog(@"点击了暂停录音按钮");
    [[AudioTool shareAudioTool] pauseRecord];
}

// 结束录音
-(void)endRecordClick
{
    NSLog(@"点击了结束录音按钮");
    [[AudioTool shareAudioTool] endRecord];
}

// 删除录音
-(void)deleteRecordClick
{
    NSLog(@"点击了删除录音按钮");
    [[AudioTool shareAudioTool] deleteRecord];
}

// 播放录音
-(void)playRecordClick
{
    NSLog(@"点击了播放录音按钮");
    
    // 播放歌曲
    [[AudioPlayerTool shareAudioPlayerTool] playAudioWith:[cachesRecorderPath stringByAppendingPathComponent:@"xiejiapei.mp3"]];
    
    // 立体声平衡
    [AudioPlayerTool shareAudioPlayerTool].span = 0;
}

#pragma mark - 操作音频文件拼接、剪切、转化

// 音频的拼接：追加某个音频在某个音频的后面
-(void)joinRecordClick
{
    [AudioFileTool addAudio:[cachesRecorderPath stringByAppendingPathComponent:@"test2.caf"] toAudio:[cachesRecorderPath stringByAppendingPathComponent:@"test1.caf"] outputPath:[cachesRecorderPath stringByAppendingPathComponent:@"test3.caf"]];
}

// caf 转 mp3
-(void)pcmAudioToMP3Click
{
    // 第一个参数是原音频的路径，第二个参数是转换为 MP3 后是否删除原来音频
    [LameTool audioToMP3:[cachesRecorderPath stringByAppendingPathComponent:@"xiejiapei.caf"] isDeleteSourchFile:YES withSuccessBack:^(NSString * _Nonnull resultPath) {
        
        NSLog(@"转为MP3后的路径 = %@",resultPath);
    } withFailBack:^(NSString * _Nonnull error) {
        NSLog(@"转换失败：%@",error);
    }];
}

#pragma mark - Delegate

// TalkingRecordViewDelegate
- (void)recordView:(TalkingRecordView *)sender didFinishSavePath:(NSString *)path duration:(NSTimeInterval)duration convertToAudioType:(AudioType)audioType
{
    NSLog(@"文件完成后存储路径为：%@",path );
    NSLog(@"录音时长为：%f",duration);
    
    // 隐藏录音视图
    self.recordView.hidden = YES;
    // 展示播放按钮
    self.playPictureButton.hidden = NO;
    
    // 获取想要转化为的音频类型和音频存储路径
    self.audioPath = path;
    self.audioType = audioType;
    
    // 创建播放器的提示语并展示
    if (!self.tipLabel)
    {
        UILabel *tipLabel = [[UILabel alloc] initWithFrame:CGRectMake((self.view.frame.size.width - 350)/2,self.view.frame.size.height - 300, 350, 30)];
        tipLabel.textAlignment = NSTextAlignmentCenter;
        [self.view addSubview:tipLabel];
        self.tipLabel = tipLabel;
    }
    self.tipLabel.hidden = NO;
    
    
    if (audioType == AudioTypeMP3)
    {
        self.tipLabel.text = [NSString stringWithFormat:@"MP3音频录制成功，时长%ld秒，点击播放",(long)duration];
    }
    else
    {
        self.tipLabel.text = [NSString stringWithFormat:@"AMR音频录制成功，时长%ld秒，点击播放",(long)duration];
    }
}

// AudioPlayerDelegate
- (void)audioPlayerDidFinishPlaying:(AudioPlayerTool *)playerTool
{
    NSLog(@"播放完成的委托被调用了");
}

#pragma mark - 创建视图

- (void)createSubViews
{
    self.view.backgroundColor = [UIColor whiteColor];
    
    // 在这里决定转化为MP3或者AMR
    self.recordView = [[TalkingRecordView alloc] initWithFrame:CGRectMake((self.view.frame.size.width - 160) / 2, 200 , 160, 160) delegate:self convertToAudioType:AudioTypeMP3];
    [self.view addSubview:self.recordView];
    
    UIButton *holdTalkButton = [UIButton buttonWithType:UIButtonTypeCustom];
    holdTalkButton.backgroundColor = [UIColor lightGrayColor];
    holdTalkButton.layer.cornerRadius = 5;
    holdTalkButton.layer.masksToBounds = YES;
    [holdTalkButton setTitle:@"按住说话" forState:UIControlStateNormal];
    [holdTalkButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    holdTalkButton.titleLabel.font = [UIFont systemFontOfSize:14];
    [holdTalkButton addTarget:self action:@selector(holdTalkButtonTouchDown) forControlEvents:UIControlEventTouchDown];
    [holdTalkButton addTarget:self action:@selector(holdTalkButtonMoveIn) forControlEvents:UIControlEventTouchDragInside];
    [holdTalkButton addTarget:self action:@selector(holdTalkButtonMoveOut) forControlEvents:UIControlEventTouchDragOutside];
    [holdTalkButton addTarget:self action:@selector(holdTalkButtonTouchUpInside) forControlEvents:UIControlEventTouchUpInside];
    [holdTalkButton addTarget:self action:@selector(holdTalkButtonTouchUpOutside) forControlEvents:UIControlEventTouchUpOutside];
    holdTalkButton.frame = CGRectMake((self.view.frame.size.width - 200)/2,640, 200, 40);
    [self.view addSubview:holdTalkButton];
    
    UIButton * playPictureButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [playPictureButton setImage:[UIImage imageNamed:@"播放"] forState:0];
    [playPictureButton addTarget:self action:@selector(playTalk) forControlEvents:UIControlEventTouchUpInside];
    playPictureButton.frame = CGRectMake((self.view.frame.size.width - 60)/2,self.view.frame.size.height - 460, 60, 60);
    [self.view addSubview:playPictureButton];
    playPictureButton.hidden = YES;
    self.playPictureButton = playPictureButton;
    
    UIButton *startRecordButtton = [[UIButton alloc]initWithFrame:CGRectMake(20, 700, 100, 40)];
    startRecordButtton.layer.cornerRadius = 5;
    startRecordButtton.layer.masksToBounds = YES;
    startRecordButtton.backgroundColor = [UIColor lightGrayColor];
    [startRecordButtton setTitle:@"开始录音" forState:UIControlStateNormal];
    [startRecordButtton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    startRecordButtton.titleLabel.font = [UIFont systemFontOfSize:14.f];
    [startRecordButtton addTarget:self action:@selector(startRecordClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:startRecordButtton];
    
    UIButton *suspendRecordButtton = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetMaxX(startRecordButtton.frame)+20, 700, 100, 40)];
    suspendRecordButtton.layer.cornerRadius = 5;
    suspendRecordButtton.layer.masksToBounds = YES;
    suspendRecordButtton.backgroundColor = [UIColor lightGrayColor];
    [suspendRecordButtton setTitle:@"暂停录音" forState:UIControlStateNormal];
    [suspendRecordButtton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    suspendRecordButtton.titleLabel.font = [UIFont systemFontOfSize:14.f];
    [suspendRecordButtton addTarget:self action:@selector(suspendRecordClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:suspendRecordButtton];
    
    UIButton *endRecordButtton = [[UIButton alloc]initWithFrame:CGRectMake(CGRectGetMaxX(suspendRecordButtton.frame)+20, 700, 100, 40)];
    endRecordButtton.layer.cornerRadius = 5;
    endRecordButtton.layer.masksToBounds = YES;
    endRecordButtton.backgroundColor = [UIColor lightGrayColor];
    [endRecordButtton setTitle:@"结束录音" forState:UIControlStateNormal];
    [endRecordButtton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    endRecordButtton.titleLabel.font = [UIFont systemFontOfSize:14.f];
    [endRecordButtton addTarget:self action:@selector(endRecordClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:endRecordButtton];
    
    UIButton *deleteRecordButtton = [[UIButton alloc]initWithFrame:CGRectMake(20, CGRectGetMaxY(endRecordButtton.frame)+30, 100, 40)];
    deleteRecordButtton.layer.cornerRadius = 5;
    deleteRecordButtton.layer.masksToBounds = YES;
    deleteRecordButtton.backgroundColor = [UIColor lightGrayColor];
    [deleteRecordButtton setTitle:@"删除录音" forState:UIControlStateNormal];
    [deleteRecordButtton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    deleteRecordButtton.titleLabel.font = [UIFont systemFontOfSize:14.f];
    [deleteRecordButtton addTarget:self action:@selector(deleteRecordClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:deleteRecordButtton];
    
    UIButton *playRecordButtton = [[UIButton alloc]initWithFrame:CGRectMake(CGRectGetMaxX(deleteRecordButtton.frame)+20, CGRectGetMaxY(startRecordButtton.frame)+30, 100, 40)];
    playRecordButtton.layer.cornerRadius = 5;
    playRecordButtton.layer.masksToBounds = YES;
    playRecordButtton.backgroundColor = [UIColor lightGrayColor];
    [playRecordButtton setTitle:@"播放录音" forState:UIControlStateNormal];
    [playRecordButtton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    playRecordButtton.titleLabel.font = [UIFont systemFontOfSize:14.f];
    [playRecordButtton addTarget:self action:@selector(playRecordClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:playRecordButtton];
    
    UIButton *joinRecordButtton = [[UIButton alloc]initWithFrame:CGRectMake(CGRectGetMaxX(playRecordButtton.frame)+20, CGRectGetMaxY(startRecordButtton.frame)+30, 100, 40)];
    joinRecordButtton.layer.masksToBounds = YES;
    joinRecordButtton.backgroundColor = [UIColor lightGrayColor];
    [joinRecordButtton setTitle:@"拼接录音" forState:UIControlStateNormal];
    [joinRecordButtton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    joinRecordButtton.titleLabel.font = [UIFont systemFontOfSize:14.f];
    [joinRecordButtton addTarget:self action:@selector(joinRecordClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:joinRecordButtton];
    
    UIButton *convertRecordButtton = [[UIButton alloc]initWithFrame:CGRectMake(20, CGRectGetMaxY(joinRecordButtton.frame)+30, 100, 40)];
    convertRecordButtton.layer.masksToBounds = YES;
    convertRecordButtton.backgroundColor = [UIColor lightGrayColor];
    [convertRecordButtton setTitle:@"caf转mp3" forState:UIControlStateNormal];
    [convertRecordButtton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    convertRecordButtton.titleLabel.font = [UIFont systemFontOfSize:14.f];
    [convertRecordButtton addTarget:self action:@selector(pcmAudioToMP3Click) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:convertRecordButtton];
}

@end
