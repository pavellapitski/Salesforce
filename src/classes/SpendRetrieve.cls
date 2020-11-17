/**
 * Created by Pavel Lapitski on 2019-10-30.
 */

public class SpendRetrieve implements Schedulable {

    private StrikeDataAPI.PackageType packageType { get; set; }

    public SpendRetrieve(StrikeDataAPI.PackageType packageType) {
        this.packageType = packageType;
    }

    public void execute(SchedulableContext sc) {
        run(packageType.name());
    }

    @Future(Callout=true) // to avoid "Callout from scheduled Apex not supported."
    public static void run(String packageTypeName) {
        Map<String, Utility.SpendAssignResult> assignResults = SpendManager.assignSpends(packageTypeName);
        System.debug('### JOB assignResults: ' + assignResults);
        SpendRetrieveNotification.sendErrorNotification(packageTypeName);
    }
}