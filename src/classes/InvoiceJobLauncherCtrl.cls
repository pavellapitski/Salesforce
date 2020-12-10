/**
 * Created by pavel on 2020-12-02.
 */

public without sharing class InvoiceJobLauncherCtrl {

    public static final String DATE_FORMAT_PATTERN = 'HH:mmaa | MM/dd/yyyy';

    @AuraEnabled
    public static List<String> onInit() {
        String jobName = '%' + InvoiceScheduler.JOB_NAME + '%';
        List<CronTrigger> scheduledJobs = [
            SELECT Id, CronExpression, CronJobDetail.Name, CronJobDetailId, EndTime, NextFireTime, PreviousFireTime, StartTime, State, TimesTriggered
            FROM CronTrigger
            WHERE CronJobDetail.Name LIKE :jobName
            ORDER BY NextFireTime ASC NULLS LAST, PreviousFireTime DESC NULLS LAST
        ];

        System.debug('### scheduledJobs: ' + scheduledJobs);

        Datetime nextJobRun, lastJobRun;
        for (CronTrigger job :scheduledJobs) {
            if (nextJobRun == null || nextJobRun > job.NextFireTime) {
                nextJobRun = job.NextFireTime;
            }
            if (lastJobRun == null || lastJobRun < job.PreviousFireTime) {
                lastJobRun = job.PreviousFireTime;
            }
        }

        String nextJobRunStr = (nextJobRun != null) ? nextJobRun.format(DATE_FORMAT_PATTERN) : 'None',
                lastJobRunStr = (lastJobRun != null) ? lastJobRun.format(DATE_FORMAT_PATTERN) : 'None';
        return new List<String>{nextJobRunStr, lastJobRunStr};
    }

    @AuraEnabled
    public static List<String> launchInvoiceJob(Integer monthIdx) {
        System.debug('### monthIdx: ' + monthIdx);
        String cronExpression = '0 ' + Datetime.now().addMinutes(1).minute() + ' ' +
                Datetime.now().hour() + ' ' +
                System.today().day() + ' ' +
                String.valueOf(monthIdx + 1) + ' ? ' + System.today().year();

        String newJobName = InvoiceScheduler.JOB_NAME + ' ' + Datetime.now().addMinutes(1).format(InvoiceJobLauncherCtrl.DATE_FORMAT_PATTERN);
        System.schedule(newJobName, cronExpression, new InvoiceScheduler());

        return onInit();
    }
}