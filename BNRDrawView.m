//
//  BNRDrawView.m
//  TouchTracker
//
//  Created by Peter Molnar on 17/05/2015.
//  Copyright (c) 2015 Peter Molnar. All rights reserved.
//

#import "BNRDrawView.h"
#import "BNRLine.h"
#import "BNRCircle.h"

@interface BNRDrawView() <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIPanGestureRecognizer *moveRecognizer;

@property (nonatomic, strong) NSMutableDictionary *linesInProgress;
@property (nonatomic, strong) NSMutableArray *finishedLines;


@property (nonatomic, strong) NSMutableDictionary *circleInProgress;
@property (nonatomic, strong) NSMutableArray *finishedCircles;

// Could be weak =, since it's just a reference of one of the finishedLine
@property (nonatomic, weak) BNRLine *selectedLine;

@end

@implementation BNRDrawView

- (instancetype) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        self.linesInProgress = [[NSMutableDictionary alloc]init];
        self.finishedLines = [[NSMutableArray alloc]init];
        self.circleInProgress = [[NSMutableDictionary alloc]init];
        self.finishedCircles = [[NSMutableArray alloc]init];
        self.backgroundColor = [UIColor grayColor];
        // Enable mulitouch
        self.multipleTouchEnabled = YES;
        // Add double tap recognizer as clearing the slate.
        UITapGestureRecognizer *doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                              action:@selector(doubleTap:)];
        doubleTapRecognizer.numberOfTapsRequired = 2;
        doubleTapRecognizer.delaysTouchesBegan = YES;
        [self addGestureRecognizer:doubleTapRecognizer];
        //        Single tap recognizer
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
        tapRecognizer.delaysTouchesBegan = YES;
        
        //        Don't catch the DoubleTap's first tap
        [tapRecognizer requireGestureRecognizerToFail:doubleTapRecognizer];
        [self addGestureRecognizer:tapRecognizer];
        
        UILongPressGestureRecognizer *pressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                                      action:@selector(longPress:)];
        [self addGestureRecognizer:pressRecognizer];
        // Adding pinch gr
        UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchIt:)];
        [self addGestureRecognizer:pinchRecognizer];
        
        // Adding pan gesture
        
        self.moveRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveLine:)];
        self.moveRecognizer.delegate = self;
        self.moveRecognizer.cancelsTouchesInView = NO;// In order to prevent the normal tap to trigger it's things.
        [self addGestureRecognizer:self.moveRecognizer];
        
        
        
        [self loadLinesFromFile];
    }
    return self;
}


#pragma mark - saving and loading data
-(void)loadLinesFromFile
{
    NSArray *propertyListArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"mySavedArray"];
    
    for (NSArray *strline in propertyListArray) {
        BNRLine *line = [[BNRLine alloc] init];
        line.begin = CGPointFromString(strline[0]);
        line.end = CGPointFromString(strline[1]);
        [self.finishedLines addObject:line];
    }
    
    [self setNeedsDisplay];
}

-(void)saveLinesToFile
{
    NSMutableArray *propertyListArray = [[NSMutableArray alloc] init];
    
    for (BNRLine *line in self.finishedLines) {
        
        NSArray *strLine = @[NSStringFromCGPoint(line.begin), NSStringFromCGPoint(line.end)];
        
        [propertyListArray addObject:strLine];
    }
    
    
    [[NSUserDefaults standardUserDefaults] setObject:propertyListArray forKey:@"mySavedArray"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    
}


#pragma mark - Drawing and stroking
-(void)strokeLine:(BNRLine *)line
{
    UIBezierPath *bp = [UIBezierPath bezierPath];
    bp.lineWidth = 10;
    bp.lineCapStyle = kCGLineCapRound;
    
    [bp moveToPoint:line.begin];
    [bp addLineToPoint:line.end];
    [bp stroke];
}


-(void)strokeCircle:(BNRCircle *)line
{
    UIBezierPath *bp = [UIBezierPath bezierPath];
    bp.lineWidth = 10;
    
    
    [bp moveToPoint:line.begin];
    [bp addLineToPoint:line.end];
    [bp stroke];
}

-(void)drawRect:(CGRect)rect
{
    
    //    Draw finished lines in black
    for (BNRLine *line in self.finishedLines) {
        UIColor *lineColor = [line setupColorFromAngle];
        [lineColor set];
        [self strokeLine:line];
    }
    
//    [[UIColor redColor]set];
// A little hack to get the lines in progress changing colour
    for (NSValue *key in self.linesInProgress) {
        BNRLine *curLine =self.linesInProgress[key];
        UIColor *lineColor = [curLine setupColorFromAngle];
        [lineColor set];
        [self strokeLine:curLine];
    }
    
    
    if (self.selectedLine) {
        [[UIColor greenColor] set];
        [self strokeLine:self.selectedLine];
    }
    
    //    Not multitouch solutiion
    //    if (self.currentLine) {
    ////        If there is a line currently being drawn, do it in red
    //        [[UIColor redColor] set];
    //        [self strokeLine:self.currentLine];
    //    }
    
//    To test the Time Profiler instrument
    
//    float f=0.0;
//    
//    for (int i=0; i<1000000; i++) {
//        f=f+sin(sin(time(NULL)+i));
//    }
//    NSLog(@"f = %f",f);
}


#pragma mark - Utility functions


- (BNRLine *)lineAtPoint:(CGPoint)p
{
    //     Find a line close to p
    for (BNRLine *l in self.finishedLines) {
        CGPoint start = l.begin;
        CGPoint end = l.end;
        
        //        Check few points on the line
        for (float t = 0.0; t <= 1.0; t +=0.05) {
            float x = start.x + t * (end.x - start.x);
            float y = start.y + t * (end.y - start.y);
            //          If the tapped point is within 20 points let's return this line
            if (hypot(x-p.x, y-p.y) < 20.0) {
                return l;
            }
        }
    }
    //    If nothing close enough
    return nil;
}


-(void)deleteLine:(id)sender
{
    //    REmove the selected line from the list of the finished lines
    [self.finishedLines removeObject:self.selectedLine];
    
    [self setNeedsDisplay];
}

-(BOOL)canBecomeFirstResponder
{
    //    To be able to become first responder and pop up the UIMenu below.
    return YES;
}

#pragma mark - Gesture actions


-(void)doubleTap:(UIGestureRecognizer *)gr
{
    
    [self.linesInProgress removeAllObjects];
    [self.finishedLines removeAllObjects];
    [self setNeedsDisplay];
}



-(void)tap:(UIGestureRecognizer *)gr
{
    
    CGPoint point = [gr locationInView:self];
    
    
    self.selectedLine = [self lineAtPoint:point];
    
    if (self.selectedLine ) {
        
        //    Build a (local) menu
        //    Make ourselves the target of hte item action messages
        [self becomeFirstResponder];
        
        //    Grab the menu controller
        UIMenuController *menu1= [UIMenuController sharedMenuController];
        
        //    Create a new "DElete" menuItem
        UIMenuItem *deleteItem = [[UIMenuItem alloc] initWithTitle:@"Delete"
                                                            action:@selector(deleteLine:)];
        menu1.menuItems = @[deleteItem];
        
        //    Tell the menu where should it appear
        [menu1 setTargetRect:CGRectMake(point.x, point.y, 2, 2) inView:self];
        [menu1 setMenuVisible:YES animated:YES];
    } else {
        //        Hide menu
        
        [[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
        self.selectedLine = nil;
    }
    
    
    [self setNeedsDisplay];
}

-(void)longPress:(UIGestureRecognizer *)gr
{
    //  Long press has more states
    if (gr.state == UIGestureRecognizerStateBegan) {
        CGPoint point = [gr locationInView:self];
        self.selectedLine = [self lineAtPoint:point];
        
        if (self.selectedLine) {
            [self.linesInProgress removeAllObjects];
            
        } else if (gr.state == UIGestureRecognizerStateEnded) {
            self.selectedLine = nil;
            
        }
        
        [self setNeedsDisplay];
        
        
    }
}

-(void)moveLine:(UIPanGestureRecognizer *)gr
{
    //    If we have no selectted line we don't do anything
    if (!self.selectedLine) {
        return;
    }
    
    //    When pan recogizer changes it's position
    if (gr.state == UIGestureRecognizerStateChanged) {
        //    How far was the move:
        CGPoint translation = [gr translationInView:self];
        
        //        Add the transation to the current beginning and the end of the points
        CGPoint begin = self.selectedLine.begin;
        CGPoint end = self.selectedLine.end;
        
        begin.x += translation.x;
        begin.y += translation.y;
        end.x += translation.x;
        end.y += translation.y;
        
        //        Set the new beginnign and the end:
        self.selectedLine.begin = begin;
        self.selectedLine.end = end;
        
        [self setNeedsDisplay];
        
        [gr setTranslation:CGPointZero inView:self];
        
    } else if (gr.state == UIGestureRecognizerStateEnded) {
        self.selectedLine = nil;
        
    }
}

-(void)pinchIt:(UIPinchGestureRecognizer *)pgr
{
    //   CGPoint
    NSLog(@"Pinched");
    
    [self setNeedsDisplay];
}



#pragma mark - Touch events
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.selectedLine = nil;
    int paralellTouches = 0;
    for (UITouch *t in touches) {
        paralellTouches++;
        CGPoint location = [t locationInView:self];
        
        BNRLine *line = [[BNRLine alloc]init];
        line.begin = location;
        line.end = location;
        // Getting the UItouch unique key - holds the address of the UITouch object
        NSValue *key = [NSValue valueWithNonretainedObject:t];
        self.linesInProgress[key] = line;
    }
    
    [self setNeedsDisplay];
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    for (UITouch *t in touches) {
        NSValue *key = [NSValue valueWithNonretainedObject:t];
        BNRLine *line = self.linesInProgress[key];
        
        line.end = [t locationInView:self];
    }
    
    [self setNeedsDisplay];
    
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    for (UITouch *t in touches) {
        NSValue *key = [NSValue valueWithNonretainedObject:t];
        
        BNRLine *line = self.linesInProgress[key];
        
        [self.finishedLines addObject:line];
        [self.linesInProgress removeObjectForKey:key];
    }
    
    
    
    [self setNeedsDisplay];
    [self saveLinesToFile];
}

-(void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    for (UITouch *t in touches) {
        NSValue *key = [NSValue valueWithNonretainedObject:t];
        
        [self.linesInProgress removeObjectForKey:key];
    }
    
    [self setNeedsDisplay];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if (gestureRecognizer == self.moveRecognizer) {
        return YES;
    }
    return NO;
}

@end


