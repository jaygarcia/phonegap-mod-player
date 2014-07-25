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
    
    ModPlug_Settings settings;

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
    
    NSString *firstDir = [dirs objectAtIndex:1];
    
    NSMutableArray *files = [self getFilesInDirectory:firstDir];
    NSURL *fileUrl = [files objectAtIndex:3];
    NSString *firstFile = [[fileUrl filePathURL] absoluteString];

    firstFile = [[firstFile componentsSeparatedByString:@"%20"] componentsJoinedByString: @" "];
    firstFile = [[firstFile componentsSeparatedByString:@"file://"] componentsJoinedByString: @""];
    
    
    [self playFile:firstFile];


//    NSLog(@"Here");
}

- (void) playFile:(NSString *) filePath {
    ModPlug_GetSettings(&settings);


//    settings.mFlags=MODPLUG_ENABLE_OVERSAMPLING;
    
//    	int mFlags;  /* One or more of the MODPLUG_ENABLE_* flags above, bitwise-OR'ed */
	
	/* Note that ModPlug always decodes sound at 44100kHz, 32 bit, stereo and then
	 * down-mixes to the settings you choose. */
//	int mChannels;       /* Number of channels - 1 for mono or 2 for stereo */
//	int mBits;           /* Bits per sample - 8, 16, or 32 */
//	int mFrequency;      /* Sampling rate - 11025, 22050, or 44100 */
//	int mResamplingMode; /* One of MODPLUG_RESAMPLE_*, above */
//
//	int mStereoSeparation; /* Stereo separation, 1 - 256 */
//	int mMaxMixChannels; /* Maximum number of mixing channels (polyphony), 32 - 256 */
//	
//	int mReverbDepth;    /* Reverb level 0(quiet)-100(loud)      */
//	int mReverbDelay;    /* Reverb delay in ms, usually 40-200ms */
//	int mBassAmount;     /* XBass level 0(quiet)-100(loud)       */
//	int mBassRange;      /* XBass cutoff in Hz 10-100            */
//	int mSurroundDepth;  /* Surround level 0(quiet)-100(heavy)   */
//	int mSurroundDelay;  /* Surround delay in ms, usually 5-40ms */
//	int mLoopCount;      /* Number of times to loop.  Zero prevents looping.
//	                        -1 loops forever. */
//    
    
    settings.mChannels=2;
    settings.mBits=16;
    settings.mFrequency=44100;
    settings.mResamplingMode=MODPLUG_RESAMPLE_NEAREST;
    settings.mReverbDepth=0;
    settings.mReverbDelay=100;
    settings.mBassAmount=0;
    settings.mBassRange=50;
    settings.mSurroundDepth=0;
    settings.mSurroundDelay=10;
    settings.mLoopCount=-1;
    settings.mStereoSeparation=32;
    
    ModPlug_SetSettings(&settings);
    
    FILE *file;
    char *fileData;
    int fileSize;

    const char* fil = [filePath cStringUsingEncoding:NSASCIIStringEncoding];
    
    file = fopen(fil, "rb");
    
    if (file == NULL) {
      return;
    }
    
    fseek(file, 0L, SEEK_END);
    (fileSize) = ftell(file);
    rewind(file);
    fileData = (char*) malloc(fileSize);
    
    fread(fileData, fileSize, sizeof(char), file);
    fclose(file);

    ModPlugFile *mpFile;
    
    mpFile = ModPlug_Load(fileData, fileSize);
    ModPlug_SetMasterVolume(mpFile, 128);
    ModPlug_Seek(mpFile, 0);
    
    
    const char *modName = ModPlug_GetName(mpFile);

    /* Get the length of the mod, in milliseconds.  Note that this result is not always
     * accurate, especially in the case of mods with loops. */
    int len = ModPlug_GetLength(mpFile);

    NSLog(@"Loaded file %@", filePath);
    NSLog(@"Length: %i", len);
    NSLog(@"ModName: %s", modName);

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
    
    
    NSString *appUrlFull = [NSString stringWithFormat:@"file://%@", appUrl];
    appUrlFull = [[appUrlFull componentsSeparatedByString:@"%20"] componentsJoinedByString: @" "];
    
    NSString *shortenedUrlPath;
    
    for (NSURL *url in directories) {
        shortenedUrlPath = (NSString *)[url absoluteString];
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
