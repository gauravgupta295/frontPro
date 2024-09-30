/********************************************************************************************************************
* Apex Class: SBR_3_0_Get_User_Records_Invocable
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - This class is for getting User records from User Ids or Account Relationship Ids.
* - 
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                        DATE                DETAIL FEATURES
    1.0         Saathvik Tulasi                    09-28-2023             Initial version 
*********************************************************************************************************************/
public class SBR_3_0_Get_User_Records_Invocable {

     /**
     * @description This is a invocable method which is getting invoked from flow- SBR_3_0_Re_rank_Accounts_Analysis_Region
     * @param request 
     */
	@InvocableMethod(
        label = 'Re-rank Account Relationship records'
        description = 'Re-rank Account Relationship records in desc order of TTM'
    )
    Public static void getUserRecords(List<RequetToRerank> request) {
        Map<String,Analysis_Region__c> mAnalysisRegions = new Map<String,Analysis_Region__c>();
		list<User> lUser = new list<User>(); 
        //SF-4102
        list<User> allUser = new list<User>();
        set<String> arkeySet = new set<String>();
        String arkeyValue;
        
        list<String> Ids = request[0].Ids;
        String objectAPIName = request[0].ObjectAPIName;


        list<Analysis_Region__c> lAnalysisRegions = new list<Analysis_Region__c>();
        if(objectAPIName == 'Analysis_Region__c'){
            String analysisRegionQuery =  	'SELECT '+ 
                                            'Id, '+
                                            'Name, '+
            //SF-4102
                							'Company_Code__c, '+
                                            'Analysis_Region_Key__c '+
                                            'FROM '+
                                            'Analysis_Region__c '+
                                            'WHERE '+
                                            'Id IN : Ids ';
            lAnalysisRegions = Database.query(analysisRegionQuery);


            for(Analysis_Region__c oAnalysisRegion : lAnalysisRegions){
                mAnalysisRegions.put(oAnalysisRegion.Analysis_Region_Key__c,oAnalysisRegion);
                arkeySet.add(oAnalysisRegion.Analysis_Region_Key__c + '-' + oAnalysisRegion.Company_Code__c);
            }
            allUser =  	[



                			SELECT
                            Id,
                			Name,
                            Analysis_Region_Key__c,
                		    //SF-4102
                			CompanyName
                            FROM
                            User
                            WHERE
                			Id IN (SELECT User_Account__c FROM Account_Relationship__c WHERE User_Account__c != null) 
                			AND
                            Analysis_Region_Key__c IN : mAnalysisRegions.keySet()
                        ];
            
            for(User u: allUser){
                arkeyValue = u.Analysis_Region_Key__c + '-' + u.CompanyName;
                system.debug('arkeyValue and arkeySet: '+ arkeyValue + '  ' + arkeySet);
                if (arkeySet.contains(arkeyValue)){
                    lUser.add(u);
                }
            }
        }
        else if(objectAPIName == 'User'){
            lUser =  	[
                			SELECT
                            Id,
                			Name,
                            Analysis_Region_Key__c
                            FROM
                            User
                            WHERE
                            Id IN : Ids
                			AND 
                			Id IN (SELECT User_Account__c FROM Account_Relationship__c WHERE User_Account__c != null) 
                		];
        }


        if(!lUser.isEmpty()){
        	Database.executeBatch(new SBR_3_0_AR_Ranking_Batch(lUser,lAnalysisRegions,objectAPIName),1);    
        }
    }
    public class RequetToRerank {
        @InvocableVariable(label='Ids list' required=FALSE)
        public list<String> Ids;
        @InvocableVariable(label='Object API Name' required=FALSE)
        public String ObjectAPIName;
    }
}