@isTest
public class PPA_ExportPriceListsUtility_Test {

    @Testsetup
    public static void createTestData(){
        List<PPA_Price_List__c> PriceLists = new List<PPA_Price_List__c>();
        PPA_Price_List__c priceList = new PPA_Price_List__c();
		PPA_Rental_CatClass__c testRental = new PPA_Rental_CatClass__c();
        PPA_Transportation__c testTrans= new PPA_Transportation__c();
                
        Id renewalRecordTypeId = [SELECT Id FROM RecordType WHERE sObjectType = 'PPA_Price_List__c' AND DeveloperName='PPA_Renewal'].Id;
        Id extensionRecordTypeId = [SELECT Id FROM RecordType WHERE sObjectType = 'PPA_Price_List__c' AND DeveloperName='PPA_Extension'].Id;
        
        List<PPA_Rental_CatClass__c> rentalCatClass = new List<PPA_Rental_CatClass__c>();
        List<PPA_Transportation__c> transportations = new List<PPA_Transportation__c>();
                
        //create test price list with Verified status 
        priceList = new PPA_Price_List__c();
        priceList.RecordTypeId = renewalRecordTypeId;
        priceList.Name = 'TestPriceList';
        priceList.PPA_Verification_Status__c = 'Verified';
        priceList.PPA_CompanyId__c = '01';
        priceList.PPA_Rate_Load_Scope__c = 'National';
        priceList.PPA_New_Start_Date__c = Date.valueOf('2023-01-01');
        priceList.PPA_New_End_Date__c = Date.valueOf('2023-12-31');
        priceList.PPA_Rate_Type__c = 'Firm Fixed';
        PriceLists.add(priceList);

        priceList = new PPA_Price_List__c();
        priceList.RecordTypeId = extensionRecordTypeId;
        priceList.Name = 'TestPriceList';
        priceList.PPA_Verification_Status__c = 'Verified';
        priceList.PPA_CompanyId__c = '01';
        priceList.PPA_Rate_Load_Scope__c = 'National';
        priceList.PPA_Old_Start_Date__c = Date.valueOf('2023-01-01');
        priceList.PPA_New_End_Date__c = Date.valueOf('2023-12-31');
        priceList.PPA_Rate_Type__c = 'Firm Fixed';
        PriceLists.add(priceList);

        //create test price list with Verified status 
       	priceList = new PPA_Price_List__c();
        priceList.RecordTypeId = renewalRecordTypeId;
        priceList.Name = 'TestPriceList';
        priceList.PPA_Verification_Status__c = 'Verified';
        priceList.PPA_CompanyId__c = '02';
        priceList.PPA_Rate_Load_Scope__c = 'National';
        priceList.PPA_New_Start_Date__c = Date.valueOf('2023-01-01');
        priceList.PPA_New_End_Date__c = Date.valueOf('2023-12-31');
        priceList.PPA_Rate_Type__c = 'Firm Fixed';
        PriceLists.add(priceList);

        priceList = new PPA_Price_List__c();
        priceList.RecordTypeId = extensionRecordTypeId;
        priceList.Name = 'TestPriceList';
        priceList.PPA_Verification_Status__c = 'Verified';
        priceList.PPA_CompanyId__c = '02';
        priceList.PPA_Rate_Load_Scope__c = 'National';
        priceList.PPA_Old_Start_Date__c = Date.valueOf('2023-01-01');
        priceList.PPA_New_End_Date__c = Date.valueOf('2023-12-31');
        priceList.PPA_Rate_Type__c = 'Not To Exceed';
        PriceLists.add(priceList);

        //create test price list with Verified status 
        priceList = new PPA_Price_List__c();
        priceList.RecordTypeId = renewalRecordTypeId;
        priceList.Name = 'TestPriceList';
        priceList.PPA_Verification_Status__c = 'Verified';
        priceList.PPA_CompanyId__c = '01';
        priceList.PPA_Rate_Load_Scope__c = 'Regional';
		priceList.PPA_Regions__c = '1;3;5';
        priceList.PPA_New_Start_Date__c = Date.valueOf('2023-01-01');
        priceList.PPA_New_End_Date__c = Date.valueOf('2023-12-31');
        priceList.PPA_Rate_Type__c = 'Not To Exceed';
        PriceLists.add(priceList);

        //create test price list with Verified status 
        priceList = new PPA_Price_List__c();
        priceList.RecordTypeId = renewalRecordTypeId;
        priceList.Name = 'TestPriceList';
        priceList.PPA_Verification_Status__c = 'Verified';
        priceList.PPA_CompanyId__c = '02';
        priceList.PPA_Rate_Load_Scope__c = 'Regional';
		priceList.PPA_Regions__c = '20';
        priceList.PPA_New_Start_Date__c = Date.valueOf('2023-01-01');
        priceList.PPA_New_End_Date__c = Date.valueOf('2023-12-31');
        priceList.PPA_Rate_Type__c = 'Not To Exceed';
        PriceLists.add(priceList);
        
        //create test price list with UnVerified status 
        priceList = new PPA_Price_List__c();
        priceList.Name = 'TestPriceList';
        priceList.PPA_Verification_Status__c = 'Unverified';
        PriceLists.add(priceList);
        
        insert PriceLists;
        
        //create test Rental cat class
        for(Integer i=0;i<6;i++) {
            testRental = new PPA_Rental_CatClass__c();
            testRental.PPA_Price_List__c = PriceLists[i].Id;
            testRental.PPA_Like_CatClass__c = false;
            testRental.PPA_New_Day__c = 100;
            testRental.PPA_New_Week__c = 200;
            testRental.PPA_New_Month__c = 500;

            if(i != 0) {
                testRental.PPA_Apply_Rate_Type__c = true;
            }
            
            if(i <= 1) {
                testRental.PPA_Min_Rate__c = 'Day';
            }

            if(i > 1) {
                testRental.PPA_Min_Rate__c = 'Week';
            }

            if(i > 3) {
                testRental.PPA_Min_Rate__c = 'Month';
            }

            rentalCatClass.add(testRental);            
        }
        
        insert rentalCatClass;

        //create test transportation 
        for(Integer i=0;i<6;i++) {
            testTrans = new PPA_Transportation__c();
            testTrans.PPA_Price_List__c = PriceLists[i].Id;

            if(i < 3) {
                testTrans.PPA_Transportation_Type__c = 'Union';
            }
            else {
                testTrans.PPA_Transportation_Type__c = 'NonUnion';                
            }

            testTrans.PPA_Truck_Type__c = 'Pickup / Stakebody';
            testTrans.PPA_Rates_Loaded__c = true;
            testTrans.PPA_New_Band1__c = 10;
            testTrans.PPA_New_Band2__c = 10;
            testTrans.PPA_New_Band3__c = 10;
            testTrans.PPA_New_Band4__c = 10;
            testTrans.PPA_New_Excess__c = 10;
            transportations.add(testTrans);
        }
        
        insert transportations;
    }    
}