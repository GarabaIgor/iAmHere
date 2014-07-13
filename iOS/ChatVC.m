//
//  ChatVC.m
//  iAmHere
//
//  Created by Igor Garaba on 11.07.14.
//  Copyright (c) 2014 Igor Garaba. All rights reserved.
//

#import "ChatVC.h"
#import <Parse/Parse.h>
#import "ChatCell.h"

#define ONLINE_TIME  60

@interface ChatVC () <UITableViewDataSource,UITableViewDelegate>
@property(strong,nonatomic)NSMutableArray *users;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *timerLabel;
@property (strong,nonatomic)NSTimer *timer;
@property (assign)NSInteger seconds;
@end

@implementation ChatVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(addUser:)
                                                     name:@"AddUser"
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(removeUser:)
                                                     name:@"RemoveUser"
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(becomeActive:)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];

    }
    return self;
}

//Если пользователь за время прибывания приложения в фоне стал OFFLINE (сервер каждую минуту проверяет, если пользователь онлайн больше 2-х минут, то переводит в статус OFFLINE)
- (void)becomeActive:(NSNotification *)notification
{
    PFQuery *query = [PFQuery queryWithClassName:@"Users"];
    NSString *udid = [[[UIDevice currentDevice]identifierForVendor]UUIDString];
    [query whereKey:@"udid" equalTo:udid];
    [query whereKey:@"Status" equalTo:@OFFLINE];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject * userObject, NSError *error) {
        if (!error && userObject)
        {
            [self removeUserByUdid:udid];
        }
        
    }];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                  target:self
                                                selector:@selector(updateTimerLabel)
                                                userInfo:nil
                                                 repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:UITrackingRunLoopMode];
    self.seconds = ONLINE_TIME;
}
-(void)viewDidAppear:(BOOL)animated
{
    [self.timer fire];
    PFQuery *query = [PFQuery queryWithClassName:@"Users"];
    [query whereKey:@"Status" equalTo:@(ONLINE)];
    [query whereKey:@"udid" notEqualTo:[[[UIDevice currentDevice]identifierForVendor]UUIDString]];
    __weak ChatVC *weakSelf = self;
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error)
        {
            weakSelf.users = [[NSMutableArray alloc]initWithArray:objects];
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.tableView reloadData];
            });
        }
        else
        {
            UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:
                                      @"Ошибка" message:@"Ошибка при загрузке списка пользователей" delegate:self
                                                     cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
            [alertView show];
        }
    }];

}

-(void)updateTimerLabel
{
    if(self.seconds >0)
    {
        self.seconds--;
        self.timerLabel.text = [NSString stringWithFormat:@"%ld",self.seconds];
    }
    else
    {
        [self performSegueWithIdentifier:@"unwindToLoginVC" sender:self];
    }
        
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.users count];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ChatCell *cell = [tableView dequeueReusableCellWithIdentifier:@"chatCellId" forIndexPath:indexPath];
    cell.userName.text = self.users[indexPath.row][@"UserName"];
    return cell;
}

-(void)addUser:(NSNotification *)notification
{
    // Добавляем, если только пользователь с другим udid
    if (![notification.object[@"udid"] isEqualToString:self.currentUser[@"udid"]])
    {
        NSMutableDictionary *user = [[NSMutableDictionary alloc]init];
        if(!self.users)
        {
            self.users = [[NSMutableArray alloc]init];
        }
        //Если пользователь с таким udid есть в списке, то обновляем его
        NSPredicate *sameUdidPredicate = [NSPredicate predicateWithFormat:@"(udid == %@)",notification.object[@"udid"]];
        NSArray *filteredUsers = [self.users filteredArrayUsingPredicate:sameUdidPredicate];
        if([filteredUsers count])
        {
            NSIndexPath *indPath = [NSIndexPath indexPathForRow:[self.users indexOfObject:filteredUsers[0]] inSection:0];
            if(filteredUsers[0][@"UserName"] != notification.object[@"userName"])
            {
                filteredUsers[0][@"UserName"] = notification.object[@"userName"];
            }
            [self.tableView beginUpdates];
            [self.tableView reloadRowsAtIndexPaths:@[indPath] withRowAnimation:UITableViewRowAnimationNone];
            [self.tableView endUpdates];
        }
        //Если такого пользователя нет, то добавляем его
        else
        {
            user[@"UserName"] = notification.object[@"userName"];
            user[@"udid"] = notification.object[@"udid"];
            [self.users addObject:user];
            NSIndexPath *indPath = [NSIndexPath indexPathForRow:[self.users count]-1  inSection:0];
            [self.tableView beginUpdates];
            [self.tableView insertRowsAtIndexPaths:@[indPath] withRowAnimation:UITableViewRowAnimationRight];
            [self.tableView endUpdates];
        }
    }
}
-(void)removeUser:(NSNotification *)notification
{
    [self removeUserByUdid:notification.object[@"udid"]];
}

-(void)removeUserByUdid:(NSString *)udid
{
    if ([udid isEqualToString:self.currentUser[@"udid"]])
    {
        [self dismissViewControllerAnimated:NO completion:nil];
    }
    else
    {
        if(self.users)
        {
            //Найти такого User по udid в массиве и удалить
            NSPredicate *sameUdidPredicate = [NSPredicate predicateWithFormat:@"(udid == %@)",udid];
            NSArray *filteredUsers = [self.users filteredArrayUsingPredicate:sameUdidPredicate];
            if([filteredUsers count])
            {
                NSLog(@"Zero index: %@",filteredUsers[0]);
                NSIndexPath *indPath = [NSIndexPath indexPathForRow:[self.users indexOfObject:filteredUsers[0]] inSection:0];
                [self.users removeObject:filteredUsers[0]];
                [self.tableView beginUpdates];
                [self.tableView deleteRowsAtIndexPaths:@[indPath] withRowAnimation:UITableViewRowAnimationRight];
                [self.tableView endUpdates];
            }
        }
    }
   
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
