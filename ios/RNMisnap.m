
#import "RNMisnap.h"
#import <RNMisnap/RNMisnap.h>
#import <MiSnapSDK/MiSnapSDK.h>
#import "MiSnapSDKViewControllerUX2.h"
#import "MiSnapSDKViewController.h"
#import "LivenessViewController.h"
#import <MiSnapLiveness/MiSnapLiveness.h>

@interface RNMisnap () <LivenessViewControllerDelegate>

// MiSnap
@property (nonatomic, strong) MiSnapSDKViewController *miSnapController;
@property (nonatomic, strong) NSString *selectedJobType;
@property (strong, nonatomic) MiSnapLivenessCaptureParameters *captureParams;

// Liveness
@property (nonatomic, strong) LivenessViewController *livenessController;

@end

@implementation RNMisnap

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

RCT_EXPORT_MODULE()

RCT_REMAP_METHOD(greet, resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
    NSString *greetText = @"HELLO FROM IOS NATIVE CODE (1.0.5)";
    resolve(greetText);
    // reject([NSError errorWithDomain:@"com.companyname.app" code:0 userInfo:@{ @"text": @"something happend" }]);
}

RCT_EXPORT_METHOD(capture:(NSDictionary *)config resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
    cResolver = resolve;
    cRejecter = reject;
    
    // Bypassing the tutorial views for iDFront an iDBack, as they dirupt the camera view making it black screen.
    
    // [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"MiSnapShowTutorialIdFront"];
    // [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"MiSnapShowTutorialIdBack"];
    
    self.miSnapController = nil;
    self.livenessController = nil;
    
    if ([config[@"captureType"] isEqualToString:@"idFront"]) {
        self.selectedJobType = kMiSnapDocumentTypeCheckFront;
    } else if ([config[@"captureType"] isEqualToString:@"idBack"]) {
        self.selectedJobType = kMiSnapDocumentTypeCheckBack;
    }
    
    self.miSnapController = (MiSnapSDKViewController *)[[UIStoryboard storyboardWithName:@"MiSnapUX2" bundle:nil] instantiateViewControllerWithIdentifier:@"MiSnapSDKViewControllerUX2"];
    
    self.miSnapController.delegate = self;
    [self.miSnapController setupMiSnapWithParams:[self getMiSnapParameters:config]];
    // self.miSnapController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        // transición
    self.miSnapController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;

    // For iOS 13, UIModalPresentationFullScreen is not the default, so be explicit
    self.miSnapController.modalPresentationStyle = UIModalPresentationFullScreen;
    
    if (self.miSnapController != nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
            if (rootViewController != nil) {
                [rootViewController presentViewController:self.miSnapController animated:YES completion:nil ];
            }
        });
    } else {
        //reject(@"400", @"Could not create a misnap controller.", [NSError errorWithDomain:@"com.omni.minsnap" code:0 userInfo:@{ @"text": @"MiSnapSDKViewController controller not created." }]);
    }
}

#pragma mark - <MiSnapViewControllerDelegate>

// Called when an image has been captured in either automatic or manual mode
- (void)miSnapFinishedReturningEncodedImage:(NSString *)encodedImage originalImage:(UIImage *)originalImage andResults:(NSDictionary *)results
{
    UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    if (rootViewController != nil) {
        [rootViewController dismissViewControllerAnimated:YES completion: ^{
            NSMutableDictionary *resultDic = [[NSMutableDictionary alloc] init];
            resultDic[@"base64encodedImage"] = encodedImage;
            resultDic[@"metadata"] = results;
            // [self storeImageToDocumentsDirectory:encodedImage];
            cResolver(resultDic);
        }];
    }
}

- (NSDictionary *)getMiSnapParameters:(NSDictionary *)options
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:[MiSnapSDKViewController defaultParametersForACH]];
    if ([self.selectedJobType isEqualToString:kMiSnapDocumentTypeCheckFront]) { //@"ID_CARD_FRONT"
        parameters = [NSMutableDictionary dictionaryWithDictionary:[MiSnapSDKViewController defaultParametersForCheckFront]];
        [parameters setObject:@"ID Card Front" forKey:kMiSnapShortDescription];
        [parameters setObject:@"0" forKey:kMiSnapTorchMode];
    } else if ([self.selectedJobType isEqualToString:kMiSnapDocumentTypeCheckBack]) { //@"ID_CARD_FRONT"
        parameters = [NSMutableDictionary dictionaryWithDictionary:[MiSnapSDKViewController defaultParametersForCheckBack]];
        [parameters setObject:@"ID Card Back" forKey:kMiSnapShortDescription];
        [parameters setObject:@"0" forKey:kMiSnapTorchMode];
    }
    // External settings
    NSNumber *glare = options[@"glare"];
    NSNumber *contrast = options[@"contrast"];
    NSNumber *imageQuality = options[@"imageQuality"];
    
    NSLog(@"Glare: %@", glare);
    NSLog(@"Contrast: %@", contrast);
    NSLog(@"Quality: %@", imageQuality);
    if (glare != nil) {
        [parameters setObject:glare.stringValue forKey:kMiSnapGlareConfidence];
    }
    if (contrast != nil) {
        [parameters setObject:contrast.stringValue forKey:kMiSnapBackgroundConfidence];
    }
    if (imageQuality != nil) {
        [parameters setObject:imageQuality.stringValue forKey:kMiSnapImageQuality];
    }
    
    // [parameters setObject:@"2" forKey:kMiSnapOrientationMode];
    
    // Must set specific server type and server version
    [parameters setObject:@"test" forKey:kMiSnapServerType];
    [parameters setObject:@"0.0" forKey:kMiSnapServerVersion];
    
    // LanguageOverride forces only English "en". Uncomment this to enforce just English localization.
    // [parameters setObject:@"es" forKey:@"LanguageOverride"];
    [parameters setObject:@"25000" forKey:kMiSnapTimeout];
    [parameters setObject:@"2" forKey:kMiSnapMaxCaptures]; // Shows how to set 3 rather than default 5
    
    if (options[@"autocapture"] == NO) {
        [parameters setObject:@"1" forKey:kMiSnapCaptureMode];
    }
    
    return [parameters copy];
}


@end
