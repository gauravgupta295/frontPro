//PPA Phase 2: DP-1025
public with sharing class PPA_SeedDataForAddSubmitterGrp {

    public static void addUserstoGrp() {
        List<GroupMember> groupMemberList = new List<GroupMember>();
        Map<String,String> groupMap = new Map<String,String>();
        Map<String,String> userMap = new Map<String,String>();
        List<String> managersList;
        final string GROUP_NAME_AS = 'PPA_Additional_Submitters';

        //Use test data when test class is running
        if(Test.isRunningTest()) {
            managersList = new List<String>{'0001', '0002'};
        }
        else {
            managersList = new List<String>{'105675','23749','77822','35346','51194','617','34475','27215','35467','62','53256','9707','19818','1655','28604','48604','29656','41922','53373','77025','81018'};
        }
        
        //Create users map
        for (User usr : [SELECT Id, EmployeeNumber FROM User WHERE isActive = true AND EmployeeNumber IN:managersList LIMIT 49999]) {
            userMap.put(usr.EmployeeNumber, usr.Id);
        }
        //Create groups map
        for(Group grp : [SELECT Id, DeveloperName FROM Group WHERE DeveloperName =:GROUP_NAME_AS LIMIT 49999]) {
            groupMap.put(grp.DeveloperName, grp.Id);    
        }
        if(groupMap.size()>0 && userMap.size()>0) {
            for (String emp : managersList) {
                GroupMember grpMem = new GroupMember();
                grpMem.GroupId = groupMap.get(GROUP_NAME_AS);
                grpMem.UserOrGroupId = userMap.get(emp);
                groupMemberList.add(grpMem);
            }
        }
        if(!groupMemberList.isEmpty()) {
            Database.insert(groupMemberList, false);
        }
    }
}