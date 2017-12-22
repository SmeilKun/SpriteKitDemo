//
//  MainScene.m
//  SpriteKitDemo
//
//  Created by HYG on 2017/12/20.
//  Copyright © 2017年 a_kon. All rights reserved.
//

#import "MainScene.h"
#import <AVFoundation/AVFoundation.h>
#import "ResultScene.h"
@interface MainScene ()
@property (nonatomic, copy) NSMutableArray *enemys;
@property (nonatomic, copy) NSMutableArray *weapons;
@property (nonatomic,strong) AVAudioPlayer * bgPlayer;
@property (nonatomic,strong) SKAction * soundAction;
@property (nonatomic,assign) NSInteger count;

@property (nonatomic,strong) SKLabelNode * numLabel;
@end

@implementation MainScene

- (NSMutableArray *)enemys {
    if (!_enemys) {
        _enemys = [NSMutableArray array];
    }
    return _enemys;
}

- (NSMutableArray *)weapons {
    if (!_weapons) {
        _weapons = [NSMutableArray array];
    }
    return _weapons;
}

- (instancetype)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        self.backgroundColor = [SKColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1];
        self.count = 0;
        NSString * bgmPath = [[NSBundle mainBundle] pathForResource:@"dnf_login" ofType:@"mp3"];
        self.bgPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL URLWithString:bgmPath] error:nil];
        self.bgPlayer.numberOfLoops = -1;
        [self.bgPlayer play];

        self.soundAction = [SKAction playSoundFileNamed:@"heat_bg.caf" waitForCompletion:NO];

        self.numLabel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
        self.numLabel.text = @"0";
        self.numLabel.fontSize = 20;
        self.numLabel.fontColor = [SKColor redColor];
        self.numLabel.position = CGPointMake(self.size.width- 40, self.size.height * 0.90);
        [self addChild:self.numLabel];

        //创建一个主角精灵
        SKSpriteNode * player = [SKSpriteNode spriteNodeWithImageNamed:@"player"];
        player.position = CGPointMake(player.size.width / 2.0f, size.height / 2.0f);
        //add
        [self addChild:player];
        //每秒创建一个敌人
        SKAction * actionAddEnemy = [SKAction runBlock:^{
            [self addEnemy];
        }];
        SKAction * actionWait = [SKAction waitForDuration:1];
        [self runAction:[SKAction repeatActionForever:[SKAction sequence:@[actionAddEnemy,actionWait]]]];
    }
    return self;
}

- (void)update:(NSTimeInterval)currentTime {
    NSMutableArray *weaponsToDelete = [[NSMutableArray alloc] init];
    for (SKSpriteNode *weapon in self.weapons) {

        NSMutableArray *enemysToDelete = [[NSMutableArray alloc] init];
        for (SKSpriteNode *enemy in self.enemys) {

            if (CGRectIntersectsRect(weapon.frame, enemy.frame)) {
                [enemysToDelete addObject:enemy];
            }
        }

        for (SKSpriteNode *enemy in enemysToDelete) {
            [self.enemys removeObject:enemy];
            [enemy removeFromParent];

            self.count++;
            self.numLabel.text = [NSString stringWithFormat:@"%ld",(long)self.count];
            if (self.count >= 30) {
                [self changeToResultSceneWithWon:YES];
            }
        }

        if (enemysToDelete.count > 0) {
            [weaponsToDelete addObject:weapon];
        }
    }

    for (SKSpriteNode *weapon in weaponsToDelete) {
        [self.weapons removeObject:weapon];
        [weapon removeFromParent];
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        //1 Set up initial location of projectile
        CGSize winSize = self.size;
        SKSpriteNode *weapon = [SKSpriteNode spriteNodeWithImageNamed:@"weapon"];
        weapon.position = CGPointMake(weapon.size.width/2, winSize.height/2);

        //2 Get the touch location tn the scene and calculate offset
        CGPoint location = [touch locationInNode:self];
        CGPoint offset = CGPointMake(location.x - weapon.position.x, location.y - weapon.position.y);

        // Bail out if you are shooting down or backwards
        if (offset.x <= 0) return;
        // Ok to add now - we've double checked position
        [self addChild:weapon];
        [self.weapons addObject:weapon];

        int realX = winSize.width + (weapon.size.width/2);
        float ratio = (float) offset.y / (float) offset.x;
        int realY = (realX * ratio) + weapon.position.y;
        CGPoint realDest = CGPointMake(realX, realY);

        //3 Determine the length of how far you're shooting
        int offRealX = realX - weapon.position.x;
        int offRealY = realY - weapon.position.y;
        float length = sqrtf((offRealX*offRealX)+(offRealY*offRealY));
        float velocity = self.size.width/1; // projectile speed.
        float realMoveDuration = length/velocity;

        //4 Move projectile to actual endpoint
        SKAction * moveAction = [SKAction moveTo:realDest duration:realMoveDuration];
        SKAction * projectileCaseAction = [SKAction group:@[moveAction,self.soundAction]];
        [weapon runAction:projectileCaseAction completion:^{
            [weapon removeFromParent];
            [self.weapons removeObject:weapon];
        }];
    }
}

//添加敌人
- (void)addEnemy {
    SKSpriteNode * enemy = [SKSpriteNode spriteNodeWithImageNamed:@"enemy"];
    CGSize winSize = self.size;
    int minY = enemy.size.height / 2.0f;
    int maxY = winSize.height - enemy.size.height / 2.0f;
    int rangeY = maxY - minY;
    int y = (arc4random() % rangeY) + minY;

    enemy.position = CGPointMake(winSize.width + enemy.size.width / 2, y);
    [self addChild:enemy];
    [self.enemys addObject:enemy];

    int minDuration = 4.0;
    int maxDuration = 7.0;
    int rangeDuration = maxDuration - minDuration;
    int actualDuration = (arc4random() % rangeDuration) + minDuration;
    SKAction * actionMove = [SKAction moveTo:CGPointMake(-enemy.size.width / 2, y) duration:actualDuration];
    SKAction * actionMoveDone = [SKAction runBlock:^{
        [enemy removeFromParent];
        [self.enemys removeObject:enemy];

        [self changeToResultSceneWithWon:NO];
    }];
    [enemy runAction:[SKAction sequence:@[actionMove,actionMoveDone]]];
}

-(void)changeToResultSceneWithWon:(BOOL)won
{
    [self.bgPlayer stop];
    self.bgPlayer = nil;
    ResultScene *rs = [[ResultScene alloc] initWithSize:self.size won:won];
    SKTransition *reveal = [SKTransition revealWithDirection:SKTransitionDirectionUp duration:1.0];
    [self.scene.view presentScene:rs transition:reveal];
}

@end
