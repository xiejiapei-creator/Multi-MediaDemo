//
//  ToolKitViewController.m
//  AVAudioRecorderDemo
//
//  Created by 谢佳培 on 2020/8/28.
//  Copyright © 2020 xiejiapei. All rights reserved.
//

#import "ToolKitViewController.h"
#import "RecorderKit.h"

@interface ToolKitViewController ()

@end

@implementation ToolKitViewController

#pragma mark - Life Circle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self createSubViews];
}

- (void)createSubViews
{
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton *buttton1 = [[UIButton alloc]initWithFrame:CGRectMake(20, 100, 100, 40)];
    [buttton1 setTitle:@"开始录音" forState:UIControlStateNormal];
    [buttton1 setTitleColor:[UIColor brownColor] forState:UIControlStateNormal];
    [buttton1 setBackgroundColor:[UIColor yellowColor]];
    [buttton1 addTarget:self action:@selector(beginRecordClick) forControlEvents:UIControlEventTouchUpInside];
    buttton1.titleLabel.font = [UIFont systemFontOfSize:18.f];
    [self.view addSubview:buttton1];
    
    UIButton *buttton12 = [[UIButton alloc]initWithFrame:CGRectMake(CGRectGetMaxX(buttton1.frame)+20, 100, 100, 40)];
    [buttton12 setTitle:@"暂停录音" forState:UIControlStateNormal];
    [buttton12 setTitleColor:[UIColor brownColor] forState:UIControlStateNormal];
    [buttton12 setBackgroundColor:[UIColor yellowColor]];
    [buttton12 addTarget:self action:@selector(pauseRecordClick) forControlEvents:UIControlEventTouchUpInside];
    buttton12.titleLabel.font = [UIFont systemFontOfSize:18.f];
    [self.view addSubview:buttton12];
    
    UIButton *buttton2 = [[UIButton alloc]initWithFrame:CGRectMake(20, CGRectGetMaxY(buttton1.frame)+30, 100, 40)];
    [buttton2 setTitle:@"结束录音" forState:UIControlStateNormal];
    [buttton2 setTitleColor:[UIColor brownColor] forState:UIControlStateNormal];
    [buttton2 setBackgroundColor:[UIColor yellowColor]];
    [buttton2 addTarget:self action:@selector(endRecordClick) forControlEvents:UIControlEventTouchUpInside];
    buttton2.titleLabel.font = [UIFont systemFontOfSize:18.f];
    [self.view addSubview:buttton2];
    
    UIButton *buttton3 = [[UIButton alloc]initWithFrame:CGRectMake(20, CGRectGetMaxY(buttton2.frame)+30, 100, 40)];
    [buttton3 setTitle:@"删除录音" forState:UIControlStateNormal];
    [buttton3 setTitleColor:[UIColor brownColor] forState:UIControlStateNormal];
    [buttton3 setBackgroundColor:[UIColor yellowColor]];
    [buttton3 addTarget:self action:@selector(deleteRecordClick) forControlEvents:UIControlEventTouchUpInside];
    buttton3.titleLabel.font = [UIFont systemFontOfSize:18.f];
    [self.view addSubview:buttton3];
    
    UIButton *buttton4 = [[UIButton alloc]initWithFrame:CGRectMake(20, CGRectGetMaxY(buttton3.frame)+30, 100, 40)];
    [buttton4 setTitle:@"播放录音" forState:UIControlStateNormal];
    [buttton4 setTitleColor:[UIColor brownColor] forState:UIControlStateNormal];
    [buttton4 setBackgroundColor:[UIColor yellowColor]];
    [buttton4 addTarget:self action:@selector(playRecordClick) forControlEvents:UIControlEventTouchUpInside];
    buttton4.titleLabel.font = [UIFont systemFontOfSize:18.f];
    [self.view addSubview:buttton4];
    
    UIButton *buttton5 = [[UIButton alloc]initWithFrame:CGRectMake(20, CGRectGetMaxY(buttton4.frame)+30, 100, 40)];
    [buttton5 setTitle:@"拼接录音" forState:UIControlStateNormal];
    [buttton5 setTitleColor:[UIColor brownColor] forState:UIControlStateNormal];
    [buttton5 setBackgroundColor:[UIColor yellowColor]];
    [buttton5 addTarget:self action:@selector(editRecordClick) forControlEvents:UIControlEventTouchUpInside];
    buttton4.titleLabel.font = [UIFont systemFontOfSize:18.f];
    [self.view addSubview:buttton5];
    
    UIButton *buttton6 = [[UIButton alloc]initWithFrame:CGRectMake(20, CGRectGetMaxY(buttton5.frame)+30, 110, 40)];
    [buttton6 setTitle:@"caf转mp3" forState:UIControlStateNormal];
    [buttton6 setTitleColor:[UIColor brownColor] forState:UIControlStateNormal];
    [buttton6 setBackgroundColor:[UIColor yellowColor]];
    [buttton6 addTarget:self action:@selector(pcmAudioToMP3Click) forControlEvents:UIControlEventTouchUpInside];
    buttton6.titleLabel.font = [UIFont systemFontOfSize:18.f];
    [self.view addSubview:buttton6];
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    NSLog(@"Home目录 = %@",NSHomeDirectory());
    
    NSString *name = @"hha.af";
    
    if ([name containsString:@".caf"]) {
        NSLog(@"包含 .caf");
    }else{
        NSLog(@"不包含 .caf");
    }
}

#pragma mark - 音频录制

// 开始录音
-(void)beginRecordClick
{
    NSLog(@"开始录音");
    
    // 不同的文件格式，存放不同的编码数据
    // 这里存放以caf为后缀的文件
    // 基本上可以存放任何苹果支持的编码格式
    [[AudioTool shareAudioTool] beginRecordWithRecordName:@"test6" withRecordType:@"caf" withIsConventToMp3:YES];
    
}

// 暂停录音
-(void)pauseRecordClick
{
    NSLog(@"暂停录音");
    [[AudioTool shareAudioTool] pauseRecord];
}

// 结束录音
-(void)endRecordClick
{
    [[AudioTool shareAudioTool] endRecord];
}

// 删除录音
-(void)deleteRecordClick
{
    [[AudioTool shareAudioTool] deleteRecord];
}

// 播放录音
-(void)playRecordClick
{
    // 播放歌曲
    [[AudioPlayerTool shareAudioPlayerTool] playAudioWith:[cachesRecorderPath stringByAppendingPathComponent:@"test6.mp3"]];
    
    // 立体声平衡
    [AudioPlayerTool shareAudioPlayerTool].span = 0;
}

#pragma mark - 操作音频文件拼接、剪切、转化

// 音频的拼接：追加某个音频在某个音频的后面
-(void)editRecordClick
{
    [AudioFileTool addAudio:[cachesRecorderPath stringByAppendingPathComponent:@"test2.caf"] toAudio:[cachesRecorderPath stringByAppendingPathComponent:@"test1.caf"] outputPath:[cachesRecorderPath stringByAppendingPathComponent:@"test3.caf"]];
}

// caf 转 mp3
-(void)pcmAudioToMP3Click
{
    // 第一个参数是原音频的路径，第二个参数是转换为 MP3 后是否删除原来音频
    [LameTool audioToMP3:[cachesRecorderPath stringByAppendingPathComponent:@"test2.caf"] isDeleteSourchFile:YES withSuccessBack:^(NSString * _Nonnull resultPath) {
        
        NSLog(@"转为MP3后的路径 = %@",resultPath);
    } withFailBack:^(NSString * _Nonnull error) {
        NSLog(@"转换失败：%@",error);
    }];
}



@end
