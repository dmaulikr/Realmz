//
//  AZRGameSpec.m
//  Realmz
//  Spec for AZRGame
//
//  Created by Ankh on 05.03.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "Kiwi.h"

#import "AZRGame.h"
#import "AZRPlayer.h"
#import "AZRPlayerState.h"
#import "AZRRealm.h"
#import "AZRMap.h"
#import "AZRInGameResourceManager.h"
#import "AZRTechTree.h"

SPEC_BEGIN(AZRGameSpec)

describe(@"AZRGame", ^{
	it(@"should properly initialize", ^{
		AZRGame *game = [AZRGame game];
		[[game shouldNot] beNil];
		[[game should] beKindOfClass:[AZRGame class]];
	});

	it(@"should provide unique resource and tech managers", ^{
		AZRGame *game = [AZRGame game];

		AZRInGameResourceManager *manager1 = [game newResourcesManager];
		AZRInGameResourceManager *manager2 = [game newResourcesManager];
		[[manager1 shouldNot] beNil];
		[[manager2 shouldNot] beNil];
		[[manager1 shouldNot] equal:manager2];

		AZRTechTree *techTree1 = [game newTechTree];
		AZRTechTree *techTree2 = [game newTechTree];
		[[techTree1 shouldNot] beNil];
		[[techTree2 shouldNot] beNil];
		[[techTree1 shouldNot] equal:techTree2];
	});
	
	it(@"should manage players", ^{
		AZRGame *game = [AZRGame game];

		AZRPlayer *player1 = [game newPlayer];
		[[player1 shouldNot] beNil];
		[[player1 should] beKindOfClass:[AZRPlayer class]];
		[[player1.game should] equal:game];

		AZRPlayer *player2 = [game newPlayer];
		[[player2 shouldNot] beNil];
		[[player2 should] beKindOfClass:[AZRPlayer class]];

		AZRPlayer *player3 = [game newPlayer];
		[[player3 shouldNot] beNil];
		[[player3 should] beKindOfClass:[AZRPlayer class]];

		[[player1 shouldNot] beIdenticalTo:player2];
		[[player2 shouldNot] beIdenticalTo:player3];
		[[theValue(player1.uid) should] equal:theValue(1)];
		[[theValue(player2.uid) should] equal:theValue(2)];
		[[theValue(player3.uid) should] equal:theValue(3)];

		[[[game getPlayerByUID:2] should] equal:player2];
		[[[game getPlayerByUID:5] should] beNil];
	});

	it(@"should manage game realm", ^{
		AZRGame *game = [AZRGame game];
		AZRRealm *realm = [game realm];
		[[realm shouldNot] beNil];
	});

	it(@"should manage game map", ^{
		AZRGame *game = [AZRGame game];
		[[game.map should] beNil];

		AZRMap *map = [game loadMapNamed:@"map01"];
		[[map shouldNot] beNil];
		[[map should] equal:game.map];
	});

});

SPEC_END
