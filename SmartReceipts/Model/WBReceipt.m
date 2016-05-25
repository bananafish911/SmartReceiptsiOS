//
//  WBReceipt.m
//  SmartReceipts
//
//  Created on 18/03/14.
//  Copyright (c) 2014 Will Baumann. All rights reserved.
//

#import <FMDB/FMResultSet.h>
#import "WBReceipt.h"
#import "WBTrip.h"
#import "WBCurrency.h"
#import "Price.h"
#import "PaymentMethod.h"
#import "NSDecimalNumber+WBNumberParse.h"
#import "DatabaseTableNames.h"
#import "Constants.h"
#import "NSDate+Calculations.h"

static NSString* checkNoData(NSString* str) {
    if ([SRNoData caseInsensitiveCompare:str] == NSOrderedSame) {
        return nil;
    }
    return str;
}

@interface WBReceipt ()

@property (nonatomic, strong) NSDate *originalDate;

@end

@implementation WBReceipt
{
    NSString *_fileName;
    NSString *_name, *_category;
    NSString *_extraEditText1, *_extraEditText2, *_extraEditText3;
    NSTimeZone *_timeZone;
}

- (id)initWithId:(NSUInteger)rid
            name:(NSString *)name
        category:(NSString *)category
   imageFileName:(NSString *)imageFileName
            date:(NSDate *)date
    timeZoneName:(NSString *)timeZoneName
         comment:(NSString *)comment
           price:(Price *)price
             tax:(Price *)tax
    isExpensable:(BOOL)isExpensable
      isFullPage:(BOOL)isFullPage
  extraEditText1:(NSString *)extraEditText1
  extraEditText2:(NSString *)extraEditText2
  extraEditText3:(NSString *)extraEditText3 {
    self = [super init];
    if (self) {
        _objectId = rid;
        _name = [name lastPathComponent];
        _category = category;
        _fileName = checkNoData([imageFileName lastPathComponent]);

        _date = date;

        _timeZone = [NSTimeZone timeZoneWithName:timeZoneName];
        if (!_timeZone) {
            _timeZone = [NSTimeZone localTimeZone];
        }

        _comment = comment;
        _price = price;
        _tax = tax;

        _expensable = isExpensable;
        _fullPage = isFullPage;
        _extraEditText1 = checkNoData(extraEditText1);
        _extraEditText2 = checkNoData(extraEditText2);
        _extraEditText3 = checkNoData(extraEditText3);
    }
    return self;
}

-(NSUInteger)receiptId {
    return self.objectId;
}

-(NSString*)imageFileName {
    return _fileName;
}

-(NSTimeZone*)timeZone {
    if (_timeZone) {
        return _timeZone;
    }
    return [NSTimeZone localTimeZone];
}

-(NSString*)category {
    return _category;
}

- (NSString *)priceAsString {
    return self.price.amountAsString;
}

- (NSString *)taxAsString {
    return self.tax.amountAsString;
}

- (NSDecimalNumber *)priceAmount {
    return self.price.amount;
}

- (NSDecimalNumber *)tax_as_nsdecnum {
    return self.tax.amount;
}

//TODO jaanus: check where it's called
- (WBCurrency *)currency {
    return self.price.currency;
}

- (BOOL)dateChanged {
    return ![self.date isEqualToDate:self.originalDate];
}

- (void)setDate:(NSDate *)date {
    _date = date;

    if (!self.originalDate) {
        [self setOriginalDate:date];
    }
}


-(NSString*)extraEditText1 {
    return _extraEditText1;
}

-(NSString*)extraEditText2 {
    return _extraEditText2;
}

-(NSString*)extraEditText3 {
    return _extraEditText3;
}

-(void)setImageFileName:(NSString*)imageFileName{
    _fileName = [imageFileName lastPathComponent];
}

-(NSString*)imageFilePathForTrip:(WBTrip*)trip {
    if (!_fileName) {
        return nil;
    }
    return [[trip directoryPath] stringByAppendingPathComponent:_fileName];
}

- (BOOL)hasFileForTrip:(WBTrip *)trip {
    SRAssert(trip);
    return _fileName && ([[NSFileManager defaultManager] fileExistsAtPath:[self imageFilePathForTrip:trip]]);
}

-(BOOL)fileHasExtension:(NSArray*) possibleExtensions {
    NSString* ext = [_fileName pathExtension];
    for (NSString* pe in possibleExtensions) {
        if ([pe caseInsensitiveCompare:ext]==NSOrderedSame) {
            return true;
        }
    }
    return false;
}

- (BOOL)hasImage {
    return [self hasFileForTrip:self.trip] && [self hasImageFileName];
}

- (BOOL)hasPDF {
    return [self hasFileForTrip:self.trip] && [self hasPDFFileName];
}

-(BOOL)hasImageFileName {
    return [self fileHasExtension:@[@"jpg",@"jpeg",@"png"]];
}

-(BOOL)hasPDFFileName {
    return [self fileHasExtension:@[@"pdf"]];
}

- (NSString *)priceWithCurrencyFormatted {
    return self.price.currencyFormattedPrice;
}

- (NSString *)taxWithCurrencyFormatted {
    return self.tax.currencyFormattedPrice;
}

-(BOOL)hasExtraEditText1 {
    return _extraEditText1 != nil;
}

-(BOOL)hasExtraEditText2 {
    return _extraEditText2 != nil;
}

-(BOOL)hasExtraEditText3 {
    return _extraEditText3 != nil;
}

- (void)loadDataFromResultSet:(FMResultSet *)resultSet {
    NSDecimalNumber *price = [NSDecimalNumber decimalNumberOrZero:[resultSet stringForColumn:ReceiptsTable.COLUMN_PRICE]];
    NSDecimalNumber *tax = [NSDecimalNumber decimalNumberOrZero:[resultSet stringForColumn:ReceiptsTable.COLUMN_TAX]];
    NSDecimalNumber *exchangeRate = [NSDecimalNumber decimalNumberOrZero:[resultSet stringForColumn:ReceiptsTable.COLUMN_EXCHANGE_RATE]];
    NSString *currencyCode = [resultSet stringForColumn:ReceiptsTable.COLUMN_ISO4217];

    NSString *receiptIdAsName = [NSString stringWithFormat:@"%@_%@", ReceiptsTable.TABLE_NAME, ReceiptsTable.COLUMN_ID];
    [self setObjectId:(NSUInteger) [resultSet intForColumn:receiptIdAsName]];
    _name = [resultSet stringForColumn:ReceiptsTable.COLUMN_NAME];
    _category = [resultSet stringForColumn:ReceiptsTable.COLUMN_CATEGORY];
    _fileName = [resultSet stringForColumn:ReceiptsTable.COLUMN_PATH];
    _comment = [resultSet stringForColumn:ReceiptsTable.COLUMN_COMMENT];
    _price = [Price priceWithAmount:price currencyCode:currencyCode];
    _price.exchangeRate = exchangeRate;
    _tax = [Price priceWithAmount:tax currencyCode:currencyCode];
    _tax.exchangeRate = exchangeRate;
    [self setExpensable:[resultSet boolForColumn:ReceiptsTable.COLUMN_EXPENSEABLE]];
    [self setFullPage:![resultSet boolForColumn:ReceiptsTable.COLUMN_NOTFULLPAGEIMAGE]];
    _extraEditText1 = [resultSet stringForColumn:ReceiptsTable.COLUMN_EXTRA_EDITTEXT_1];
    _extraEditText2 = [resultSet stringForColumn:ReceiptsTable.COLUMN_EXTRA_EDITTEXT_2];
    _extraEditText3 = [resultSet stringForColumn:ReceiptsTable.COLUMN_EXTRA_EDITTEXT_3];
    _timeZone = [NSTimeZone timeZoneWithName:[resultSet stringForColumn:ReceiptsTable.COLUMN_TIMEZONE]];
    [self setDate:[NSDate dateWithMilliseconds:[resultSet longLongIntForColumn:ReceiptsTable.COLUMN_DATE]]];
    [self setTripName:[resultSet stringForColumn:ReceiptsTable.COLUMN_PARENT]];
    
    NSString *paymentMethodIdAsName = [NSString stringWithFormat:@"%@_%@", PaymentMethodsTable.TABLE_NAME, PaymentMethodsTable.COLUMN_ID];
    NSUInteger paymentMethodId = [resultSet intForColumn:paymentMethodIdAsName];
    NSString *paymentMethodName = [resultSet stringForColumn:PaymentMethodsTable.COLUMN_METHOD];
    if (paymentMethodName) {
        [self setPaymentMethod:[[PaymentMethod alloc] initWithId:paymentMethodId method:paymentMethodName]];
    }
}

- (BOOL)isEqual:(id)other {
    if (other == self) {
        return YES;
    }
    if (!other || ![[other class] isEqual:[self class]]) {
        return NO;
    }

    WBReceipt *otherReceipt = other;
    return self.objectId == otherReceipt.objectId;
}

- (NSUInteger)hash {
    return @(self.objectId).hash;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"name: %@, ", self.name];
    [description appendFormat:@"date: %@", self.date];
    [description appendString:@">"];
    return description;
}

- (NSString *)attachmentMarker {
    if (self.hasImage) {
        return NSLocalizedString(@"receipt.attachment.marker.image", nil);
    } else if (self.hasPDF) {
        return NSLocalizedString(@"receipt.attachment.marker.pdf", <#comment#>);
    }

    return @"";
}

@end
