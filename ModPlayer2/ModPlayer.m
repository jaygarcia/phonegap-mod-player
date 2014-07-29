//
//  ModPlayer.m
//  ModPlayer2
//
//  Created by Jesus Garcia on 7/23/14.
//  Copyright (c) 2014 Modus Create. All rights reserved.
//


#include "ModPlayer.h"




@implementation ModPlayer {
//    ModPlugFile *mpFile;
	int *genRow,*genPattern, *playRow,*playPattern;
    unsigned char *genVolData, *playVolData;
	char *mp_data;
	int numPatterns, numSamples, numInstr;
    
    ModPlug_Settings settings;
    
    AudioQueueRef mAudioQueue;
    AudioQueueBufferRef *mBuffers;
    PlayState *playState;
}



- (ModPlugFile *) getMpFile {
    return self.mpFile;
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
    NSURL *fileUrl = [files objectAtIndex:1];
    NSString *firstFile = [[fileUrl filePathURL] absoluteString];

    firstFile = [[firstFile componentsSeparatedByString:@"%20"] componentsJoinedByString: @" "];
    firstFile = [[firstFile componentsSeparatedByString:@"file://"] componentsJoinedByString: @""];
    
    
    [self playFile:firstFile];


//    NSLog(@"Here");
}

- (void) playFile:(NSString *) filePath {
    
    NSLog(@"Loaded file %@", filePath);

    ModPlug_GetSettings(&settings);

    settings.mFlags=MODPLUG_ENABLE_OVERSAMPLING;
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
    self.mpFile = mpFile;
    
    ModPlug_SetMasterVolume(mpFile, 128);
    ModPlug_Seek(mpFile, 0);
    
    const char *modName = ModPlug_GetName(mpFile);

    int len = ModPlug_GetLength(mpFile);

    NSLog(@"Length: %i", len);
    NSLog(@"ModName: %s", modName);
 
     
    [self initSound];

//    [NSThread detachNewThreadSelector:@selector(myMainThreadMethod) toTarget:self withObject:nil];
}

- (void) myMainThreadMethod {
    NSLog(@"Thread kicked off");
    
    while (1) {
        [NSThread sleepForTimeInterval:0.1];
    
        NSLog(@"Teh Thread is werking");
        NSLog(@"ModName: %s", ModPlug_GetName(self.mpFile));

    }

}



- (void) initSound {
    ModPlugFile *mpFile = self.mpFile;

    AudioStreamBasicDescription mDataFormat;
    UInt32 err;
    float mVolume = 1.0f;
    
//    PlayState *playState2 = playState;
//    playState2->currentPacket = 0;
//
//    
    /* We force this format for iPhone */
    mDataFormat.mFormatID = kAudioFormatLinearPCM;
    mDataFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
	mDataFormat.mSampleRate = PLAYBACK_FREQ;
	mDataFormat.mBitsPerChannel = 16;
	mDataFormat.mChannelsPerFrame = 2;
    mDataFormat.mBytesPerFrame = (mDataFormat.mBitsPerChannel>>3) * mDataFormat.mChannelsPerFrame;
    mDataFormat.mFramesPerPacket = 1;
    mDataFormat.mBytesPerPacket = mDataFormat.mBytesPerFrame;



    err = AudioQueueNewOutput(&mDataFormat,
                         audioCallback,
                         CFBridgingRetain(self),
                         CFRunLoopGetCurrent(),
                         kCFRunLoopCommonModes,
                         0,
                         &mAudioQueue);

    /* Create associated buffers */
    mBuffers = (AudioQueueBufferRef*) malloc( sizeof(AudioQueueBufferRef) * SOUND_BUFFER_NB );
    
    for (int i = 0; i < SOUND_BUFFER_NB; i++) {
		AudioQueueBufferRef mBuffer;
		err = AudioQueueAllocateBuffer(mAudioQueue, SOUND_BUFFER_SIZE_SAMPLE * 2 * 2, &mBuffer );
		
		mBuffers[i] = mBuffer;
        NSLog(@"Created Buffer #%i", i);
        mBuffer->mAudioDataByteSize = SOUND_BUFFER_SIZE_SAMPLE * 2 * 2;
        
        
        ModPlug_Read(mpFile, (char*)mBuffer->mAudioData, SOUND_BUFFER_SIZE_SAMPLE * 2 * 2);

        AudioQueueEnqueueBuffer(mAudioQueue, mBuffers[i], 0, NULL);
    }
    
    
    /* Set initial playback volume */
    err = AudioQueueSetParameter(mAudioQueue, kAudioQueueParam_Volume, mVolume );
    err = AudioQueueStart(mAudioQueue, NULL );
    
}


void audioCallback(void *data, AudioQueueRef mQueue, AudioQueueBufferRef mBuffer) {
    ModPlayer *modPlayer = (__bridge ModPlayer*)data;
    ModPlugFile *mpFile = modPlayer.mpFile;
    
    NSLog(@"audioCallback");
    
    mBuffer->mAudioDataByteSize = SOUND_BUFFER_SIZE_SAMPLE*2*2;
    ModPlug_Read(mpFile, (char*)mBuffer->mAudioData, SOUND_BUFFER_SIZE_SAMPLE * 2 * 2);
    AudioQueueEnqueueBuffer(mQueue, mBuffer, 0, NULL);

    NSLog(@"Just read");
}


- (NSMutableArray *) getModFileDirectories: (NSString *)modPath {
    NSMutableArray *paths = [[NSMutableArray alloc] init];
    
    NSString *appUrl      = [[NSBundle mainBundle] bundlePath];
    NSString *modsUrl     = [appUrl stringByAppendingString:@"/mods"];
    
    NSURL *directoryUrl   = [[NSURL alloc] initFileURLWithPath:modsUrl];
    
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
//            NSLog(@"%@", [url lastPathComponent]);

            [files addObject:url];
        }
    }
    
    return files;
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
