//
//  ViewController.m
//  HandWritingDigtalClassifier
//
//  Created by Robin Shen on 2020/3/20.
//  Copyright © 2020 Robin Shen. All rights reserved.
//

#import "ViewController.h"
#import <CoreML/CoreML.h>
#import <Vision/Vision.h>
#import "MNISTClassifier.h"
#import "DrawView.h"

@interface ViewController ()

@property (weak,nonatomic) IBOutlet DrawView *drawingView;
@property (weak,nonatomic) IBOutlet UIImageView *imageView;
@property (weak,nonatomic) IBOutlet UILabel *resultLabel;
@property (weak,nonatomic) IBOutlet UILabel *accuracyLabel;
@property (weak,nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.drawingView.strokeColor = [UIColor redColor];
    self.drawingView.strokeWidth = 25.0f;
    self.drawingView.backgroundColor = [UIColor blackColor];
}

- (VNCoreMLRequest *)makeClassificationRequest {
    @try {
        MNISTClassifier *classifier = [[MNISTClassifier alloc] init];
        NSError *error = nil;
        VNCoreMLModel *model = [VNCoreMLModel modelForMLModel:classifier.model error:&error];
        VNCoreMLRequest *request = [[VNCoreMLRequest alloc] initWithModel:model completionHandler:^(VNRequest * _Nonnull request, NSError * _Nullable error) {
            NSArray *observations = request.results;
            if (observations.count>0) {
                VNClassificationObservation *best = [observations firstObject];
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.resultLabel.text = best.identifier;
                    self.accuracyLabel.text = [NSString stringWithFormat:@"%.2f",best.confidence];
                });
            } else {
                NSLog(@"Can't get best result.");
            }
        }];
        return request;
    } @catch (NSException *exception) {
        NSLog(@"Can't load Vision ML model: \(error).");
    }
}

- (void)prodictWithImage:(UIImage *)image {
    [self.loadingIndicator startAnimating];
    NSLog(@"Original Image Size:%f x %f",image.size.width,image.size.height);
    UIImage *garyImage = [self convertToGrayImage:image];
    [self.imageView setImage:garyImage];
    NSLog(@"Converted Image Size:%f x %f",garyImage.size.width,garyImage.size.height);
    CIImage *ciImage = [CIImage imageWithCGImage:garyImage.CGImage];
    VNImageRequestHandler *handler = [[VNImageRequestHandler alloc] initWithCIImage:ciImage options:@{}];
    VNCoreMLRequest *request = [self makeClassificationRequest];
    NSError *error;
    [handler performRequests:@[request] error:&error];
    [self.loadingIndicator stopAnimating];
}

- (UIImage *)convertToGrayImage:(UIImage*)sourceImage {
   int width = 28;
   int height = 28;
   CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
   CGContextRef context = CGBitmapContextCreate(nil,width,height,8,28,colorSpace,kCGImageAlphaNone);
   CGColorSpaceRelease(colorSpace);
   if(context== NULL){
       return nil;
   }
   CGContextDrawImage(context,CGRectMake(0,0, width, height), sourceImage.CGImage);
   CGImageRef grayImageRef = CGBitmapContextCreateImage(context);
   UIImage*grayImage = [UIImage imageWithCGImage:grayImageRef];
   CGContextRelease(context);
   CGImageRelease(grayImageRef);
   return grayImage;
}

- (IBAction)cleanContext:(id)sender {
    [self.drawingView clearDrawing];
    self.drawingView.strokeColor = [UIColor redColor];
    self.drawingView.strokeWidth = 25.0f;
    self.drawingView.backgroundColor = [UIColor blackColor];
    [self.imageView setImage:nil];
    [self.resultLabel setText:@"-"];
    [self.accuracyLabel setText:@"-"];
}

- (IBAction)predictImage:(id)sender {
    UIImage *drawingImage = [self.drawingView imageRepresentation];
    [self prodictWithImage:drawingImage];
}


- (IBAction)takePhoto:(id)sender {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
        [imagePicker setMediaTypes:@[@"public.image"]];
        [imagePicker setSourceType:UIImagePickerControllerSourceTypeCamera];
        [imagePicker setDelegate:self];
        if (@available(iOS 13.0, *)) {
            imagePicker.modalPresentationStyle = UIModalPresentationFullScreen;
        }
        [self presentViewController:imagePicker animated:YES completion:NULL];
    } else {
        UIAlertController *alert = [[UIAlertController alloc] init];
        [alert setTitle:@"出错啦"];
        [alert setMessage:@"不能在模拟器中执行此操作"];
        [alert showViewController:self sender:nil];
    }
}


#pragma mark - UIImagePickerController delegate methods

- (void)navigationController:(UINavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated {
    if ([navigationController isKindOfClass:[UIImagePickerController class]]) {
        viewController.navigationController.navigationBar.translucent = NO;
        viewController.edgesForExtendedLayout = UIRectEdgeNone;
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:NULL];
    picker = nil;
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [self.loadingIndicator startAnimating];
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:@"public.image"]) {
        UIImage *originalImage = [info objectForKey:UIImagePickerControllerOriginalImage];
        [self prodictWithImage:originalImage];
    }
    [picker dismissViewControllerAnimated:YES completion:NULL];
    picker = nil;
}

@end
