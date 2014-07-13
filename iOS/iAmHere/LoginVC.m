//
//  LoginVC.m
//  iAmHere
//
//  Created by Igor Garaba on 11.07.14.
//  Copyright (c) 2014 Igor Garaba. All rights reserved.
//

#import "LoginVC.h"
#import <Parse/Parse.h>
#import "ChatVC.h"

@interface LoginVC () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *userName;
@property(strong,nonatomic) PFObject *user;
@end

@implementation LoginVC
- (IBAction)login:(id)sender
{
        [self login];
}

-(void)login
{
    if([self.userName.text length]==0)
    {
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:
                                  @"Ошибка" message:@"Введите имя пользователя" delegate:self
                                                 cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
        [alertView show];
    }
    else
    {
        PFQuery *query = [PFQuery queryWithClassName:@"Users"];
        [query whereKey:@"udid" equalTo:[[[UIDevice currentDevice]identifierForVendor]UUIDString]];
        __weak LoginVC *weakSelf = self;
        [query getFirstObjectInBackgroundWithBlock:^(PFObject * userObject, NSError *error) {
            if (!error)
            {
                userObject[@"UserName"] = weakSelf.userName.text;
                userObject[@"Status"] = @ONLINE;
                [userObject saveInBackground];
                weakSelf.user = userObject;
                [weakSelf  performSegueWithIdentifier:@"toChatVC" sender:self];
            }
            else
            {
                PFObject *user = [PFObject objectWithClassName:@"Users"];
                user[@"UserName"] = self.userName.text;
                user[@"Status"]= @ONLINE;
                user[@"udid"]=[[[UIDevice currentDevice]identifierForVendor]UUIDString];
                [user saveInBackground];
                weakSelf.user = user;
                [weakSelf  performSegueWithIdentifier:@"toChatVC" sender:self];
            }
            
        }];
    }
}

//Получить текущего пользователя и передать в ChatVC
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    ((ChatVC *)segue.destinationViewController).currentUser = self.user;
}
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(IBAction)returnToLoginVC2:(UIStoryboardSegue *)segue
{
    if ([self.user[@"Status"]integerValue]==ONLINE)
    {
        self.user[@"Status"] = @OFFLINE;
        [self.user saveInBackground];
    }
   
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.userName)
    {
        [self login];
    }
    return YES;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.userName setDelegate:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
