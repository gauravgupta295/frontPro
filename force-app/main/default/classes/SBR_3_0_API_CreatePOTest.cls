@isTest
public with sharing class SBR_3_0_API_CreatePOTest implements HttpCalloutMock {
    private static final String TOKENNAME = 'MuleJWT';
    public string poId { get; set; }
    public string poLI1 { get; set; }
    public string poLI2 { get; set; }
    public string poLI3 { get; set; }

    public SBR_3_0_API_CreatePOTest(string poId, string poLI1, string poLI2, string poLI3) {
        this.poId = poId;
        this.poLI1 = poLI1;
        this.poLI2 = poLI2;
        this.poLI3 = poLI3;
    }
    public HTTPResponse respond(HTTPRequest req) {
        HTTPResponse res=new HTTPResponse();
        res.setHeader('Content-Type',SBR_3_0_Constants.APP_JSON);
        if(req.getEndpoint().endsWithIgnoreCase('token')){
            res.setBody('{"access_token":"test"}');
            res.setStatusCode(200);
        }else if(req.getEndpoint().endsWithIgnoreCase('potest')){
            res.setBody(		'{'+
            '  "Salesforce_Id": "' + this.poId + '",' +
            '  "poNumber": 1000014,'+
            '  "message": "Purchase Order processed successfully",'+
            '  "poLineItems": [{' +
		    '  "Salesforce_Id" : "' + this.poLI1 + '",' +
		    '  "Line_Item_Number" :  1	},' +
	        '  { ' + 
            '  "Salesforce_Id" : "' + this.poLI2 + '",' +
		    '  "Line_Item_Number" :  2	},' +
	        '  {' +
		    '  "Salesforce_Id" : "' + this.poLI3 + '",' +
		    '  "Line_Item_Number" :  3 }]'+
            '}');
            res.setStatusCode(200);
        }else {
            res.setBody(		'{'+
		'  "errors": {'+
		'    "ind": true,'+
		'    "code": "WOCRTT1000",'+
		'    "text": "Error occured in Rental Man",'+
		'    "reference": "1499"'+
		'  }'+
		'}');
            res.setStatusCode(400);
        }
        return res;
    }

    @testSetup
    static void createTestData(){
        DescribeSObjectResult dsr = Account.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED);
        Id recordTypeId = SBR_3_0_TestDataFactory.getAvailableRecordTypeId(dsr, 'Vendor');
        Account acct = SBR_3_0_TestDataFactory.createSingleAccount(true, recordTypeId, 'acc090', '1234567', '01');
        Purchase_Order__c po= new Purchase_Order__c();
        po.name='testname';
        po.Location__c = '9999';
        po.Vendor__c = acct.Id;
        po.Company_Code__c = '01';
        insert po;
        List<PO_Line_Item__c> lineItems = new List<PO_Line_Item__c>();
        for(Integer i = 0; i < 3; i++) {
            lineItems.add(new PO_Line_Item__c(
                Purchase_Order__c = po.Id,
                Item_Number__c = '10', 
                Quantity__c = 10,
                Unit_Cost__c = 10 ,
                Units__c = '11',
                Status__c = 'Draft',                
                RecordTypeId = Schema.SObjectType.PO_Line_Item__c.getRecordTypeInfosByDeveloperName().get('Standard_Purchase_Order').getRecordTypeId()
            ));        
        }
        insert lineItems;
        String uniqueUserName = 'testAdminUser' + DateTime.now().getTime() + '@SBRtestorg.com';
        // This code runs as the system user
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User testUser = new User(Alias = 'standt', Email = 'standarduser@testorg.com', EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles', UserName = uniqueUserName);
        insert testUser;

        Credential__c credential = new Credential__c();
        credential.Name = 'Mule_Token_Endpoint';
        credential.Environment__c = SBR_3_0_Constants.SANDBOX;
        credential.Key_Id__c = 'Mule_Token_Endpoint';
        insert credential;
    }

    @isTest
    static void createPOTest1() {
        string poId;
        string poLI1;
        string poLI2;
        string poLI3;
        Purchase_Order__c po = [SELECT Id FROM Purchase_Order__c LIMIT 1];
        poId = po.Id;
        List<PO_Line_Item__c> lineItems = [SELECT Id FROM PO_Line_Item__c WHERE Purchase_Order__c =:poId LIMIT 3];
        poLI1 = lineItems[0].Id;
        poLI2 = lineItems[1].Id;
        poLI3 = lineItems[2].Id;
        Test.startTest();
        Cache.Org.put(TOKENNAME, 'testToken', 850);
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreatePOTest(poId, poLI1, poLI2, poLI3));
        SBR_3_0_API_CreatePO cpo = SBR_3_0_API_CreatePO.createPO(poId, true);
        Test.stopTest();
    }
    @isTest
    static void createPOTest2() {
        string poId;
        string poLI1;
        string poLI2;
        string poLI3;
        Purchase_Order__c po = [SELECT Id FROM Purchase_Order__c LIMIT 1];
        poId = po.Id;
        po.ShipTo_Name__c='INDIAN TRAIL PC040';
        po.Vendor_Number__c = '12345';
        po.ShipTo_Addr1__c='1009 TECHNOLOGY DR';
        po.ShipTo_Addr2__c='';
        po.ShipTo_City__c='INDIAN TRAIL';
        po.ShipTo_State__c='NC';
        po.ShipTo_Zip__c='28079 7523';
        po.ShipTo_Phone__c='9088213800';
        po.Status__c='Draft';
        po.Issue_Date__c=Date.today();
        po.Promised_Date__c=Date.today();
        po.Requested_Date__c=Date.today();
        po.Closed_Date__c=Date.today();
        po.OrderedBy_Text__c='MWILKINSON';
        po.Ordered_From__c='LAST;FIRST';
        po.Ordered_For__c='';
        po.PO_Total__c=6.48;
        po.PO_Tax__c=0;
        po.Material_Code__c='RR';
        po.Employee__c='AKULKARNI';
        po.Taxable__c='Y';
        po.Tax_Pct__c=0;
        po.Ship_Method__c='Option1';
        po.Terms__c='NET 30 DAYS 2';
        po.FOB__c='';
        po.ShipTo__c='0040';
        po.Customer_or_Contract_Number__c=0;
        po.Alternate_AddrNum__c='0';
        po.Reference_Num__c='0';
        po.CurrencyISOCode='USD';
        po.CurrencyExchangeRate__c=0;
        po.Order_Time__c=110500;
        po.Driv_Lic_State__c='';
        po.Driv_Lic_Num__c='';
        po.Misc_Group3__c=0;
        po.Third_Party_RefNum__c='';
        po.Term_Days__c=30;
        po.Disc_Pct__c=0;
        po.Disc_Days__c=0;
        po.Reason_Code__c='';
        po.Invoice_Due_Date_Code__c='';
        po.Job_Num__c='LAMPASAS';
        po.Account_Num__c=0;
        po.PhoneNumberType__c='';
        po.InternationPhoneNumber__c='';
        po.Project_Num__c=0;
        po.Phase_Num__c=0;
        po.Carrier_Num__c='0';
        po.Terms_Code_Override__c='';
        po.Pay_By_Date__c=Date.today();
        po.PO_Comments__c='';
        update po;
        List<PO_Line_Item__c> lineItems = [SELECT Id FROM PO_Line_Item__c WHERE Purchase_Order__c =:poId LIMIT 3];
        List<PO_Line_Item__c> updLineItems = new List<PO_Line_Item__c>();
        for(PO_Line_Item__c poLI : lineItems) {
            poLI.Company_Code__c='01';
            poLI.Item_Number__c='#15';
            poLI.Stock_Class__c='PALME';
            poLI.Vendor_Item_Num__c='#15';
            poLI.Unit_Cost__c=5.478;
            poLI.Open_Order_Qty__c=2.0;
            poLI.Quantity_Rcvd__c=0.0;
            poLI.Quantity__c=1.0;
            poLI.Units__c='EA';
            poLI.Total_Cost__c=10.95;
            poLI.Total_Disc_Pct__c=0.0;
            poLI.Discount_Pct1__c=0.0;
            poLI.Discount_Pct2__c=0.0;
            poLI.Discount_Pct3__c=0.0;
            poLI.Status__c='P';
            poLI.PO_Date__c=Date.today();
            poLI.Request_Date__c=Date.today();
            poLI.Due_Date__c=Date.today();
            poLI.Date_Rcvd__c=Date.today();
            poLI.Taxable__c='';
            poLI.Warehouse__c='';
            poLI.GL_Account__c=109;
            poLI.Item_Type__c='M';
            poLI.Drop_Shipment__c='false';
            poLI.AcctNumber__c=0;
            poLI.Driver_Lic_State__c='';
            poLI.Driver_Lic_Num__c='';
            poLI.ContractOrWONumberOrCustNumber__c=0;
            poLI.Equipment_Num__c='';
            poLI.Config_Num__c=0;
            poLI.OrderedBy_Text__c='';
            poLI.Tax_Code__c='';
            poLI.Job_Num__c='LAMPASAS';
            poLI.Equipment_Type__c='';
            poLI.Work_Code__c='';
            poLI.Analysis_Code1__c=0;
            poLI.Analysis_Code2__c=0;
            poLI.Analysis_Code3__c=0;
            poLI.Analysis_Code4__c=0;
            poLI.Analysis_Code5__c=0;
            poLI.Analysis_Code6__c=0;
            poLI.Transaction_Cost__c=0.0;
            poLI.Purchase_Reason__c='Test';
            poLI.Third_Party_DtlNum__c='Test';
            poLI.Freight_Type__c='Test';
            poLI.Freight_Reason__c='Test';
            poLI.Order_Comments_Line_Level__c='Test';
            poLI.ProductSkuNumber__c=0;
            poLI.RM_Item_Type__c='';

            updLineItems.add(poLI);
        }
        update updLineItems;
        poLI1 = lineItems[0].Id;
        poLI2 = lineItems[1].Id;
        poLI3 = lineItems[2].Id;
        Test.startTest();
        Cache.Org.put(TOKENNAME, 'testToken', 850);
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreatePOTest(poId, poLI1, poLI2, poLI3));
        SBR_3_0_API_CreatePO cpo = SBR_3_0_API_CreatePO.createPO(poId, false);
        Test.stopTest();
    }
}