//
//  ChatVC.h
//  iAmHere
//
//  Created by Igor Garaba on 11.07.14.
//  Copyright (c) 2014 Igor Garaba. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#define ONLINE 1
#define OFFLINE 0
@interface ChatVC : UIViewController
@property (strong,nonatomic) PFObject *currentUser;
@end
