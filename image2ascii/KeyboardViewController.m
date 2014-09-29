//
//  KeyboardViewController.m
//  image2ascii
//
//  Created by SangChan on 2014. 9. 25..
//  Copyright (c) 2014년 sangchan. All rights reserved.
//

#import "KeyboardViewController.h"

@interface KeyboardViewController () {
    UIBezierPath *bezierPath;
    UIImage *lastDrawImage;
    NSMutableArray *undoStack;
    NSMutableArray *redoStack;
    CGPoint lastTouchPoint;
    BOOL firstMovedFlg;
    
    CGPoint touchPoint;
}
@property (nonatomic, strong) UIButton *nextKeyboardButton;
@property (nonatomic, strong) UIButton *redoBtn;
@property (nonatomic, strong) UIButton *undoBtn;
@property (nonatomic, strong) UIButton *clearBtn;
@property (nonatomic, strong) UIImageView *canvas;

@end

@implementation KeyboardViewController


- (void)updateViewConstraints {
    [super updateViewConstraints];
    
    // Add custom view sizing constraints here
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UIView *xibView = [[[NSBundle mainBundle] loadNibNamed:@"KeyboardView" owner:self options:nil] objectAtIndex:0];
    [self.view addSubview:xibView];
    for (UIView* temp_v in xibView.subviews) {
        switch (temp_v.tag) {
            case 10:
                self.canvas = (UIImageView *)temp_v;
                break;
            case 5:
                self.nextKeyboardButton = (UIButton *)temp_v;
                break;
            case 4:
                [((UIButton *)temp_v) addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
                break;
                
            default:
                break;
        }
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated
}

- (void)textWillChange:(id<UITextInput>)textInput {
    // The app is about to change the document's contents. Perform any preparation here.
}

- (void)textDidChange:(id<UITextInput>)textInput {
    // The app has just changed the document's contents, the document context has been updated.
    
    UIColor *textColor = nil;
    if (self.textDocumentProxy.keyboardAppearance == UIKeyboardAppearanceDark) {
        textColor = [UIColor whiteColor];
    } else {
        textColor = [UIColor blackColor];
    }
    [self.nextKeyboardButton setTitleColor:textColor forState:UIControlStateNormal];
}

static NSString * characterMap = @" .,;_-`*";
- (NSString *)getRGBAsFromImage:(UIImage*)image atX:(int)xx andY:(int)yy count:(int)count
{
    
    NSMutableString * characterResult = [[NSMutableString alloc] initWithCapacity:count];
    
    // First get the image into your data buffer
    CGImageRef imageRef = [image CGImage];
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *rawData = malloc(height * width * 4);
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    
    // Now your rawData contains the image data in the RGBA8888 pixel format.
    int byteIndex = (bytesPerRow * yy) + xx * bytesPerPixel;
    for (int ii = 0 ; ii < count ; ++ii)
    {
        
        int r = rawData[byteIndex] & 0xff;
        int g = (rawData[byteIndex] >> 8 ) & 0xff;
        int b = (rawData[byteIndex] >> 16 ) & 0xff;
        
        byteIndex += 4;
        NSInteger characterIndex =  7 - (((int)(r+g+b)/3)>>5) & 0x7 ;
        NSRange range;
        range.location = characterIndex;
        range.length = 1;
        NSString * resultCharacter = [characterMap substringWithRange:range];
        [characterResult appendString:resultCharacter];
        
    }
    
    free(rawData);
    
    return characterResult;
}

#pragma mark - Private
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    // 터치한 좌표를 가져옴
    CGPoint currentPoint = [[touches anyObject] locationInView:self.canvas];
    
    // Path 초기화
    bezierPath = [UIBezierPath bezierPath];
    bezierPath.lineCapStyle = kCGLineCapRound;
    bezierPath.lineWidth = 5.0;
    [bezierPath moveToPoint:currentPoint];
    firstMovedFlg = NO;
    
    // 터치한 좌표를 전역 변수에 저장
    lastTouchPoint = currentPoint;
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    // Path가 초기화 완료되어 인스턴스화 되어 있지 않으면 이벤트 종료
    if (bezierPath == nil){
        return;
    }
    
    // 터치한 좌표를 가져옴
    CGPoint currentPoint = [[touches anyObject] locationInView:self.canvas];
    
    // 최초 이동일 경우, 스킵함
    if (!firstMovedFlg){
        firstMovedFlg = YES;
        lastTouchPoint = currentPoint;
        return;
    }
    
    // 중심점의 좌표를 가져옴
    CGPoint middlePoint = CGPointMake((lastTouchPoint.x + currentPoint.x) / 2,
                                      (lastTouchPoint.y + currentPoint.y) / 2);
    
    // Path에 중심점과 마지막 터치 좌표를 추가함.
    [bezierPath addQuadCurveToPoint:middlePoint controlPoint:lastTouchPoint];
    
    // 선 그림
    [self drawLine:bezierPath];
    
    // 터치한 좌표를 전역 변수에 저장
    lastTouchPoint = currentPoint;
    
    NSLog(@"bezierPath is %@",  NSStringFromCGRect(CGPathGetBoundingBox(bezierPath.CGPath)));
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    // Path가 초기화 완료되어 인스턴스화 되어 있지 않으면 이벤트 종료
    if (bezierPath == nil){
        return;
    }
    
    // 터치한 좌표를 가져옴
    CGPoint currentPoint = [[touches anyObject] locationInView:self.canvas];
    
    // Path에 좌표를 추가함
    [bezierPath addQuadCurveToPoint:currentPoint controlPoint:lastTouchPoint];
    
    
    
    // 선을 그림
    [self drawLine:bezierPath];
    
    // 이번에 그린 이미지를 저장함.
    lastDrawImage = self.canvas.image;
    
    // undo용 Path를 저장하고, redo 스택은 클리어함.
    [undoStack addObject:bezierPath];
    [redoStack removeAllObjects];
    bezierPath = nil;
    
    // 버튼을 사용가능하게 함.
    self.undoBtn.enabled = YES;
    self.redoBtn.enabled = NO;
}

- (void)drawLine:(UIBezierPath*)path
{
    // 이미지가 그려질 영역을 생성함
    UIGraphicsBeginImageContextWithOptions(self.canvas.frame.size, NO, 0.0);
    
    // 이미지 영역에 기존에 그린 이미지가 있다면 화면에 그림.
    [lastDrawImage drawAtPoint:CGPointZero];
    
    // 색 지정
    [[UIColor redColor] setStroke];
    
    // 선을 그림
    [path stroke];
    
    // 그린 이미지를 canvas 에 세팅하고 화면에 표시함.
    self.canvas.image = UIGraphicsGetImageFromCurrentImageContext();
    
    // 그리기 종료
    UIGraphicsEndImageContext();
}

- (void)buttonPressed:(id)sender
{
    UIImage *dummyImage = [self imageWithImage:self.canvas.image scaledToSize:CGSizeMake(32, 32)];
    NSInteger imgWidth = dummyImage.size.width;
    NSInteger imgHeight = dummyImage.size.height;
    
    NSMutableString * resultString = [[NSMutableString alloc] initWithCapacity:imgWidth * imgHeight];
    
    for ( int i = 0; i < imgHeight; i++) {
        NSString * line = [self getRGBAsFromImage:dummyImage atX:0 andY:i count:imgWidth];
        [resultString appendString:line];
        [resultString appendString:@"\n"];
        
    }
    NSLog(@"\n%@",resultString);
    [self.textDocumentProxy insertText:resultString];
}

- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@end
