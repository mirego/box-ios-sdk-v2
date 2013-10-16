//
//  BoxCocoaSDK.m
//  BoxCocoaSDK
//
//  Created on 7/29/13.
//  Copyright (c) 2013 Box. All rights reserved.
//
//  NOTE: this file is a mirror of BoxSDK/BoxSDK.m. Changes made here should be reflected there.
//

#import "BoxCocoaSDK.h"
#import "BoxSDKConstants.h"
#import "BoxOAuth2Session.h"
#import "BoxSerialOAuth2Session.h"
#import "BoxSerialAPIQueueManager.h"

@implementation BoxCocoaSDK
@synthesize APIBaseURL = _APIBaseURL;
@synthesize OAuth2Session = _OAuth2Session;
@synthesize queueManager = _queueManager;
@synthesize foldersManager = _foldersManager;
@synthesize filesManager = _filesManager;
@synthesize usersManager = _usersManager;

#pragma mark - Globally accessible API singleton instance
+ (BoxCocoaSDK *)sharedSDK
{
    static dispatch_once_t pred;
    static BoxCocoaSDK *sharedBoxSDK;
    
    dispatch_once(&pred, ^{
        sharedBoxSDK = [[BoxCocoaSDK alloc] init];
        
        [sharedBoxSDK setAPIBaseURL:BoxAPIBaseURL];
        
        // the circular reference between the queue manager and the OAuth2 session is necessary
        // because the OAuth2 session enqueues API operations to fetch access tokens and the queue
        // manager uses the OAuth2 session as a lock object when enqueuing operations.
        sharedBoxSDK.queueManager = [[BoxParallelAPIQueueManager alloc] init];
        sharedBoxSDK.OAuth2Session = [[BoxParallelOAuth2Session alloc] initWithClientID:nil
                                                                                 secret:nil
                                                                             APIBaseURL:BoxAPIBaseURL
                                                                           queueManager:sharedBoxSDK.queueManager];
        
        sharedBoxSDK.queueManager.OAuth2Session = sharedBoxSDK.OAuth2Session;
        
        sharedBoxSDK.filesManager = [[BoxFilesResourceManager alloc] initWithAPIBaseURL:BoxAPIBaseURL OAuth2Session:sharedBoxSDK.OAuth2Session queueManager:sharedBoxSDK.queueManager];
        sharedBoxSDK.filesManager.uploadBaseURL = BoxAPIUploadBaseURL;
        sharedBoxSDK.filesManager.uploadAPIVersion = BoxAPIUploadAPIVersion;
        
        sharedBoxSDK.foldersManager = [[BoxFoldersResourceManager alloc] initWithAPIBaseURL:BoxAPIBaseURL OAuth2Session:sharedBoxSDK.OAuth2Session queueManager:sharedBoxSDK.queueManager];

        sharedBoxSDK.usersManager = [[BoxUsersResourceManager alloc] initWithAPIBaseURL:BoxAPIBaseURL OAuth2Session:sharedBoxSDK.OAuth2Session queueManager:sharedBoxSDK.queueManager];

    });
    
    return sharedBoxSDK;
}

- (void)setAPIBaseURL:(NSString *)APIBaseURL
{
    _APIBaseURL = APIBaseURL;
    self.OAuth2Session.APIBaseURLString = APIBaseURL;
    
    // managers
    self.filesManager.APIBaseURL = APIBaseURL;
    self.foldersManager.APIBaseURL = APIBaseURL;
    self.usersManager.APIBaseURL = APIBaseURL;
}

/*
- (BoxFolderPickerViewController *)folderPickerWithRootFolderID:(NSString *)rootFolderID
                                              thumbnailsEnabled:(BOOL)thumbnailsEnabled
                                           cachedThumbnailsPath:(NSString *)cachedThumbnailsPath
                                           fileSelectionEnabled:(BOOL)fileSelectionEnabled;
{
    return [[BoxFolderPickerViewController alloc] initWithSDK:self rootFolderID:rootFolderID thumbnailsEnabled:thumbnailsEnabled cachedThumbnailsPath:cachedThumbnailsPath fileSelectionEnabled:fileSelectionEnabled];
}
*/

// Load the resources bundle.
+ (NSBundle *)resourcesBundle
{
    static NSBundle* frameworkBundle = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        NSString* mainBundlePath = [[NSBundle mainBundle] resourcePath];
        NSString* frameworkBundlePath = [mainBundlePath stringByAppendingPathComponent:@"BoxSDKResources.bundle"];
        frameworkBundle = [NSBundle bundleWithPath:frameworkBundlePath];
    });
    return frameworkBundle;
}

@end
