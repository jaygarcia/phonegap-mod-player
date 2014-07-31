//
//  ModPlayer.m
//  ModPlayer2
//
//  Created by Jesus Garcia on 7/23/14.
//  Copyright (c) 2014 Modus Create. All rights reserved.
//


#include "ModPlayer.h"

@implementation ModPlayer {
	int *genRow,*genPattern, *playRow,*playPattern;
    unsigned char *genVolData, *playVolData;
	char *mp_data;
	
    int numPatterns;
    int numSamples;
    int numInstr;
    int numChannels;
    char *modMessage;
    
    int lastPattern; // Used for determining if we already looked at this pattern. TODO: Delete
    
    
    ModPlugFile *loadedModPlugFile;
    ModPlug_Settings settings;
    
    AudioQueueRef mAudioQueue;
    AudioQueueBufferRef *mBuffers;
    
    NSMutableArray *songPatterns;
    char *loadedFileData;
    int loadedFileSize;

}

static char note2charA[12]={'C','C','D','D','E','F','F','G','G','A','A','B'};
static char note2charB[12]={'-','#','-','#','-','-','#','-','#','-','#','-'};
static char dec2hex[16]={'0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'};

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
    
    NSString *firstDir = [dirs objectAtIndex:2];
    
    NSMutableArray *files = [self getFilesInDirectory:firstDir];
    NSURL *fileUrl = [files objectAtIndex:0];
    NSString *firstFile = [[fileUrl filePathURL] absoluteString];

    firstFile = [[firstFile componentsSeparatedByString:@"%20"] componentsJoinedByString: @" "];
    firstFile = [[firstFile componentsSeparatedByString:@"file://"] componentsJoinedByString: @""];
    
    
    
    [self loadFile:firstFile];
//    [self preLoadPatterns:firstFile];
    [self playFile:firstFile];


//    NSLog(@"Here");
}

- (void) preLoadPatterns:(NSString *)  filePath  {
    NSLog(@"Loaded file %@", filePath);
    
    //songPatterns
    
    
    
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
}

- (void) playFile:(NSString *)filePath {
    
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
    
    loadedModPlugFile = ModPlug_Load(loadedFileData, loadedFileSize);
    numPatterns       = ModPlug_NumPatterns(loadedModPlugFile);
    numChannels       = ModPlug_NumChannels(loadedModPlugFile);
    numSamples        = ModPlug_NumSamples(loadedModPlugFile);
    numInstr          = ModPlug_NumInstruments(loadedModPlugFile);
    modMessage        = ModPlug_GetMessage(loadedModPlugFile);
    
    self.mpFile = loadedModPlugFile;
    
    ModPlug_SetMasterVolume(loadedModPlugFile, 128);
    ModPlug_Seek(loadedModPlugFile, 0);
    
    const char *modName = ModPlug_GetName(loadedModPlugFile);

    int len = ModPlug_GetLength(loadedModPlugFile);

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
//        NSLog(@"Created Buffer #%i", i);
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
    
//    NSLog(@"audioCallback");
    
    mBuffer->mAudioDataByteSize = SOUND_BUFFER_SIZE_SAMPLE*2*2;
    bytesRead = ModPlug_Read(mpFile, (char*)mBuffer->mAudioData, SOUND_BUFFER_SIZE_SAMPLE * 2 * 2);

    if (bytesRead < 1) {
        ModPlug_Seek(mpFile, 0);
        bytesRead = ModPlug_Read(mpFile, (char*)mBuffer->mAudioData, SOUND_BUFFER_SIZE_SAMPLE * 2 * 2);
    }
    
    [modPlayer parsePattern];

    
    
    AudioQueueEnqueueBuffer(mQueue, mBuffer, 0, NULL);
}


- (void) parsePattern {
    
    ModPlugFile *mpFile = self.mpFile;
    

    int currOrder = ModPlug_GetCurrentOrder(mpFile);
    int currentPatternNumber = ModPlug_GetCurrentPattern(mpFile);
    int currRow   = ModPlug_GetCurrentRow(mpFile);

    unsigned int rowsToGet;
    ModPlugNote *pattern = ModPlug_GetPattern(mpFile, currentPatternNumber, &rowsToGet);


    unsigned int patternNote;
    unsigned int instrument;
    unsigned int volumeEffect;
    unsigned int effect;
    unsigned int volume;
    unsigned int parameter;

    
    if (currentPatternNumber != lastPattern) {
        lastPattern = currentPatternNumber;
        printf("\n\n                              ____ 01 ___  ___ 02 ___  ___ 03 ___  ___ 04 ___  ___ 05 ___  ___ 06 ___  ___ 07 ___  ___ 08 ___\n");
        // ">> Ord 2	Pat 50	Row 60 	 ..........  .......D..  .......D..  B-31B.....  ..........  .......L..  B-41A0A...  .........."
//        printf("\n\t\t\t 1\t\t2\n");
    }
    
    printf(">> Ord %i\tPat %i\tRow %i \t ", currOrder, currentPatternNumber, currRow);
  
    int index;
    int k = 0;
    char str_data[200];
    int currentPatternPosition;
    
    
    

    // The following was inspired by the Modizer project: https://github.com/yoyofr/modizer
    for (index = 0; index < numChannels; index++) {
        currentPatternPosition = index + (numChannels * currRow);
        
        patternNote  = pattern[currentPatternPosition].Note;
        instrument   = pattern[currentPatternPosition].Instrument;
        volumeEffect = pattern[currentPatternPosition].VolumeEffect;
        effect       = pattern[currentPatternPosition].Effect;
        volume       = pattern[currentPatternPosition].Volume;
        parameter    = pattern[currentPatternPosition].Parameter;
 
        if (patternNote) {
            str_data[k++] = note2charA[(patternNote - 13) % 12];
            str_data[k++] = note2charB[(patternNote - 13) % 12];
            str_data[k++] = (patternNote - 13) / 12 + '0';
        }
        else {
            str_data[k++]='.';
            str_data[k++]='.';
            str_data[k++]='.';
        }
        
        if (instrument) {
            str_data[k++]=dec2hex[ (instrument >> 4) & 0xF ];
            str_data[k++]=dec2hex[ instrument & 0xF ];
        }
        else {
            str_data[k++]='.';
            str_data[k++]='.';
        }
        
        if (volume) {
            str_data[k++] = dec2hex[ (volume >> 4) & 0xF ];
            str_data[k++] = dec2hex[ volume & 0xF ];
        }
        else {
            str_data[k++]='.';
            str_data[k++]='.';
        }
        
        if (effect) {
            str_data[k++]='A' + effect;
        }
        else {
            str_data[k++]='.';
        }
        
        if (parameter) {
            str_data[k++] = dec2hex[(parameter >> 4) & 0xF];
            str_data[k++] = dec2hex[parameter & 0xF];
        }
        else {
            str_data[k++]='.';
            str_data[k++]='.';
        }
        
        str_data[k++]=' ';
        str_data[k++]=' ';
      
    }
    
        printf("%s\n", str_data);

    
//    NSLog(@"bytesRead: %i", bytesRead);
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
