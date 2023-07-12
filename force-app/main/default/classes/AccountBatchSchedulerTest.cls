@isTest
public with sharing class AccountBatchSchedulerTest {


    @isTest
    static void AccountBatchSchedulerTest(){

        // String CRON_EXP = '0 0 0 10 7 ? 2022';

        Test.startTest();

        // String jobId = System.schedule('test', CRON_EXP, new AccountBatchScheduler());
        // CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        // System.assertEquals(CRON_EXP, ct.CronExpression);
        // System.assertEquals(0, ct.TimesTriggered);
        // System.assertEquals('2022-07-10 00:00:00', String.valueOf(ct.NextFireTime));
        AccountBatchScheduler s = new AccountBatchScheduler();
        s.execute(null);

        Test.stopTest();
    }
}