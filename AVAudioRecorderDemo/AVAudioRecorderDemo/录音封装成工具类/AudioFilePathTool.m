//
//  AudioFilePathTool.m
//  AVAudioRecorderDemo
//
//  Created by 谢佳培 on 2020/8/28.
//  Copyright © 2020 xiejiapei. All rights reserved.
//

#import "AudioFilePathTool.h"

@implementation AudioFilePathTool

// 判断文件或文件夹是否存在
+ (BOOL)judgeFileOrFolderExists:(NSString *)filePathName
{
    // 长度等于0，直接返回不存在
    if (filePathName.length == 0)
    {
        return NO;
    }
    
    BOOL isDir = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *filePath = [NSString stringWithFormat:@"%@",filePathName];
    // fileExistsAtPath 判断一个文件或目录是否有效，isDirectory判断是否一个目录
    BOOL existed = [fileManager fileExistsAtPath:filePath isDirectory:&isDir];
    
    if ( !(isDir == YES && existed == YES) )
    {
        // 不存在
        return NO;
    }
    else
    {
        return YES;
    }
    return nil;
}

+ (BOOL)judgeFileExists:(NSString *)filePath
{
    // 长度等于0，直接返回不存在
    if (filePath.length == 0)
    {
        return NO;
    }
    
    BOOL isDir = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *path = [NSString stringWithFormat:@"%@",filePath];
    // fileExistsAtPath 判断一个文件或目录是否有效，isDirectory判断是否一个目录
    BOOL existed = [fileManager fileExistsAtPath:path isDirectory:&isDir];
    
    if (existed == YES)
    {
        return YES;
    }
    else
    {
        // 不存在
        return NO;
    }
    return nil;
}

// 创建文件夹目录
+(NSString *)createFolder:(NSString *)folderName
{
    NSString *filePath = [NSString stringWithFormat:@"%@",folderName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    // fileExistsAtPath 判断一个文件或目录是否有效，isDirectory判断是否一个目录
    BOOL existed = [fileManager fileExistsAtPath:filePath isDirectory:&isDir];
    
    if ( !(isDir == YES && existed == YES) )
    {
        // 不存在的路径才会创建
        [fileManager createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return filePath;
}

@end
