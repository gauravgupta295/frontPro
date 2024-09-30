@isTest
public class SBR_3_0_GeneratePOPDFUtility_Test {

    @TestSetup
    static void makeData(){
        // Create Account
        Account acct =  SBR_3_0_ServiceTestDataFactory.createAccount(false,'33333');
        acct.E_mail_Address__c = '123@asdf.com';
        acct.Company_Code__c   = '01';
        acct.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Vendor').getRecordTypeId(); 
        insert acct;

        //PO with basic information
        List<Purchase_Order__c> pos= new List<Purchase_Order__c>();
        Purchase_Order__c po1 = new Purchase_Order__c();
        po1.Name = '887796990';
        po1.Vendor__c = acct.id;
        po1.RecordTypeId = Schema.SObjectType.Purchase_Order__c.getRecordTypeInfosByDeveloperName().get(SBR_3_0_GeneratePOPDFUtility.PURCHASEORDER_RECORDTYPE_STANDARD).getRecordTypeId();
		pos.add(po1);
        
        Purchase_Order__c po2 = new Purchase_Order__c();
        po2.Name = '887796991';
        po2.Vendor__c = acct.id;
        po2.RecordTypeId = Schema.SObjectType.Purchase_Order__c.getRecordTypeInfosByDeveloperName().get(SBR_3_0_GeneratePOPDFUtility.PURCHASEORDER_RECORDTYPE_RERENT).getRecordTypeId();
		pos.add(po2);
        
        //PO with basic information
        Purchase_Order__c po3 = new Purchase_Order__c();
        po3.Name = '887796992';
        po3.Vendor__c = acct.id;
        po3.RecordTypeId = Schema.SObjectType.Purchase_Order__c.getRecordTypeInfosByDeveloperName().get(SBR_3_0_GeneratePOPDFUtility.PURCHASEORDER_RECORDTYPE_3RD).getRecordTypeId();
		pos.add(po3);
        insert pos;        
    }

    @isTest
    public static void getPurchaseOrderTest(){     

        Test.startTest();
            // Standard Purchase Order
            Purchase_Order__c po = [SELECT Id FROM Purchase_Order__c WHERE Name = '887796990' LIMIT 1];
            Purchase_Order__c stdPO = SBR_3_0_GeneratePOPDFUtility.getPurchaseOrder(po.Id);
            Assert.areEqual(SBR_3_0_GeneratePOPDFUtility.PURCHASEORDER_RECORDTYPE_STANDARD, stdPO.RecordType.DeveloperName);

            // Rerent
            po = [SELECT Id FROM Purchase_Order__c WHERE Name = '887796991' LIMIT 1];
            Purchase_Order__c rerentPO = SBR_3_0_GeneratePOPDFUtility.getPurchaseOrder(po.Id);
            Assert.areEqual(SBR_3_0_GeneratePOPDFUtility.PURCHASEORDER_RECORDTYPE_RERENT, rerentPO.RecordType.DeveloperName);

            // Third Party PO
            po = [SELECT Id FROM Purchase_Order__c WHERE Name = '887796992' LIMIT 1];
            Purchase_Order__c thirdPO = SBR_3_0_GeneratePOPDFUtility.getPurchaseOrder(po.Id);
            Assert.areEqual(SBR_3_0_GeneratePOPDFUtility.PURCHASEORDER_RECORDTYPE_3RD, thirdPO.RecordType.DeveloperName);
        Test.stopTest();
    }

    @isTest
    public static void getPurchaseOrderMapTest(){

        Test.startTest();
            // Standard Purchase Order
            Purchase_Order__c po = [SELECT Id FROM Purchase_Order__c WHERE Name = '887796990' LIMIT 1];
            Purchase_Order__c stdPO = SBR_3_0_GeneratePOPDFUtility.getPurchaseOrder(po.Id);
            Map<String, Object> stdPOMap = SBR_3_0_GeneratePOPDFUtility.getPurchaseOrderMap(stdPO);
            Assert.isNotNull(stdPOMap);

            // Rerent
            po = [SELECT Id FROM Purchase_Order__c WHERE Name = '887796991' LIMIT 1];
            Purchase_Order__c rerentPO = SBR_3_0_GeneratePOPDFUtility.getPurchaseOrder(po.Id);
            Map<String, Object> rerentPOMap = SBR_3_0_GeneratePOPDFUtility.getPurchaseOrderMap(rerentPO);
            Assert.isNotNull(rerentPOMap);

            // Third Party Hauler
            po = [SELECT Id FROM Purchase_Order__c WHERE Name = '887796992' LIMIT 1];
            Purchase_Order__c thirdPO = SBR_3_0_GeneratePOPDFUtility.getPurchaseOrder(po.Id);
            Map<String, Object> thirdPOMap = SBR_3_0_GeneratePOPDFUtility.getPurchaseOrderMap(thirdPO);
            Assert.isNotNull(thirdPOMap);
        Test.stopTest();
    }
    
    @isTest
    public static void getTemplateIdTest(){
        Test.startTest();
            // Standard Purchase Order
            Purchase_Order__c po = [SELECT Id FROM Purchase_Order__c WHERE Name = '887796990' LIMIT 1];
            String templateId = SBR_3_0_GeneratePOPDFUtility.getTemplateId();
            Assert.isNotNull(templateId);
        Test.stopTest();
    }
    
    @isTest
    public static void getFileNameTest(){
        Test.startTest();
            //Check file name
            Purchase_Order__c po = [SELECT Id,Name FROM Purchase_Order__c WHERE Name = '887796990' LIMIT 1];
            String fileName = SBR_3_0_GeneratePOPDFUtility.getFileName(po);
            Assert.areEqual(('PO_'+po.Name), fileName);
        Test.stopTest();
    }

    @isTest
    public static void stripExtraDataTest(){
        Map<String, Object> testMap = new Map<String, Object>{
            'ShipTo_Location__r' => new Map<String, Object>{
                'attributes'     => 'someValue'
            },
            'OrderedBy__r'          => new Map<String, Object>{
                'attributes'     => 'someValue'
            },
            'Branch_Location__r' => new Map<String, Object>{
                'attributes'     => 'someValue'
            },
            'PO_Line_Items__r' => new Map<String, Object>{
                'done'      => true,
                'totalSize' => 1,
                'records'   => new List<Object>{
                    new Map<String, Object>{
                        'attributes'                    => 'someValue',
                        'Quantity__c'                   => 10,
                        'Quantity_Rcvd__c'              => 10
                    }
                }
            },
            'PO_Receipts__r' => new Map<String, Object>{
                'done'      => true,
                'totalSize' => 1,
                'records'   => new List<Object>{
                    new Map<String, Object>{
                        'attributes'             => 'someValue',
                        'Bin_1__c' => 'A5'
                    }
                }
            }
        };
        Test.startTest();
            SBR_3_0_GeneratePOPDFUtility.stripExtraData(testMap);
            Assert.areEqual(false, ((Map<String, Object>)testMap.get('PO_Line_Items__r')).containsKey('done'), 'done attribute removed from map');
        Test.stopTest();
    }
}