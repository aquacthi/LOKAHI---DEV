@isTest
public with sharing class BcRequestBatchSchedulerTest {
    
    @isTest
    static void BcRequestBatchSchedulerTest() {
        // String CRON_EXP = '0 0 0 10 7 ? 2022';

        Test.startTest();

        // String jobId = System.schedule('test', CRON_EXP, new BcRequestBatchScheduler());
        // CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        // System.assertEquals(CRON_EXP, ct.CronExpression);
        // System.assertEquals(0, ct.TimesTriggered);
        // System.assertEquals('2022-07-10 00:00:00', String.valueOf(ct.NextFireTime));

        BcRequestBatchScheduler s = new BcRequestBatchScheduler();
        s.execute(null);


        Test.stopTest();
    }
}