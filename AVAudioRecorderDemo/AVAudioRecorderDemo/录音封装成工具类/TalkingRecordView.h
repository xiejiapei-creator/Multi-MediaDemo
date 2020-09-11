//
//  TalkingRecordView.h
//  AVAudioRecorderDemo
//
//  Created by 谢佳培 on 2020/9/11.
//  Copyright © 2020 xiejiapei. All rights reserved.
//

#import <UIKit/UIKit.h>

// 录音状态
typedef enum TalkState
{
    TalkStateNone = 0,
    TalkStateTalking = 1,
    TalkStateCanceling = 2
} TalkState;

// 想要转化为的音频文件类型
typedef enum AudioType
{
    AudioTypeMP3 = 0,
    AudioTypeAMR = 1,
} AudioType;

@class TalkingRecordView;

@protocol TalkingRecordViewDelegate <NSObject>

// 录音完成时调用的方法
@optional
- (void)recordView:(TalkingRecordView*)sender didFinishSavePath:(NSString*)path duration:(NSTimeInterval)duration convertToAudioType:(AudioType)audioType;

@end

@interface TalkingRecordView : UIView

/** 委托 */
@property (nonatomic, weak) id <TalkingRecordViewDelegate> delegate;
/** 录音状态 */
@property (nonatomic, assign) int talkState;
/** 录音文件存储路径 */
@property (nonatomic, strong) NSString * audioFileSavePath;

/** 初始化 */
- (id)initWithFrame:(CGRect)frame delegate:(id)delegate convertToAudioType:(AudioType)audioType;
/** 取消录音 */
- (void)cancelRecord;
/** 结束录音 */
- (void)endRecord;

@end
 
