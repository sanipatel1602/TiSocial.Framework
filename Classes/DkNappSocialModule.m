/**
 * Module developed by Napp CMS
 * Mads Møller
 * 
 * Appcelerator Titanium is Copyright (c) 2009-2010 by Appcelerator, Inc.
 * and licensed under the Apache Public License (version 2)
 */
#import "DkNappSocialModule.h"
#import "TiBase.h"
#import "TiHost.h"
#import "TiUtils.h"
#import "TiApp.h"


//include Social and Accounts Frameworks
#import <Social/Social.h>
#import <Accounts/Accounts.h>

//for iOS5 twitter framework
#import <Twitter/Twitter.h>

@implementation DkNappSocialModule

#pragma mark Internal

// this is generated for your module, please do not change it
-(id)moduleGUID
{
	return @"8152d7fc-6edb-4c40-8d6f-bc2cef87bc1a";
}

// this is generated for your module, please do not change it
-(NSString*)moduleId
{
	return @"dk.napp.social";
}

#pragma mark Lifecycle

-(void)startup
{
	// this method is called when the module is first loaded
	// you *must* call the superclass
	[super startup];
	
	NSLog(@"[INFO] %@ loaded",self);
}

-(void)shutdown:(id)sender
{
	// this method is called when the module is being unloaded
	// typically this is during shutdown. make sure you don't do too
	// much processing here or the app will be quit forceably
	
	// you *must* call the superclass
	[super shutdown:sender];
}

#pragma mark Cleanup 

-(void)dealloc
{
	// release any resources that have been retained by the module
    RELEASE_TO_NIL(popoverController);
    RELEASE_TO_NIL(accountStore);
	[super dealloc];
}

#pragma mark Internal Memory Management

-(void)didReceiveMemoryWarning:(NSNotification*)notification
{
	// optionally release any resources that can be dynamically
	// reloaded once memory is available - such as caches
	[super didReceiveMemoryWarning:notification];
}

#pragma mark Listener Notifications

-(void)_listenerAdded:(NSString *)type count:(int)count
{
	if (count == 1 && [type isEqualToString:@"my_event"])
	{
		// the first (of potentially many) listener is being added 
		// for event named 'my_event'
	}
}

-(void)_listenerRemoved:(NSString *)type count:(int)count
{
	if (count == 0 && [type isEqualToString:@"my_event"])
	{
		// the last listener called for event named 'my_event' has
		// been removed, we can optionally clean up any resources
		// since no body is listening at this point for that event
	}
}

#pragma Public APIs

- (BOOL) validateUrl: (NSString *) candidate {
    NSString *urlRegEx = @"(http|https)://((\\w)*|([0-9]*)|([-|_])*)+([\\.|/]((\\w)*|([0-9]*)|([-|_])*))+";
    NSPredicate *urlTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", urlRegEx];
    return [urlTest evaluateWithObject:candidate];
}

-(NSNumber*)isNetworkSupported:(NSString *)service {
    BOOL available = NO;
    if(NSClassFromString(@"SLComposeViewController")){
        if([SLComposeViewController isAvailableForServiceType:service]) {
            available=YES;
        }
    }
    return NUMBOOL(available); //This can call this to let them know if this feature is supported
}

-(NSNumber*)isActivitySupported {
    BOOL available = NO;
    if(NSClassFromString(@"UIActivityViewController")){
        available=YES;
    }
    return NUMBOOL(available); //This can call this to let them know if this feature is supported
}

-(NSNumber*)isTwitterSupported:(id)args {
    if(NSClassFromString(@"SLComposeViewController") != nil){
        return [self isNetworkSupported:SLServiceTypeTwitter];
    }else if(NSClassFromString(@"TWTweetComposeViewController") != nil){
        return NUMBOOL(YES);
    }else{
        return NUMBOOL(NO);
    }
}

-(NSNumber*)isRequestTwitterSupported:(id)args { //for iOS6 twitter
    return [TiUtils isIOS6OrGreater]?[self isNetworkSupported:SLServiceTypeTwitter]:NUMBOOL(NO);
}

-(NSNumber*)isFacebookSupported:(id)args {
    return [TiUtils isIOS6OrGreater]?[self isNetworkSupported:SLServiceTypeFacebook]:NUMBOOL(NO);
}

-(NSNumber*)isSinaWeiboSupported:(id)args {
    return [TiUtils isIOS6OrGreater]?[self isNetworkSupported:SLServiceTypeSinaWeibo]:NUMBOOL(NO);
}

-(NSNumber*)isActivityViewSupported:(id)args {
    return [TiUtils isIOS6OrGreater]?[self isActivitySupported]:NUMBOOL(NO);
}

-(UIImage *)findImage:(NSString *)imagePath
{
    if(imagePath != nil){
        UIImage *image = nil;
        
        // Load the image from the application assets
        NSString *fileNamePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:imagePath];;
        image = [UIImage imageWithContentsOfFile:fileNamePath];
        if (image != nil) {
            return image;
        }
        
        //Load local image by extracting the filename without extension
        NSString* newImagePath = [[imagePath lastPathComponent] stringByDeletingPathExtension];
        image = [UIImage imageNamed:newImagePath];
        if(image != nil){
            return image;
        }
        
        //image from URL
        image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:imagePath]]];
        if(image != nil){
            return image;
        }
        
        //load remote image
        image = [UIImage imageWithContentsOfFile:imagePath];
        if(image != nil){
            return image;
        }
        NSLog(@"image NOT found");
    }
    return nil;
}


/*
 * Accounts
 */
-(id)twitterAccountList:(id)args
{
    if(accountStore == nil){
        accountStore =  [[ACAccountStore alloc] init];
    }
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier: ACAccountTypeIdentifierTwitter];
    
    // request access
    [accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error){
         if (granted == YES) {
             NSArray * arrayOfAccounts = [accountStore accountsWithAccountType:accountType];
             [arrayOfAccounts retain];
             
             NSMutableArray *accounts = [[NSMutableArray alloc] init];
             NSMutableDictionary * dictAccounts = [[NSMutableDictionary alloc] init];
             for( int i = 0; i < [arrayOfAccounts count]; i++ )
             {
                 ACAccount * account = [arrayOfAccounts objectAtIndex:i];
                 NSDictionary * dict = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSString stringWithString:account.username], @"username",
                                        [NSString stringWithString:account.identifier], @"identifier",
                                        nil];
                 [accounts addObject:dict];
             }
             [dictAccounts setObject:accounts forKey:@"accounts"];
             [self fireEvent:@"accountList" withObject:dictAccounts];
         } else {
             NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:NUMBOOL(NO),@"success",@"No account",@"status",nil];
             [self fireEvent:@"error" withObject:event];
         }
    }];
    
}

-(void)shareToNetwork:(NSString *)service args:(id)args {
    ENSURE_SINGLE_ARG_OR_NIL(args, NSDictionary);
 
    SLComposeViewController *controller = [SLComposeViewController composeViewControllerForServiceType:service];
    SLComposeViewControllerCompletionHandler myBlock = ^(SLComposeViewControllerResult result){
        if (result == SLComposeViewControllerResultCancelled) {
            NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:NUMBOOL(NO),@"success",nil];
            [self fireEvent:@"cancelled" withObject:event];
        } else {
            NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:NUMBOOL(YES),@"success",nil];
            [self fireEvent:@"complete" withObject:event];
        }
        [controller dismissViewControllerAnimated:YES completion:Nil];
    };
    controller.completionHandler = myBlock;
    
    //get the properties from javascript
    NSString * shareText = [TiUtils stringValue:@"text" properties:args def:nil];
    NSString * shareUrl = [TiUtils stringValue:@"url" properties:args def:nil];
    NSString * shareImage = [TiUtils stringValue:@"image" properties:args def:nil];
    
    BOOL animated = [TiUtils boolValue:@"animated" properties:args def:YES];
    
    if (shareText != nil) {
        [controller setInitialText:shareText];
    }
    
    if (shareUrl != nil) {
        [controller addURL:[NSURL URLWithString:shareUrl]];
    }
    
    if (shareImage != nil) {
        [controller addImage: [self findImage:shareImage]];
    }
    
    [[TiApp app] showModalController:controller animated:animated];

}

/*
 *  Facebook
 */

-(void)facebook:(id)args{
    ENSURE_UI_THREAD(facebook, args);
    [self shareToNetwork:SLServiceTypeFacebook args:args];
}


-(void)requestFacebook:(id)args{
    NSDictionary *arguments = [args objectAtIndex:0];
    
    // Defaults
    NSDictionary *requestParameter = nil;
    NSArray *permissionsArray = nil;
    
    if([args count] > 1){
        requestParameter = [args objectAtIndex:1];
    }

    if(accountStore == nil){
        accountStore =  [[ACAccountStore alloc] init];
    }
    
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
    
    NSString *appId = [arguments objectForKey:@"appIdKey"];
    NSString *permissions = [arguments objectForKey:@"permissionsKey"];
    NSString *callbackEventName = [TiUtils stringValue:@"callbackEvent" properties:arguments def:@"facebookRequest"];
    
    
    // Append permissions
    if(permissions != nil) {
       permissionsArray = [permissions componentsSeparatedByString:@","];
    }
    
    NSDictionary *options = @{
        ACFacebookAppIdKey: appId,
        ACFacebookAudienceKey: ACFacebookAudienceEveryone,
        ACFacebookPermissionsKey: permissionsArray
    };
    
    
    [accountStore requestAccessToAccountsWithType:accountType options:options completion:^(BOOL granted, NSError *error){
        if (granted){
            NSArray *arrayOfAccounts = [accountStore accountsWithAccountType:accountType];
            
            if ([arrayOfAccounts count] > 0) {
                ACAccount *fbAccount = [arrayOfAccounts lastObject];
                
                //requestType: GET, POST, DELETE
                NSInteger facebookRequestMethod = SLRequestMethodPOST;
                NSString *requestType = [[TiUtils stringValue:@"requestType" properties:arguments def:@"POST"] uppercaseString];
                
                if( [requestType isEqualToString:@"POST"] ){
                    facebookRequestMethod = SLRequestMethodPOST;
                } else if( [requestType isEqualToString:@"GET"] ){
                    facebookRequestMethod = SLRequestMethodGET;
                } else if( [requestType isEqualToString:@"DELETE"] ) {
                    facebookRequestMethod = SLRequestMethodDELETE;
                } else {
                    NSLog(@"[Social] no valid request method found - using POST");
                }
                
                //args
                NSString *requestURL = [arguments objectForKey:@"url"];
                
                if(requestURL != nil ){
 
                    SLRequest *fbRequest = [SLRequest requestForServiceType:SLServiceTypeFacebook
                                                                   requestMethod:facebookRequestMethod
                                                                             URL:[NSURL URLWithString:requestURL]
                                                                      parameters:requestParameter];
                    [fbRequest setAccount:fbAccount];
                    [fbRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error){
                        NSNumber *isSuccess;
                                        
                        if ([urlResponse statusCode] == 200) {
                            isSuccess = NUMBOOL(YES);
                        } else {
                            isSuccess = NUMBOOL(NO);
                        }
                        
                        NSArray *response = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableLeaves error:&error];
                        NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys: isSuccess,@"success", response,@"response", nil];
                        [self fireEvent:callbackEventName withObject:event];
                    }];
                    
                } else {
                    NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:NUMBOOL(NO),@"success",@"Missing arguments",@"status",nil];
                    [self fireEvent:@"error" withObject:event];
                }
            }
        } else {
            NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:NUMBOOL(NO),@"success",@"No account",@"status",nil];
            [self fireEvent:@"error" withObject:event];
        }
    }];
}



///////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////
//                  TWITTER API
///////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////

-(void)twitter:(id)args{
    ENSURE_UI_THREAD(twitter, args);
    
    if(NSClassFromString(@"SLComposeViewController") != nil){
        [self shareToNetwork:SLServiceTypeTwitter args:args];
    }else{
        //iOS5 Support
        
        ENSURE_SINGLE_ARG(args, NSDictionary);
        
        if ([TWTweetComposeViewController canSendTweet])
        {
            TWTweetComposeViewController *tweetSheet = [[TWTweetComposeViewController alloc] init];
            
            NSString *url = [args objectForKey:@"url"];
            NSString *message = [args objectForKey:@"text"];
            
            if (message != nil) {
                [tweetSheet setInitialText: message];
            }
            
            if (url != nil) {
                [tweetSheet addURL:[TiUtils toURL:url proxy:nil]];
            }
            
            tweetSheet.completionHandler = ^(TWTweetComposeViewControllerResult result) {
	
			    if (result == TWTweetComposeViewControllerResultCancelled) {
			        NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:NUMBOOL(NO),@"success",nil];
			        [self fireEvent:@"cancelled" withObject:event];
			    } else {
			        NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:NUMBOOL(YES),@"success",nil];
			        [self fireEvent:@"complete" withObject:event];
			    }
	
                [[TiApp app] hideModalController:tweetSheet animated:YES];
                [tweetSheet release];
            };
            
            [[TiApp app] showModalController:tweetSheet animated:YES];
        }
    }
}

/**
 * args[0] - requestType, url, accountWithIdentifier
 * args[1] - requestParameter
 *
 */
-(void)requestTwitter:(id)args {
    NSDictionary *arguments = [args objectAtIndex:0];
    
    // Defaults
    NSDictionary *requestParameter = nil;
    
    if([args count] > 1){
        requestParameter = [args objectAtIndex:1];
    }
    
    if(accountStore == nil){
        accountStore =  [[ACAccountStore alloc] init];
    }

    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier: ACAccountTypeIdentifierTwitter];
    
    NSString *callbackEventName = [TiUtils stringValue:@"callbackEvent" properties:arguments def:@"twitterRequest"];
    
    [accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error){
        if (granted == YES){
            NSArray *arrayOfAccounts = [accountStore accountsWithAccountType:accountType];
            
            if ([arrayOfAccounts count] > 0) {
                NSString *selectedAccount = [TiUtils stringValue:@"accountWithIdentifier" properties:arguments def:nil];
                ACAccount *twitterAccount;
                if(selectedAccount !=nil){
                    //user selected
                    twitterAccount = [accountStore accountWithIdentifier:selectedAccount];
                    if(twitterAccount == nil){
                        //fallback
                        NSLog(@"[ERROR] Account with identifier does not exist");
                        twitterAccount = [arrayOfAccounts lastObject];
                    }
                } else {
                    //use last account in array
                    twitterAccount = [arrayOfAccounts lastObject];
                }
                
                
                //requestType: GET, POST, DELETE
                NSInteger requestMethod = SLRequestMethodPOST;
                NSString *requestType = [[TiUtils stringValue:@"requestType" properties:arguments def:@"POST"] uppercaseString];
                
                if( [requestType isEqualToString:@"POST"] ){
                    requestMethod = SLRequestMethodPOST;
                } else if( [requestType isEqualToString:@"GET"] ){
                    requestMethod = SLRequestMethodGET;
                } else if( [requestType isEqualToString:@"DELETE"] ) {
                    requestMethod = SLRequestMethodDELETE;
                } else {
                    NSLog(@"[Social] no valid request method found - using POST");
                }
                
                //args
                NSString *requestURL = [TiUtils stringValue:@"url" properties:arguments def:nil];
                
                if(requestURL != nil){
                    
                    SLRequest *twitterRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                                                            requestMethod:requestMethod
                                                                            URL:[NSURL URLWithString:requestURL]
                                                                            parameters:requestParameter];
                    [twitterRequest setAccount:twitterAccount];
                    [twitterRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error){
                         NSNumber *isSuccess;
                         if ([urlResponse statusCode] == 200) {
                             isSuccess = NUMBOOL(YES);
                         } else {
                             isSuccess = NUMBOOL(NO);
                         }
                         //NSString *response = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
                         NSArray *response = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableLeaves error:&error];
                         NSString *rawData = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
                         NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys: isSuccess,@"success", response,@"response", rawData,@"rawResponse", nil];
                         [self fireEvent:callbackEventName withObject:event];
                     }];
                    
                } else {
                    NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:NUMBOOL(NO),@"success",@"Missing arguments",@"status",nil];
                    [self fireEvent:@"error" withObject:event];
                }
            }
        } else {
            NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:NUMBOOL(NO),@"success",@"No account",@"status",nil];
            [self fireEvent:@"error" withObject:event];
        }
    }];
}

/*
 *  Sina Weibo
 */

-(void)sinaweibo:(id)args{
    ENSURE_UI_THREAD(sinaweibo, args);
    [self shareToNetwork:SLServiceTypeSinaWeibo args:args];
}





///////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////
//                  UIActivityViewController
///////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////



-(void)activityView:(id)args{
    ENSURE_UI_THREAD(activityView, args);
    ENSURE_SINGLE_ARG_OR_NIL(args, NSDictionary);
    
    //get the properties from javascript
    NSString * shareText = [TiUtils stringValue:@"text" properties:args def:@""];
    NSString * shareImage = [TiUtils stringValue:@"image" properties:args def:nil];
    NSString * removeIcons = [TiUtils stringValue:@"removeIcons" properties:args def:nil];
    UIImage *image = [self findImage:shareImage];
    NSArray *activityItems = [NSArray arrayWithObjects:shareText,image , nil];
    
    UIActivityViewController *avc = [[UIActivityViewController alloc] initWithActivityItems: activityItems applicationActivities:nil];
    
    //custom icons
    if(removeIcons != nil){
        NSMutableArray * excludedIcons = [self activityIcons:removeIcons];
        [avc setExcludedActivityTypes:excludedIcons];
    }
    
    [avc setCompletionHandler:^(NSString *act, BOOL done)
     {
         if (!done) {
             NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:NUMBOOL(NO),@"success",nil];
             [self fireEvent:@"cancelled" withObject:event];
         } else {
             NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:NUMBOOL(YES),@"success",nil];
             [self fireEvent:@"complete" withObject:event];
         }   
     }];
    
    [[TiApp app] showModalController:avc animated:YES];
}


-(void)activityPopover:(id)args
{
    if(![TiUtils isIPad]){
        NSLog(@"[ERROR] activityPopover is iPad Only feature");
        return;
    }
    
    ENSURE_UI_THREAD(activityPopover, args);
    ENSURE_SINGLE_ARG_OR_NIL(args, NSDictionary);
    
    if(popoverController.popoverVisible){
        [popoverController dismissPopoverAnimated:YES];
        return;
    }
    
    //get the properties from javascript
    NSString * shareText = [TiUtils stringValue:@"text" properties:args def:@""];
    NSString * shareImage = [TiUtils stringValue:@"image" properties:args def:nil];
    NSString * removeIcons = [TiUtils stringValue:@"removeIcons" properties:args def:nil];
    NSArray * passthroughViews = [args objectForKey:@"passthroughViews"];
    UIBarButtonItem * senderButton = [args objectForKey:@"view"];
    
    if(senderButton == nil){
        NSLog(@"[ERROR] You must specify a source button - property: view");
        return;
    }
    UIImage *image = [self findImage:shareImage];
    NSArray *activityItems = [NSArray arrayWithObjects:shareText,image , nil];
    
    UIActivityViewController *avc = [[UIActivityViewController alloc] initWithActivityItems: activityItems applicationActivities:nil];
    
    //custom icons
    if(removeIcons != nil){
        NSMutableArray * excludedIcons = [self activityIcons:removeIcons];
        [avc setExcludedActivityTypes:excludedIcons];
    }
    
    [avc setCompletionHandler:^(NSString *act, BOOL done)
     {
         if (!done) {
             NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:NUMBOOL(NO),@"success",nil];
             [self fireEvent:@"cancelled" withObject:event];
         } else {
             NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:NUMBOOL(YES),@"success",nil];
             [self fireEvent:@"complete" withObject:event];
         }
     }];
    
    //popOver
    popoverController = [[UIPopoverController alloc] initWithContentViewController:avc];
    if(passthroughViews != nil){
        [self setPassthroughViews:passthroughViews];
    }
    [popoverController presentPopoverFromBarButtonItem:senderButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

-(void)setPassthroughViews:(id)args
{
    NSMutableArray* views = [NSMutableArray arrayWithCapacity:[args count]];
    for (TiViewProxy* proxy in args) {
        if (![proxy isKindOfClass:[TiViewProxy class]]) {
            [self throwException:[NSString stringWithFormat:@"Passed non-view object %@ as passthrough view",proxy] subreason:nil location:CODELOCATION];
        }
        [views addObject:[proxy view]];
    }
    [popoverController setPassthroughViews:views];
}

-(NSMutableArray *)activityIcons:(NSString *)removeIcons
{
    NSDictionary *iconMapping = @{
                                  @"twitter": UIActivityTypePostToTwitter,
                                  @"facebook": UIActivityTypePostToFacebook,
                                  @"mail": UIActivityTypeMail,
                                  @"sms": UIActivityTypeMessage,
                                  @"copy": UIActivityTypeCopyToPasteboard,
                                  @"contact": UIActivityTypeAssignToContact,
                                  @"weibo": UIActivityTypePostToWeibo,
                                  @"print": UIActivityTypePrint,
                                  @"camera": UIActivityTypeSaveToCameraRoll
                                  
                                  };
    
    NSArray *icons = [removeIcons componentsSeparatedByString:@","];
    NSMutableArray *excludedIcons = [[NSMutableArray alloc] init];
    for( int i = 0; i < [icons count]; i++ )
    {
        NSString * str = [icons objectAtIndex:i];
        [excludedIcons addObject:[iconMapping objectForKey:str]];
    }
    return excludedIcons;
    
}
@end