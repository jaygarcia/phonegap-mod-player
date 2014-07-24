//
//  ModPlayer.h
//  ModPlayer2
//
//  Created by Jesus Garcia on 7/23/14.
//  Copyright (c) 2014 Modus Create. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "modplug.h"


@interface ModPlayer : NSObject {
//    ModPlugFile *mp_file;
//	int *genRow,*genPattern, *playRow,*playPattern;
//    unsigned char *genVolData, *playVolData;
//	char *mp_data;
//	int numPatterns, numSamples, numInstr;
}
//
//@property ModPlug_Settings mp_settings;
//@property ModPlugFile *mp_file;
//@property char *mp_data;
//@property int *genRow,*genPattern,*playRow,*playPattern;//,*playOffset,*genOffset;
//@property unsigned char *genVolData,*playVolData;
//@property float mVolume;
//@property int numChannels,numPatterns,numSamples,numInstr;
//

- (void) playSong;

@end
