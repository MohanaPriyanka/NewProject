/**
 * Created by PeterYao on 5/2/2021.
 */

public with sharing class SimplePostSandboxRefresher implements SandboxPostCopy {
    public void runApexClass(SandboxContext context) {
        Logger.logNow('SimplePostSandboxRefresher', 'runApexClass', 'Ran!', Logger.ERROR);
    }
}