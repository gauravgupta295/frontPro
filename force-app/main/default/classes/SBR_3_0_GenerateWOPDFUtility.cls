/*********************************************************************************************************************
* Apex Class: SBR_3_0_GenerateWOPDFUtility
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Utility class for the common functionality needed to generate and retrieve pdf from flow and quick action
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Akhil Tyagi             2023-10-31          Initial version
    2.0         Akhil Tyagi             2023-11-10          Added Error Handling
    3.0         Piyush Jindal           2023-12-01          Updated sendEmail method
    4.0         Akhil Tyagi             2023-12-05          Updated the code to handel Quote and Credit Work Order as well
    5.0         Akhil Tyagi             2023-12-15          Updated the code to handel child record fields not having data
    6.0         Akhil Tyagi             2023-12-18          Updated the logic of fileName creation
    7.0         Akhil Tyagi             2023-12-18          Added the logic for tax calculation
    8.0         Akhil Tyagi             2024-06-24          Updated the Miscllaneous mappings and Part# mapping
---------------------------------------------------------------------------------------------------------------------------------------
Note:-
* 
*********************************************************************************************************************/
public with sharing class SBR_3_0_GenerateWOPDFUtility {
    
    public static final String COMPANY_ID                       = '01';
    public static final String APINAME                          = 'DocGen_V2';
    public static final String X_CORRELATION_ID                 = SBR_3_0_Generic.generateRandomString(10);
    public static final String SOURCE_SF                        = 'SF';
    public static final String CONTENT_TYPE_JSON                = 'application/json';
    public static final String CONTENT_TYPE_PDF                 = 'application/pdf';
    public static final String THRESHOLD_WAIT_TIME              = '1';
    public static final String EXECUTION_TYPE_FLOW              = 'Flow';
    public static final String EXECUTION_TYPE_AURA              = 'Aura';
    public static final String WORKORDER_RECORDTYPE_QUOTE       = 'SF_PS_Quote';
    public static final String WORKORDER_RECORDTYPE_CREDIT      = 'SF_PS_Credit';
    public static final String WORKORDER_RECORDTYPE_INSPECTION  = 'SF_PS_Inspection_Record';
    public static final Integer ATTACHMENT_DISPOSITION_0        = 0;
    public static final String FILE_EXTENSION_PDF               = '.pdf';
    public static final String RESPONSE_STATUS_COMPLETE         = 'Complete';
    public static final String RESPONSE_STATUS_INPROGRESS       = 'In Progress';
    public static final String RESPONSE_STATUS_INCOMPLETE       = 'InComplete';

    /*********************************************************************************************************************
    * Purpose/Methods:
    * Note: Only use parent fields till single level
    * Valid eg: Product2.SM_PS_Item_number__c
    * Invalid eg: Product2.CreatedBy.Name
    *********************************************************************************************************************/
    public static final Map<String, List<String>> CHILD_OBJECT_PAYLOAD_REQUIRED_FIELDS = new Map<String, List<String>>{
        'Credit_Line_Items__r' => new List<String>{'SF_PS_Mechanic_ID__c', 'SF_PS_Hr_Mi_To_Credit__c', 'SF_PS_Credit_Rate_Hr_Mi__c', 'SF_PS_Extended_Amt__c'},
        'Credited_Parts__r'    => new List<String>{'SF_PS_Parts_To_Credit__c', 'SF_PS_Product2Id__c', 'SF_PS_Credit_Price__c', 'SF_PS_Extended_Amt__c', 'SF_PS_Description__c', 'SF_PS_Unit_Of_Measure__c', 'SF_PS_Labor_Code__c', 'SF_PS_ItemType__c'},
        'Quote_Line_Items__r'  => new List<String>{'SF_PS_Mechanic_Id__c', 'SF_PS_Duration__c', 'SF_PS_Hourly_Internal_Rate__c', 'SF_PS_Extended_Amt__c'},
        'Quoted_Parts__r'      => new List<String>{'SF_PS_Quantity__c', 'SF_PS_ProductItem__r.SM_PS_Item_Number__c', 'SM_PS_Description__c', 'SF_PS_Unit_Of_Measure__c', 'SF_PS_Selling_Price__c', 'SF_PS_Sub_Total__c', 'SF_PS_Labor_Code__c', 'SF_PS_ItemType__c'},
        'WorkOrderLineItems'   => new List<String>{'SF_PS_Mechanic_Id__c', 'Duration', 'SF_PS_Hourly_Internal_Rate__c', 'SF_PS_Extended_Rate__c'},
        'ProductsConsumed'     => new List<String>{'SF_PS_Quantity__c', 'SF_PS_Product_Item__r.SM_PS_Item_Number__c', 'SF_PS_Description__c', 'SF_PS_Unit_Of_Measure__c', 'SF_PS_Selling_Price__c', 'SF_PS_Sub_Total__c', 'SF_PS_Labor_Code__c', 'SF_PS_ItemType__c'}
    };

    /*********************************************************************************************************************
    * Purpose/Methods:
    * Returns WorkOrder record
    *********************************************************************************************************************/
    public static WorkOrder getWorkOrder(String workOrderId){
        String workOrderRecordType = getWorkOrderRecordType(workOrderId);
        String query = 'SELECT Id, WorkOrderNumber, SF_PS_Barcode__c, ServiceTerritory.Name, ServiceTerritory.Branch_Location_Number__c, ServiceTerritory.Address, SVMXA360__ContactPhone__c, SF_PS_Job_Location__c, SF_PS_Job_Site__r.JobsiteName__c, Account.BillingAddress, Account.E_mail_Address__c, Contact.Name, Contact.Phone, RecordType.DeveloperName, RecordType.Name, SF_PS_RM_WO_Number__c, SF_PS_Invoice_Date__c, SF_PS_BillCustOrLoc__c, Account.RM_Account_Number__c, SF_PS_Job_Site__r.Job_Number__c, SF_PS_PONumber__c, SF_PS_Authorized_By__c, SF_PS_Date_Opened__c, SF_PS_Closed_Date__c, CreatedBy.Name, SF_PS_Current_MiHr__c, Asset.SM_PS_Equipment_Number__c, Asset.SM_PS_Cat_Class_Description__c, SF_PS_Make__c, SF_PS_Model__c, SF_PS_Serial_Number__c, SF_PS_Work_Order_Des__c, SF_PS_Labor_Des_Comments__c, SF_PS_Company_Code__c, SF_PS_Tax_On_Sales__c, SF_PS_County_Tax_Amt__c, SF_PS_State_Tax_Amt__c, (SELECT Id, Name FROM WorkSteps), ';
        if(workOrderRecordType == WORKORDER_RECORDTYPE_CREDIT){
            query += (
                'ParentWorkOrderId, ' +
                '(SELECT ' + String.join(CHILD_OBJECT_PAYLOAD_REQUIRED_FIELDS.get('Credit_Line_Items__r'), ', ') + ' FROM Credit_Line_Items__r), ' + 
                '(SELECT ' + String.join(CHILD_OBJECT_PAYLOAD_REQUIRED_FIELDS.get('Credited_Parts__r'), ', ') + ' FROM Credited_Parts__r) '
            );
        } else if(workOrderRecordType == WORKORDER_RECORDTYPE_QUOTE){
            query += (
                '(SELECT Id, Name FROM WorkPlans), ' +
                '(SELECT ' + String.join(CHILD_OBJECT_PAYLOAD_REQUIRED_FIELDS.get('Quote_Line_Items__r'), ', ') + ' FROM Quote_Line_Items__r), ' + 
                '(SELECT ' + String.join(CHILD_OBJECT_PAYLOAD_REQUIRED_FIELDS.get('Quoted_Parts__r'), ', ') + ' FROM Quoted_Parts__r) '
            );
        } else{
            query += (
                '(SELECT Id, Name FROM WorkPlans), ' +
                '(SELECT ' + String.join(CHILD_OBJECT_PAYLOAD_REQUIRED_FIELDS.get('WorkOrderLineItems'), ', ') + ' FROM WorkOrderLineItems), ' + 
                '(SELECT ' + String.join(CHILD_OBJECT_PAYLOAD_REQUIRED_FIELDS.get('ProductsConsumed'), ', ') + ' FROM ProductsConsumed) '
            );
        }
        query += ' FROM WorkOrder WHERE Id = :workOrderId';

        WorkOrder wo = Database.query(query);
        return wo;
    }

    /*********************************************************************************************************************
    * Purpose/Methods:
    * Get workorder map with updated values
    *********************************************************************************************************************/
    public static Map<String, Object> getWorkOrderMap(WorkOrder wo){

        Map<String,Object> woMap = (Map<String,Object>)JSON.deserializeUntyped(JSON.serialize(wo));
        Decimal totalPartsCost;
        Decimal totalLineItemsCost;
        Decimal totalMiscellaneousCost;
        Decimal totalTax = 0;
        if(wo.SF_PS_Company_Code__c != null){
            if(wo.SF_PS_Company_Code__c == '01' && wo.SF_PS_Tax_On_Sales__c != null){
                totalTax = wo.SF_PS_Tax_On_Sales__c;
            } else if(wo.SF_PS_Company_Code__c == '02'){
                totalTax = (wo.SF_PS_County_Tax_Amt__c != null ? wo.SF_PS_County_Tax_Amt__c : 0) + (wo.SF_PS_State_Tax_Amt__c != null ? wo.SF_PS_State_Tax_Amt__c : 0);
            }
        }

        if(wo.RecordType.DeveloperName == WORKORDER_RECORDTYPE_CREDIT){
            totalPartsCost         = getTotalExtendedAmount(wo, 'Credited_Parts__r',    'SF_PS_Extended_Amt__c', 'parts');
            totalLineItemsCost     = getTotalExtendedAmount(wo, 'Credit_Line_Items__r', 'SF_PS_Extended_Amt__c', 'lineItems');
            totalMiscellaneousCost = getTotalExtendedAmount(wo, 'Credited_Parts__r',    'SF_PS_Extended_Amt__c', 'misc');
            
            setChildRecordsData(woMap, 'Credited_Parts__r');
            setChildRecordsData(woMap, 'Credit_Line_Items__r');
            getCreditWOMap(woMap);
        } else if(wo.RecordType.DeveloperName == WORKORDER_RECORDTYPE_QUOTE){
            totalPartsCost         = getTotalExtendedAmount(wo, 'Quoted_Parts__r',     'SF_PS_Sub_Total__c',    'parts');
            totalLineItemsCost     = getTotalExtendedAmount(wo, 'Quote_Line_Items__r', 'SF_PS_Extended_Amt__c', 'lineItems');
            totalMiscellaneousCost = getTotalExtendedAmount(wo, 'Quoted_Parts__r',     'SF_PS_Sub_Total__c',    'misc');
            
            setChildRecordsData(woMap, 'Quoted_Parts__r');
            setChildRecordsData(woMap, 'Quote_Line_Items__r');
            getQuoteWOMap(woMap);
        } else{
            totalPartsCost         = getTotalExtendedAmount(wo, 'ProductsConsumed',   'SF_PS_Sub_Total__c',     'parts');
            totalLineItemsCost     = getTotalExtendedAmount(wo, 'WorkOrderLineItems', 'SF_PS_Extended_Rate__c', 'lineItems');
            totalMiscellaneousCost = getTotalExtendedAmount(wo, 'ProductsConsumed',   'SF_PS_Sub_Total__c',     'misc');
            
            setChildRecordsData(woMap, 'ProductsConsumed');
            setChildRecordsData(woMap, 'WorkOrderLineItems');
            getInspectionWOMap(woMap);
        }

        woMap.put('TotalPartsCost',  getAmountString(totalPartsCost));
        woMap.put('TotalLineItemsCost', getAmountString(totalLineItemsCost));
        woMap.put('TotalMiscellaneousCost', getAmountString(totalMiscellaneousCost));
        woMap.put('TotalTax', getAmountString(totalTax));
        woMap.put('TotalSubtotal', getAmountString(totalPartsCost + totalLineItemsCost + totalMiscellaneousCost));
        woMap.put('TotalAmount',  getAmountString(totalPartsCost + totalLineItemsCost + totalMiscellaneousCost + totalTax));
        woMap.put('AccountNumber', ((wo.SF_PS_BillCustOrLoc__c == 'C' && String.isNotBlank(wo.AccountId) && String.isNotBlank(wo.Account.RM_Account_Number__c)) ? wo.Account.RM_Account_Number__c : ''));
        woMap.put('SF_PS_Invoice_Date__c', (wo.SF_PS_Invoice_Date__c != null ? (wo.SF_PS_Invoice_Date__c.month() + '/' + wo.SF_PS_Invoice_Date__c.day() + '/' + wo.SF_PS_Invoice_Date__c.year()) : ''));
        woMap.put('SF_PS_Date_Opened__c', (wo.SF_PS_Date_Opened__c != null ? wo.SF_PS_Date_Opened__c.format('MM/dd/yyyy') : ''));
        woMap.put('SF_PS_Closed_Date__c', (wo.SF_PS_Closed_Date__c != null ? wo.SF_PS_Closed_Date__c.format('MM/dd/yyyy') : ''));
        woMap.put('SF_PS_Labor_Des_Comments__c', (wo.SF_PS_Labor_Des_Comments__c != null ? wo.SF_PS_Labor_Des_Comments__c.replace('\r\n', ' ').replace('\n', ' ').trim() : ''));

        stripExtraData(woMap);
        return woMap;
    }

    /*********************************************************************************************************************
    * Purpose/Methods:
    * Gives the sum of the field on the child records
    *********************************************************************************************************************/
    public static Decimal getTotalExtendedAmount(WorkOrder wo, String childRelationshipName, String fieldName, String childType){
        Decimal total = 0;
        List<SObject> childRecords = wo.getSObjects(childRelationshipName);
        if(childRecords != null && !childRecords.isEmpty()){
            for(SObject child : childRecords){
                String itemType;
                if(childType == 'parts' || childType == 'misc'){
                    itemType = (String)child.get('SF_PS_ItemType__c');
                }
                Object fieldValue = child.get(fieldName);
                if(fieldValue != null){
                    if( (childType == 'parts' && (itemType == 'M' || itemType == 'P')) || 
                        (childType == 'misc' && itemType == 'MI') ||
                        (childType == 'lineItems')
                    ){
                        total += (Decimal)fieldValue;
                    }
                }
            }
        }
        return total;
    }

    /*********************************************************************************************************************
    * Purpose/Methods:
    * Sets the child record fields in the map whose value is null on the record
    *********************************************************************************************************************/
    public static void setChildRecordsData(Map<String, Object> woMap, String childRelationshipName){
        if(woMap.get(childRelationshipName) != null){
            List<String> fieldList = CHILD_OBJECT_PAYLOAD_REQUIRED_FIELDS.get(childRelationshipName);
            Map<String, Object> childRecordsMap = (Map<String, Object>)woMap.get(childRelationshipName);
            for(Object childRecord : (List<Object>)childRecordsMap.get('records')){
                Map<String, Object> childMap = (Map<String, Object>)childRecord;
                for(String fieldName : fieldList){
                    if(!fieldName.contains('.') && !childMap.containsKey(fieldName)){
                        childMap.put(fieldName, '');
                    } else if(fieldName.contains('.')){
                        List<String> splitedFields = fieldName.split('\\.');
                        if(!childMap.containsKey(splitedFields[0])){
                            childMap.put(splitedFields[0], new Map<String, Object>{splitedFields[1] => ''});
                        } else if(!((Map<String, Object>)childMap.get(splitedFields[0])).containsKey(splitedFields[1])){
                            ((Map<String, Object>)childMap.get(splitedFields[0])).put(splitedFields[1], '');
                        }
                    }
                }
            }
        }
    }

    /*********************************************************************************************************************
    * Purpose/Methods:
    * Coverts Decimal amount to String
    *********************************************************************************************************************/
    public static String getAmountString(Decimal amount){
        return ('$' + String.valueOf(amount.setScale(2)));
    }

    /*********************************************************************************************************************
    * Purpose/Methods:
    * Removes extra data from the payload
    *********************************************************************************************************************/
    public static void stripExtraData(Map<String,Object> woMap){
        woMap.remove('attributes');
        if(woMap.containsKey('Asset') && woMap.get('Asset') != null){
            ((Map<String, Object>)woMap.get('Asset')).remove('attributes');
        }
        if(woMap.containsKey('RecordType')){
            woMap.remove('RecordType');
        }
        if(woMap.containsKey('Account') && woMap.get('Account') != null){
            ((Map<String, Object>)woMap.get('Account')).remove('attributes');
        }
        if(woMap.containsKey('Contact') && woMap.get('Contact') != null){
            ((Map<String, Object>)woMap.get('Contact')).remove('attributes');
        }
        if(woMap.containsKey('SF_PS_Job_Site__r') && woMap.get('SF_PS_Job_Site__r') != null){
            ((Map<String, Object>)woMap.get('SF_PS_Job_Site__r')).remove('attributes');
        }
        if(woMap.containsKey('ServiceTerritory') && woMap.get('ServiceTerritory') != null){
            ((Map<String, Object>)woMap.get('ServiceTerritory')).remove('attributes');
        }
        if(woMap.containsKey('CreatedBy') && woMap.get('CreatedBy') != null){
            ((Map<String, Object>)woMap.get('CreatedBy')).remove('attributes');
        }

        if(woMap.get('WorkPlans') != null){
            Map<String, Object> wpMap = (Map<String, Object>)woMap.get('WorkPlans');
            wpMap.remove('done');
            wpMap.remove('totalSize');
            for(Object obj : (List<Object>)wpMap.get('records')){
                ((Map<String, Object>)obj).remove('attributes');
            }
        }

        if(woMap.get('WorkSteps') != null){
            Map<String, Object> wsMap = (Map<String, Object>)woMap.get('WorkSteps');
            wsMap.remove('done');
            wsMap.remove('totalSize');
            for(Object obj : (List<Object>)wsMap.get('records')){
                ((Map<String, Object>)obj).remove('attributes');
            }
        }
    }

    /*********************************************************************************************************************
    * Purpose/Methods:
    * Updats the amount values to fromatted String for Credit WO
    *********************************************************************************************************************/
    public static void getCreditWOMap(Map<String,Object> woMap){
        List<WorkPlan> parentWOWPList = [SELECT Id, Name FROM WorkPlan WHERE WorkOrderId = :(String)woMap.get('ParentWorkOrderId')];
        if(!parentWOWPList.isEmpty()){
            woMap.put('WorkPlans', new Map<String, List<Map<String, Object>>>{ 'records' => new List<Map<String, Object>>()});
            for(WorkPlan wp : parentWOWPList){
                Map<String, Object> wpRec = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(wp));
                Map<String, List<Map<String, Object>>> wpMap = (Map<String, List<Map<String, Object>>>)woMap.get('WorkPlans');
                ((List<Map<String, Object>>)wpMap.get('records')).add(wpRec);
            }
        }
        
        if(woMap.get('Credit_Line_Items__r') != null){
            Map<String, Object> cliMap = (Map<String, Object>)woMap.get('Credit_Line_Items__r');
            cliMap.remove('done');
            cliMap.remove('totalSize');
            for(Object obj : (List<Object>)cliMap.get('records')){
                Map<String, Object> cli = (Map<String, Object>)obj;
                cli.remove('attributes');
                if(cli.get('SF_PS_Credit_Rate_Hr_Mi__c') != null){ 
                    cli.put('SF_PS_Credit_Rate_Hr_Mi__c', getAmountString((Decimal)cli.get('SF_PS_Credit_Rate_Hr_Mi__c')));
                }
                if(cli.get('SF_PS_Extended_Amt__c') != null){
                    cli.put('SF_PS_Extended_Amt__c', getAmountString((Decimal)cli.get('SF_PS_Extended_Amt__c')));
                }
            }
        }

        if(woMap.get('Credited_Parts__r') != null){
            Map<String, Object> cpMap = (Map<String, Object>)woMap.get('Credited_Parts__r');
            cpMap.remove('done');
            cpMap.remove('totalSize');
            
            List<Object> miscRecords = new List<Object>();
            List<Object> cpList = (List<Object>)cpMap.get('records');
            for(Integer i = cpList.size() - 1; i >= 0; i--){
                Map<String, Object> cp = (Map<String, Object>)cpList[i];
                cp.remove('attributes');
                if((String)cp.get('SF_PS_ItemType__c') == 'MI'){
                    miscRecords.add(cpList[i]);
                    cpList.remove(i);
                }
            }

            for(Object obj : cpList){
                Map<String, Object> cp = (Map<String, Object>)obj;
                if(cp.get('SF_PS_Credit_Price__c') != null){
                    cp.put('SF_PS_Credit_Price__c', getAmountString((Decimal)cp.get('SF_PS_Credit_Price__c')));
                }
                if(cp.get('SF_PS_Extended_Amt__c') != null){
                    cp.put('SF_PS_Extended_Amt__c', getAmountString((Decimal)cp.get('SF_PS_Extended_Amt__c')));
                }
            }
            
            if(!miscRecords.isEmpty()){
                woMap.put('Miscellaneous', new List<Map<String, Object>>());
                for(Object misc: miscRecords){
                    Map<String, Object> cpRec = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(misc));
                    ((List<Map<String, Object>>)woMap.get('Miscellaneous')).add(cpRec);
                }

                for(Map<String, Object> misc : (List<Map<String, Object>>)woMap.get('Miscellaneous')){
                    misc.remove('attributes');
                    if(misc.get('SF_PS_Credit_Price__c') != null){
                        misc.put('SF_PS_Credit_Price__c', getAmountString((Decimal)misc.get('SF_PS_Credit_Price__c')));
                    }
                    if(misc.get('SF_PS_Extended_Amt__c') != null){
                        misc.put('SF_PS_Extended_Amt__c', getAmountString((Decimal)misc.get('SF_PS_Extended_Amt__c')));
                    }
                }
            }
        }

        System.debug('@@@@woMap ==>> ' + woMap);
    }

    /*********************************************************************************************************************
    * Purpose/Methods:
    * Updats the amount values to fromatted String for Quote WO
    *********************************************************************************************************************/
    public static void getQuoteWOMap(Map<String,Object> woMap){
        if(woMap.get('Quote_Line_Items__r') != null){
            Map<String, Object> qliMap = (Map<String, Object>)woMap.get('Quote_Line_Items__r');
            qliMap.remove('done');
            qliMap.remove('totalSize');
            for(Object obj : (List<Object>)qliMap.get('records')){
                Map<String, Object> qli = (Map<String, Object>)obj;
                qli.remove('attributes');
                if(qli.get('SF_PS_Hourly_Internal_Rate__c') != null){ 
                    qli.put('SF_PS_Hourly_Internal_Rate__c', getAmountString((Decimal)qli.get('SF_PS_Hourly_Internal_Rate__c')));
                }
                if(qli.get('SF_PS_Extended_Amt__c') != null){
                    qli.put('SF_PS_Extended_Amt__c', getAmountString((Decimal)qli.get('SF_PS_Extended_Amt__c')));
                }
            }
        }

        if(woMap.get('Quoted_Parts__r') != null){
            Map<String, Object> qpMap = (Map<String, Object>)woMap.get('Quoted_Parts__r');
            qpMap.remove('done');
            qpMap.remove('totalSize');

            List<Object> miscRecords = new List<Object>();
            List<Object> qpList = (List<Object>)qpMap.get('records');
            for(Integer i = qpList.size() - 1; i >= 0; i--){
                Map<String, Object> qp = (Map<String, Object>)qpList[i];
                qp.remove('attributes');
                if(qp.get('SF_PS_ProductItem__r') != null){
                    ((Map<String, Object>)qp.get('SF_PS_ProductItem__r')).remove('attributes');
                }
                if((String)qp.get('SF_PS_ItemType__c') == 'MI'){
                    miscRecords.add(qpList[i]);
                    qpList.remove(i);
                }
            }

            for(Object obj : qpList){
                Map<String, Object> qp = (Map<String, Object>)obj;
                if(qp.get('SF_PS_Selling_Price__c') != null){
                    qp.put('SF_PS_Selling_Price__c', getAmountString((Decimal)qp.get('SF_PS_Selling_Price__c')));
                }
                if(qp.get('SF_PS_Sub_Total__c') != null){
                    qp.put('SF_PS_Sub_Total__c', getAmountString((Decimal)qp.get('SF_PS_Sub_Total__c')));
                }
                if(!qp.containsKey('SF_PS_Part_Number__c')){
                    qp.put('SF_PS_Part_Number__c', '');
                }
            }

            if(!miscRecords.isEmpty()){
                woMap.put('Miscellaneous', new List<Map<String, Object>>());
                for(Object misc: miscRecords){
                    Map<String, Object> qpRec = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(misc));
                    ((List<Map<String, Object>>)woMap.get('Miscellaneous')).add(qpRec);
                }

                for(Map<String, Object> misc : (List<Map<String, Object>>)woMap.get('Miscellaneous')){
                    misc.remove('attributes');
                    if(misc.get('SF_PS_Selling_Price__c') != null){
                        misc.put('SF_PS_Selling_Price__c', getAmountString((Decimal)misc.get('SF_PS_Selling_Price__c')));
                    }
                    if(misc.get('SF_PS_Sub_Total__c') != null){
                        misc.put('SF_PS_Sub_Total__c', getAmountString((Decimal)misc.get('SF_PS_Sub_Total__c')));
                    }
                    if(!misc.containsKey('SF_PS_Part_Number__c')){
                        misc.put('SF_PS_Part_Number__c', '');
                    }
                }
            }
        }
    }

    /*********************************************************************************************************************
    * Purpose/Methods:
    * Updats the amount values to fromatted String for Inspecton WO
    *********************************************************************************************************************/
    public static void getInspectionWOMap(Map<String,Object> woMap){
        if(woMap.get('WorkOrderLineItems') != null){
            Map<String, Object> woliMap = (Map<String, Object>)woMap.get('WorkOrderLineItems');
            woliMap.remove('done');
            woliMap.remove('totalSize');
            for(Object obj : (List<Object>)woliMap.get('records')){
                Map<String, Object> woli = (Map<String, Object>)obj;
                woli.remove('attributes');
                if(woli.get('SF_PS_Extended_Rate__c') != null){ 
                    woli.put('SF_PS_Extended_Rate__c', getAmountString((Decimal)woli.get('SF_PS_Extended_Rate__c')));
                }
                if(woli.get('SF_PS_Hourly_Internal_Rate__c') != null){
                    woli.put('SF_PS_Hourly_Internal_Rate__c', getAmountString((Decimal)woli.get('SF_PS_Hourly_Internal_Rate__c')));
                }
            }
        }

        if(woMap.get('ProductsConsumed') != null){
            Map<String, Object> pcMap = (Map<String, Object>)woMap.get('ProductsConsumed');
            pcMap.remove('done');
            pcMap.remove('totalSize');

            List<Object> miscRecords = new List<Object>();
            List<Object> pcList = (List<Object>)pcMap.get('records');
            for(Integer i = pcList.size() - 1; i >= 0; i--){
                Map<String, Object> pc = (Map<String, Object>)pcList[i];
                pc.remove('attributes');
                if(pc.get('SF_PS_Product_Item__r') != null){
                    ((Map<String, Object>)pc.get('SF_PS_Product_Item__r')).remove('attributes');
                }
                if((String)pc.get('SF_PS_ItemType__c') == 'MI'){
                    miscRecords.add(pcList[i]);
                    pcList.remove(i);
                }
            }

            for(Object obj : pcList){
                Map<String, Object> pc = (Map<String, Object>)obj;
                if(pc.get('SF_PS_Selling_Price__c') != null){
                    pc.put('SF_PS_Selling_Price__c', getAmountString((Decimal)pc.get('SF_PS_Selling_Price__c')));
                }
                if(pc.get('SF_PS_Sub_Total__c') != null){
                    pc.put('SF_PS_Sub_Total__c', getAmountString((Decimal)pc.get('SF_PS_Sub_Total__c')));
                }
            }

            if(!miscRecords.isEmpty()){
                woMap.put('Miscellaneous', new List<Map<String, Object>>());
                for(Object misc: miscRecords){
                    Map<String, Object> pcRec = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(misc));
                    ((List<Map<String, Object>>)woMap.get('Miscellaneous')).add(pcRec);
                }

                for(Map<String, Object> misc : (List<Map<String, Object>>)woMap.get('Miscellaneous')){
                    misc.remove('attributes');
                    if(misc.get('SF_PS_Selling_Price__c') != null){
                        misc.put('SF_PS_Selling_Price__c', getAmountString((Decimal)misc.get('SF_PS_Selling_Price__c')));
                    }
                    if(misc.get('SF_PS_Sub_Total__c') != null){
                        misc.put('SF_PS_Sub_Total__c', getAmountString((Decimal)misc.get('SF_PS_Sub_Total__c')));
                    }
                }
            }
        }
    }

    /*********************************************************************************************************************
    * Purpose/Methods:
    * Return RecordType of WorkOrder
    *********************************************************************************************************************/
    public static String getWorkOrderRecordType(String workOrderId){
        WorkOrder wo = [SELECT Id, RecordType.DeveloperName FROM WorkOrder WHERE Id = :workOrderId];
        return wo.RecordType.DeveloperName;
    }

    /*********************************************************************************************************************
    * Purpose/Methods:
    * Return template id needed to generate the pdf
    *********************************************************************************************************************/
    public static String getTemplateId(String woRecordType){
        String aqtName = (woRecordType == WORKORDER_RECORDTYPE_CREDIT ? System.Label.AQTWokOrderCreditTemplateRecord :
            woRecordType == WORKORDER_RECORDTYPE_QUOTE ? System.Label.AQTWokOrderQuoteTemplateRecord : System.Label.AQTWokOrderInvoiceTemplateRecord
        );
        Adobe_Quote_Template__c aqt = [SELECT Id, Name, Template_Id__c FROM Adobe_Quote_Template__c WHERE Name = :aqtName];
        return aqt.Template_Id__c;
    }

    /*********************************************************************************************************************
    * Purpose/Methods:
    * Returns Attachment fileName
    *********************************************************************************************************************/
    public static String getFileName(WorkOrder wo){
        DateTime dt = DateTime.now();
        String fileName = 'WOInv_' + (String.isNotBlank(wo.SF_PS_RM_WO_Number__c) ? (wo.SF_PS_RM_WO_Number__c + '_') : '');
        fileName += (String.valueOf(dt.month()) + String.valueOf(dt.day()) + String.valueOf(dt.year()) + 'T' + String.valueOf(dt.hour()) + String.valueOf(dt.minute()) + String.valueOf(dt.second()));
        return fileName;
    }

    /*********************************************************************************************************************
    * Purpose/Methods:
    * Sends email to customer
    *********************************************************************************************************************/
    public static String sendEmail(Blob pdfBlob, WorkOrder wo){
        SBR_3_0_SendgridEmailRequestWrapper.WorkOrderWrapper workOrderWrapper = new SBR_3_0_SendgridEmailRequestWrapper.WorkOrderWrapper();
        workOrderWrapper.workOrderNumber = wo.WorkOrderNumber;
        workOrderWrapper.recordTypeC     = wo.RecordType.Name;
        workOrderWrapper.jobLocationC    = wo.SF_PS_Job_Location__c;
        workOrderWrapper.poNumberC       = wo.SF_PS_PONumber__c;

        SBR_3_0_SendgridEmailRequestWrapper.AttachmentWrapper attachmentWrapper = new SBR_3_0_SendgridEmailRequestWrapper.AttachmentWrapper();
        attachmentWrapper.fileContent = EncodingUtil.base64Encode(pdfBlob);
        attachmentWrapper.fileName    = getFileName(wo) + FILE_EXTENSION_PDF;
        attachmentWrapper.disposition = ATTACHMENT_DISPOSITION_0;
        attachmentWrapper.mimeType    = CONTENT_TYPE_PDF;

        SBR_3_0_SendgridEmailRequestWrapper.EmailWrapper emailWrapper = new SBR_3_0_SendgridEmailRequestWrapper.EmailWrapper();
        emailWrapper.toAddresses      = new List<String>{wo.Account.E_mail_Address__c};
        emailWrapper.recordId         = wo.Id;
        emailWrapper.workOrderDetails = workOrderWrapper;
        emailWrapper.attachmentData   = new List<SBR_3_0_SendgridEmailRequestWrapper.AttachmentWrapper>{attachmentWrapper};
        
        String emailDeliveryStatus = SBR_3_0_SendEmailCmpController.sendEmail(JSON.serialize(emailWrapper));
        return emailDeliveryStatus;
    }

    public class ExceptionData{
        public Exception ex;
        public String className;
        public String methodName;
        public String exceptionMessage;

        public ExceptionData(){}

        public ExceptionData(Exception ex, String clName, String mtName){
            this.ex         = ex;
            this.className  = clName;
            this.methodName = mtName;
        }

        public ExceptionData(String clName, String mtName, String exMessage){
            this.className        = clName;
            this.methodName       = mtName;
            this.exceptionMessage = exMessage;
        }
    }

    /*********************************************************************************************************************
    * Purpose/Methods:
    * Logs the exception
    *********************************************************************************************************************/
    public static void logException(ExceptionData exData){
        System.debug('@@@@ Exception data ==>> ' + exData);
        // Handle any exceptions that occur during the update process.
        Map<String,String> exceptionParams = new Map<String,String>{
            'ClassName'  => exData.className,
            'MethodName' => exData.methodName,
            'Type'       => exData.ex != null ? exData.ex.getTypeName() : '',
            'LineNumber' => exData.ex != null ? String.valueOf(exData.ex.getLineNumber()) : '0',
            'StackTrace' => exData.ex != null ? exData.ex.getStackTraceString() : exData.exceptionMessage,
            'Message'    => exData.ex != null ? exData.ex.getMessage() : exData.exceptionMessage
        };
        PPA_ExceptionLogHandler.createExceptionLog(exceptionParams);
    }
}