/*************************************************************************************
 * Created By: Peter Yao
 *
 * Description: Shows login history for portal users so we don't have to give the running user "Manage User"
 *
 * Tested By: PortalLoginHistoryControllerTest
 *************************************************************************************/

public without sharing class PortalLoginHistoryController {
    private Map<String, UserHistory> userLoginMap;
    public Datetime beginDate {get;set;}
    public Boolean showDetail {get;set;}
    public Boolean showLoginProfile {get;set;}
    private Boolean isTest = false;

    public PortalLoginHistoryController() {
        if (ApexPages.currentPage().getParameters().get('isTest') != null) {
            isTest = true;
        }
        if (ApexPages.currentPage().getParameters().get('dayRange') != null) {
            beginDate = DateTime.now() - Integer.valueOf(ApexPages.currentPage().getParameters().get('dayRange'));
        } else {
            beginDate = DateTime.now() - 30;
        }

        userLoginMap = new Map<String, UserHistory>();
        showDetail = false;
        showLoginProfile = false;
        List<AggregateResult> loginHistory =
            [SELECT UserId, Status, DAY_ONLY(convertTimezone(LoginTime)) date, COUNT(id) cnt
             FROM LoginHistory
             WHERE LoginType = 'Chatter Communities External User'
             AND LoginTime > :beginDate
             GROUP BY UserId, status, DAY_ONLY(convertTimezone(LoginTime))
             ORDER BY userid, DAY_ONLY(convertTimezone(LoginTime)) desc];

        Set<Id> userIds = new Set<Id>();
        for (AggregateResult ar : loginHistory) {
            userIds.add((Id) ar.get('UserId'));
        }
        Map<Id, User> userMap = new Map<Id, User>([SELECT Id, Name, FirstName, LastName, Profile.Name
                                                   FROM User
                                                   WHERE Id = : userIds
                                                   AND Profile.Name like 'Partner Community%'
                                                   AND IsActive = true]);
        for (User u : userMap.values()) {
            UserHistory uh = new UserHistory(u);
            userLoginMap.put(u.Name, uh);
        }

        for (AggregateResult ar : loginHistory) {
            UserHistory uh = userLoginMap.get((String) userMap.get((Id) ar.get('UserId')).Name);
            uh.addLogin(new Login((String) ar.get('status'),
                                   (Date) ar.get('date'),
                                   (Integer) ar.get('cnt')));
        }

        if (isTest) {
            for (Integer i = 0; i < 65; i++) {
                userLoginMap.put('Test User ' + i, fakeUH('Test', 'User', i));
            }
        }
    }

    public static List<Profile> profiles = [SELECT Id, Name FROM PROFILE WHERE Name like 'Partner Community%'];
    public UserHistory fakeUH(String first, String last, Integer i) {
        User u = new User(FirstName = first,
                          LastName = last + ' ' + i,
                          Profile = profiles[Math.mod(i, profiles.size())]);
        UserHistory uh = new UserHistory(u);
        for (Integer j = 0; j < 30; j++) {
            uh.addLogin(new Login('Success',
                                  (beginDate + j).date(),
                                  Math.round(Math.random()*10)));
            uh.addLogin(new Login('Invalid Password',
                                  (beginDate + j).date(),
                                  Math.round(Math.random()*5)));
        }
        return uh;
    }

    // Used when displaying the groupings, and data
    public List<UserHistory> getUsers() {
        List<UserHistory> uhList = userLoginMap.values();
        uhList.sort();
        List<UserHistory> prunedUHList = new List<UserHistory>();
        for (UserHistory uh : uhList) {
            if (showLoginProfile && uh.profileName.startsWith('Partner Community Login')) {
                prunedUHList.add(uh);
            } else if (!showLoginProfile && uh.profileName.startsWith('Partner Community User')) {
                prunedUHList.add(uh);
            }
        }
        return prunedUHList;
    }

    // Used to pass data to google charts
    public String getUsersAsJSON() {
        List<UserHistory> uhList = userLoginMap.values();
        uhList.sort();
        List<UserHistory> prunedUHList = new List<UserHistory>();
        for (UserHistory uh : uhList) {
            if (showLoginProfile && uh.profileName.startsWith('Partner Community Login')) {
                prunedUHList.add(uh);
            } else if (!showLoginProfile && uh.profileName.startsWith('Partner Community User')) {
                prunedUHList.add(uh);
            }
        }
        return JSON.serialize(prunedUHList);
    }

    public class UserHistory implements Comparable {
        public String name {get;set;}
        public String profileName {get;set;}
        public Integer totalSuccesses {get;set;}
        private Map<Date, Login> logins;

        public UserHistory(User u) {
            this.name = u.FirstName + ' ' + u.LastName;
            this.profileName = u.Profile.Name;
            this.totalSuccesses = 0;
            this.logins = new Map<Date, Login>();
        }

        public void addLogin(Login l) {
            this.totalSuccesses += l.success;
            if (logins.get(l.loginDate) == null) {
                logins.put(l.loginDate, l);
            } else {
                logins.get(l.loginDate).updateLoginStatusCount(l);
            }
        }

        public List<Login> getLoginHistory() {
            return logins.values();
        }

        // Sorts by total successes ascending
        public Integer compareTo(Object compareTo) {
            UserHistory compareToUH = (UserHistory) compareTo;

            Integer returnValue = 0;
            if (this.totalSuccesses > compareToUH.totalSuccesses) {
                returnValue = 1;
            } else if (this.totalSuccesses < compareToUH.totalSuccesses) {
                returnValue = -1;
            }

            return returnValue;
        }
    }

    public class Login {
        public Date loginDate {get;set;}
        public Integer success {get;set;}
        public Integer noAccess {get;set;}
        public Integer passwordLockout {get;set;}
        public Integer invalidPassword {get;set;}
        public Integer inactive {get;set;}
        public Integer unsuccessful {get;set;}

        public Login(String status, Date loginDate, Integer count) {
            this.loginDate = loginDate;
            this.success = 0;
            this.noAccess = 0;
            this.passwordLockout = 0;
            this.invalidPassword = 0;
            this.inactive = 0;
            this.unsuccessful = 0;
            if (status == 'Success') {
                this.success = count;
            } else if (status == 'No Community Access') {
                this.noAccess = count;
            } else if (status == 'Password Lockout') {
                this.passwordLockout = count;
            } else if (status == 'Invalid Password') {
                this.invalidPassword = count;
            } else if (status == 'User Is Inactive') {
                this.inactive = count;
            } else {
                Logger.logNow('PortalLoginHistoryController', 'Login', 'Unhandled failure type: ' + status);
            }
        }

        public void updateLoginStatusCount(Login l) {
            this.success += l.success;
            this.noAccess += l.noAccess;
            this.passwordLockout += l.passwordLockout;
            this.invalidPassword += l.invalidPassword;
            this.inactive += l.inactive;
            this.unsuccessful += l.noAccess + l.passwordLockout + l.invalidPassword + l.inactive;
        }
    }

}
