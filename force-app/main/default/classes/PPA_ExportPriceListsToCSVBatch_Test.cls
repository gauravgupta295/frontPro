@isTest
public class PPA_ExportPriceListsToCSVBatch_Test {

    @TestSetup
    public static void testSetup(){
        PPA_ExportPriceListsUtility_Test.createTestData();
        loadExportCSVKey();
        loadCustomSettings();
    }

    public static void loadExportCSVKey() {
        Id rentalRecTypeId = [SELECT Id FROM RecordType WHERE sObjectType = 'PPA_Export_CSV_Key__c' AND DeveloperName = 'PPA_Rental'].Id;
        Id transRecTypeId = [SELECT Id FROM RecordType WHERE sObjectType = 'PPA_Export_CSV_Key__c' AND DeveloperName = 'PPA_Transportation'].Id;
        Id truckRecTypeId = [SELECT Id FROM RecordType WHERE sObjectType = 'PPA_Export_CSV_Key__c' AND DeveloperName = 'PPA_TruckType'].Id;
        
        List<PPA_Export_CSV_Key__c> keys = [SELECT Id FROM PPA_Export_CSV_Key__c];

        if(keys.size() == 0) {
            // Rental
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=rentalRecTypeId,PPA_CompanyId__c='01',PPA_Region__c='1',PPA_Export_Region__c='1'));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=rentalRecTypeId,PPA_CompanyId__c='01',PPA_Region__c='2',PPA_Export_Region__c='200'));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=rentalRecTypeId,PPA_CompanyId__c='01',PPA_Region__c='3',PPA_Export_Region__c='300'));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=rentalRecTypeId,PPA_CompanyId__c='01',PPA_Region__c='4',PPA_Export_Region__c='400'));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=rentalRecTypeId,PPA_CompanyId__c='01',PPA_Region__c='5',PPA_Export_Region__c='500'));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=rentalRecTypeId,PPA_CompanyId__c='01',PPA_Region__c='6',PPA_Export_Region__c='600'));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=rentalRecTypeId,PPA_CompanyId__c='01',PPA_Region__c='7',PPA_Export_Region__c='700'));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=rentalRecTypeId,PPA_CompanyId__c='01',PPA_Region__c='8',PPA_Export_Region__c='800'));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=rentalRecTypeId,PPA_CompanyId__c='01',PPA_Region__c='9',PPA_Export_Region__c='900'));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=rentalRecTypeId,PPA_CompanyId__c='01',PPA_Region__c='10',PPA_Export_Region__c='10',PPA_Exclude_National__c=true));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=rentalRecTypeId,PPA_CompanyId__c='01',PPA_Region__c='11',PPA_Export_Region__c='11'));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=rentalRecTypeId,PPA_CompanyId__c='01',PPA_Region__c='12',PPA_Export_Region__c='12'));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=rentalRecTypeId,PPA_CompanyId__c='01',PPA_Region__c='14',PPA_Export_Region__c='14'));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=rentalRecTypeId,PPA_CompanyId__c='02',PPA_Region__c='20',PPA_Export_Region__c='20'));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=rentalRecTypeId,PPA_CompanyId__c='02',PPA_Region__c='21',PPA_Export_Region__c='21'));

            // Truck Type
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=truckRecTypeId,PPA_Truck_Type__c='Pickup / Stakebody',PPA_Export_Class__c='A;Y'));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=truckRecTypeId,PPA_Truck_Type__c='Rollback',PPA_Export_Class__c='C;Z'));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=truckRecTypeId,PPA_Truck_Type__c='Tractor',PPA_Export_Class__c='E'));

            // Transportation
            // Union
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=transRecTypeId,PPA_CompanyId__c='01',PPA_Transportation_Type__c='Union',PPA_Region__c='1',PPA_Export_District__c='103'));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=transRecTypeId,PPA_CompanyId__c='01',PPA_Transportation_Type__c='Union',PPA_Region__c='1',PPA_Export_District__c='104'));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=transRecTypeId,PPA_CompanyId__c='01',PPA_Transportation_Type__c='Union',PPA_Region__c='1',PPA_Export_District__c='108'));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=transRecTypeId,PPA_CompanyId__c='01',PPA_Transportation_Type__c='Union',PPA_Region__c='1',PPA_Export_District__c='109'));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=transRecTypeId,PPA_CompanyId__c='01',PPA_Transportation_Type__c='Union',PPA_Region__c='2',PPA_Export_District__c='208'));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=transRecTypeId,PPA_CompanyId__c='01',PPA_Transportation_Type__c='Union',PPA_Region__c='2',PPA_Export_District__c='209'));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=transRecTypeId,PPA_CompanyId__c='01',PPA_Transportation_Type__c='Union',PPA_Region__c='2',PPA_Export_District__c='212'));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=transRecTypeId,PPA_CompanyId__c='01',PPA_Transportation_Type__c='Union',PPA_Region__c='6',PPA_Export_District__c='611'));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=transRecTypeId,PPA_CompanyId__c='01',PPA_Transportation_Type__c='Union',PPA_Region__c='6',PPA_Export_District__c='613'));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=transRecTypeId,PPA_CompanyId__c='01',PPA_Transportation_Type__c='Union',PPA_Region__c='9',PPA_Export_District__c='606'));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=transRecTypeId,PPA_CompanyId__c='01',PPA_Transportation_Type__c='Union',PPA_Region__c='9',PPA_Export_District__c='607'));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=transRecTypeId,PPA_CompanyId__c='01',PPA_Transportation_Type__c='Union',PPA_Region__c='9',PPA_Export_District__c='608'));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=transRecTypeId,PPA_CompanyId__c='01',PPA_Transportation_Type__c='Union',PPA_Region__c='9',PPA_Export_District__c='904'));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=transRecTypeId,PPA_CompanyId__c='01',PPA_Transportation_Type__c='Union',PPA_Region__c='9',PPA_Export_District__c='905'));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=transRecTypeId,PPA_CompanyId__c='01',PPA_Transportation_Type__c='Union',PPA_Region__c='9',PPA_Export_District__c='906'));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=transRecTypeId,PPA_CompanyId__c='01',PPA_Transportation_Type__c='Union',PPA_Region__c='9',PPA_Export_District__c='909'));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=transRecTypeId,PPA_CompanyId__c='01',PPA_Transportation_Type__c='Union',PPA_Region__c='9',PPA_Export_District__c='1301'));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=transRecTypeId,PPA_CompanyId__c='01',PPA_Transportation_Type__c='Union',PPA_Region__c='11',PPA_Export_District__c='105'));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=transRecTypeId,PPA_CompanyId__c='01',PPA_Transportation_Type__c='Union',PPA_Region__c='11',PPA_Export_District__c='106'));
            
            // NonUnion
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=transRecTypeId,PPA_CompanyId__c='01',PPA_Transportation_Type__c='NonUnion',PPA_Region__c='2',PPA_Export_District__c='102'));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=transRecTypeId,PPA_CompanyId__c='01',PPA_Transportation_Type__c='NonUnion',PPA_Region__c='2',PPA_Export_District__c='202'));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=transRecTypeId,PPA_CompanyId__c='01',PPA_Transportation_Type__c='NonUnion',PPA_Region__c='2',PPA_Export_District__c='205'));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=transRecTypeId,PPA_CompanyId__c='01',PPA_Transportation_Type__c='NonUnion',PPA_Region__c='2',PPA_Export_District__c='206'));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=transRecTypeId,PPA_CompanyId__c='01',PPA_Transportation_Type__c='NonUnion',PPA_Region__c='2',PPA_Export_District__c='210'));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=transRecTypeId,PPA_CompanyId__c='01',PPA_Transportation_Type__c='NonUnion',PPA_Region__c='2',PPA_Export_District__c='211'));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=transRecTypeId,PPA_CompanyId__c='01',PPA_Transportation_Type__c='NonUnion',PPA_Region__c='3',PPA_Export_Region__c='300'));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=transRecTypeId,PPA_CompanyId__c='01',PPA_Transportation_Type__c='NonUnion',PPA_Region__c='4',PPA_Export_Region__c='400'));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=transRecTypeId,PPA_CompanyId__c='01',PPA_Transportation_Type__c='NonUnion',PPA_Region__c='5',PPA_Export_Region__c='500'));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=transRecTypeId,PPA_CompanyId__c='01',PPA_Transportation_Type__c='NonUnion',PPA_Region__c='6',PPA_Export_District__c='601'));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=transRecTypeId,PPA_CompanyId__c='01',PPA_Transportation_Type__c='NonUnion',PPA_Region__c='6',PPA_Export_District__c='602'));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=transRecTypeId,PPA_CompanyId__c='01',PPA_Transportation_Type__c='NonUnion',PPA_Region__c='6',PPA_Export_District__c='603'));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=transRecTypeId,PPA_CompanyId__c='01',PPA_Transportation_Type__c='NonUnion',PPA_Region__c='6',PPA_Export_District__c='609'));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=transRecTypeId,PPA_CompanyId__c='01',PPA_Transportation_Type__c='NonUnion',PPA_Region__c='6',PPA_Export_District__c='614'));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=transRecTypeId,PPA_CompanyId__c='01',PPA_Transportation_Type__c='NonUnion',PPA_Region__c='6',PPA_Export_District__c='615'));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=transRecTypeId,PPA_CompanyId__c='01',PPA_Transportation_Type__c='NonUnion',PPA_Region__c='6',PPA_Export_District__c='616'));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=transRecTypeId,PPA_CompanyId__c='01',PPA_Transportation_Type__c='NonUnion',PPA_Region__c='7',PPA_Export_Region__c='700'));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=transRecTypeId,PPA_CompanyId__c='01',PPA_Transportation_Type__c='NonUnion',PPA_Region__c='7',PPA_Export_District__c='1303'));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=transRecTypeId,PPA_CompanyId__c='01',PPA_Transportation_Type__c='NonUnion',PPA_Region__c='8',PPA_Export_Region__c='800'));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=transRecTypeId,PPA_CompanyId__c='01',PPA_Transportation_Type__c='NonUnion',PPA_Region__c='9',PPA_Export_District__c='612'));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=transRecTypeId,PPA_CompanyId__c='01',PPA_Transportation_Type__c='NonUnion',PPA_Region__c='10',PPA_Export_Region__c='10',PPA_Exclude_National__c=true));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=transRecTypeId,PPA_CompanyId__c='01',PPA_Transportation_Type__c='NonUnion',PPA_Region__c='12',PPA_Export_Region__c='12'));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=transRecTypeId,PPA_CompanyId__c='01',PPA_Transportation_Type__c='NonUnion',PPA_Region__c='14',PPA_Export_Region__c='14'));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=transRecTypeId,PPA_CompanyId__c='02',PPA_Transportation_Type__c='NonUnion',PPA_Region__c='20',PPA_Export_Region__c='20'));
            keys.add(new PPA_Export_CSV_Key__c(RecordTypeId=transRecTypeId,PPA_CompanyId__c='02',PPA_Transportation_Type__c='NonUnion',PPA_Region__c='21',PPA_Export_Region__c='21'));
        
            insert keys;        
        }
    }    
    
    public static void loadCustomSettings() {
        List<PPA_Admin_Config__c> admConfigExists = [SELECT Id FROM PPA_Admin_Config__c];
        if(admConfigExists.size() == 0) {
            PPA_Admin_Config__c admConfig = new PPA_Admin_Config__c();
            admConfig.PPA_Admin_Group_Email__c='rateanalytics@sunbeltrentals.com';
            insert admConfig;                
        }

        List<PPA_MulesoftDocumentApi__c> apiDocExists = [SELECT Id FROM PPA_MulesoftDocumentApi__c];
        if(apiDocExists.size() == 0) {
            PPA_MulesoftDocumentApi__c apiDoc = new PPA_MulesoftDocumentApi__c();
            apiDoc.PPA_Base_URL__c = 'https://api.sunbeltrentals.com';
            apiDoc.PPA_Token_Endpoint__c = '/api/v1/oauth2/token';
            apiDoc.PPA_Document_Endpoint__c = '/api/v2/document';
            apiDoc.PPA_Client_Id__c = 'TBD';
            apiDoc.PPA_Client_Secret__c = 'TBD';
            apiDoc.PPA_Template_Id__c = 'TBD';
            insert apiDoc;    
        }
    }

    @isTest
    static void testBatch() {
        List<PPA_Price_List__c> priceLists = [SELECT Id, PPA_Export_Status__c FROM PPA_Price_List__c WHERE PPA_Verification_Status__c IN ('Verified', 'Overridden')];
		for(PPA_Price_List__c PriceList : priceLists) {
            PriceList.PPA_Export_Status__c = 'Scheduled';
        }
        
        update priceLists;

        Test.startTest();
        PPA_ExportPriceListsToCSVBatch batchJob = new PPA_ExportPriceListsToCSVBatch();
		Id JobId = Database.executeBatch(batchJob);
        Test.stopTest();
                
        Assert.isNotNull(JobId, 'Job Id was not created as expected');
    }
}