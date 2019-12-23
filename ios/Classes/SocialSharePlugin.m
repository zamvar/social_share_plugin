#import "SocialSharePlugin.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKShareKit/FBSDKShareKit.h>

@implementation SocialSharePlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"social_share_plugin"
            binaryMessenger:[registrar messenger]];
  SocialSharePlugin* instance = [[SocialSharePlugin alloc] init];
  [registrar addApplicationDelegate:instance];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

  [[FBSDKApplicationDelegate sharedInstance] application:application
                           didFinishLaunchingWithOptions:launchOptions];
  return YES;
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
            options:
                (NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
  BOOL handled = [[FBSDKApplicationDelegate sharedInstance]
            application:application
                openURL:url
      sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey]
             annotation:options[UIApplicationOpenURLOptionsAnnotationKey]];
  return handled;
}

- (BOOL)application:(UIApplication *)application
              openURL:(NSURL *)url
    sourceApplication:(NSString *)sourceApplication
           annotation:(id)annotation {
  BOOL handled =
      [[FBSDKApplicationDelegate sharedInstance] application:application
                                                     openURL:url
                                           sourceApplication:sourceApplication
                                                  annotation:annotation];
  return handled;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"getPlatformVersion" isEqualToString:call.method]) {
    result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
  } else if ([@"shareToFeedInstagram" isEqualToString:call.method]) {
      NSURL *instagramURL = [NSURL URLWithString:@"instagram://app"];
      if([[UIApplication sharedApplication] canOpenURL:instagramURL]) {
          [self instagramShare:call.arguments[@"path"]];
      } else {
          NSString *instagramLink = @"itms://itunes.apple.com/us/app/apple-store/id389801252?mt=8";
          [[UIApplication sharedApplication] openURL:[NSURL URLWithString:instagramLink]];
      }

      result(nil);
  } else if ([@"shareToFeedFacebook" isEqualToString:call.method]) {
      NSURL *fbURL = [NSURL URLWithString:@"fbapi://"];
      if([[UIApplication sharedApplication] canOpenURL:fbURL]) {
          [self facebookShare:call.arguments[@"path"]];
          result(nil);
      } else {
          NSString *fbLink = @"itms://itunes.apple.com/us/app/apple-store/id284882215?mt=8";
          [[UIApplication sharedApplication] openURL:[NSURL URLWithString:fbLink]];
      }

      result(nil);
    } else if ([@"shareToWhatsapp" isEqualToString:call.method]) {
        if (call.arguments[@"path"] != nil) {
            [self share:call.arguments[@"caption"] path: call.arguments[@"path"]];
            result(nil);
            return;
        }
      NSURL *whatsappURL = [NSURL URLWithString:@"whatsapp://"];
      if([[UIApplication sharedApplication] canOpenURL:whatsappURL]) {
          [self whatsappShare:call.arguments[@"caption"]];
          result(nil);
      } else {
          NSString *fbLink = @"itms://itunes.apple.com/us/app/apple-store/id310633997?mt=8";
          [[UIApplication sharedApplication] openURL:[NSURL URLWithString:fbLink]];
      }
    } else if ([@"share" isEqualToString: call.method]) {
      [self share:call.arguments[@"caption"] path: call.arguments[@"path"]];
      result(nil);
    } else if ([@"shareText" isEqualToString: call.method]) {
      [self share:call.arguments[@"caption"] path: nil];
      result(nil);
  } else {
    result(FlutterMethodNotImplemented);
  }
}

- (void)share:(NSString*)caption  path:(NSString*) path {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray * shareItems = [[NSMutableArray alloc] init];
        if (path != nil) {
            NSURL *url = [NSURL URLWithString:path];
            if ([@[@"png", @"jpg", @"jpeg", @"gif"] containsObject:path.pathExtension]) {
                UIImage * image;
                if ([url.scheme containsString:@"http"]) {
                    NSData *data = [NSData dataWithContentsOfURL:url];
                    image = [[UIImage alloc] initWithData:data];
                } else if ([url.scheme containsString:@"file"]) {
                    image = [[UIImage alloc] initWithContentsOfFile:path];
                }
                if (image != nil) {
                    [shareItems addObject: image];
                } else {
                    [shareItems addObject: url];
                }
            } else {
                [shareItems addObject: url];
            }
        }
        if (caption != nil && caption.length > 0) {
            [shareItems addObject: caption];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            UIActivityViewController *activityViewController =
            [[UIActivityViewController alloc] initWithActivityItems:shareItems
                                              applicationActivities:nil];
            [[UIApplication sharedApplication].delegate.window.rootViewController presentViewController:activityViewController
                                                                                               animated:true
                                                                                             completion:nil];
        });
    });

}

- (void)whatsappShare:(NSString*)caption {
    NSString *string =[NSString stringWithFormat:@"whatsapp://send?text=%@", [caption stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    NSURL *whatsappURL = [NSURL URLWithString: string];
    [[UIApplication sharedApplication] openURL: whatsappURL];
}


- (void)facebookShare:(NSString*)imagePath {
    //NSURL* path = [[NSURL alloc] initWithString:call.arguments[@"path"]];
    FBSDKSharePhoto *photo = [[FBSDKSharePhoto alloc] init];
    photo.image = [[UIImage alloc] initWithContentsOfFile:imagePath];
    FBSDKSharePhotoContent *content = [[FBSDKSharePhotoContent alloc] init];
    content.photos = @[photo];
    UIViewController* controller = [UIApplication sharedApplication].delegate.window.rootViewController;
    [FBSDKShareDialog showFromViewController:controller withContent:content delegate:nil];
}

- (void)instagramShare:(NSString*)imagePath {
    NSError *error = nil;
    [[NSFileManager defaultManager] moveItemAtPath:imagePath toPath:[NSString stringWithFormat:@"%@.igo", imagePath] error:&error];
    NSURL *path = [NSURL URLWithString:[NSString stringWithFormat:@"file://%@.igo", imagePath]];
    dic = [UIDocumentInteractionController interactionControllerWithURL:path];
    dic.UTI = @"com.instagram.exclusivegram";
    if (![dic presentOpenInMenuFromRect:CGRectZero inView:[UIApplication sharedApplication].delegate.window.rootViewController.view animated:TRUE]) {
        NSLog(@"Error sharing to instagram");
    };
}

@end
