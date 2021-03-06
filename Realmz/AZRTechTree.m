//
//  AZRTechTree.m
//  Realmz
//
//  Created by Ankh on 01.03.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZRTechTree.h"
#import "AZRTechnology.h"
#import "AZRInGameResourceManager.h"
#import "AZRInGameResource.h"
#import "AZRGame.h"
#import "AZRRealm.h"
#import "AZRObject+VisibleObject.h"

@implementation AZRTechTree
@synthesize technologies = _technologies;

#pragma mark - Instantiation

+ (instancetype) techTreeForGame:(AZRGame *)game {
	return [[self alloc] initForGame:game];
}

- (id)initForGame:(AZRGame *)game {
	if (!(self = [super init]))
		return self;

	_game = game;
	_technologies = [NSMutableDictionary dictionary];
	return self;
}

- (id) copyWithZone:(NSZone *)zone {
	AZRTechTree *instance = [AZRTechTree techTreeForGame:_game];
	for (AZRTechnology *tech in [_technologies allValues]) {
		AZRTechnology *copy = [tech copy];
    [instance addTech:copy];
	}
	for (AZRTechnology *tech in [_technologies allValues]) {
		AZRTechnology *copy = [instance techNamed:tech.name];
    for (NSValue *holder in tech.requiredTechs) {
			AZRTechnology *required = [holder nonretainedObjectValue];
			[copy addRequired:required.name];
		}
	}
	return instance;
}

#pragma mark - Process

/*!
 @summary Process tech-tree. All techs will be re-calced for their availability, in-process techs will be processed.
 */
- (void) process:(NSTimeInterval)lastTick {
	for (AZRTechnology *tech in [_technologies allValues]) {
		[tech process:lastTick];
	}
}

#pragma mark - Tech management

- (void) addTech:(AZRTechnology *)technology {
	_technologies[technology.name] = technology;
	technology.techTree = self;
}

- (AZRTechnology *) techNamed:(NSString *)techName {
	AZRTechnology *tech = _technologies[techName];
	if (!tech) {
		AZRTechLoader *loader = [AZRTechLoader new];
		tech = [loader loadFromFile:techName];
		if (!tech) {
			[AZRLogger log:NSStringFromClass([self class]) withMessage:@"Failed to load tech %@!", techName];
			return nil;
		}

		[self addTech:tech];
	}

	for (NSString *required in tech.requiredTechsNames) {
    [tech addRequired:required];
	}
	for (AZRTechResource *techResource in [tech getDrained:AZRTechResourceTypeTech]) {
    [self techNamed:techResource.resource];
	}
	for (AZRTechResource *techResource in [tech getGained:AZRTechResourceTypeTech]) {
    [self techNamed:techResource.resource];
	}
	return tech;
}

- (AZRTechnology *) removeTech:(NSString *)techName {
	AZRTechnology *tech = [self techNamed:techName];
	if (tech)
		[_technologies removeObjectForKey:techName];
	return tech;
}

- (NSDictionary *) fetchTechStates {
	NSNumber *normalState = @(AZRTechnologyStateNormal);
	NSArray *states =
	@[
		@(AZRTechnologyStateNotImplementable),
		@(AZRTechnologyStateImplemented),
		@(AZRTechnologyStateUnavailable),
		@(AZRTechnologyStateInProcess),
		];
	NSMutableDictionary *fetch = [NSMutableDictionary dictionary];
	fetch[normalState] = [NSMutableArray array];
	for (NSNumber *state in states) {
    fetch[state] = [NSMutableArray array];
	}
	for (AZRTechnology *tech in [_technologies allValues]) {
    int used = 0;
		for (NSNumber *state in states) {
			AZRTechnologyState stateBit = (AZRTechnologyState)[state integerValue];
			if (TEST_BIT(tech.state, stateBit)) {
				used++;
				[fetch[state] addObject:tech];
			}
		}
		if (!used) {
			[fetch[normalState] addObject:tech];
		}
	}

	return fetch;
}


- (NSArray *) fetchTechDependencies:(AZRTechnology *)tech {
	NSMutableArray *fetch = [NSMutableArray array];
	for (AZRTechnology *testTech in [_technologies allValues]) {
    if ([testTech isDependentOf:tech]) {
			[fetch addObject:testTech];
		}
	}
	return fetch;
}

#pragma mark - Resources

- (BOOL) isResourceAvailable:(AZRTechResource *)techResource {
	switch (techResource.type) {
		case AZRTechResourceTypeResource:
		{
			AZRInGameResource *resource = [_resourceManager resourceNamed:techResource.resource];
			return resource && [resource enoughtResource:techResource.amount];
		}
		case AZRTechResourceTypeTech:
		{
			AZRTechnology *tech = [self techNamed:techResource.resource];
			return tech && [tech isImplemented];
		}
		case AZRTechResourceTypeUnit:
		{
			//TODO: unit resource availablility check
			return NO;
		}
	}
	// unknown resource? O_o
	return NO;
}

- (BOOL) drainResource:(AZRTechResource *)techResource targeted:(id)target {
	switch (techResource.handler) {
		case AZRResourceHandlerOnMap:
			if (!target) {
				return NO;
			}
			break;
		default:
			break;
	}

	switch (techResource.type) {
		case AZRTechResourceTypeResource:
		{
			AZRInGameResource *resource = [_resourceManager resourceNamed:techResource.resource];
			if (resource && [resource enoughtResource:techResource.amount]) {
				[resource addAmount:-techResource.amount];
			} else
				return NO;
			return YES;
		}
		case AZRTechResourceTypeTech:
		{
			AZRTechnology *tech = [self techNamed:techResource.resource];
			if (tech) {
				[tech forceImplemented:NO];
			} else
				return NO;
			return YES;
		}
		default:
			return NO;
	}

	return YES;
}

- (BOOL) gainResource:(AZRTechResource *)techResource targeted:(id)target {
	switch (techResource.handler) {
		case AZRResourceHandlerOnMap:
			if (!target) {
				return NO;
			}
			break;
		default:
			break;
	}

	switch (techResource.type) {
		case AZRTechResourceTypeResource:
		{
			AZRInGameResource *resource = [_resourceManager resourceNamed:techResource.resource];
			if (resource && [resource enoughtResource:techResource.amount]) {
				[resource addAmount:techResource.amount];
			} else
				return NO;
			return YES;
		}
		case AZRTechResourceTypeTech:
		{
			AZRTechnology *tech = [self techNamed:techResource.resource];
			if (tech) {
				[tech forceImplemented:YES];
			} else
				return NO;
			return YES;
		}
		case AZRTechResourceTypeUnit:
		{
			CGPoint pos = [target coordinates];
			[[self.game realm] spawnObject:techResource.resource atX:pos.x andY:pos.y];
			[[self.game realm] killObject:target];
			return YES;
		}
		default:
			return NO;
	}

	return YES;
}

- (BOOL) implement:(BOOL)implement tech:(NSString *)techName withTarget:(id)target {
	AZRTechnology *tech = [self techNamed:techName];
	return tech && [tech implement:implement withTarget:target];
}

@end
