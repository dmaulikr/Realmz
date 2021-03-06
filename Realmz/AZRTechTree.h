//
//  AZRTechTree.h
//  Realmz
//
//  Created by Ankh on 01.03.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZRUnifiedResource.h"
#import "AZRTechLoader.h"

@class AZRTechnology, AZRTechResource, AZRInGameResourceManager, AZRGame;
@interface AZRTechTree : NSObject <NSCopying>

@property (nonatomic, weak, readonly) AZRGame *game;
@property (nonatomic, weak) AZRInGameResourceManager *resourceManager;
@property (nonatomic) NSMutableDictionary *technologies;

/*! @brief Instantiating tech tree.*/
+ (instancetype) techTreeForGame:(AZRGame *)game;

- (void) process:(NSTimeInterval)lastTick;

/*! @brief Adding tech to tech tree.*/
- (void) addTech:(AZRTechnology *)technology;
/*! @brief Find tech in tech tree.*/
- (AZRTechnology *) techNamed:(NSString *)techName;
/*! @brief Remove tech from tech tree.*/
- (AZRTechnology *) removeTech:(NSString *)techName;

/*! @brief Returns all techs, groupped by their states. */
- (NSDictionary *) fetchTechStates;

- (NSArray *) fetchTechDependencies:(AZRTechnology *)tech;

- (BOOL) isResourceAvailable:(AZRTechResource *)techResource;

- (BOOL) drainResource:(AZRTechResource *)techResource targeted:(id)target;
- (BOOL) gainResource:(AZRTechResource *)techResource targeted:(id)target;

- (BOOL) implement:(BOOL)implement tech:(NSString *)techName withTarget:(id)target;

@end
