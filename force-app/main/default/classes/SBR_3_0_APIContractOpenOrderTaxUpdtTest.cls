/**
 * @description       : Unit test for SBR_3_0_API_ContractOpenOrderTaxUpdate
 * @author            : Salesforce
 * @group             :
 * @last modified on  : 03-28-2024
 * @last modified by  : Hashem Abdul
**/
@IsTest
private class SBR_3_0_APIContractOpenOrderTaxUpdtTest implements HttpCalloutMock{

    @TestSetup
    static void makeData(){
            Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
            
            UserRole ur = [SELECT Id, Name FROM UserRole where Name = 'Sales - US'];
            
            User user = new User(Alias = 'standt', Email='standardperson@airrexusa.com', 
            EmailEncodingKey='UTF-8', LastName='Testing',UserRoleId =ur.Id, LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, Analysis_Region_Key__c = '921',
            TimeZoneSidKey='America/Los_Angeles', UserName='standardperson@airrexusa.com');

            insert user;
         system.runAs(user){
            Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;

        // Create Account
        Account acct = new Account(
            RM_Account_Number__c = '4',
            Company_Code__c = '01',
            Name = 'Test Account',
            Record_Type_Text__c = 'Credit',
            E_mail_Address__c = '123@asdf.com',
            Phone = '1234567890',
            BillingStreet = '123 Main Street',
            BillingCity = 'Toronto',
            BillingPostalCode = 'M9N7V5',
            BillingState = 'ON',
            BillingCountry = 'CA',
            Drivers_License__c = 'AKF',
            Driver_s_License_State__c = 'AL'
        );
        insert acct;

        //Create Asset
        Asset ast = new Asset(
            Status = 'SCHEDULED FOR PICKUP',
            Name = 'Test Asset',
            AccountId = acct.Id
        );
        insert ast;

        // Create Price Book
        Pricebook2 priceBook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update priceBook;

        // Create Order
        Order order = new Order(
            Name = 'Test',
            Quote_Name__c = 'Test Quote',
            AccountId = acct.Id,
            Deliverymethod__c = 'Delivery',
            Delivery_Charge__c = 10,
            Status = 'Draft',
            Pricebook2Id = priceBook.Id,
            Start_Date__c = system.today() + 1,
            EffectiveDate = system.today() +1,
            EndDate = system.today() +12,
            Return_Date__c = system.today() +30,
            Estimated_Return_Date__c = system.today() +30,
            Earliest_Delivery_Date__c = system.today(),
            Opt_Out_RPP__c = false,
            Order_Initiating_Channel__c = 'SLSFRC',
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
            Duration__c = 'Custom',
            Reservation_Order_Number__c = '12342',
            Total_Sales_Taxes__c = 900.00,
            //Branch__c = branchLocation.Id,
            RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Sales Order').getRecordTypeId()
        );
        insert order;
        Order order1 = new Order(
            Name = 'Test',
            Quote_Name__c = 'Test Quote1',
            AccountId = acct.Id,
            Deliverymethod__c = 'Delivery',
            Delivery_Charge__c = 10,
            Status = 'Draft',
            Pricebook2Id = priceBook.Id,
            Start_Date__c = system.today() + 1,
            EffectiveDate = system.today() +1,
            EndDate = system.today() +12,
            Return_Date__c = system.today() +30,
            Estimated_Return_Date__c = system.today() +30,
            Earliest_Delivery_Date__c = system.today(),
            Opt_Out_RPP__c = false,
            Order_Initiating_Channel__c = 'SLSFRC',
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
            Duration__c = 'Custom',
            Reservation_Order_Number__c = '12342',
            //Total_Sales_Taxes__c = 900,
            Total_Misc__c = null,
            Total_Rental_Amount__c = null,
            Total_Sales_Amount__c = null,
            RPP_Amount__c = null,
            Total_Sales_Taxes__c = null,
            Total_Ordered_Amount__c = null,
            RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Reservation Order').getRecordTypeId()
        );
        insert order1;

        // Create Product
        List<Product2> products = new List<Product2>{
            new Product2(
                Name = 'Test Product 0',
                Company_Code__c = '01',
                Product_Type__c = 'Cat-Class',
                Product_SKU__c = '123456',
                Category__c = '32134',
                Class__c = '2039',
                ToolFlex__c = 'N'
            ),
            new Product2(
                Name = 'Test Product 1',
                Company_Code__c = '01',
                Product_Type__c = 'Parts',
                Item_Number__c = '1234GH',
                Stock_Class__c = 'AIMFV'
            ),
            new Product2(
                Name = 'Test Product 2',
                Company_Code__c = '01',
                Product_Type__c = '',
                Item_Number__c = '1285JC',
                Stock_Class__c = 'UJEKL'
            )
        };
        insert products;


        // Create Price Book Entry
        List<PricebookEntry> pbeList = SBR_3_0_TestDataFactory.createPriceBookEntries(products);

        //Create Order item details
        Order_Item_Detail__c orderItemDetail = new Order_Item_Detail__c();
        orderItemDetail.Pickup_Ticket__c = 'Test ticket';
        insert orderItemDetail;

        // Create Order item
        List<OrderItem> orderItems = new List<OrderItem>();
        for(PricebookEntry pbe : pbeList){
            OrderItem orderItem = new OrderItem();
            orderItem.OrderId = order.Id;
            orderItem.Product2Id = pbe.Product2Id;
            orderItem.UnitPrice = 100;
            orderItem.Item_Number__c = orderItems.size();
            orderItem.Min_Rate__c = 2;
            orderItem.Daily_Rate__c = 2.0;
            orderItem.Weekly_Rate__c = 2.0;
            orderItem.Monthly_Rate__c = 2.0;
            orderItem.Order_Item_Detail__c = orderItemDetail.Id;
            orderItem.SBQQ__Asset__c = ast.Id;
            orderItem.PricebookEntryId = pbe.Id;
            if(orderItems.size() == 0) {
                orderItem.Hourly_Rate__c = 2.0;
                orderItem.Min_Rate__c = 2.0;
                orderItem.Quantity = 5;
                orderItem.Free_Flag__c = false;
                orderItem.Suggested_Daily_Rate__c = 2.0;
                orderItem.Suggested_Weekly_Rate__c = 2.0;
                orderItem.Suggested_Monthly_Rate__c = 2.0;
                orderItem.Daily_Rate__c = 2.0;
                orderItem.Weekly_Rate__c = 2.0;
                orderItem.Monthly_Rate__c = 2.0;
                orderItem.Rates_Overriden__c = false;
            } else if (orderItems.size() == 1) {
                orderItem.Quantity = 3;
            } else {
                orderItem.Quantity = 3;
                orderItem.Misc_Charges_Type__c = 'TRANSPORTATION CHARGE';
                orderItem.Misc_Charge__c = 20.3;
                orderItem.Misc_Charges_Tax__c = 2.34;
                orderItem.Taxable__c = false;
                orderItem.Misc_Charges_Non_Taxable__c = false;
                orderItem.Misc_Charges_Item_Tax_Rate__c = 2.0;
            }
            orderItems.add(orderItem);
        }
         
        OrderItem orderItem = new OrderItem();
            orderItem.OrderId = order1.Id;
            orderItem.Product2Id = pbeList[0].Product2Id;
            orderItem.UnitPrice = 100;
            orderItem.Item_Number__c = orderItems.size();
            orderItem.Min_Rate__c = 2;
            orderItem.Daily_Rate__c = 2.0;
            orderItem.Weekly_Rate__c = 2.0;
            orderItem.Monthly_Rate__c = 2.0;
            orderItem.Order_Item_Detail__c = orderItemDetail.Id;
            orderItem.SBQQ__Asset__c = ast.Id;
            orderItem.PricebookEntryId = pbeList[0].Id;
            orderItem.Hourly_Rate__c = 2.0;
            orderItem.Min_Rate__c = 2.0;
            orderItem.Quantity = 5;
            orderItem.Free_Flag__c = false;
            orderItem.Suggested_Daily_Rate__c = 2.0;
            orderItem.Suggested_Weekly_Rate__c = 2.0;
            orderItem.Suggested_Monthly_Rate__c = 2.0;
            orderItem.Daily_Rate__c = 2.0;
            orderItem.Weekly_Rate__c = 2.0;
            orderItem.Monthly_Rate__c = 2.0;
            orderItem.Rates_Overriden__c = false;
            orderItem.Line_Composite_Key__c ='1234-2';
                
        orderItems.add(orderItem);
        insert orderItems;

        

        Order order2 = new Order(
            Name = 'Test 2',
            Quote_Name__c = 'Test Quote2',
            AccountId = acct.Id,
            Deliverymethod__c = 'Delivery',
            Delivery_Charge__c = 10,
            Status = 'Draft',
            Pricebook2Id = priceBook.Id,
            Start_Date__c = system.today() + 1,
            EffectiveDate = system.today() +1,
            EndDate = system.today() +12,
            Return_Date__c = system.today() +30,
            Estimated_Return_Date__c = system.today() +30,
            Earliest_Delivery_Date__c = system.today(),
            Opt_Out_RPP__c = false,
            Order_Initiating_Channel__c = 'SLSFRC',
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
            Duration__c = 'Custom',
            Rentalman_Quote_Id__c = '98765',
            Total_Sales_Taxes__c = 900.00,
            RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Sales Order').getRecordTypeId()
        );
        insert order2;
         }
        
   
        
    }
    @isTest
    static void testUpdateOrderItemTaxes(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_APIContractOpenOrderTaxUpdtTest());
        Order order = [SELECT id FROM Order WHERE Quote_Name__c = 'Test Quote1'];
                User adminUser = [Select Id from User Limit 1];

        System.runAs(adminUser){
            Test.startTest();
      
            SBR_3_0_API_Contract_OpenOrderTaxUpdate.OrderWrapper orderWrapped = SBR_3_0_API_Contract_OpenOrderTaxUpdate.updateOrderItemTaxes(order.Id);
      
            Test.stopTest();
            System.assert(orderWrapped != null, 'Order Wrapped was null');

        }
        
    }
    /*
    @isTest
    static void testParseResponseAndUpdateTaxes(){
                User adminUser = [Select Id from User Limit 1];
        System.runAs(adminUser){
            SBR_3_0_API_Contract_OpenOrderTaxUpdate.WrapOrderResponse wrapOrder = new SBR_3_0_API_Contract_OpenOrderTaxUpdate.WrapOrderResponse();
           wrapOrder.companyId = '01';
            wrapOrder.contractNumber = '9889';
            wrapOrder.totals = new SBR_3_0_API_Contract_OpenOrderTaxUpdate.WrapTotals();
            wrapOrder.totals.fuel = '98';
            wrapOrder.totals.environmental = '89';
            wrapOrder.totals.misc = '89';
            wrapOrder.totals.deliveryAndPickup = '89';
            wrapOrder.totals.rentals = '89';
            wrapOrder.totals.salesAmount = '89';
            wrapOrder.totals.rpp = '89';
            wrapOrder.totals.finalTotal = '89';
            wrapOrder.totals.tax = '89';

            List<SBR_3_0_API_Contract_OpenOrderTaxUpdate.WrapProductOrderItem> ordItmWrapperLst = new List<SBR_3_0_API_Contract_OpenOrderTaxUpdate.WrapProductOrderItem>();
            SBR_3_0_API_Contract_OpenOrderTaxUpdate.WrapProductOrderItem ordItmWrapper = new SBR_3_0_API_Contract_OpenOrderTaxUpdate.WrapProductOrderItem();
            ordItmWrapper.description = 'test';
            ordItmWrapperLst.add(ordItmWrapper);

            List<SBR_3_0_API_Contract_OpenOrderTaxUpdate.WrapMiscOrderItem> miscOrdItmWrapperLst = new List<SBR_3_0_API_Contract_OpenOrderTaxUpdate.WrapMiscOrderItem>();
            SBR_3_0_API_Contract_OpenOrderTaxUpdate.WrapMiscOrderItem miscOrdItmWrapper = new SBR_3_0_API_Contract_OpenOrderTaxUpdate.WrapMiscOrderItem();
            miscOrdItmWrapper.item = '01';
            miscOrdItmWrapperLst.add(miscOrdItmWrapper);

            List<SBR_3_0_API_Contract_OpenOrderTaxUpdate.WrapSalesOrderItem> salesOrdItmWrapperLst = new List<SBR_3_0_API_Contract_OpenOrderTaxUpdate.WrapSalesOrderItem>();
            SBR_3_0_API_Contract_OpenOrderTaxUpdate.WrapSalesOrderItem salesOrdItmWrapper = new SBR_3_0_API_Contract_OpenOrderTaxUpdate.WrapSalesOrderItem();
            salesOrdItmWrapper.description = 'test';
            salesOrdItmWrapperLst.add(salesOrdItmWrapper);

            wrapOrder.products = ordItmWrapperLst;
            wrapOrder.miscItems = miscOrdItmWrapperLst;
            wrapOrder.salesItems = salesOrdItmWrapperLst;
            String res = JSON.serialize(wrapOrder);
                    Test.setMock(HttpCalloutMock.class, new SBR_3_0_APIContractOpenOrderTaxUpdtTest());
            Test.startTest();
                Order order = [SELECT id,Total_Misc__c,Quote_Name__c,Total_Rental_Amount__c,Total_Sales_Amount__c,RPP_Amount__c,Total_Sales_Taxes__c,
                        Total_Ordered_Amount__c FROM Order WHERE Quote_Name__c = 'Test Quote1'];
                        
                List<OrderItem> lstOrdItm = [SELECT id,Line_Composite_Key__c,Total_Price__c,Rental_Tax__c FROM OrderItem Where OrderId =: order.Id];
            
            //   String response ='{"companyId":"01","contractNumber":"119085598","sequenceNumber":"0000","type":"RESERVATION","channel":"SBRWEBSITE","contractStartDateTime":"2022-03-25 14:36","contractReturnDateTime":"2022-03-28 14:36","numberOfRentalDays":"2","numberOfRentalHours":".00","isDeliveryAndPickupCharge":"true","isRPPCharge":"false","assignedToEmployeeID":"","assignedToEmployeeName":"","fulfillmentStatus":"N","stagingStatus":"N","customerOnSite":"N","Cancellation_NameF":"","Cancellation_NameL":"","Cancellation_Phone":"","Cancellation_Email":"","Cancellation_Date":"","Cancellation_Code":"","Cancellation_Reason":"","Cancellation_Channel":"","pc":[{"id":"0720","name":"FORT MILL SC","address":{"line1":"120 SUTTON RIDGE LN","line2":"","city":"FORT MILL","state":"SC","zip":"29708 9400","phoneNumber":"8032289999","latitude":"34.999907","longitude":"-80.976919","email":"pcm@sunbeltrentals.com"}}],"customer":[{"driverLicenseState":"NC","driverLicenseNumber":"123456","name":"TEST, MANDATORY","address":{"type":"billing","line1":"100 E MAIN STREET","line2":"","city":"FORT MILL","state":"NC","zip":"28105","phoneNumber":"9546729801","poNumber":"RPO-11186","orderedBy":"USER"}}],"jobsite":[{"location":"","number":"","name":"TEST, MANDATORY","address":{"line1":"100 E MAIN STREET","line2":"","city":"FORT MILL","state":"NC","zip":"28105","phoneNumber":"9546729801"}}],"orderComments":[],"deliveryInstruction":[],"products":[{"description":"4 GALLON COMMERCIAL CARPET EXTRACTOR","productId":"0680210","make":"","model":"","serial#":"","minimumRate":"190.00","dayRate":"190.00","weekRate":"420.00","monthlyRate":"775.00","quantity":"1.00","unitCost":"380.00","rentalCost":"380.000","lineNumber":"1","rmLineNumber":"152620617","rentalTax":"3.50","miscellaneousOptions":"","rentalItemComments":[]},{"productId":"0680210","description":"4 GALLON COMMERCIAL CARPET EXTRACTOR","make":"","model":"","serial#":"","minimumRate":"190.00","dayRate":"190.00","weekRate":"420.00","monthlyRate":"775.00","quantity":"1.00","unitCost":"380.00","rentalCost":"380.000","lineNumber":"2","rmLineNumber":"152620618","rentalTax":"3.50","miscellaneousOptions":"","rentalItemComments":[]}],"salesItems":[{"itemNumber":"123458","description":"4 GALLON COMMERCIAL CARPET EXTRACTOR","stockClass":"9","quantity":"1.00","unitCost":"190.000","cost":"190.000","salesTax":"11.40","rmLineNumber":"152420916","SKU":"0"}],"miscItems":[{"item":"TRANSPORTATION SURCHARGE","stockClass":"FUEL","quantity":"1.00","unitCost":"17.500","cost":"17.500","tax":"1.23","rmLineNumber":"152620622","SKU":"10037737"},{"item":"ENVIRONMENTAL","stockClass":"MISC","quantity":"1.00","unitCost":"9.500","cost":"9.500","tax":".67","rmLineNumber":"152620619","SKU":"10044906"},{"item":"DELIVERY","stockClass":"DEL","quantity":"1.00","unitCost":"50.000","cost":"50.000","tax":"3.50","rmLineNumber":"152620620","SKU":"10036685"},{"item":"PICKUP","stockClass":"DEL","quantity":"1.00","unitCost":"50.000","cost":"50.000","tax":"3.50","rmLineNumber":"152620621","SKU":"10106520"}],"totals":{"rentals":"760.00","salesAmount":".00","rpp":".00","fuel":".00","environmental":"9.50","deliveryAndPickup":"100.00","misc":"17.50","tax":"62.10","finalTotal":"949.10"}}';
               // SBR_3_0_API_Contract_OpenOrderTaxUpdate.parseResponseAndUpdateTaxes('1234',lstOrdItm,response,order);
                               SBR_3_0_API_Contract_OpenOrderTaxUpdate.OrderWrapper orderWrapped = SBR_3_0_API_Contract_OpenOrderTaxUpdate.updateOrderItemTaxes(order.Id);

                             Test.stopTest();
            Order updatedOrder = [SELECT id,Total_Misc__c,Quote_Name__c,Total_Rental_Amount__c,Total_Sales_Amount__c,RPP_Amount__c,Total_Sales_Taxes__c,
                        Total_Ordered_Amount__c FROM Order WHERE Quote_Name__c = 'Test Quote1'];
            System.assertEquals(760.00, updatedOrder.Total_Rental_Amount__c, 'Total Rental Amount was an unexpected value.');
        }
    }
    */
    @isTest
    static void testUpdateOrderItemTaxesReservationOrder(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_APIContractOpenOrderTaxUpdtTest());
        Order order = [SELECT id FROM Order WHERE Quote_Name__c = 'Test Quote1'];
              User adminUser = [Select Id from User Limit 1];

        System.runAs(adminUser){
            Test.startTest();
            
                SBR_3_0_API_Contract_OpenOrderTaxUpdate.OrderWrapper orderWrapped = SBR_3_0_API_Contract_OpenOrderTaxUpdate.updateOrderItemTaxes(order.Id);
               
            Test.stopTest();
            System.assert(orderWrapped != null, 'orderWrapped was null');
        }
        
    }
    @isTest
    static void testUpdateOrderItemTaxesSalesOrder(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_APIContractOpenOrderTaxUpdtTest());
        Order order = [SELECT id FROM Order WHERE Quote_Name__c = 'Test Quote2'];
                    User adminUser = [Select Id from User Limit 1];
                        List<OrderItem> lstOrdItm = [SELECT id,Line_Composite_Key__c,Total_Price__c,Rental_Tax__c FROM OrderItem Where OrderId =: order.Id];

     //   String res = '{"company": "01", "contractNumber": "119211470","sequenceNumber": "0000", "type": "SALES ORDER", "openDate": " ", "closedDate": " ", "issuedDate": "          ","dueDate": "          ","status": "HL",  "isDeliveryAndPickupCharge": "true", "assignedToEmployeeID": "", "assignedToEmployeeName": "","fulfillmentStatus": "N", "stagingStatus": "N", "customerOnSite": "N","Cancellation_NameF": "", "Cancellation_NameL": "", "Cancellation_Phone": "",  "Cancellation_Email": "", "Cancellation_Date": "",  "Cancellation_Code": "", "Cancellation_Reason": "", "Cancellation_Channel": "","location": [ { "number": "0011",  "name": "DURHAM PC7862",  "address1": "6425 RANGELINE RD",  "address2": "", "city": "THEODORE",  "state": "AL", "zip": "36582",    "phoneNumber": "9193836668",     "latitude": "30.557716",     "longitude": "-88.122827",   "pcEmail": "PCM011@sunbeltrentals.com"   }],"customer": [ { "corpLink": "1", "number": "1","name": "SUNBELT RENTALS MISC ACCT", "cusDueTerms": "Net 30","billingAddress1": "2341 DEERFIELD DR","billingAddress2": "","billingCity": "FORT MILL","billingState": "SC","billingZip": "29715", "phoneNumber": "7320",  "poNumber": "T", "orderedBy": "" }],"jobsite": [ { "location": "14425 BALLANTYNE LAKE RD, CHARLOTTE", "number": "&&&&&&PCTPCTPCTPCT**","name": "&&&&&&PCTPCTPCTPCT**", "address1": "14425 BALLANTYNE LAKE RD", "address2": "","city": "CHARLOTTE","state": "NC","zip": "28277 3334","phoneNumber": "7319187348"    } ],"mailPayments": [ {    "name": "SUNBELT RENTALS INC.", "address1": "PO BOX 409211","address2": "", "city": "ATLANTA","state": "GA", "zip": "30384-9211" }],  "orderComments": [], "deliveryInstruction": [], "salesItems": [ {  "quantity": "1.00",  "price": "3.153",  "part": "#10", "unitOfMeasure": "EA",   "description": "KEY",  "amount": "3.15", "rowID": "53473892", "SKU": "11356543",  "salesItemComments": []}, {  "quantity": "1.00",  "price": ".000", "part": "DELIVERY",  "unitOfMeasure": "",  "description": "DELIVERY",  "amount": ".00",  "rowID": "53473893",  "SKU": "10036685", "salesItemComments": [] }],"subTotals": {"salesItemsSubtotal": "3.15" },"totals": { "credit": ".00", "deliveryAndPickup": "200.00","fuel": ".00","misc": ".00","tax": ".22","appliedDiscountAmount": ".00","payment": ".00","currentBalance": ".22","totalInvoiceAmount": "3.37"}}' ;
        System.runAs(adminUser){
        Test.startTest();
            SBR_3_0_API_Contract_OpenOrderTaxUpdate.OrderWrapper orderWrapped = SBR_3_0_API_Contract_OpenOrderTaxUpdate.updateOrderItemTaxes(order.Id);
        Test.stopTest();
        System.assert(orderWrapped != null, 'orderWrapped was null');
        }
    }
    /**
     * @description mock response 
     * @param request 
     * @return  `HTTPResponse`
     */
    public HTTPResponse respond(HTTPRequest request) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        request.setHeader('Content-Type',SBR_3_0_Constants.APP_JSON);
        if(request.getEndpoint().endsWithIgnoreCase('token')){
            res.setBody('{"access_token":"test"}');
        }
        if(request.getEndpoint().contains('12342'))
        {
            res.setBody(' {"companyId":"01","contractNumber":"119085598","sequenceNumber":"0000","type":"RESERVATION","channel":"SBRWEBSITE","contractStartDateTime":"2022-03-25 14:36","contractReturnDateTime":"2022-03-28 14:36","numberOfRentalDays":"2","numberOfRentalHours":".00","isDeliveryAndPickupCharge":"true","isRPPCharge":"false","assignedToEmployeeID":"","assignedToEmployeeName":"","fulfillmentStatus":"N","stagingStatus":"N","customerOnSite":"N","Cancellation_NameF":"","Cancellation_NameL":"","Cancellation_Phone":"","Cancellation_Email":"","Cancellation_Date":"","Cancellation_Code":"","Cancellation_Reason":"","Cancellation_Channel":"","pc":[{"id":"0720","name":"FORT MILL SC","address":{"line1":"120 SUTTON RIDGE LN","line2":"","city":"FORT MILL","state":"SC","zip":"29708 9400","phoneNumber":"8032289999","latitude":"34.999907","longitude":"-80.976919","email":"pcm@sunbeltrentals.com"}}],"customer":[{"driverLicenseState":"NC","driverLicenseNumber":"123456","name":"TEST, MANDATORY","address":{"type":"billing","line1":"100 E MAIN STREET","line2":"","city":"FORT MILL","state":"NC","zip":"28105","phoneNumber":"9546729801","poNumber":"RPO-11186","orderedBy":"USER"}}],"jobsite":[{"location":"","number":"","name":"TEST, MANDATORY","address":{"line1":"100 E MAIN STREET","line2":"","city":"FORT MILL","state":"NC","zip":"28105","phoneNumber":"9546729801"}}],"orderComments":[],"deliveryInstruction":[],"products":[{"description":"4 GALLON COMMERCIAL CARPET EXTRACTOR","productId":"0680210","make":"","model":"","serial#":"","minimumRate":"190.00","dayRate":"190.00","weekRate":"420.00","monthlyRate":"775.00","quantity":"1.00","unitCost":"380.00","rentalCost":"380.000","lineNumber":"1","rmLineNumber":"152620617","rentalTax":"3.50","miscellaneousOptions":"","rentalItemComments":[]},{"productId":"0680210","description":"4 GALLON COMMERCIAL CARPET EXTRACTOR","make":"","model":"","serial#":"","minimumRate":"190.00","dayRate":"190.00","weekRate":"420.00","monthlyRate":"775.00","quantity":"1.00","unitCost":"380.00","rentalCost":"380.000","lineNumber":"2","rmLineNumber":"152620618","rentalTax":"3.50","miscellaneousOptions":"","rentalItemComments":[]}],"salesItems":[{"itemNumber":"123458","description":"4 GALLON COMMERCIAL CARPET EXTRACTOR","stockClass":"9","quantity":"1.00","unitCost":"190.000","cost":"190.000","salesTax":"11.40","rmLineNumber":"152420916","SKU":"0"}],"miscItems":[{"item":"TRANSPORTATION SURCHARGE","stockClass":"FUEL","quantity":"1.00","unitCost":"17.500","cost":"17.500","tax":"1.23","rmLineNumber":"152620622","SKU":"10037737"},{"item":"ENVIRONMENTAL","stockClass":"MISC","quantity":"1.00","unitCost":"9.500","cost":"9.500","tax":".67","rmLineNumber":"152620619","SKU":"10044906"},{"item":"DELIVERY","stockClass":"DEL","quantity":"1.00","unitCost":"50.000","cost":"50.000","tax":"3.50","rmLineNumber":"152620620","SKU":"10036685"},{"item":"PICKUP","stockClass":"DEL","quantity":"1.00","unitCost":"50.000","cost":"50.000","tax":"3.50","rmLineNumber":"152620621","SKU":"10106520"}],"totals":{"rentals":"760.00","salesAmount":".00","rpp":".00","fuel":".00","environmental":"9.50","deliveryAndPickup":"100.00","misc":"17.50","tax":"62.10","finalTotal":"949.10"}}');
        } else if(request.getEndpoint().contains('65'))
        {
            res.setBody('{"company": "01", "contractNumber": "119211470","sequenceNumber": "0000", "type": "SALES ORDER", "openDate": " ", "closedDate": " ", "issuedDate": "          ","dueDate": "          ","status": "HL",  "isDeliveryAndPickupCharge": "true", "assignedToEmployeeID": "", "assignedToEmployeeName": "","fulfillmentStatus": "N", "stagingStatus": "N", "customerOnSite": "N","Cancellation_NameF": "", "Cancellation_NameL": "", "Cancellation_Phone": "",  "Cancellation_Email": "", "Cancellation_Date": "",  "Cancellation_Code": "", "Cancellation_Reason": "", "Cancellation_Channel": "","location": [ { "number": "0011",  "name": "DURHAM PC7862",  "address1": "6425 RANGELINE RD",  "address2": "", "city": "THEODORE",  "state": "AL", "zip": "36582",    "phoneNumber": "9193836668",     "latitude": "30.557716",     "longitude": "-88.122827",   "pcEmail": "PCM011@sunbeltrentals.com"   }],"customer": [ { "corpLink": "1", "number": "1","name": "SUNBELT RENTALS MISC ACCT", "cusDueTerms": "Net 30","billingAddress1": "2341 DEERFIELD DR","billingAddress2": "","billingCity": "FORT MILL","billingState": "SC","billingZip": "29715", "phoneNumber": "7320",  "poNumber": "T", "orderedBy": "" }],"jobsite": [ { "location": "14425 BALLANTYNE LAKE RD, CHARLOTTE", "number": "&&&&&&PCTPCTPCTPCT**","name": "&&&&&&PCTPCTPCTPCT**", "address1": "14425 BALLANTYNE LAKE RD", "address2": "","city": "CHARLOTTE","state": "NC","zip": "28277 3334","phoneNumber": "7319187348"    } ],"mailPayments": [ {    "name": "SUNBELT RENTALS INC.", "address1": "PO BOX 409211","address2": "", "city": "ATLANTA","state": "GA", "zip": "30384-9211" }],  "orderComments": [], "deliveryInstruction": [], "salesItems": [ {  "quantity": "1.00",  "price": "3.153",  "part": "#10", "unitOfMeasure": "EA",   "description": "KEY",  "amount": "3.15", "rowID": "53473892", "SKU": "11356543",  "salesItemComments": []}, {  "quantity": "1.00",  "price": ".000", "part": "DELIVERY",  "unitOfMeasure": "",  "description": "DELIVERY",  "amount": ".00",  "rowID": "53473893",  "SKU": "10036685", "salesItemComments": [] }],"subTotals": {"salesItemsSubtotal": "3.15" },"totals": { "credit": ".00", "deliveryAndPickup": "200.00","fuel": ".00","misc": ".00","tax": ".22","appliedDiscountAmount": ".00","payment": ".00","currentBalance": ".22","totalInvoiceAmount": "3.37"}}');
        }
        res.setStatusCode(200);
       
        return res;
    }
}