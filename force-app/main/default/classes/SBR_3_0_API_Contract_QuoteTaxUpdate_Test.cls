/**
* Apex Class: SBR_3_0_API_Contract_QuoteTaxUpdate_Test
* ---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* @description test class for SBR_3_0_API_Contract_QuoteTaxUpdate
*---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
*    2.0        Amanjot Kaur            2023-12-13          Fixed Recordtype Issues
*/
@isTest
public class SBR_3_0_API_Contract_QuoteTaxUpdate_Test Implements HttpCalloutMock{
    
    @TestSetup
    static void makeData(){
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
        // Create Account
        Account acct = new Account();
        acct.RM_Account_Number__c = '4';
        acct.Company_Code__c = '01';
        acct.Name = 'Test Account';
        acct.Record_Type_Text__c = 'Credit';
        acct.E_mail_Address__c = '123@asdf.com';
        acct.Phone = '1234567899';
        acct.BillingStreet = '123 Main Street';
        acct.BillingCity = 'Toronto';
        acct.BillingPostalCode = 'M9N7V5';
        acct.BillingState = 'ON';
        acct.BillingCountry = 'CA';
        acct.Drivers_License__c = 'AKF';
        acct.Driver_s_License_State__c = 'AL';
        insert acct;
       
        Contact contact = SBR_3_0_TestDataFactory.createContacts(1, acct.Id, true)[0];
        // Create Analysis Region
        Analysis_Region__c region = new Analysis_Region__c();
        region.Analysis_Region_Key__c = '001';
        region.Name = 'Test Region';
        region.Company_Code__c = '01';
        insert region;
        // Create Location
        Schema.Location jobLocation = new Schema.Location();
        jobLocation.Name = 'Test Job Location';
        jobLocation.Street_Address__c = '12 Main Street';
        jobLocation.City__c = 'Toronto';
        jobLocation.Zip_Code__c = 'M7N7B3';
        jobLocation.State__c = 'ON';
        jobLocation.Country__c = 'CA';
        jobLocation.RecordTypeId = SBR_3_0_Constants.LOCATION_JOB_RT_ID;
        jobLocation.OMS_Sourcing_Enabled__c = true;
        jobLocation.Distance_Multiplier__c = 50;
        jobLocation.Analysis_Region_Key__c = '001';
        jobLocation.Company_Code__c = '01';
        insert jobLocation;
        // Create Branch
        Schema.Location branchLocation = new Schema.Location();
        branchLocation.Branch_Location_Number__c = '720';
        branchLocation.Name = 'Test Branch Location';
        branchLocation.Street_Address__c = '12 Main Street';
        branchLocation.City__c = 'Toronto';
        branchLocation.Zip_Code__c = 'M7N7B3';
        branchLocation.State__c = 'ON';
        branchLocation.Country__c = 'CA';
        branchLocation.Job_Number__c='332112';
        branchLocation.RecordTypeId = SBR_3_0_Constants.LOCATION_BRANCH_RT_ID;
        branchLocation.Company_Code__c = 'X';
        branchLocation.Time_Zone_Name__c = 'America/Chicago';
        branchLocation.Time_Zone__c = 3;
        insert branchLocation;
        // Create Job Site
        AssociatedLocation jobSite = new AssociatedLocation(
            Name__c = 'Test Job Site',
            ParentRecordId = acct.Id,
            LocationId = jobLocation.Id,
            Branch__c = branchLocation.Id,
            Job_Number__c = '20221004A'
        );
        insert jobSite;
                // Create Price Book
        Pricebook2 priceBook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update priceBook;
        Id contractOrderRTId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Contract_Order').getRecordTypeId();
        // Create Order
        Order order = new Order(
            Quote_Name__c = 'Test Quote',
            AccountId = acct.Id,
            Jobsite__c = jobSite.Id,
            Deliverymethod__c = 'Delivery',
            Delivery_Charge__c = 10,
            Pricebook2Id = priceBook.Id,
            Start_Date__c = date.valueOf('2022-12-12 12:00:00'),
            EffectiveDate = date.valueOf('2022-12-12 12:00:00'),
            EndDate = date.valueOf('2023-10-09 8:00:00'),
            Return_Date__c = date.valueOf('2023-10-09 8:00:00'),
            Earliest_Delivery_Date__c = date.valueOf('2022-10-08 12:00:00'),
            Opt_Out_RPP__c = false,
            Order_By__c = contact.Id,
            Order_Initiating_Channel__c = 'SLSFRC',
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
            Duration__c = 'Custom',
            Contract_Order_Number__c = '12345',
            Reservation_Order_Number__c = '12345',
            Rentalman_Quote_Id__c = '12345',
            recordtypeId = contractOrderRTId,
            Status = 'Draft'
        );
        insert order;

         
        // Create Product
        List<Product2> products = new List<Product2>();
        for(Integer i = 0; i < 3; i++) {
            Product2 product = new Product2();
            product.Name = 'Test Product ' + i;
            if(i == 0) {
                product.Product_Type__c = 'Cat-Class';
                product.Product_SKU__c = '123456';
                product.Category__c = '32134';
                product.Class__c = '2039';
                product.ToolFlex__c = 'N';
            } else if (i == 1) {
                product.Product_Type__c = 'Parts';
                product.Item_Number__c = '1234GH';
                product.Stock_Class__c = 'AIMFV';
            } else {
                product.Product_Type__c = '';
                product.Item_Number__c = '1285JC';
                product.Stock_Class__c = 'UJEKL';
            }
            products.add(product);
        }
        insert products;
        // Create Price Book Entry
        List<PricebookEntry> listPbe = new List<PricebookEntry>();
        Map<Id, Id> mapPBE = new Map<Id, Id>();
        for(PricebookEntry pbEntry : [SELECT Id,Product2Id FROM PricebookEntry WHERE Pricebook2Id = :Test.getStandardPricebookId()]) {
            if(pbEntry.Product2Id == products[0].Id){
                mapPBE.put(pbEntry.Product2Id, pbEntry.Id);
            }
            else if(pbEntry.Product2Id == products[1].Id){
                mapPBE.put(pbEntry.Product2Id, pbEntry.Id);
            }
            else if(pbEntry.Product2Id == products[2].Id){
                mapPBE.put(pbEntry.Product2Id, pbEntry.Id);
            }
        }
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__BillingCity__c = 'Test City',
            Contingency_Plan__c = true,
            Seasonal_Quote__c = true,
            Shift_Pricing_Required__c = true,
            Standby_Pricing__c = true,
            Rentalman_Quote_Id__c = '65287816',
            SBQQ__Account__c = acct.Id,
            Company_Code__c = '01'
        );
        insert quote;

        List <SBQQ__QuoteLine__c> quoteLineList = new List <SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = products[0].Id, Line_Composite_Key__c='87816-456');
        quoteLineList.add(quoteLine);

        SBQQ__QuoteLine__c quoteLine2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = products[1].Id, Line_Composite_Key__c='87816-123');
        quoteLineList.add(quoteLine2);
        insert quoteLineList;
    }
    /** 
     * @description mock response 
     * @param        req 
     * @return       `HTTPResponse`
     */
       public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type',SBR_3_0_Constants.APP_JSON);
        if(req.getEndpoint().endsWithIgnoreCase('token')){
            res.setBody('{"access_token":"test"}');
            
        }else {
            res.setBody('{"companyId": "01","contractNumber": "119085598","sequenceNumber": 0,"type": "QUOTE","channel": "SBRWEBSITE","contractStartDateTime": "2022-03-25T14:36:00Z","contractReturnDateTime": "2022-03-28T14:36:00Z","numberOfRentalDays": "2","numberOfRentalHours": "0","isDeliveryAndPickupCharge": "true","isRPPCharge": "false","assignedToEmployeeID": "","assignedToEmployeeName": "","fulfillmentStatus": "N","stagingStatus": "N","customerOnSite": "N","Cancellation_NameF": "","Cancellation_NameL": "","Cancellation_Phone": "","Cancellation_Email": "","Cancellation_Date": "","Cancellation_Code": "","Cancellation_Reason": "","Cancellation_Channel": "","pc": [{"id": "720","name": "FORT MILL SC","address": {"line1": "120 SUTTON RIDGE LN","line2": "","city": "FORT MILL","state": "SC","zip": "29708 9400","phoneNumber": "8032289999","latitude": "34.999907","longitude": "-80.976919"},"email": "pcm@sunbeltrentals.com"}],"customer": [{"driverLicenseState": "NC","driverLicenseNumber": "123456","name": "TEST, MANDATORY","address": {"type": "billing","line1": "100 E MAIN STREET","line2": "","city": "FORT MILL","state": "FORT MILL","zip": "28105","phoneNumber": "9546729801"},"poNumber": "RPO-11186","orderedBy": "USER"}],"jobsite": [{"location": "","number": "","name": "TEST, MANDATORY","address": {"line1": "100 E MAIN STREET","line2": "","city": "FORT MILL","state": "NC","zip": "28105","phoneNumber": "9546729801"}}],"orderComments": [],"deliveryInstruction": [],"products": [{"description": "4 GALLON COMMERCIAL CARPET EXTRACTOR","productId": "0680210","make": "","model": "","serialNumber": "","minimumRate": "190","dayRate": "190","weekRate": "420","monthlyRate": "775","quantity": "1","unitCost": "380","rentalCost": "380","lineNumber": "123","rmLineNumber": "","rentalTax": "1.4","miscellaneousOptions": ""},{"description": "4 GALLON COMMERCIAL CARPET EXTRACTOR","productId": "0680210","make": "","model": "","serialNumber": "","minimumRate": "190","dayRate": "190","weekRate": "420","monthlyRate": "775","quantity": "1","unitCost": "380","rentalCost": "380","lineNumber": "456","rmLineNumber": "","rentalTax": "1.4","miscellaneousOptions": ""}],"salesItems": [{"description": "4 GALLON COMMERCIAL CARPET EXTRACTOR","itemNumber": "0680210","quantity": "1","unitCost": "380","cost": "380","lineNumber": "123","rmLineNumber": "","salesTax": "2.0","stockClass":"FUEL", "SKU": ""}],"miscItems": [{"item": "TRANSPORTATION SURCHARGE","stockClass": "FUEL","quantity": "1","unitCost": "17.500","cost": "17.500","tax": "1.23","lineNumber": "123","rmLineNumber": "","SKU": ""},{"item": "ENVIRONMENTAL","stockClass": "MISC","quantity": "1","unitCost": "9.500","cost": "9.500","tax": "0.67","lineNumber": "412","rmLineNumber": "","SKU": ""},{"item": "DELIVERY","stockClass": "DEL","quantity": "1","unitCost": "50","cost": "50","tax": "3.50","rmLineNumber": "","SKU": ""},{"item": "PICKUP","stockClass": "DEL","quantity": "1","unitCost": "50","cost": "50","tax": "3.50","rmLineNumber": "","SKU": ""}],"totals": {"rentals": "760","salesAmount": "0","rpp": "0","fuel": "0","environmental": "9.50","deliveryAndPickup": "100","misc": "17.50","tax": "62.10","finalTotal": "949.1"}}');
        }
        res.setStatusCode(200);
        return res;
    }
    
    @isTest 
    static void loadQuoteUpdateTaxes(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Contract_QuoteTaxUpdate_Test());
        Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User oUsers = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);
        SBR_3_0_API_Contract_OpenQuoteTaxUpdate.QuoteWrapper qrap;
        System.runAs(oUsers){
            Test.startTest();
            
            SBQQ__Quote__c quoteRecd = [SELECT Id FROM SBQQ__Quote__c Where Rentalman_Quote_Id__c='65287816'];
            qrap = SBR_3_0_API_Contract_OpenQuoteTaxUpdate.updateQuoteTaxes(quoteRecd.id);
            
            Test.stopTest();
           
            Assert.isNotNull(qrap);
        }
    } 
    @isTest 
    static void buildRequestTest(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Contract_QuoteTaxUpdate_Test());

        SBR_3_0_API_Contract_OpenQuoteTaxUpdate.WrappedResponse respond = new SBR_3_0_API_Contract_OpenQuoteTaxUpdate.WrappedResponse();
        List<SBQQ__Quote__c>  quotes = Database.query('SELECT Id,Name, Total_Misc__c,Total_Rental_Amount__c, RPP_Amount__c,Total_Sales_Amount__c,Total_Sales_Taxes__c,Total_Quoted_Amount__c,SBQQ__Status__c,RecordTypeId,RM_Account_Number__c,Company_Code__c,Rentalman_Quote_Id__c,(Select id,Line_Composite_Key__c,Misc_Charges_Item_Tax_Rate__c,Misc_Charges_Tax__c,Rental_Tax__c,Sales_Tax__c,Global_Line_Number__c FROM SBQQ__LineItems__r) from SBQQ__Quote__c LIMIT 1');
        List<SBQQ__QuoteLine__c> quoteItems = quotes[0].SBQQ__LineItems__r;
        String rmId = '65287816';
      
        Test.startTest();
       
            respond = SBR_3_0_API_Contract_OpenQuoteTaxUpdate.buildRequest(rmId,'01','1');
            SBR_3_0_API_Contract_OpenQuoteTaxUpdate.parseResponseAndUpdateTaxes(rmId,quoteItems, respond.body, quotes[0]); 
            List<SBQQ__Quote__c>  quotesList = Database.query('SELECT Id,Name,Total_Rental_Amount__c, RPP_Amount__c,Total_Sales_Amount__c,Total_Sales_Taxes__c,Total_Quoted_Amount__c from SBQQ__Quote__c LIMIT 1');
            SBR_3_0_API_Contract_OpenQuoteTaxUpdate.WrapQuoteResponse wrapQuoteResp  = (SBR_3_0_API_Contract_OpenQuoteTaxUpdate.WrapQuoteResponse) JSON.deserialize(respond.body, SBR_3_0_API_Contract_OpenQuoteTaxUpdate.WrapQuoteResponse.class);         
            List<SBR_3_0_API_Contract_OpenQuoteTaxUpdate.WrapProductQuoteLineItem> products = wrapQuoteResp.products;
            List<SBR_3_0_API_Contract_OpenQuoteTaxUpdate.WrapSalesQuoteLineItem> salesItems = wrapQuoteResp.salesItems;
            List<SBR_3_0_API_Contract_OpenQuoteTaxUpdate.WrapMiscQuoteLineItem> miscItems = wrapQuoteResp.miscItems;
          
       
            Assert.isNotNull(respond);
            Assert.isNotNull(quotesList[0].Total_Quoted_Amount__c,'949.1');

            Assert.isNotNull(products);
            Assert.isNotNull(salesItems);
            Assert.isNotNull(miscItems);

       Test.stopTest();
    }
}