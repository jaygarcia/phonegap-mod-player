//
//  ModPlayer.m
//  ModPlayer2
//
//  Created by Jesus Garcia on 7/23/14.
//  Copyright (c) 2014 Modus Create. All rights reserved.
//

#import "ModPlayer.h"

@implementation ModPlayer {
    ModPlugFile *mp_file;
	int *genRow,*genPattern, *playRow,*playPattern;
    unsigned char *genVolData, *playVolData;
	char *mp_data;
	int numPatterns, numSamples, numInstr;
}


- (void) playSong {
    UIAlertView *alert = [
        [UIAlertView alloc]
        initWithTitle:@"Title"
        message:@"App loaded"
        delegate:nil
        cancelButtonTitle:@"ok"
        otherButtonTitles:nil,
    nil];
    
    
    [alert show];
    

    
    NSMutableArray *dirs = [self getModFileDirectories:@""];
    
    NSString *firstDir = [dirs objectAtIndex:0];
    
    NSMutableArray *files = [self getFilesInDirectory:firstDir];
    NSString *firstFile = [files objectAtIndex:0];
    
    
    
    
    NSLog(@"Here");
   
}




- (NSMutableArray *) getModFileDirectories: (NSString *)modPath {
    NSMutableArray *paths = [[NSMutableArray alloc] init];
    
    NSString *appUrl    = [[NSBundle mainBundle] bundlePath];
    NSString *modsUrl   = [appUrl stringByAppendingString:@"/mods"];
    
    NSURL *directoryUrl = [[NSURL alloc] initFileURLWithPath:modsUrl] ;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSArray *keys = [NSArray arrayWithObject:NSURLIsDirectoryKey];
    
    NSArray *directories = [fileManager
                 contentsOfDirectoryAtURL: directoryUrl
                 includingPropertiesForKeys : keys
                 options : 0
                 error:nil];
    

    NSString *s = @"A567B$%C^.123456abcdefg";
    NSCharacterSet *doNotWant1 = [[NSCharacterSet characterSetWithCharactersInString:@"ABCabc123"] invertedSet];
    s = [[s componentsSeparatedByCharactersInSet: doNotWant1] componentsJoinedByString: @""];
    NSLog(@"%@", s); // => ABC123abc

    
    
    NSString *appUrlFull = [NSString stringWithFormat:@"file://%@", appUrl];
    appUrlFull = [[appUrlFull componentsSeparatedByString:@"%20"] componentsJoinedByString: @" "];
    
    NSString *shortenedUrlPath;
    
    for (NSURL *url in directories) {
        shortenedUrlPath = [url absoluteString];
        shortenedUrlPath = [[shortenedUrlPath componentsSeparatedByString:@"%20"] componentsJoinedByString: @" "];
        shortenedUrlPath = [[shortenedUrlPath componentsSeparatedByString:@"/mods/"] componentsJoinedByString: @""];
        shortenedUrlPath = [[shortenedUrlPath componentsSeparatedByString:appUrlFull] componentsJoinedByString: @""];
    
        [paths addObject:shortenedUrlPath];
    }
    
    return paths;
}


- (NSMutableArray *) getFilesInDirectory: (NSString*)path {
    NSMutableArray *files = [[NSMutableArray alloc] init];
    
    
//    Todo: This is for the Touch 2 app. Be sure to re-enable this.
    NSString *appUrl    = [[NSBundle mainBundle] bundlePath];
    NSString *modsUrl   = [appUrl stringByAppendingString:@"/mods/"];
    NSString *targetPath = [modsUrl stringByAppendingString: path];
    
    
    NSURL *directoryUrl = [[NSURL alloc] initFileURLWithPath:targetPath];
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    
    NSArray *keys = [NSArray arrayWithObject:NSURLIsDirectoryKey];
    
    NSDirectoryEnumerator *enumerator = [fileManager
                                         enumeratorAtURL : directoryUrl
                                         includingPropertiesForKeys : keys
                                         options : 0
                                         errorHandler : ^(NSURL *url, NSError *error) {
                                             //Handle the error.
                                             // Return YES if the enumeration should continue after the error.
                                             NSLog(@"Error :: %@", error);
                                             return YES;
                                         }];
    
    for (NSURL *url in enumerator) {
        NSError *error;
        NSNumber *isDirectory = nil;
        if (! [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error]) {
            //handle error
        }
        else if (! [isDirectory boolValue]) {
            NSLog(@"%@", [url lastPathComponent]);

            [files addObject:url];
        }
    }
    
    return files;
}


- (NSString *) getModDirectoriesAsJson {

    NSString *appUrl    = [[NSBundle mainBundle] bundlePath];
    NSString *modsUrl   = [appUrl stringByAppendingString:@"/mods"];
    
    NSURL *directoryUrl = [[NSURL alloc] initFileURLWithPath:modsUrl] ;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *keys = [NSArray arrayWithObject:NSURLIsDirectoryKey];
    
    NSArray *directories = [fileManager
                             contentsOfDirectoryAtURL: directoryUrl
                             includingPropertiesForKeys : keys
                             options : 0
                             error:nil
                            ];

    NSMutableArray *pathDictionaries = [[NSMutableArray alloc] init];
    
    for (NSURL *url in directories) {
         NSDictionary *jsonObj = [[NSDictionary alloc]
                                    initWithObjectsAndKeys:
                                        [url lastPathComponent], @"dirName",
                                        [url path], @"path",
                                        nil
                                    ];
        
        
        [pathDictionaries addObject:jsonObj];
    }
    
    NSError *jsonError;
    NSData *jsonData = [NSJSONSerialization
                        dataWithJSONObject:pathDictionaries
                        options:NSJSONWritingPrettyPrinted
                        error:&jsonError
                       ];
    
    NSString *jsonDataString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

    return jsonDataString;
}



- (NSString *) getModFilesAsJson: (NSString*)path {
    
    NSURL *directoryUrl = [[NSURL alloc] initFileURLWithPath:path];
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    
    NSArray *keys = [NSArray arrayWithObject:NSURLIsDirectoryKey];
    
    NSDirectoryEnumerator *enumerator = [fileManager
                                         enumeratorAtURL : directoryUrl
                                         includingPropertiesForKeys : keys
                                         options : 0
                                         errorHandler : ^(NSURL *url, NSError *error) {
                                             //Handle the error.
                                             // Return YES if the enumeration should continue after the error.
                                             NSLog(@"Error :: %@", error);
                                             return YES;
                                         }];
    
    NSMutableArray *pathDictionaries = [[NSMutableArray alloc] init];

    for (NSURL *url in enumerator) {
        NSError *error;
        NSNumber *isDirectory = nil;
        if (! [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error]) {
            //handle error
        }
        else if (! [isDirectory boolValue]) {
            NSDictionary *jsonObj = [[NSDictionary alloc]
                initWithObjectsAndKeys:
                    [url lastPathComponent], @"fileName",
                    [url path], @"path",
                    nil
                ];
            [pathDictionaries addObject:jsonObj];

        }
    }
    
    NSError *jsonError;
    NSData *jsonData = [NSJSONSerialization
                        dataWithJSONObject:pathDictionaries
                        options:NSJSONWritingPrettyPrinted
                        error:&jsonError
                    ];
    
    NSString *jsonDataString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

    return jsonDataString;
}


#pragma mark - CORDOVA
//
//
//- (void) cordovaGetModPaths:(CDVInvokedUrlCommand*)command {
//    
//    NSString* modPaths = [self getModDirectoriesAsJson];
//    
//    CDVPluginResult *pluginResult = [CDVPluginResult
//                                    resultWithStatus:CDVCommandStatus_OK
//                                    messageAsString:modPaths
//                                ];
//    
//    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];    
//}
//
//- (void) cordovaGetModFiles:(CDVInvokedUrlCommand*)command {
//    
//    NSString* path = [command.arguments objectAtIndex:0];
//
//    NSString* modPaths = [self getModFilesAsJson:path];
//    
//    CDVPluginResult *pluginResult = [CDVPluginResult
//                                    resultWithStatus:CDVCommandStatus_OK
//                                    messageAsString:modPaths
//                                ];
//    
//    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];    
//}

@end
