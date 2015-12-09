//
//  TapDatas.m
//  OznerBluetooth
//
//  Created by zhiyongxu on 15/3/27.
//  Copyright (c) 2015年 zhiyongxu. All rights reserved.
//

#import "CupRecordList.h"


@implementation CupRecordList

-(id)init:(NSString*) Address 
{
    if (self=[super init])
    {
        self->mIdentifiter=[[NSString alloc]initWithString:Address];
        self->mDB=[[SqlLiteDB alloc] init:@"CupDB" Version:2];
        [self->mDB ExecSQLNonQuery:@"CREATE TABLE IF NOT EXISTS DayDateTable (Id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, Identifiter VARCHAR NOT NULL, Time INTEGER NOT NULL, JSON TEXT NOT NULL, UpdateFlag BOOLEAN NOT NULL)" params:NULL];
        
        [self->mDB ExecSQLNonQuery:@"CREATE TABLE IF NOT EXISTS HourDateTable (Id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, Identifiter VARCHAR NOT NULL, Time INTEGER NOT NULL, JSON TEXT NOT NULL)" params:NULL];
        
        NSDate* time=[[NSDate alloc]initWithTimeIntervalSinceNow:0];
        //小时表只保存当天数据，隔天删除
        int t=(int)([time timeIntervalSince1970]-86400)/86400*86400;
        NSString* sql=[[NSString alloc] initWithFormat:@"delete from HourDateTable where Time<%d",t];
        [mDB ExecSQLNonQuery:sql params:nil];
    }
    return self;
}
-(CupRecord*) lastDay
{
    NSArray* data=[mDB ExecSQL:@"select Id,Time,JSON from DayDateTable where Identifiter=? order by time desc limit 1;" params:[NSArray arrayWithObject:mIdentifiter]];
    if ([data count]>0)
    {
        NSDate* time=[[NSDate alloc] initWithTimeIntervalSince1970: [[[data objectAtIndex:0] objectAtIndex:1] intValue]];
        CupRecord* item= [[CupRecord alloc] initWithJSON:time JSON:[[data objectAtIndex:0] objectAtIndex:2]];
        item.Id=[[[data objectAtIndex:0] objectAtIndex:0] intValue];
        return item;
    }else
        return NULL;
}

-(CupRecord*) lastHour
{
    NSArray* data=[mDB ExecSQL:@"select Id,Time,JSON from HourDateTable where Identifiter=? order by time desc limit 1;" params:[NSArray arrayWithObject:mIdentifiter]];
    if ([data count]>0)
    {
        NSDate* time=[[NSDate alloc] initWithTimeIntervalSince1970: [[[data objectAtIndex:0] objectAtIndex:1] intValue]];
        CupRecord* item= [[CupRecord alloc] initWithJSON:time JSON:[[data objectAtIndex:0] objectAtIndex:2]];
        item.Id=[[[data objectAtIndex:0] objectAtIndex:0] intValue];
        return item;
    }else
        return NULL;
}
-(void) LoadReocrds:(NSArray*)dayRecords HourRecords:(NSArray*)hourRecords
{
    [mDB ExecSQLNonQuery:@"delete from DayDateTable where Identifiter=?" params:[NSArray arrayWithObject:mIdentifiter]];
    [mDB ExecSQLNonQuery:@"delete from HourDateTable where Identifiter=?" params:[NSArray arrayWithObject:mIdentifiter]];
    
    
    for (CupRecord* CupRecord in dayRecords) {
        [mDB ExecSQLNonQuery:@"insert into DayDateTable (Identifiter,Time,JSON,UpdateFlag) values (?,?,?,1);"
                      params:[NSArray arrayWithObjects:mIdentifiter
                              ,[[NSString alloc] initWithFormat:@"%d",(int)[CupRecord.Time timeIntervalSince1970]]
                              ,[CupRecord json],nil]];
    }
    
    for (CupRecord* CupRecord in hourRecords) {
        [mDB ExecSQLNonQuery:@"insert into HourDateTable (Identifiter,Time,JSON) values (?,?,?);"
                      params:[NSArray arrayWithObjects:mIdentifiter
                              ,[[NSString alloc] initWithFormat:@"%d",(int)[CupRecord.Time timeIntervalSince1970]]
                              ,[CupRecord json],nil]];
    }
}
-(void) AddRecord:(NSArray*)CupRecords
{
    CupRecord* lastHour=[self lastHour];  //取小时表最后一条数据
    CupRecord* lastDay=[self lastDay]; //去日表最后一条数据
    if (!lastHour)            //如果没有数据初始化一个
        lastHour=[[CupRecord alloc] init];
    if (!lastDay)
        lastDay=[[CupRecord alloc] init];
    
    int hour=(int)[lastHour.Time timeIntervalSince1970]/3600;  //取整数小时
    int day=(int)[lastDay.Time timeIntervalSince1970]/86400;  //去整数日
    BOOL dayChange=NO;
    BOOL hourChange=NO;
    //循环
    for (CupRawRecord* item in CupRecords) {
        int inv= [item.time timeIntervalSince1970];
        if ((int)inv/3600==hour)
        {
            lastHour.Vol+=item.Vol;//如果数据和小时数据一样，把量累加
            [lastHour incTDS:item.TDS];
            [lastHour incTemp:item.Temperature];
            hourChange=YES;
        }else
        {
            if (hourChange) //如果小时不一样，看上次没有有改过数据，如果有数据更新到数据库中
            {
                NSString* sql= @"Update HourDateTable set JSON=? where Id=?;";
                [mDB ExecSQL:sql params:[NSArray arrayWithObjects:
                                         [lastHour json],
                                         [[NSString alloc] initWithFormat:@"%d",lastHour.Id],nil]];
            }
            
            lastHour=[[CupRecord alloc] init];
            hour=inv/3600;
            lastHour.Time=[NSDate dateWithTimeIntervalSince1970:hour*3600];
            lastHour.Vol=item.Vol;
            [lastHour incTDS:item.TDS];
            [lastHour incTemp:item.Temperature];
            ///吧新建的数据在数据库中加一条
            NSString* sql=@"Insert into HourDateTable (Identifiter,Time,JSON) Values (?,?,?);";
            if ([mDB ExecSQL:sql params:[NSArray arrayWithObjects:mIdentifiter
                                         ,[[NSString alloc] initWithFormat:@"%d",(int)[lastHour.Time timeIntervalSince1970]]
                                         ,[lastHour json], nil]])
            {
                ///拿到加的那条数据ID
                lastHour.Id=[[mDB ExecSQLOneRet:@"select LAST_INSERT_ROWID();" params:nil] intValue];
            }
            hourChange=YES;
        }
        
        if ((int)inv/86400==day)
        {
            lastDay.Vol+=item.Vol;
            [lastDay incTDS:item.TDS];
            [lastDay incTemp:item.Temperature];
            dayChange=YES;
        }else
        {
            if (dayChange)
            {
                NSString* sql= @"Update DayDateTable set JSON=?,UpdateFlag=0 where Id=?;";
                [mDB ExecSQL:sql params:[NSArray arrayWithObjects:
                                         [lastDay json],
                                         [[NSString alloc] initWithFormat:@"%d",lastDay.Id],nil]];
                
            }
            
            
            lastDay=[[CupRecord alloc] init];
            day=inv/86400;
            lastDay.Time=[NSDate dateWithTimeIntervalSince1970: day*86400];
            lastDay.Vol=item.Vol;
            [lastDay incTDS:item.TDS];
            [lastDay incTemp:item.Temperature];
            ///吧新建的数据在数据库中加一条
            NSString* sql=@"Insert into DayDateTable (Identifiter,Time,JSON,UpdateFlag) Values (?,?,?,0);";
            if ([mDB ExecSQL:sql params:[NSArray arrayWithObjects:mIdentifiter
                                         ,[[NSString alloc] initWithFormat:@"%d",(int)[lastDay.Time timeIntervalSince1970]]
                                         ,[lastDay json],nil]])
            {
                ///拿到加的那条数据ID
                lastDay.Id=[[mDB ExecSQLOneRet:@"select LAST_INSERT_ROWID();" params:nil] intValue];
            }
            
            dayChange=YES;
        }
    }
    ///如果前面循环有数据变更，更新下数据库
    if (hourChange)
    {
        NSString* sql= @"Update HourDateTable set JSON=? where Id=?;";
        [mDB ExecSQL:sql params:[NSArray arrayWithObjects:
                                 [lastHour json],
                                 [[NSString alloc] initWithFormat:@"%d",lastHour.Id],nil]];
    }
    if (dayChange)
    {
        NSString* sql= @"Update DayDateTable set JSON=?,UpdateFlag=0 where Id=?;";
        [mDB ExecSQL:sql params:[NSArray arrayWithObjects:
                                 [lastDay json],
                                 [[NSString alloc] initWithFormat:@"%d",lastDay.Id]
                                 ,nil]];
    }
    
}

//去当前整数小时的喝水了量
-(int) GetCurrHourVol
{
    CupRecord* lastHour=[self lastHour];
    if (lastHour)
    {
        if ([lastHour.Time timeIntervalSinceNow]>3600)
            return 0;
        else
            return lastHour.Vol;
    }else
        return 0;
}
-(CupRecord *)GetTodayItem
{
    NSDate* time=[NSDate dateWithTimeIntervalSinceNow:0];
    return [self GetRecordByDate:time];
}
-(CupRecord *)GetRecordByDate:(NSDate *)Time
{
    int start=(int)[Time timeIntervalSince1970]/86400*86400;
    NSString* sql=[[NSString alloc] initWithFormat:@"select Id,Time,JSON from DayDateTable where Identifiter=? and Time=%d;",start];
    NSArray* ret=[mDB ExecSQL:sql params:[NSArray arrayWithObject:mIdentifiter]];
    for (NSArray* row in ret)
    {
        NSDate* time=[[NSDate alloc] initWithTimeIntervalSince1970: [[row objectAtIndex:1] intValue]];
        CupRecord* item=[[CupRecord alloc] initWithJSON:time JSON:[row objectAtIndex:2]];
        item.Id=[[row objectAtIndex:0] intValue];
        return item;
    }
    return nil;
}
-(NSArray*)GetRecordsByDate:(NSDate *)Time
{
    NSMutableArray* rets=[[NSMutableArray alloc] init];
    int start=(int)[Time timeIntervalSince1970]/86400*86400;
    NSString* sql=[[NSString alloc] initWithFormat:@"select Id,Time,JSON from DayDateTable where Identifiter=? and Time>=%d;",start];
    NSArray* ret=[mDB ExecSQL:sql params:[NSArray arrayWithObject:mIdentifiter]];
    for (NSArray* row in ret)
    {
        NSDate* time=[[NSDate alloc] initWithTimeIntervalSince1970: [[row objectAtIndex:1] intValue]];
        CupRecord* item=[[CupRecord alloc] initWithJSON:time JSON:[row objectAtIndex:2]];
        item.Id=[[row objectAtIndex:0] intValue];
        [rets addObject:item];
    }
    return rets;
}
//获取今日的饮水数据
-(NSArray*) GetToday
{
    NSMutableArray* rets=[[NSMutableArray alloc] init];
    NSDate* t=[[NSDate alloc] initWithTimeIntervalSinceNow:0];
    int start=(int)[t timeIntervalSince1970]/86400*86400;
    int end=(int)[t timeIntervalSince1970]+86400/86400*86400;
    NSString* sql=[[NSString alloc] initWithFormat:@"select Id,Time,JSON from HourDateTable where Identifiter=? and (Time between %d and %d);",start,end];
    NSArray* ret=[mDB ExecSQL:sql params:[NSArray arrayWithObject:mIdentifiter]];
    for (NSArray* row in ret)
    {
        NSDate* time=[[NSDate alloc] initWithTimeIntervalSince1970: [[row objectAtIndex:1] intValue]];
        CupRecord* item=[[CupRecord alloc] initWithJSON:time JSON:[row objectAtIndex:2]];
        item.Id=[[row objectAtIndex:0] intValue];
        [rets addObject:item];
    }
    return rets;
}

-(NSArray*) GetNoSyncItenDay:(NSDate*) Time
{
    NSMutableArray* rets=[[NSMutableArray alloc] init];
    NSString* sql=[NSString stringWithFormat:@"select Id,Time,JSON from DayDateTable where Identifiter=? and Time>=%d and UpdateFlag=0",
                   (int)[Time timeIntervalSince1970]];
    
    NSArray* ret=[mDB ExecSQL:sql params:[NSArray arrayWithObjects:mIdentifiter, nil]];
    
    for (NSArray* row in ret)
    {
        NSDate* time=[[NSDate alloc] initWithTimeIntervalSince1970: [[row objectAtIndex:1] intValue]];
        CupRecord* item=[[CupRecord alloc] initWithJSON:time JSON:[row objectAtIndex:2]];
        item.Id=[[row objectAtIndex:0] intValue];
        [rets addObject:item];
    }
    
    return rets;
}

-(NSArray*) GetShotItemDay:(NSDate*) Time
{
    NSMutableArray* rets=[[NSMutableArray alloc] init];
    NSString* sql=@"select Id,Time,JSON from DayDateTable where Identifiter=? and Time>=?";
    NSArray* ret=[mDB ExecSQL:sql params:[NSArray arrayWithObjects:mIdentifiter,(uint)[Time timeIntervalSince1970], nil]];
    for (NSArray* row in ret)
    {
        NSDate* time=[[NSDate alloc] initWithTimeIntervalSince1970: [[row objectAtIndex:1] intValue]];
        CupRecord* item=[[CupRecord alloc] initWithJSON:time JSON:[row objectAtIndex:2]];
        item.Id=[[row objectAtIndex:0] intValue];
        [rets addObject:item];
    }
    return rets;
}

-(void) SetSyncTime:(NSDate*) Time
{
    NSString* sql=[NSString stringWithFormat:@"update DayDateTable set UpdateFlag=1 where Identifiter=? and Time<=%d",(int)[Time timeIntervalSince1970]];
    [mDB ExecSQLNonQuery:sql params:[NSArray arrayWithObjects:mIdentifiter, nil]];
}
@end
