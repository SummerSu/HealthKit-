//
//  ViewController.m
//  HealthKit
//
//  Created by 孙苏 on 2017/6/2.
//  Copyright © 2017年 sunsu. All rights reserved.
//

#import "ViewController.h"

#import "SSHealthKitHelper.h"

#import <HealthKit/HealthKit.h>

@interface ViewController ()
{
    UILabel * myStep;
    UITextField * addStep;
    UIButton * addBtn;
}


@property (nonatomic,strong) HKHealthStore *healthStore;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    myStep = [[UILabel alloc]initWithFrame:CGRectMake(10, 100, 200, 30)];
    myStep.backgroundColor = [UIColor yellowColor];
    myStep.textColor = [UIColor blackColor];
    myStep.text = @"步数为：";
    
    addStep = [[UITextField alloc]initWithFrame:CGRectMake(10, CGRectGetMaxY(myStep.frame)+10, 100, 30)];
    addStep.backgroundColor = [UIColor cyanColor];
    
    addBtn = [[UIButton alloc]initWithFrame:CGRectMake(10, CGRectGetMaxY(addStep.frame)+10, 100, 30)];
    [addBtn setTitle:@"添加" forState:UIControlStateNormal];
    [addBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [addBtn addTarget:self action:@selector(addStepBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:myStep];
    [self.view addSubview:addStep];
    [self.view addSubview:addBtn];
    

    [self getStepsFromHealthKit];
}


-(HKHealthStore *)healthStore
{
    if (!_healthStore) {
        _healthStore = [[HKHealthStore alloc]init];
    }
    return _healthStore;
}


-(void)addStepBtnClicked
{
    NSLog(@"addStep==%@",addStep.text);
    [self addstepWithStepNum:[addStep.text doubleValue]];
}

//4.获取步数
#pragma mark - 获取步数 刷新界面
- (void)getStepsFromHealthKit{
    HKQuantityType *stepType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    [self fetchSumOfSamplesTodayForType:stepType unit:[HKUnit countUnit] completion:^(double stepCount, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"你的步数为：%.f",stepCount);
            myStep.text = [NSString stringWithFormat:@"步数为：%.f",stepCount];
        });
    }];
}


#pragma mark - 读取HealthKit数据
- (void)fetchSumOfSamplesTodayForType:(HKQuantityType *)quantityType unit:(HKUnit *)unit completion:(void (^)(double, NSError *))completionHandler {
    NSPredicate *predicate = [self predicateForSamplesToday];
    
    HKStatisticsQuery *query = [[HKStatisticsQuery alloc] initWithQuantityType:quantityType quantitySamplePredicate:predicate options:HKStatisticsOptionCumulativeSum completionHandler:^(HKStatisticsQuery *query, HKStatistics *result, NSError *error) {
        HKQuantity *sum = [result sumQuantity];
        if (completionHandler) {
            double value = [sum doubleValueForUnit:unit];
            completionHandler(value, error);
        }
    }];
    [self.healthStore executeQuery:query];
}

#pragma mark - NSPredicate数据模型
- (NSPredicate *)predicateForSamplesToday {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *now = [NSDate date];
    NSDate *startDate = [calendar startOfDayForDate:now];
    NSDate *endDate = [calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:startDate options:0];
    return [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionStrictStartDate];
}

//5.添加步数
#pragma mark - 添加步数
- (void)addstepWithStepNum:(double)stepNum {
    HKQuantitySample *stepCorrelationItem = [self stepCorrelationWithStepNum:stepNum];
    
    [self.healthStore saveObject:stepCorrelationItem withCompletion:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                [self.view endEditing:YES];
                UIAlertView *doneAlertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"添加成功" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
                [doneAlertView show];
                //刷新数据  重新获取步数
                [self getStepsFromHealthKit];
            }else {
                NSLog(@"The error was: %@.", error);
                UIAlertView *doneAlertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"添加失败" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
                [doneAlertView show];
                return ;
            }
        });
    }];
}

#pragma Mark - 获取HKQuantitySample数据模型
- (HKQuantitySample *)stepCorrelationWithStepNum:(double)stepNum {
    NSDate *endDate = [NSDate date];
    NSDate *startDate = [NSDate dateWithTimeInterval:-300 sinceDate:endDate];
    
    HKQuantity *stepQuantityConsumed = [HKQuantity quantityWithUnit:[HKUnit countUnit] doubleValue:stepNum];
    HKQuantityType *stepConsumedType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    
    NSString *strName = [[UIDevice currentDevice] name];
    NSString *strModel = [[UIDevice currentDevice] model];
    NSString *strSysVersion = [[UIDevice currentDevice] systemVersion];
    NSString *localeIdentifier = [[NSLocale currentLocale] localeIdentifier];
    
    HKDevice *device = [[HKDevice alloc] initWithName:strName manufacturer:@"Apple" model:strModel hardwareVersion:strModel firmwareVersion:strModel softwareVersion:strSysVersion localIdentifier:localeIdentifier UDIDeviceIdentifier:localeIdentifier];
    
    HKQuantitySample *stepConsumedSample = [HKQuantitySample quantitySampleWithType:stepConsumedType quantity:stepQuantityConsumed startDate:startDate endDate:endDate device:device metadata:nil];
    
    return stepConsumedSample;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self.view endEditing:YES];
}
@end
