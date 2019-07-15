//
//  AppDelegate.m
//  LLReplaceName
//
//  Created by Apple on 2019/6/17.
//  Copyright © 2019 kvnll. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;

@property (nonatomic, strong) NSMutableArray *classFilePaths;
@property (nonatomic, strong) NSMutableDictionary *classMaps;

@end

@implementation AppDelegate

#define kClass_Prefix @"WW_"
#define kClass_Suffix @"_ZZ"

- (NSMutableArray *)classFilePaths{
    if (!_classFilePaths) {
        _classFilePaths = [NSMutableArray array];
    }
    return _classFilePaths;
}

- (NSMutableDictionary *)classMaps{
    if (!_classMaps) {
        _classMaps = [NSMutableDictionary new];
    }
    return _classMaps;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    
    panel.title = @"选择工程";
    [panel setMessage:@"选择待操作的工程"];
    [panel setExtensionHidden:NO];
    [panel setCanChooseDirectories:YES];
    [panel setCanChooseFiles:NO];
    
    __weak typeof(self) weakSelf = self;
    
    [panel beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse result) {
        NSString *path = [[panel URL] path];
        
        NSError *error = nil;
        NSArray <NSString *>*fileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&error];
        
        [weakSelf preHandlerMethodWithDir:path fileNames:fileNames];
        NSLog(@"%@",self.classMaps);
    }];
}

- (void)preHandlerMethodWithDir:(NSString *)dirPath fileNames:(NSArray <NSString *>*)fileNames{
    NSString *filePath = nil;
    BOOL isDir = NO;
    NSError *error = nil;
    NSString *content = nil;
    NSString *className = nil;
    
    for (NSString *fileName in fileNames) {
        filePath = [dirPath stringByAppendingPathComponent:fileName];
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDir]) {
            if (isDir) {
                //文件夹
                NSArray <NSString *>*subDirContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:filePath error:&error];
                if (error) {
                    continue;
                }
                [self preHandlerMethodWithDir:filePath fileNames:subDirContent];
            } else {
                //文件
                if (![self isClassFileWithFileName:fileName]) {
                    //不是类文件,跳过
                    continue;
                }
                [self.classFilePaths addObject:fileName];
                content = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
                if (error || !content) {
                    continue;
                }
                //预处理文件
                [self classInfoPreHandler:[self classInfoWithFileContent:content]];
            }
        }
    }
//    [NSString stringWithFormat:@"%@%@%@",kClass_Prefix,className,kClass_Suffix]
}

- (void)classInfoPreHandler:(NSDictionary <NSString *,NSDictionary *>*)classNames{
    [self.classMaps addEntriesFromDictionary:classNames];
}

#pragma mark - RegularExpression

- (BOOL)isClassFileWithFileName:(NSString *)fileName
{
    NSString *classFileRegex = @".*\\.(h|m|mm|swift)$";
    NSPredicate *classFilePre = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", classFileRegex];
    if ([fileName hasSuffix:@"WWMyViewController.m"]) {
        NSLog(@"%@",fileName);
    }
    return [classFilePre evaluateWithObject:fileName];
}

- (NSDictionary <NSString *,NSDictionary *>*)classInfoWithFileContent:(NSString *)fileContent{
    NSMutableDictionary *classInfos = [NSMutableDictionary dictionary];
    NSMutableDictionary *classInfo = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(?<=@implementation).*" options:0 error:nil];
    NSArray *matches = [regex matchesInString:fileContent options:0 range:NSMakeRange(0,fileContent.length)];
    NSString *className = nil;
    for(NSTextCheckingResult *result in [matches objectEnumerator]) {
        className = [fileContent substringWithRange:[result range]];
        className = [className stringByReplacingOccurrencesOfString:@" " withString:@""];
        
        classInfo = [NSMutableDictionary dictionary];
        NSString *classImpContent = [self classImpContentWithFileContent:fileContent className:className];
        if (classImpContent) {
            [classInfo addEntriesFromDictionary:[self methodWithFileContent:classImpContent]];
        }
        [classInfos setObject:classInfo forKey:className];
    }
    return classInfos;
}

- (NSString *)classImpContentWithFileContent:(NSString *)fileContent className:(NSString *)className{
    NSString *classFileRegex = [NSString stringWithFormat:@"(?<=@implementation)[\\s\\S]*%@[\\s\\S]*(?=@end)",className];
    NSRange range = [fileContent rangeOfString:classFileRegex options:NSRegularExpressionSearch];
    if (range.location != NSNotFound) {
        return [fileContent substringWithRange:range];
    }
    return nil;
}

- (NSDictionary *)methodWithFileContent:(NSString *)fileContent{
    NSMutableDictionary *methods = [NSMutableDictionary dictionary];
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[-+]\\s*?\\([\\w ]+\\)[\\s\\S]*?(?=\\{)" options:0 error:&error];
    NSArray *matches = [regex matchesInString:fileContent options:0 range:NSMakeRange(0,fileContent.length)];
    NSString *method = nil;
    for(NSTextCheckingResult *result in [matches objectEnumerator]) {
        method = [fileContent substringWithRange:[result range]];
        [methods setObject:@"" forKey:method];
        NSLog(@"%@",method);
    }
    return methods;
}

- (void)contentOfDirAtPathWithExtensions:(NSArray *)extension callback:(void(^)(NSString *))callback{
    
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end

