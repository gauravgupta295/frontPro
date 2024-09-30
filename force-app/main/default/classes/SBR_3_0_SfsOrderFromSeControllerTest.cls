/*********************************************************************************************************************
* Apex Class: SBR_3_0_SfsOrderFromSeControllerTest
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class containing all methods used to test SBR_3_0_SfsOrderFromSeController class
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION       DATE               DETAIL FEATURES
1.0          2023-06-19          Vikas Kumar/Hrishi 
**********************************************************************************************************************************************/
@istest
global class SBR_3_0_SfsOrderFromSeControllerTest implements HttpCalloutMock {
     class SBR_3_0_API_CreateWorkOrderLineItemsTest implements HttpCalloutMock{    
     public HTTPResponse respond(HTTPRequest req) {
        HTTPResponse res=new HTTPResponse();
        res.setHeader('Content-Type',SBR_3_0_Constants.APP_JSON);
        if(req.getEndpoint().endsWithIgnoreCase('token')){
            res.setBody('{"access_token":"test"}');
            res.setStatusCode(200);
        }else if(req.getEndpoint().endsWithIgnoreCase('inside-labor')){
            res.setBody(		'{'+
		'  "workOrderNumber": 86684649,'+
		'  "mode": "U",'+
		'  "message": "Work Order processed successfully",'+
		'  "workOrderLineItems": [ { "rmLineNumber": 9999, "rmUniqueId": 12345678911, "referenceLineNumber": "" } ]'+
		'}');
            res.setStatusCode(200);
        }else {
            res.setBody(		'{'+
		'  "errors": {'+
		'    "ind": true,'+
		'    "code": "WOCRTT2000",'+
		'    "text": "Invalid claim type entered. Valid types are N, D, M, or S..",'+
		'    "reference": "1496"'+
		'  }'+
		'}');
            res.setStatusCode(400);
        }
        return res;
    }
    }
    
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest request) {
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/xml');
        
        response.setBody('<?xml version="1.0" encoding="UTF-8" standalone="yes"?><cXML xml:lang="en_US" payloadID="rW68ujzduQ" timestamp="1687193822773"><Response><Status code="200" text="success"/><PunchOutSetupResponse><StartPage><URL>https://sunbeltca.smartequip.net/sunbelt-se/punchin?punchinSession=b5e8969ffc5b41f8a70838327e01fef9</URL></StartPage></PunchOutSetupResponse></Response></cXML>');
        response.setStatusCode(200);
        return response; 
    }
    @testsetup
    private static void createData()
    {
        User usr=SBR_3_0_ServiceTestDataFactory.createServiceResourceUser(true,'test12','test124');
     	PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Integration_API_Access'];
		List <PermissionSetAssignment> permSetCheck = [SELECT Id from PermissionSetAssignment WHERE PermissionSetId = : ps.Id
                                                    AND AssigneeId = : UserInfo.getUserId()];
        if (permSetCheck.size()==0){
        insert new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = ps.Id);
        }
    }
    @istest
    private static void testGenerateCXML()
    {
        FSL.GlobalAPIS.addStatusTransition('Open', 'Scheduled');
         Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
        WorkOrder wo=SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
        ServiceResource sr=SBR_3_0_ServiceTestDataFactory.create_Service_Resource(false);
        User usr=[select id from user where username like '%SBRtestorg.com' order by createdDate limit 1];
        ServiceTerritory st= SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);
        wo.ServiceTerritoryId=st.id;
        wo.SF_PS_Expense_To_Location__c=st.id;
        
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_SfsOrderFromSeControllerTest.SBR_3_0_API_CreateWorkOrderLineItemsTest());
        insert wo;
        wo.SF_PS_Company_Code__c='01';
        update wo;
        ServiceAppointment sa = SBR_3_0_ServiceTestDataFactory.createServiceAppointment(true,wo.id);
        sr.RelatedRecordId=usr.id;
        sr.ResourceType='T';
        sr.IsActive=true;
        insert sr;
        SBR_3_0_ServiceTestDataFactory.createServiceTerritoryMember(true,sr.id,st.id);
        AssignedResource ar  = new AssignedResource(ServiceAppointmentId=sa.id,ServiceResourceId=sr.id);
        insert ar;
        map <string,object> data=new map<string,Object>();
        Test.startTest();
        SBR_3_0_SfsOrderFromSeController.generateCXML(wo.id,data);
        Test.stopTest();
        Integer size=data.size();
        Assert.isTrue(size>0, 'Response should not be null');      
    }
    @istest
    private static void testGenerateCXML2()
    {
        FSL.GlobalAPIS.addStatusTransition('Open', 'Scheduled');
         Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
        WorkOrder wo=SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
        ServiceResource sr=SBR_3_0_ServiceTestDataFactory.create_Service_Resource(false);
        User usr=[select id from user where username like '%SBRtestorg.com' order by createdDate limit 1];
        ServiceTerritory st= SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);
        wo.ServiceTerritoryId=st.id;
        wo.SF_PS_Expense_To_Location__c=st.id;
         Test.setMock(HttpCalloutMock.class, new SBR_3_0_SfsOrderFromSeControllerTest.SBR_3_0_API_CreateWorkOrderLineItemsTest());
        insert wo;
        
        map <string,object> data=new map<string,Object>();
        Test.startTest();
        SBR_3_0_SfsOrderFromSeController.generateCXML(wo.id,data);
        Test.stopTest();
        Integer size=data.size();
        Assert.isTrue(size>0, 'Response should not be null');
        
    }
    @istest
    private static void testGenerateCXML3()
    {
        FSL.GlobalAPIS.addStatusTransition('Open', 'Scheduled');
         Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
        WorkOrder wo=SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
         Test.setMock(HttpCalloutMock.class, new SBR_3_0_SfsOrderFromSeControllerTest.SBR_3_0_API_CreateWorkOrderLineItemsTest());
        ServiceResource sr=SBR_3_0_ServiceTestDataFactory.create_Service_Resource(false);
        User usr=[select id from user where username like '%SBRtestorg.com' order by createdDate limit 1];
        ServiceTerritory st= SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);
        wo.ServiceTerritoryId=st.id;
        wo.SF_PS_Expense_To_Location__c=st.id;
        
        
        insert wo;
        wo.SF_PS_Company_Code__c='01';
        update wo;
        ServiceAppointment sa = SBR_3_0_ServiceTestDataFactory.createServiceAppointment(true,wo.id);
        sr.RelatedRecordId=usr.id;
        sr.ResourceType='T';
        sr.IsActive=true;
        insert sr;
        SBR_3_0_ServiceTestDataFactory.createServiceTerritoryMember(true,sr.id,st.id);
        AssignedResource ar  = new AssignedResource(ServiceAppointmentId=sa.id,ServiceResourceId=sr.id);
        insert ar;
        map <string,object> data=new map<string,Object>();
        Test.startTest();
        SBR_3_0_SfsOrderFromSeController.generateCXML(wo.id,data);
        Test.stopTest();
        Integer size=data.size();
        Assert.isTrue(size>0, 'Response should not be null');       
    }
    @istest
    private static void testpunchoutxml()
    {
        FSL.GlobalAPIS.addStatusTransition('Open', 'Scheduled');
         Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
        WorkOrder wo=SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
         Test.setMock(HttpCalloutMock.class, new SBR_3_0_SfsOrderFromSeControllerTest.SBR_3_0_API_CreateWorkOrderLineItemsTest());
        ServiceResource sr=SBR_3_0_ServiceTestDataFactory.create_Service_Resource(false);
        User usr=[select id from user where username like '%SBRtestorg.com' order by createdDate limit 1];
        ServiceTerritory st= SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);
        wo.ServiceTerritoryId=st.id;
        wo.SF_PS_Expense_To_Location__c=st.id;
        wo.SF_PS_Work_Order_Des__c='ANNUAL INSPECTION';
        insert wo;
        wo.SF_PS_Company_Code__c='01';
        update wo;
        ServiceAppointment sa = SBR_3_0_ServiceTestDataFactory.createServiceAppointment(true,wo.id);
        sr.RelatedRecordId=usr.id;
        sr.ResourceType='T';
        sr.IsActive=true;
        insert sr;
        SBR_3_0_ServiceTestDataFactory.createServiceTerritoryMember(true,sr.id,st.id);
        AssignedResource ar  = new AssignedResource(ServiceAppointmentId=sa.id,ServiceResourceId=sr.id);
        insert ar;
        map <string,object> data=new map<string,Object>();
        
        // Call method to test
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_SfsOrderFromSeControllerTest());
        data= SBR_3_0_SfsOrderFromSeController.generateXml(wo.id,'Desktop','test.salesforce.com');
        
        Test.stopTest();
        Integer size=data.size();
        Assert.isTrue(size>0, 'Response should not be null');

}
}