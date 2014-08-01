//
//  ModPlayer.m
//  ModPlayer2
//
//  Created by Jesus Garcia on 7/23/14.
//  Copyright (c) 2014 Modus Create. All rights reserved.
//


#include "ModPlayer.h"
#include "time.h"

@implementation ModPlayer {

    unsigned char *genVolData,
                  *playVolData;
	
    char *mp_data,
    *modMessage;
	
    int numPatterns,
        numSamples,
        numInstr,
        numChannels;
    
    int lastPattern; // Used for determining if we already looked at this pattern. TODO: Delete
    
    ModPlugFile *loadedModPlugFile;
    ModPlug_Settings settings;
    
    AudioQueueRef mAudioQueue;
    AudioQueueBufferRef *mBuffers;
    
    char *loadedFileData;
    int loadedFileSize;
    char *modName;
    

    // An Object to produce the JSON below.
    NSObject *songPatterns;
    /*
    {
        patternX : [
            "Pattern 1",
            "Pattern 2"
            "Pattern 3"
        ]
    
    }
    
    */


}

static char note2charA[12]={'C','C','D','D','E','F','F','G','G','A','A','B'};
static char note2charB[12]={'-','#','-','#','-','-','#','-','#','-','#','-'};
static char dec2hex[16]={'0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'};

- (ModPlugFile *) getMpFile {
    return self.mpFile;
}


- (void) playSong {
//    UIAlertView *alert = [
//        [UIAlertView alloc]
//        initWithTitle:@"Title"
//        message:@"App loaded"
//        delegate:nil
//        cancelButtonTitle:@"ok"
//        otherButtonTitles:nil,
//    nil];
//    
//    [alert show];
    
    
    NSMutableArray *dirs = [self getModFileDirectories:@""];
    
    NSString *firstDir = [dirs objectAtIndex:2];
    
    NSMutableArray *files = [self getFilesInDirectory: firstDir];
    NSURL *fileUrl = [files objectAtIndex:0];
    NSString *firstFile = [[fileUrl filePathURL] absoluteString];

    firstFile = [[firstFile componentsSeparatedByString:@"%20"] componentsJoinedByString: @" "];
    firstFile = [[firstFile componentsSeparatedByString:@"file://"] componentsJoinedByString: @""];
    
    [self loadFile:firstFile];
    [self preLoadPatterns];
    [self playFile:firstFile];

}
- (void) loadFile:(NSString *)filePath  {
    FILE *file;
    int fileSize;

    const char* fil = [filePath cStringUsingEncoding:NSASCIIStringEncoding];
    
    file = fopen(fil, "rb");
    
    if (file == NULL) {
      return;
    }
    
    fseek(file, 0L, SEEK_END);
    (loadedFileSize) = ftell(file);
    rewind(file);
    loadedFileData = (char*) malloc(loadedFileSize);
    
    fread(loadedFileData, fileSize, sizeof(char), file);
    fclose(file);
    
    
    loadedModPlugFile = ModPlug_Load(loadedFileData, loadedFileSize);
    numPatterns       = ModPlug_NumPatterns(loadedModPlugFile);
    numChannels       = ModPlug_NumChannels(loadedModPlugFile);
    numSamples        = ModPlug_NumSamples(loadedModPlugFile);
    numInstr          = ModPlug_NumInstruments(loadedModPlugFile);
    modMessage        = ModPlug_GetMessage(loadedModPlugFile);
    modName           = (char *)ModPlug_GetName(loadedModPlugFile);
    
    self.mpFile = loadedModPlugFile;
}

- (void) initModPlugSettings {
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
}

- (void) playFile:(NSString *)filePath {
    [self initModPlugSettings];
    
    ModPlug_SetMasterVolume(loadedModPlugFile, 128);
    ModPlug_Seek(loadedModPlugFile, 0);
    
    int len = ModPlug_GetLength(loadedModPlugFile);

    NSLog(@"Length: %i", len);
    NSLog(@"ModName: %s", modName);
    
    [self initSound];
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
    
    int bytesRead;

    for (int i = 0; i < SOUND_BUFFER_NB; i++) {
		AudioQueueBufferRef mBuffer;
		err = AudioQueueAllocateBuffer(mAudioQueue, SOUND_BUFFER_SIZE_SAMPLE * 2 * 2, &mBuffer );
		
		mBuffers[i] = mBuffer;
        mBuffer->mAudioDataByteSize = SOUND_BUFFER_SIZE_SAMPLE * 2 * 2;
        
        bytesRead = ModPlug_Read(mpFile, (char*)mBuffer->mAudioData, SOUND_BUFFER_SIZE_SAMPLE * 2 * 2);
        
        [self parsePattern];
        
        AudioQueueEnqueueBuffer(mAudioQueue, mBuffers[i], 0, NULL);
    }
    
    
    /* Set initial playback volume */
    err = AudioQueueSetParameter(mAudioQueue, kAudioQueueParam_Volume, mVolume );
    err = AudioQueueStart(mAudioQueue, NULL );
}


void audioCallback(void *data, AudioQueueRef mQueue, AudioQueueBufferRef mBuffer) {
    ModPlayer *modPlayer = (__bridge ModPlayer*)data;
    ModPlugFile *mpFile = modPlayer.mpFile;
    
    int bytesRead;
    
    mBuffer->mAudioDataByteSize = SOUND_BUFFER_SIZE_SAMPLE*2*2;
    bytesRead = ModPlug_Read(mpFile, (char*)mBuffer->mAudioData, SOUND_BUFFER_SIZE_SAMPLE * 2 * 2);

    if (bytesRead < 1) {
        ModPlug_Seek(mpFile, 0);
        bytesRead = ModPlug_Read(mpFile, (char*)mBuffer->mAudioData, SOUND_BUFFER_SIZE_SAMPLE * 2 * 2);
    }
  
    AudioQueueEnqueueBuffer(mQueue, mBuffer, 0, NULL);
}


- (void) preLoadPatterns  {

    NSLog(@"preLoadPatterns for %s", modName);
    NSDate *start = [NSDate date];
    
    // do stuff...
    ModPlugFile *mpFile = self.mpFile;
    
    int bytesRead,
        currPattrn,
        currRow,
        prevPattrn,
        prevRow;
    
    prevPattrn = prevRow =  -1;
    
    char *buffer = malloc(sizeof(char) * SOUND_BUFFER_SIZE_SAMPLE * 2 * 2);
    
    bytesRead = ModPlug_Read(mpFile, buffer, SOUND_BUFFER_SIZE_SAMPLE * 2 * 2);
    
    // We're going to stuff row strings in here.
    NSMutableArray *patternStrings;
    
    while (bytesRead > 0) {
        currPattrn = ModPlug_GetCurrentPattern(mpFile);
        currRow    = ModPlug_GetCurrentRow(mpFile);
        
        
//       NSLog(@"O %i \t P %i \t R %i", currOrder, currPattrn, currRow);

        // When we hit a new pattern, create a new array so that we can stuff strings into it.
        if (currPattrn != prevPattrn) {
//                NSLog(@"New pattern :: #%i", currPattrn);

            // Add new pattern
            if (patternStrings) {
                NSString *key = [NSString stringWithFormat:@"%d", prevPattrn];
                [songPatterns setValue:patternStrings forKey:key];
            }
            
            patternStrings = [[NSMutableArray alloc] init];
        }
    
        // Skip to the next row so we don't get duplicate patterns in the array.
        if (currPattrn == prevPattrn && currRow == prevRow) {
            
            memset(buffer, 0, SOUND_BUFFER_SIZE_SAMPLE * 2 * 2);
            bytesRead = ModPlug_Read(mpFile, buffer, SOUND_BUFFER_SIZE_SAMPLE * 2 * 2);

            continue;
        }
        
        
        NSString *rowString = [self parsePattern];
        [patternStrings addObject:rowString];
        
                 
        prevPattrn = currPattrn;
        prevRow    = currRow;
        
        memset(buffer, 0, SOUND_BUFFER_SIZE_SAMPLE * 2 * 2);
        bytesRead = ModPlug_Read(mpFile, buffer, SOUND_BUFFER_SIZE_SAMPLE * 2 * 2);
    }
    
    NSTimeInterval timeInterval = [start timeIntervalSinceNow];
    
    NSString *message = [[NSString alloc] initWithFormat:@"Done reading %f(ms)", timeInterval];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"DONE!" message:message delegate:nil cancelButtonTitle:@"sweet" otherButtonTitles:nil, nil];
    [alert show];
    
}


- (NSString *) parsePattern {
    
    ModPlugFile *mpFile = self.mpFile;

    unsigned int rowsToGet,
                 patternNote,
                 instrument,
                 volumeEffect,
                 effect,
                 volume,
                 parameter;

    
    // todo: optimize (by reusing previous data);
    int currentPatternNumber = ModPlug_GetCurrentPattern(mpFile),
        currRow              = ModPlug_GetCurrentRow(mpFile);

    ModPlugNote *pattern = ModPlug_GetPattern(mpFile, currentPatternNumber, &rowsToGet);

    int index,
        curPatPosition,
        k = 0;
    
    char stringData[200];
    
    if (! pattern) {
        NSLog(@"No Pattern for pattern# %i!!", currentPatternNumber);
        return @"";
    }
    

    // The following for loop was inspired by the Modizer project: https://github.com/yoyofr/modizer
    for (index = 0; index < numChannels; index++) {
        curPatPosition = index + (numChannels * currRow);
        
        patternNote  = pattern[curPatPosition].Note;
        instrument   = pattern[curPatPosition].Instrument;
        volumeEffect = pattern[curPatPosition].VolumeEffect;
        effect       = pattern[curPatPosition].Effect;
        volume       = pattern[curPatPosition].Volume;
        parameter    = pattern[curPatPosition].Parameter;
 
        if (patternNote) {
            stringData[k++] = note2charA[(patternNote - 13) % 12];
            stringData[k++] = note2charB[(patternNote - 13) % 12];
            stringData[k++] = (patternNote - 13) / 12 + '0';
        }
        else {
            stringData[k++]='.';
            stringData[k++]='.';
            stringData[k++]='.';
        }
        
        if (instrument) {
            stringData[k++]=dec2hex[ (instrument >> 4) & 0xF ];
            stringData[k++]=dec2hex[ instrument & 0xF ];
        }
        else {
            stringData[k++]='.';
            stringData[k++]='.';
        }
        
        if (volume) {
            stringData[k++] = dec2hex[ (volume >> 4) & 0xF ];
            stringData[k++] = dec2hex[ volume & 0xF ];
        }
        else {
            stringData[k++]='.';
            stringData[k++]='.';
        }
        
        if (effect) {
            stringData[k++]='A' + effect;
        }
        else {
            stringData[k++]='.';
        }
        
        if (parameter) {
            stringData[k++] = dec2hex[(parameter >> 4) & 0xF];
            stringData[k++] = dec2hex[parameter & 0xF];
        }
        else {
            stringData[k++]='.';
            stringData[k++]='.';
        }
        
        stringData[k++]=' ';
        stringData[k++]=' ';
    }
    
    return [[NSString alloc] initWithCString:stringData];
}

- (NSMutableArray *) getModFileDirectories: (NSString *)modPath {
    
    NSString *appUrl  = [[NSBundle mainBundle] bundlePath];
    NSString *modsUrl = [appUrl stringByAppendingString:@"/mods"];
    
    NSURL *directoryUrl = [[NSURL alloc] initFileURLWithPath:modsUrl];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSArray *keys = [NSArray arrayWithObject:NSURLIsDirectoryKey];
    
    NSArray *directories = [fileManager
                 contentsOfDirectoryAtURL: directoryUrl
                 includingPropertiesForKeys : keys
                 options : 0
                 error:nil];
    
    
    NSString *appUrlFull = [NSString stringWithFormat:@"file://%@", appUrl];

    appUrlFull = [[appUrlFull componentsSeparatedByString:@"%20"] componentsJoinedByString: @" "];
    
    NSMutableArray *paths = [[NSMutableArray alloc] init];

    NSString *shortenedUrlPath;
    
    for (NSURL *url in directories) {
    
        shortenedUrlPath = (NSString *)[url absoluteString];
        shortenedUrlPath = [[shortenedUrlPath componentsSeparatedByString:@"%20"] componentsJoinedByString: @" "];

        shortenedUrlPath = [[shortenedUrlPath componentsSeparatedByString:@"mods/"] objectAtIndex:1];

    
        // ios: file:///private/var/mobile/Applications/19E18193-D351-4BFB-849B-F25297DF8387/ModPlayer2.app/mods/Ali-Dbg/
        // sim: Ali-Dbg/
        [paths addObject:shortenedUrlPath];
    }
    
    return paths;
}


- (NSMutableArray *) getFilesInDirectory: (NSString*)path {
    NSMutableArray *files = [[NSMutableArray alloc] init];
    
//    Todo: This is for the Touch 2 app. Be sure to re-enable this.
    NSString *appUrl     = [[NSBundle mainBundle] bundlePath];
    NSString *modsUrl    = [appUrl stringByAppendingString:@"/mods/"];
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
