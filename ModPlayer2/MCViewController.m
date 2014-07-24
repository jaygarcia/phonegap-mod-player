//
//  MCViewController.m
//  ModPlayer2
//
//  Created by Jesus Garcia on 7/23/14.
//  Copyright (c) 2014 Modus Create. All rights reserved.
//

#import "MCViewController.h"
#import "ModPlayer.h"

@interface MCViewController ()

@end

@implementation MCViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    ModPlayer *player = [ModPlayer alloc];
    [player playSong];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
