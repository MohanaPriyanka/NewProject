/**
 * Created by peteryao on 7/28/20.
 * Tested By: CapacitySnapshotServiceTest
 */

public without sharing class CapacitySnapshotScheduler implements Schedulable{
    private static CapacitySnapshotService snapshotService = new CapacitySnapshotService();
    public void execute(SchedulableContext param1) {
        try {
            snapshotService.createSnapshots();
        } catch (Exception e) {
            Logger.logNow('CapacitySnapshotScheduler', 'execute', e.getMessage() + '\n' + e.getStackTraceString(), Logger.ERROR);
        }
    }
}