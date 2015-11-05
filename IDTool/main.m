#import <UIKit/UIKit.h>

#define kUserIDName @"LOVELIVE_ID"
#define kPasswordName @"LOVELIVE_PW"
#define kInformationalMode 0
#define kChangingKAGMode 1
#define kNamingAccountMode 2
#define kAccountMenuMode 3
#define kConfirmEraseMode 4
#define kConfirmDummyMode 5

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@end

@interface ViewController : UIViewController <UIAlertViewDelegate, UIActionSheetDelegate>
@end

@implementation AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    return YES;
}
@end

void ensure_klab_processes_killed(void) {
    // todo: can't find a good way to kill processes by bundle id.
}

@interface ViewController ()
@property (strong, nonatomic) NSString *accessGroup;
@property (weak, nonatomic) IBOutlet UILabel *kagField;
@property (weak, nonatomic) IBOutlet UISegmentedControl *kagPicker;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property int alertViewHandleMode;
@property int actionSheetHandleMode;
@end

@interface ViewController (TableView) <UITableViewDataSource, UITableViewDelegate>
- (void)initTableViewDataSource;
@end

@implementation ViewController {
    NSData *hot_user_id;
    NSData *hot_password;
    NSInteger hot_acc_index;
}

- (void)viewDidLoad {
    self.kagPicker.selectedSegmentIndex = 1;
    [self changeAccessGroup:self.kagPicker];
    [self initTableViewDataSource];
}

- (IBAction)changeAccessGroup:(UISegmentedControl *)sender {
    switch (sender.selectedSegmentIndex) {
        case 0:
            self.accessGroup = @"PH7T7DHD79.jp.klab.lovelive-en";
            break;
        case 1:
            self.accessGroup = @"PH7T7DHD79.jp.klab.lovelive";
            break;
        case 2: {
            self.alertViewHandleMode = kChangingKAGMode;
            UIAlertView *alert = [UIAlertView alloc];
            alert =
            [alert initWithTitle:@"AccessGroup"
                         message:@"Type in the new keychain access group. "
             "Proper entitlements must be set!"
                        delegate:self
               cancelButtonTitle:@"Err... I've changed my mind."
               otherButtonTitles:@"Set KAG", nil];
            alert.alertViewStyle = UIAlertViewStylePlainTextInput;
            [alert show];
            break;
        }
        default:
            break;
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (self.alertViewHandleMode) {
        case kChangingKAGMode:
            if (buttonIndex != alertView.cancelButtonIndex) {
                self.accessGroup = [alertView textFieldAtIndex:0].text;
            } else {
                self.kagPicker.selectedSegmentIndex = 1;
                [self changeAccessGroup:self.kagPicker];
            }
            break;
        case kNamingAccountMode: {
            if (buttonIndex == alertView.cancelButtonIndex)
                return;

            NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
            NSMutableArray *accounts = [([user_defaults arrayForKey:self.accessGroup] ?: @[]) mutableCopy];
            [accounts addObject:@{
                                  @"title": [alertView textFieldAtIndex:0].text,
                                  @"userid": hot_user_id,
                                  @"password": hot_password
                                  }];
            [user_defaults setObject:accounts forKey:self.accessGroup];
            hot_user_id = nil;
            hot_password = nil;
        }
        default:
            break;
    }
}

- (void)setAccessGroup:(NSString *)accessGroup {
    _accessGroup = accessGroup;
    self.kagField.text = accessGroup;
    [self.tableView reloadData];
}

- (BOOL)fetchCurrentID:(NSData **)idOut password:(NSData **)passOut {
    CFDictionaryRef query = (__bridge CFDictionaryRef)@{
                                                        (__bridge id)kSecReturnAttributes: (__bridge id)kCFBooleanTrue,
                                                        (__bridge id)kSecReturnData: (__bridge id)kCFBooleanTrue,
                                                        (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitAll,
                                                        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                                                        (__bridge id)kSecAttrAccessGroup: self.accessGroup,
                                                        };
    CFTypeRef result = NULL;
    SecItemCopyMatching(query, &result);

    BOOL foundName = NO,
    foundPassword = NO;
    for (NSDictionary *sec_object in (__bridge NSArray *)result) {
        if ([sec_object[(__bridge id)kSecAttrService] isEqualToString:kUserIDName]) {
            if (idOut)
                *idOut = sec_object[(__bridge id)kSecValueData];
            foundName = YES;
        } else if ([sec_object[(__bridge id)kSecAttrService] isEqualToString:kPasswordName]) {
            if (passOut)
                *passOut = sec_object[(__bridge id)kSecValueData];
            foundPassword = YES;
        }
    }

    if (result)
        CFRelease(result);
    if (foundName && foundPassword)
        return YES;
    else return NO;
}

- (void)wipeKeychainInternal {
    ensure_klab_processes_killed();
    NSDictionary *uid_item = @{
                               (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                               (__bridge id)kSecAttrAccessGroup: self.accessGroup,
                               (__bridge id)kSecAttrService: kUserIDName,
                               (__bridge id)kSecAttrAccount: @"user_id",
                               };
    NSDictionary *pw_item = @{
                              (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                              (__bridge id)kSecAttrAccessGroup: self.accessGroup,
                              (__bridge id)kSecAttrService: kPasswordName,
                              (__bridge id)kSecAttrAccount: @"passwd",
                              };
    OSStatus err = SecItemDelete((__bridge CFTypeRef)uid_item);
    err |= SecItemDelete((__bridge CFTypeRef)pw_item);
    if (err == errSecSuccess)
        NSLog(@"wiped.");
    else
        NSLog(@"warning: wipeKeychainInternal error %d", (int)err);
}

- (void)restoreKeychainID:(NSData *)user_id password:(NSData *)password {
    [self wipeKeychainInternal];
    NSDictionary *uid_item = @{
                               (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                               (__bridge id)kSecAttrAccessGroup: self.accessGroup,
                               (__bridge id)kSecAttrService: kUserIDName,
                               (__bridge id)kSecValueData: user_id,
                               (__bridge id)kSecAttrAccount: @"user_id",
                               };
    NSDictionary *pw_item = @{
                              (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                              (__bridge id)kSecAttrAccessGroup: self.accessGroup,
                              (__bridge id)kSecAttrService: kPasswordName,
                              (__bridge id)kSecValueData: password,
                              (__bridge id)kSecAttrAccount: @"passwd",
                              };
    SecItemAdd((__bridge CFDictionaryRef)uid_item, NULL);
    SecItemAdd((__bridge CFDictionaryRef)pw_item, NULL);
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (self.actionSheetHandleMode) {
        case kConfirmEraseMode: {
            if (buttonIndex == actionSheet.destructiveButtonIndex) {
                [self wipeKeychainInternal];
            }
            break;
        }
        case kConfirmDummyMode: {
            if (buttonIndex == actionSheet.destructiveButtonIndex) {
                NSString *random_name = [[NSUUID UUID] UUIDString];
                unsigned char random_password[64];
                arc4random_buf(random_password, 64);
                NSMutableString *pass_hex = [[NSMutableString alloc] initWithCapacity:128];
                for (int i = 0; i < 64; ++i)
                    [pass_hex appendFormat:@"%02x", random_password[i]];
                [self restoreKeychainID:[random_name dataUsingEncoding:NSUTF8StringEncoding]
                               password:[pass_hex dataUsingEncoding:NSUTF8StringEncoding]];
            }
            break;
        }
        case kAccountMenuMode: {
            if (buttonIndex == actionSheet.destructiveButtonIndex) {
                NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
                NSMutableArray *accounts = [([user_defaults arrayForKey:self.accessGroup] ?: @[]) mutableCopy];
                [accounts removeObjectAtIndex:hot_acc_index];
                [user_defaults setObject:accounts forKey:self.accessGroup];
                hot_acc_index = -1;
            } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Restore"]) {
                NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
                NSArray *accounts = [user_defaults arrayForKey:self.accessGroup];
                NSDictionary *this_id = accounts[hot_acc_index];
                [self restoreKeychainID:this_id[@"userid"] password:this_id[@"password"]];
                hot_acc_index = -1;
            }
            break;
        }
        default: break;
    }
}

- (IBAction)wipeKeychain:(id)sender {
    NSString *warning = [NSString stringWithFormat:@"Do you really want to erase the ID in %@? Unless you saved it before, it is not recoverable.", self.accessGroup];
    self.actionSheetHandleMode = kConfirmEraseMode;
    UIActionSheet *as = [UIActionSheet alloc];
    as = [as initWithTitle:warning
                  delegate:self
         cancelButtonTitle:@"No thanks"
    destructiveButtonTitle:@"Erase"
         otherButtonTitles:nil];
    [as showInView:self.view];
}

- (IBAction)saveAccountFromKeychain:(id)sender {
    NSData *user_id;
    NSData *password;
    if (![self fetchCurrentID:&user_id password:&password]) {
        NSLog(@"No data stored.");
        self.alertViewHandleMode = kInformationalMode;
        UIAlertView *alert = [UIAlertView alloc];
        alert =
        [alert initWithTitle:@"No Data"
                     message:@"I didn't find anything to save."
                    delegate:self
           cancelButtonTitle:@"OK"
           otherButtonTitles:nil];
        [alert show];
    } else {
        hot_user_id = user_id;
        hot_password = password;
        self.alertViewHandleMode = kNamingAccountMode;
        UIAlertView *alert = [UIAlertView alloc];
        alert =
        [alert initWithTitle:@"Save"
                     message:@"Assign a name to this ID..."
                    delegate:self
           cancelButtonTitle:@"Cancel"
           otherButtonTitles:@"Save", nil];
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        UITextField *tf = [alert textFieldAtIndex:0];
        tf.text = [NSString stringWithFormat:@"%@", [NSDate date]];
        [alert show];
        [tf selectAll:self];
    }
}

- (IBAction)generateAndStoreDummyData:(id)sender {
    NSString *warning = [NSString stringWithFormat:@"The ID in %@ will be erased and replaced with dummy data. Is this okay?\nDo not try to connect to KLab servers with dummy data in place.", self.accessGroup];
    self.actionSheetHandleMode = kConfirmDummyMode;
    UIActionSheet *as = [UIActionSheet alloc];
    as = [as initWithTitle:warning
                  delegate:self
         cancelButtonTitle:@"No thanks"
    destructiveButtonTitle:@"This is okay"
         otherButtonTitles:nil];
    [as showInView:self.view];
}

- (IBAction)dumpConsole:(id)sender {
    NSLog(@"KAG: %@", self.accessGroup);
    NSData *user_id;
    NSData *password;
    if (![self fetchCurrentID:&user_id password:&password]) {
        NSLog(@"No data stored.");
    } else {
        NSLog(@"id: %@\n"
              "password: %@", user_id, password);
    }
}

@end

@implementation ViewController (TableView)

- (void)initTableViewDataSource {
    NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
    if (![user_defaults arrayForKey:self.accessGroup]) {
        NSLog(@"initialized accounts array.");
        [user_defaults setObject:@[] forKey:self.accessGroup];
    }
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:NSUserDefaultsDidChangeNotification
                                                      object:user_defaults
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      [self.tableView reloadData];
                                                  }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[NSUserDefaults standardUserDefaults] arrayForKey:self.accessGroup].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *acc_obj = [[NSUserDefaults standardUserDefaults] arrayForKey:self.accessGroup][indexPath.row];
    UITableViewCell *a_cell = [tableView dequeueReusableCellWithIdentifier:@"AccountCell"
                                                              forIndexPath:indexPath];
    a_cell.textLabel.text = acc_obj[@"title"];
    a_cell.detailTextLabel.text = [[NSString alloc] initWithData:acc_obj[@"userid"] encoding:NSUTF8StringEncoding];
    return a_cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *warning = [NSString stringWithFormat:@"What do you want to do with this ID? (%@)", self.accessGroup];
    self.actionSheetHandleMode = kAccountMenuMode;
    hot_acc_index = indexPath.row;
    UIActionSheet *as = [UIActionSheet alloc];
    as = [as initWithTitle:warning
                  delegate:self
         cancelButtonTitle:@"Nothing"
    destructiveButtonTitle:@"Delete"
         otherButtonTitles:@"Restore", nil];
    [as showInView:self.view];
}

@end

int main(int argc, char * argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
