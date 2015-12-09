//
//  TapDatas.h
//  OznerBluetooth
//
//  Created by zhiyongxu on 15/3/27.
//  Copyright (c) 2015年 zhiyongxu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CupRawRecord.h"
#import "CupRecord.h"
#import "../Helper/SqlLiteDB.h"
@interface CupRecordList : NSObject
{
    SqlLiteDB* mDB;
    NSString* mIdentifiter;
}
-(id)init:(NSString*)Identifiter;
-(void) AddRecord:(NSArray*)Records;
-(int) GetCurrHourVol;
//取今日数据
-(NSArray*) GetToday;
//获取指定日期开始的日统计数据
-(NSArray*) GetShotItemDay:(NSDate*) Time;
//获取未同步的数据
-(NSArray*) GetNoSyncItenDay:(NSDate*) Time;
//更新同步日期
-(void) SetSyncTime:(NSDate*) Time;
-(CupRecord*)GetTodayItem;
-(CupRecord*)GetRecordByDate:(NSDate*) Time;
-(NSArray*)GetRecordsByDate:(NSDate*) Time;
-(void) LoadReocrds:(NSArray*)dayRecords HourRecords:(NSArray*)hourRecords;
@end
