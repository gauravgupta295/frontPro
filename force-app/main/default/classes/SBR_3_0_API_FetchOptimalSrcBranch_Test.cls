@isTest
public with sharing class SBR_3_0_API_FetchOptimalSrcBranch_Test Implements HttpCalloutMock {
    @TestSetup
    static void makeData(){
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
    }

    public HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type',SBR_3_0_Constants.APP_JSON);
        if(req.getEndpoint().endsWithIgnoreCase('token')){
            res.setBody('{"access_token":"test"}');
        }else {
            res.setBody('{ "data": { "pc": "01-0105","latitude": 48.51, "longitude": -117.62, "companyId": "01","isLastResortBranch": true,"fulfillmentPercent": 0.0 }}');
        }
        res.setStatusCode(200);
        return res;
    }

    @isTest static void testgetOptimalSourcingBranch() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_FetchOptimalSrcBranch_Test());
        SBR_3_0_API_FetchOptimalSourcingBranch branchFetch = new SBR_3_0_API_FetchOptimalSourcingBranch();
        SBR_3_0_WrapInventorySources.ATSRequest obj = new SBR_3_0_WrapInventorySources.ATSRequest();
        obj.companyId='01';
        obj.cartId ='5242f682-13de-4b77-a654-612a62ab782e';
        obj.cartTotal =70.0;
        obj.cartType='SBRB2B';
        obj.customerType='DEFAULT';
        obj.sellingChannel = 'SBRB2B';
        obj.fulfillmentType ='DEL';
        obj.fulfillmentService = 'STANDARD';
        obj.overrideDistance= true;
        obj.sourceSystem = 'salesForce';
        SBR_3_0_WrapInventorySources.Address addr = new SBR_3_0_WrapInventorySources.Address();
          addr.line1='';
          addr.line2='';
          addr.state='TX';
          addr.city='Plano';
          addr.country='US';
          addr.zip = '75024';

        SBR_3_0_WrapInventorySources.Jobsite j = new SBR_3_0_WrapInventorySources.Jobsite();
            j.latitude = 48.51;
            j.longitude = -117.62;
            j.address = addr;

            obj.jobsite = j;

        SBR_3_0_WrapInventorySources.Products p = new SBR_3_0_WrapInventorySources.Products();
            p.requestedDeliveryDate = '2022-10-09T23:00:00+00:00';
            p.lineId = '1';
            p.uom='EACH';
            p.quantity = 1;
            p.productId = '0032958';
            p.productType='E';
            p.catId = '003';
            p.classId= '2958';
            obj.products = new List<SBR_3_0_WrapInventorySources.Products>();
            obj.products.add(p);
        SBR_3_0_WrapInventorySources.salesItems s= new SBR_3_0_WrapInventorySources.salesItems();
          s.itemNumber='123458';
          s.stockClass='9';
          s.quantity=1;
          s.unitPrice=190;
          obj.salesItems = new List<SBR_3_0_WrapInventorySources.salesItems>();
          obj.salesItems.add(s);
        SBR_3_0_WrapInventorySources.ATSResponse resp = SBR_3_0_API_FetchOptimalSourcingBranch.getOptimalSourcingBranch(obj,'01');
        System.assertEquals(resp.Data.pc,'01-0105', 'Call successfull' );
       // System.assert(String.isNotEmpty(SBR_3_0_API_FetchOptimalSourcingBranch.getOptimalSourcingBranch(branchRequestJson, '1')), 'No branch Data Received From API');
        Test.stopTest();
    }

}


//   SBR_3_0_WrapInventorySources.ATSRequest obj = new SBR_3_0_WrapInventorySources.ATSRequest();
//         obj.companyId='01';
//         obj.cartId ='5242f682-13de-4b77-a654-612a62ab782e';
//        obj.cartTotal =70.0;
//        obj.cartType='SBRB2B';
//        obj.customerType='DEFAULT';
//         obj.sellingChannel = 'SBRB2B';
//         obj.fulfillmentType ='DEL';
//         obj.fulfillmentService = 'STANDARD';
//         obj.overrideDistance= true;
//         obj.sourceSystem = 'salesForce';
//         SBR_3_0_WrapInventorySources.Address addr = new SBR_3_0_WrapInventorySources.Address();
//           addr.line1='';
//           addr.line2='';
//           addr.state='TX';
//           addr.city='Plano';
//         addr.country='US';
//         addr.zip = '75024';

//         SBR_3_0_WrapInventorySources.Jobsite j = new SBR_3_0_WrapInventorySources.Jobsite();
//         j.latitude = 48.51;
//         j.longitude = -117.62;
//         j.address = addr;

//         obj.jobsite = j;

//         SBR_3_0_WrapInventorySources.Products p = new SBR_3_0_WrapInventorySources.Products();
//         p.requestedDeliveryDate = '2022-10-09T23:00:00+00:00';
//         p.lineId = '1';
//         p.uom='EACH';
//         p.quantity = 1;
//         p.productId = '0032958';
//         p.productType='E';
//         p.catId = '003';
//         p.classId= '2958';
//         obj.products = new List<SBR_3_0_WrapInventorySources.Products>();
//         obj.products.add(p);
//         SBR_3_0_WrapInventorySources.salesItems s= new SBR_3_0_WrapInventorySources.salesItems();
//           s.itemNumber='123458';
//           s.stockClass='9';
//           s.quantity=1;
//           s.unitPrice=190;
//           obj.salesItems = new List<SBR_3_0_WrapInventorySources.salesItems>();
//           obj.salesItems.add(s);
//         String res = JSON.serializePretty(obj);
//         System.debug('\n obj = ' + res);
//         SBR_3_0_WrapInventorySources.ATSResponse resp = SBR_3_0_API_FetchOptimalSourcingBranch.getOptimalSourcingBranch(obj,'01');
//         System.debug(resp);


//         obj.products = new List<SBR_3_0_WrapAlternateItems.Products>();
//         obj.products.add(p);
//         String s = JSON.serializePretty(obj);
//         System.debug('\n obj = ' + s);
//         SBR_3_0_WrapAlternateItems.ATIResponse resp = SBR_3_0_API_FetchAlternateItems.getAlternateItems(obj,'01');
//         System.debug(resp);