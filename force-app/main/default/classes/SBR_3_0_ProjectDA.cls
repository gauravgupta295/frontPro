/*********************************************************************************************************************
* Apex Class: SBR_3_0_ProjectDA
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Concrete class for Project Data Access
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Kunal Patel           2022-03-18            Initial version    
*********************************************************************************************************************/
public with sharing class SBR_3_0_ProjectDA implements SBR_3_0_ProjectDAInterface {

    private static Set<String> repTypesViewPECProject = new Set<String>{'Industrial Scaffold','Industrial Tool Specialist','Industrial','Power - Industrial','Industrial Pump and Power','Power - Commercial','Pump and Power'};

    public static Map<Id, Project__c> getProjects(Set<Id> ids) {
        return new Map<Id, Project__c>([SELECT Id, Project_Name__c, Latitude_Longitude__c, Street__c, City__c, State__c,
            Zip_Code__c, Country__c, Primary_Project_Type__c FROM Project__c WHERE ID IN: ids ORDER BY Project_Name__c]);
    }

    public static List<Project__c> getProjects() {
        return [SELECT Id, Project_Name__c, Latitude_Longitude__c, Street__c, City__c, State__c,
            Zip_Code__c, Country__c, Primary_Project_Type__c FROM Project__c ORDER BY Project_Name__c];
    }

    public static Project__c getProject(Id id) {
        return [SELECT Id, Project_Name__c, Latitude_Longitude__c, Street__c, City__c, State__c,
            Zip_Code__c, Country__c, Project_Number__c, Primary_Project_Type__c, 
            Latitude_Longitude__Latitude__s, Latitude_Longitude__Longitude__s FROM Project__c WHERE ID =: id];
    }

    public static List<Project__c> getProjectsFiltered(SBR_3_0_GoogleMapCmpController.FilterWrapper wrapper) {

        Boolean includeDodge = false;
        if(String.isNotBlank(wrapper.projectOrigin)){
            List<String> originList = (List<String>) JSON.deserialize(wrapper.projectOrigin, List<String>.class);
            Set<String> originSet = new Set<String>(originList);
            if(originSet.contains('Dodge') || originSet.contains('All')) {
                includeDodge = true;
            }
        }

        Boolean canViewPEC = SBR_3_0_ProjectDA.canUserViewPECProject(UserInfo.getUserId());

        String sQuery = '';// = 'SELECT Id, Project_Name__c, Latitude_Longitude__c, Street__c, City__c, State__c,'
                    //+ ' Zip_Code__c, Country__c, Project_Number__c, Primary_Project_Type__c FROM Project__c WHERE ';


        System.debug('wrapper===>'+wrapper);

        sQuery += '(';

        if(String.isNotBlank(wrapper.projectSearch)) {
            sQuery += 'Project__r.Project_Name__c LIKE \'%' + String.escapeSingleQuotes(wrapper.projectSearch) + '%\' AND ';
        }

        if(wrapper.cityProject == true && String.isNotBlank(wrapper.cityProjectValue)) {
            sQuery += 'Project__r.City__c = \'' + String.escapeSingleQuotes(wrapper.cityProjectValue) + '\' AND ';
        }

        /*if(wrapper.valuationProject == true && String.isNotBlank(wrapper.valuationProjectValue)) {
            sQuery += 'Project__r.Valuation__c = \'' + String.escapeSingleQuotes(wrapper.valuationProjectValue) + '\' AND ';
        }*/

        Decimal defaultValuation = getUsersProjectMinValuation(UserInfo.getUserId());
        if(wrapper.valuationRangeProjects == true && String.isNotBlank(wrapper.valuationRangeProjectsStart) &&
            String.isNotBlank(wrapper.valuationRangeProjectsEnd)) {
            sQuery += 'Project__r.Valuation__c >= ' + String.escapeSingleQuotes(wrapper.valuationRangeProjectsStart) + ' AND Project__r.Valuation__c <= ' + String.escapeSingleQuotes(wrapper.valuationRangeProjectsEnd)
                    + ' AND ';
        }
        else if(wrapper.valuationRangeProjects == true && defaultValuation != null) {
            sQuery += 'Project__r.Valuation__c >= ' + defaultValuation + ' AND ';
        }

        if(String.isNotBlank(wrapper.projectStatus)) {
            sQuery += 'Project__r.Project_Status__c = \'' + wrapper.projectStatus + '\' AND ';
        }

        System.debug('wrapper.projectPrimaryType -> ' + wrapper.projectPrimaryType);
        if(wrapper.projectPrimaryType == 'Default') {
            List<String> primaryTypesList = getUsersProjectDodgeTypes(UserInfo.getUserId());
            Set<String> primaryTypesSet = new Set<String>(primaryTypesList);
            if(!primaryTypesSet.isEmpty()) {
                sQuery += 'Project__r.Primary_Project_Type__c IN ' + inClausify(primaryTypesSet) + ' AND ';
            }
        }
        else if(String.isNotBlank(wrapper.projectPrimaryType)) {
            List<String> primTypesList = (List<String>) JSON.deserialize(wrapper.projectPrimaryType, List<String>.class);
            Set<String> primaryTypesSet = new Set<String>(primTypesList);
            System.debug('primaryTypesSet -> ' + primaryTypesSet);
            if(!primaryTypesSet.isEmpty() && !primaryTypesSet.contains('All')) {
                sQuery += 'Project__r.Primary_Project_Type__c IN ' + inClausify(primaryTypesSet) + ' AND ';
            }
        }

        if(String.isNotBlank(wrapper.projectStage)) {
            sQuery += 'Project__r.Project_Stage__c = \'' + wrapper.projectStage + '\' AND ';
        }

        if(String.isNotBlank(wrapper.projectOrigin)){
            List<String> originList = (List<String>) JSON.deserialize(wrapper.projectOrigin, List<String>.class);
            Set<String> originSet = new Set<String>(originList);
            if(!originSet.isEmpty() && !originSet.contains('All')) {
                sQuery += 'Project__r.Project_Origin__c IN ' + inClausify(originSet) + ' AND ';
            }
        }
        
        if(!canViewPEC) {
            sQuery += 'Project__r.Project_Origin__c != \'PEC\' AND ';
        }

        if(wrapper.projectCreatedDate == 'Today') {
            sQuery += 'Project__r.CreatedDate = TODAY AND ';
        }
        else if(wrapper.projectCreatedDate == 'Last 7 Days') {
            sQuery += 'Project__r.CreatedDate = LAST_N_DAYS:7 AND ';
        }
        else if(wrapper.projectCreatedDate == 'Range' && String.isNotBlank(wrapper.dateRangeCreatedDateProjectsStart) &&
        String.isNotBlank(wrapper.dateRangeCreatedDateProjectsEnd)) {
            sQuery += 'Project__r.CreatedDate >= ' + String.escapeSingleQuotes(wrapper.dateRangeCreatedDateProjectsStart) + 'T00:00:00Z AND Project__r.CreatedDate <= ' + String.escapeSingleQuotes(wrapper.dateRangeCreatedDateProjectsEnd)
                    + 'T00:00:00Z AND ';
        }


        sQuery += ') AND ';
        sQuery = cleanSQuery(sQuery);
        sQuery += '((';

        // Dodge filters below
        if(includeDodge) {

            if(wrapper.projectDodgePhase == 'Default') {
                List<String> primaryPhaseList = getUsersProjectDodgePhases(UserInfo.getUserId());
                Set<String> primaryPhaseSet = new Set<String>(primaryPhaseList);
                if(!primaryPhaseSet.isEmpty()) {
                    sQuery += 'Project__r.Dodge_Phase__c IN ' + inClausify(primaryPhaseSet) + ' AND ';
                }
            }
            else if(String.isNotBlank(wrapper.projectDodgePhase)) {
                List<String> primPhaseList = (List<String>) JSON.deserialize(wrapper.projectDodgePhase, List<String>.class);
                Set<String> primaryPhaseSet = new Set<String>(primPhaseList);
                if(!primaryPhaseSet.isEmpty() && !primaryPhaseSet.contains('All')) {
                    sQuery += 'Project__r.Dodge_Phase__c IN ' + inClausify(primaryPhaseSet) + ' AND ';
                }
            }

            // Bid
            if(wrapper.next30DaysBidDateProject == true) {
                sQuery += 'Project__r.Bid_Date__c = NEXT_N_DAYS:30 AND ';
            }

            if(wrapper.lastXDaysBidDateProject == true && String.isNotBlank(wrapper.lastXDaysBidDateProjectValue)) {
                sQuery += 'Project__r.Bid_Date__c = LAST_N_DAYS:' + String.escapeSingleQuotes(wrapper.lastXDaysBidDateProjectValue) + ' AND ';
            }

            if(wrapper.nextXDaysBidDateProject == true && String.isNotBlank(wrapper.nextXDaysBidDateProjectValue)) {
                sQuery += 'Project__r.Bid_Date__c = NEXT_N_DAYS:' + String.escapeSingleQuotes(wrapper.nextXDaysBidDateProjectValue) + ' AND ';
            }

            if(wrapper.dateRangeBidDateProjects == true && String.isNotBlank(wrapper.dateRangeBidDateProjectsStart) &&
                String.isNotBlank(wrapper.dateRangeBidDateProjectsEnd)) {
                sQuery += 'Project__r.Bid_Date__c >= ' + String.escapeSingleQuotes(wrapper.dateRangeBidDateProjectsStart) + ' AND Project__r.Bid_Date__c <= ' + String.escapeSingleQuotes(wrapper.dateRangeBidDateProjectsEnd)
                        + ' AND ';
            }
            
            if(wrapper.squareFootageRangeProjects == true && String.isNotBlank(wrapper.squareFootageRangeProjectsStart) &&
                String.isNotBlank(wrapper.squareFootageRangeProjectsEnd)) {
                sQuery += 'Project__r.Square_Footage__c >= ' + String.escapeSingleQuotes(wrapper.squareFootageRangeProjectsStart) + ' AND Project__r.Square_Footage__c <= ' + String.escapeSingleQuotes(wrapper.squareFootageRangeProjectsEnd)
                        + ' AND ';
            }
        }

        sQuery += ') OR ';
        sQuery = cleanSQuery(sQuery);
        sQuery += '(';

        // PEC Filters below
        if(canViewPEC){
            if(wrapper.plantIdProject == true && String.isNotBlank(wrapper.plantIdProjectValue)) {
                sQuery += 'Project__r.Plant_ID__c = \'' + String.escapeSingleQuotes(wrapper.plantIdProjectValue) + '\' AND ';
            }

            if(wrapper.plantNameProject == true && String.isNotBlank(wrapper.plantNameProjectValue)) {
                sQuery += 'Project__r.Plant_Name__c = \'' + String.escapeSingleQuotes(wrapper.plantNameProjectValue) + '\' AND ';
            }

            if(String.isNotBlank(wrapper.projectActivity)) {
                sQuery += 'Project__r.Project_Activity__c = \'' + wrapper.projectActivity + '\' AND ';
            }

            if(String.isNotBlank(wrapper.projectTiming)) {
                sQuery += 'Project__r.Project_Timing__c = \'' + wrapper.projectTiming + '\' AND ';
            }


            // Completion
            if(wrapper.next30DaysCompletionDateProject == true) {
                sQuery += 'Project__r.Completion_Date__c = NEXT_N_DAYS:30 AND ';
            }

            if(wrapper.lastXDaysCompletionDateProject == true && String.isNotBlank(wrapper.lastXDaysCompletionDateProjectValue)) {
                sQuery += 'Project__r.Completion_Date__c = LAST_N_DAYS:' + String.escapeSingleQuotes(wrapper.lastXDaysCompletionDateProjectValue) + ' AND ';
            }

            if(wrapper.nextXDaysCompletionDateProject == true && String.isNotBlank(wrapper.nextXDaysCompletionDateProjectValue)) {
                sQuery += 'Project__r.Completion_Date__c = NEXT_N_DAYS:' + String.escapeSingleQuotes(wrapper.nextXDaysCompletionDateProjectValue) + ' AND ';
            }

            if(wrapper.dateRangeCompletionDateProjects == true && String.isNotBlank(wrapper.dateRangeCompletionDateProjectsStart) &&
                String.isNotBlank(wrapper.dateRangeCompletionDateProjectsEnd)) {
                sQuery += 'Project__r.Completion_Date__c >= ' + String.escapeSingleQuotes(wrapper.dateRangeCompletionDateProjectsStart) + ' AND Project__r.Completion_Date__c <= ' + String.escapeSingleQuotes(wrapper.dateRangeCompletionDateProjectsEnd)
                        + ' AND ';
            }

            // Kickoff
            if(wrapper.next30DaysKickoffDateProject == true) {
                sQuery += 'Project__r.Kickoff_Date__c = NEXT_N_DAYS:30 AND ';
            }

            if(wrapper.lastXDaysKickoffDateProject == true && String.isNotBlank(wrapper.lastXDaysKickoffDateProjectValue)) {
                sQuery += 'Project__r.Kickoff_Date__c = LAST_N_DAYS:' + String.escapeSingleQuotes(wrapper.lastXDaysKickoffDateProjectValue) + ' AND ';
            }

            if(wrapper.nextXDaysKickoffDateProject == true && String.isNotBlank(wrapper.nextXDaysKickoffDateProjectValue)) {
                sQuery += 'Project__r.Kickoff_Date__c = NEXT_N_DAYS:' + String.escapeSingleQuotes(wrapper.nextXDaysKickoffDateProjectValue) + ' AND ';
            }

            if(wrapper.dateRangeKickoffDateProjects == true && String.isNotBlank(wrapper.dateRangeKickoffDateProjectsStart) &&
                String.isNotBlank(wrapper.dateRangeKickoffDateProjectsEnd)) {
                sQuery += 'Project__r.Kickoff_Date__c >= ' + String.escapeSingleQuotes(wrapper.dateRangeKickoffDateProjectsStart) + ' AND Project__r.Kickoff_Date__c <= ' + String.escapeSingleQuotes(wrapper.dateRangeKickoffDateProjectsEnd)
                        + ' AND ';
            }

            // AFE
            if(wrapper.next30DaysAFEDateProject == true) {
                sQuery += 'Project__r.AFE_Date__c = NEXT_N_DAYS:30 AND ';
            }

            if(wrapper.lastXDaysAFEDateProject == true && String.isNotBlank(wrapper.lastXDaysAFEDateProjectValue)) {
                sQuery += 'Project__r.AFE_Date__c = LAST_N_DAYS:' + String.escapeSingleQuotes(wrapper.lastXDaysAFEDateProjectValue) + ' AND ';
            }

            if(wrapper.nextXDaysAFEDateProject == true && String.isNotBlank(wrapper.nextXDaysAFEDateProjectValue)) {
                sQuery += 'Project__r.AFE_Date__c = NEXT_N_DAYS:' + String.escapeSingleQuotes(wrapper.nextXDaysAFEDateProjectValue) + ' AND ';
            }

            if(wrapper.dateRangeAFEDateProjects == true && String.isNotBlank(wrapper.dateRangeAFEDateProjectsStart) &&
                String.isNotBlank(wrapper.dateRangeAFEDateProjectsEnd)) {
                sQuery += 'Project__r.AFE_Date__c >= ' + String.escapeSingleQuotes(wrapper.dateRangeAFEDateProjectsStart) + ' AND Project__r.AFE_Date__c <= ' + String.escapeSingleQuotes(wrapper.dateRangeAFEDateProjectsEnd)
                        + ' AND ';
            }

            // RQF
            if(wrapper.next30DaysRQFDateProject == true) {
                sQuery += 'Project__r.RQF_Date__c = NEXT_N_DAYS:30 AND ';
            }

            if(wrapper.lastXDaysRQFDateProject == true && String.isNotBlank(wrapper.lastXDaysRQFDateProjectValue)) {
                sQuery += 'Project__r.RQF_Date__c = LAST_N_DAYS:' + String.escapeSingleQuotes(wrapper.lastXDaysRQFDateProjectValue) + ' AND ';
            }

            if(wrapper.nextXDaysRQFDateProject == true && String.isNotBlank(wrapper.nextXDaysRQFDateProjectValue)) {
                sQuery += 'Project__r.RQF_Date__c = NEXT_N_DAYS:' + String.escapeSingleQuotes(wrapper.nextXDaysRQFDateProjectValue) + ' AND ';
            }

            if(wrapper.dateRangeRQFDateProjects == true && String.isNotBlank(wrapper.dateRangeRQFDateProjectsStart) &&
                String.isNotBlank(wrapper.dateRangeRQFDateProjectsEnd)) {
                sQuery += 'Project__r.RQF_Date__c >= ' + String.escapeSingleQuotes(wrapper.dateRangeRQFDateProjectsStart) + ' AND Project__r.RQF_Date__c <= ' + String.escapeSingleQuotes(wrapper.dateRangeRQFDateProjectsEnd)
                        + ' AND ';
            }
        }

        sQuery += '))';
        sQuery = cleanSQuery(sQuery);

        // Only show Projects within users Analysis Region - start
        Set<Id> ownerIds = new Set<Id>();

        String users = wrapper.userTerritories;
        if(String.isNotBlank(users)) {
            users = users.deleteWhitespace();
            for(String s : users.split(',')) {
                ownerIds.add(s);
            }
        }

        List<User_Location__c> userLocations = SBR_3_0_UserLocationDA.getUserLocation(ownerIds);

        Set<String> analysisRegions = new Set<String>();
        for(User_Location__c ul : userLocations) {
            if(ul.Analysis_Region_Key__c != null) {
                analysisRegions.add(ul.Analysis_Region_Key__c);
            }
        }

        List<Analysis_Region__c> regions = SBR_3_0_AnalysisRegionDA.getAnalysisRegionsByKey(analysisRegions);

        System.debug('analysisRegions -> ' + analysisRegions);

        Set<String> regionNames = new Set<String>();
        for(Analysis_Region__c ar : regions) {
            regionNames.add(ar.Name);
        } 
        //Adding logic to filter records by users territories
        List<Territory__c> usersTerritories = SBR_3_0_TerritoryDA.getTerritories(ownerIds);
        Set<String> userTerritoryIds = new Set<String>(); 
        for(Territory__c territory : usersTerritories) {
            if(territory.Territory_ID__c != null) {
                userTerritoryIds.add(territory.Territory_ID__c);
            }
        }

        String prQuery = 'SELECT ID, Project__c, Project__r.Project_Name__c, Project__r.Latitude_Longitude__c, Project__r.Street__c, Project__r.City__c, Project__r.State__c,'
                        + ' Project__r.Zip_Code__c, Project__r.Country__c, Project__r.Project_Number__c, Project__r.Primary_Project_Type__c FROM Project_Relationship__c'
                        + ' WHERE Territory_ID__c IN ' + inClausify(userTerritoryIds)
                        + ' AND ' + sQuery + ' AND Project__r.Display_on_Map__c INCLUDES ' + inClausify(analysisRegions);

        prQuery = cleanSQuery(prQuery);
        System.debug('prQuery -> ' + prQuery);
        List<Project_Relationship__c> relationships = Database.query(prQuery);
        System.debug('project relationships -> ' + relationships.size());

        // Only show Projects within users Analysis Region - end
        //System.debug('sQuery -> ' + sQuery);

        Set<Id> projectIds = new Set<Id>();
        for(Project_Relationship__c pr : relationships) {
            projectIds.add(pr.Project__c);
        }

        List<Project__c> result = [SELECT Id, Project_Name__c, Latitude_Longitude__c, Street__c, City__c, State__c, Zip_Code__c, Country__c, Project_Number__c, Primary_Project_Type__c 
                                    FROM Project__c WHERE ID IN: projectIds];
        
        return result;
    }

    @AuraEnabled(cacheable = true)
    public static List<String> getUsersProjectDodgeTypes(Id userId) {
        
        List<String> result = new List<String>();
        if(String.isBlank(userId)) { userId = UserInfo.getUserId();}
        User u = SBR_3_0_UserDA.getUserById(userId);
        
        System.debug('UserDetails: ' + userId);
        System.debug('Analysis_Region_Key__c: ' + u.Analysis_Region_Key__c);
        System.debug('Rep_Type__c: ' + u.Rep_Type__c);

        if(String.isNotBlank(u.Analysis_Region_Key__c)) {

            Map_Default_Filter__mdt defaults = getMapDefaultFilter(u.Analysis_Region_Key__c, u.Rep_Type__c);
            if(defaults != null && String.isNotBlank(defaults.Dodge_Types__c)) {

                List<String> typeList = defaults.Dodge_Types__c.split(',');
                Set<String> formattedSet = new Set<String>();
                for(String s : typeList) {
                    s = s.normalizeSpace();
                    s = s.removeEnd(',');
                    s = s.normalizeSpace();
                    formattedSet.add(s);
                }
                return new List<String>(formattedSet);
            }
        }

        return result;
    }

    @AuraEnabled(cacheable = true)
    public static List<String> getUsersProjectDodgePhases(Id userId) {
        
        List<String> result = new List<String>();
        if(String.isBlank(userId)) { userId = UserInfo.getUserId();}
        User u = SBR_3_0_UserDA.getUserById(userId);
        
        if(String.isNotBlank(u.Analysis_Region_Key__c)) {
                                                
            Map_Default_Filter__mdt defaults = getMapDefaultFilter(u.Analysis_Region_Key__c, u.Rep_Type__c);
            if(defaults != null && String.isNotBlank(defaults.Dodge_Phases__c)) {

                List<String> typeList = defaults.Dodge_Phases__c.split(',');
                Set<String> formattedSet = new Set<String>();
                for(String s : typeList) {
                    s = s.normalizeSpace();
                    s = s.removeEnd(',');
                    s = s.normalizeSpace();
                    formattedSet.add(s);
                }
                return new List<String>(formattedSet);
            }
            
        }
        return result;
    }

@AuraEnabled(cacheable = true)
    public static Decimal getUsersProjectMinValuation(Id userId) {
        
        Decimal result;
        if(userId == null) { userId = UserInfo.getUserId();}
        User u = SBR_3_0_UserDA.getUserById(userId);
        
        if(String.isNotBlank(u.Analysis_Region_Key__c)) {
            Map_Default_Filter__mdt defaults = getMapDefaultFilter(u.Analysis_Region_Key__c, u.Rep_Type__c);
            if(defaults != null && defaults.Valuation_Greater_Than__c != null) {
                return defaults.Valuation_Greater_Than__c;
            }
        }
        return result;
    }

    public static Map_Default_Filter__mdt getMapDefaultFilter(String analysisRegionKey, String repType) {

        Map_Default_Filter__mdt result;
        List<Map_Default_Filter__mdt> defaultsList = [SELECT ID, Analysis_Region_Key__c, Rep_Type__c, Dodge_Phases__c, Dodge_Types__c, Valuation_Greater_Than__c
            FROM Map_Default_Filter__mdt WHERE Analysis_Region_Key__c =: analysisRegionKey
            AND Rep_Type__c =: repType LIMIT 1];
            
        if(defaultsList.size() > 0) {
            result = defaultsList[0];
        }
        else {
            defaultsList = [SELECT ID, Analysis_Region_Key__c, Rep_Type__c, Dodge_Phases__c, Dodge_Types__c, Valuation_Greater_Than__c
                FROM Map_Default_Filter__mdt WHERE Analysis_Region_Key__c =: analysisRegionKey
                AND Rep_Type__c = 'All' LIMIT 1];
            
            if(defaultsList.size() > 0) {
                result = defaultsList[0];
            }
        }
        return result;
    }

    @AuraEnabled
    public static Boolean canUserViewPECProject(Id userId) {
        
        User u = SBR_3_0_UserDA.getUserById(userId);
        if(String.isNotBlank(u.Rep_Type__c) && repTypesViewPECProject.contains(u.Rep_Type__c)) {
            return true;
        }
        return false;
    }
    
    public static String inClausify(Set<String> stringSet) {
        String inClause = String.format( '(\'\'{0}\'\')', 
                             new List<String> { String.join( new List<String>(stringSet) , '\',\'') });
        return inClause;
    }

    private static String cleanSQuery(String sQuery){
        sQuery = sQuery.replaceAll('\\(\\) OR', '');
        sQuery = sQuery.replaceAll('OR \\(\\)', '');
        sQuery = sQuery.replaceAll('\\(\\) AND', '');
        sQuery = sQuery.replaceAll('AND \\(\\)', '');
        sQuery = sQuery.replaceAll('AND \\)', ')');
        sQuery = sQuery.replaceAll('OR \\)', ')');
        sQuery = sQuery.replaceAll('AND \\( \\(\\)\\)', ''); // edge cases for no filters
        sQuery = sQuery.replaceAll('AND  \\( \\(\\)\\)', ''); // edge cases for no filters

        return sQuery;
    }
}