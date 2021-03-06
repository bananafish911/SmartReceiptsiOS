//
//  PaymentMethod.h
//  SmartReceipts
//
//  Created by Jaanus Siim on 29/04/15.
//  Copyright (c) 2015 Will Baumann. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FetchedModel.h"
#import "Pickable.h"

@interface PaymentMethod : NSObject <FetchedModel, Pickable>

@property (nonatomic, assign) NSUInteger objectId;
@property (nonatomic, copy) NSString *method;

- (id)initWithId:(NSUInteger) objectId method:(NSString *)method;

@end
