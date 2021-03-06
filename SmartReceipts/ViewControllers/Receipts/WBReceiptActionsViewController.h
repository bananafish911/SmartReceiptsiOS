//
//  WBReceiptActionsViewController.h
//  SmartReceipts
//
//  Created on 18/03/14.
//  Copyright (c) 2014 Will Baumann. All rights reserved.
//

#import "WBReceiptsViewController.h"

#import "WBReceipt.h"

#import <QuickLook/QuickLook.h>

@interface WBReceiptActionsViewController : UITableViewController <UIDocumentInteractionControllerDelegate>

@property (nonatomic, weak) WBReceiptsViewController *receiptsViewController;
@property (nonatomic, strong) WBReceipt *receipt;

- (IBAction)actionDone:(id)sender;

@end
