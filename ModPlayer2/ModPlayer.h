//
//  ModPlayer.h
//  ModPlayer2
//
//  Created by Jesus Garcia on 7/23/14.
//  Copyright (c) 2014 Modus Create. All rights reserved.
//

#import <Foundation/Foundation.h>
//#include "SDL_mixer.h"
#import <AudioToolbox/AudioToolbox.h>
#import "SDL_mixer.h"
#import "modplug.h"

#define PLAYBACK_FREQ 44100
#define SOUND_BUFFER_SIZE_SAMPLE (PLAYBACK_FREQ / 30)
#define SOUND_BUFFER_NB 2
#define MIDIFX_OFS 32

typedef struct {
    AudioStreamBasicDescription  dataFormat;
    AudioQueueRef                queue;
    AudioQueueBufferRef          buffers[SOUND_BUFFER_NB];
    AudioFileID                  audioFile;
    SInt64                       currentPacket;
    bool                         playing;
} PlayState;


@interface ModPlayer : NSObject {




//    ModPlugFile *mp_file;
//	int *genRow,*genPattern, *playRow,*playPattern;
//    unsigned char *genVolData, *playVolData;
//	char *mp_data;
//	int numPatterns, numSamples, numInstr;
}

@property ModPlugFile *mpFile;


- (void) playSong;

@end
