/*********************************************************************************************************************
* Apex Class: SBR_3_0_GeneratePOPDFUtility
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Utility class for the common functionality needed to generate and retrieve pdf from flow and quick action
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES

---------------------------------------------------------------------------------------------------------------------------------------
Note:-
* 
*********************************************************************************************************************/
public with sharing class SBR_3_0_GeneratePOPDFUtility {
    
    public static final String COMPANY_ID                       = '01';
    public static final String APINAME                          = 'DocGen_V2';
    public static final String X_CORRELATION_ID                 = SBR_3_0_Generic.generateRandomString(10);
    public static final String SOURCE_SF                        = 'SF';
    public static final String CONTENT_TYPE_JSON                = 'application/json';
    public static final String CONTENT_TYPE_PDF                 = 'application/pdf';
    public static final String THRESHOLD_WAIT_TIME              = '1';
    public static final String EXECUTION_TYPE_FLOW              = 'Flow';
    public static final String EXECUTION_TYPE_AURA              = 'Aura';
    public static final String PURCHASEORDER_RECORDTYPE_3RD     = 'Third_Party_Hauler';
    public static final String PURCHASEORDER_RECORDTYPE_RERENT  = 'Rerent';
    public static final String PURCHASEORDER_RECORDTYPE_STANDARD= 'Standard_Purchase_Order';
    public static final Integer ATTACHMENT_DISPOSITION_0        = 0;
    public static final String FILE_EXTENSION_PDF               = '.pdf';
    public static final String RESPONSE_STATUS_COMPLETE         = 'Complete';
    public static final String RESPONSE_STATUS_INPROGRESS       = 'In Progress';
    public static final String RESPONSE_STATUS_INCOMPLETE       = 'InComplete';

    /*********************************************************************************************************************
    * Purpose/Methods:
    * Get workorder map with updated values
    *********************************************************************************************************************/
    public static Map<String, Object> getPurchaseOrderMap(Purchase_Order__c po){
        Map<String,Object> poMap = (Map<String,Object>)JSON.deserializeUntyped(JSON.serialize(po));
        stripExtraData(poMap);

        DateTime dt = DateTime.now();
        //poMap.put('Date', String.valueOf(dt.format('MM/dd/yyyy')));
        //poMap.put('Time', String.valueOf(dt.Hour())+':'+String.valueOf(dt.Minute()));   
        poMap.put('CreatedDate', po.CreatedDate != null ? po.CreatedDate.format('MM/dd/yyyy') : '');        
        poMap.put('Requested_Date__c',Datetime.newInstance(po.Requested_Date__c, Time.newInstance(12, 0, 0, 0)).format('MM/dd/yyyy')); 
        return poMap;
    }

    /*********************************************************************************************************************
    * Purpose/Methods:
    * Return template id needed to generate the purchase order pdf - Hard code now for testing
    *********************************************************************************************************************/
    public static String getTemplateId(){
        return System.Label.SBR_3_0_PurchaseOrderPDFTemplateId;
    }

    /*********************************************************************************************************************
    * Purpose/Methods:
    * Sends email to customer
    *********************************************************************************************************************/
    public static String sendPOEmail(Blob pdfBlob, Purchase_Order__c po){

        SBR_3_0_SendgridEmailRequestWrapper.WorkOrderWrapper workOrderWrapper = new SBR_3_0_SendgridEmailRequestWrapper.WorkOrderWrapper();
        //Temporary to leverge work order template
        workOrderWrapper.workOrderNumber = '00000002';
        workOrderWrapper.recordTypeC     = 'Inspection Record';
        workOrderWrapper.jobLocationC    = 'Phoenix';
        workOrderWrapper.poNumberC       = 'sdf';
        SBR_3_0_SendgridEmailRequestWrapper.AttachmentWrapper attachmentWrapper = new SBR_3_0_SendgridEmailRequestWrapper.AttachmentWrapper();
        attachmentWrapper.fileContent = EncodingUtil.base64Encode(pdfBlob);
        attachmentWrapper.fileName    = getFileName(po)+ FILE_EXTENSION_PDF;
        attachmentWrapper.disposition = ATTACHMENT_DISPOSITION_0;
        attachmentWrapper.mimeType    = CONTENT_TYPE_PDF;

        SBR_3_0_SendgridEmailRequestWrapper.EmailWrapper emailWrapper = new SBR_3_0_SendgridEmailRequestWrapper.EmailWrapper();
        String emailaddress = 'xibing.li@sunbeltrentals.com';
        //emailWrapper.toAddresses      = new List<String>{po.Vendor__r.Email__c};
        emailWrapper.toAddresses      = new List<String>{emailaddress};
        emailWrapper.recordId         = po.Id;
        emailWrapper.workOrderDetails = workOrderWrapper;
        emailWrapper.attachmentData   = new List<SBR_3_0_SendgridEmailRequestWrapper.AttachmentWrapper>{attachmentWrapper};
        
        String emailDeliveryStatus = SBR_3_0_SendEmailCmpController.sendEmail(JSON.serialize(emailWrapper));
        //String emailDeliveryStatus = 'Success';
        return emailDeliveryStatus;
    }

    /*********************************************************************************************************************
    * Purpose/Methods:
    * Note: Only use parent fields till single level
    * Valid eg: Product2.SM_PS_Item_number__c
    * Invalid eg: Product2.CreatedBy.Name
    *********************************************************************************************************************/
    public static final Map<String, List<String>> CHILD_OBJECT_PAYLOAD_REQUIRED_FIELDS = new Map<String, List<String>>{
        'ShipTo_Location__r'         => new List<String>{'Fax_Phone_Number__c'},
        'Vendor__r'                  => new List<String>{'Email__c','Billing_Street1__c','Billing_Street2__c','BillingCity','BillingState','BillingPostalCode'},
        'OrderedBy__r'               => new List<String>{'Phone'},
        'PO_Line_Items__r'           => new List<String>{'Quantity__c','Quantity_Rcvd__c','Unit_Cost__c','Total_Cost__c','Item_Description_Text__c','Equipment_Num__c','Manufacturer__c','Item_Class__c'},
        'PO_Receipts__r'             => new List<String>{'Bin_1__c'},
        'Branch_Location__r'         => new List<String>{'Fax_Phone_Number__c','Phone__c','Name'}
    };

    /*********************************************************************************************************************
    * Purpose/Methods:
    * Returns Attachment fileName
    *********************************************************************************************************************/
    public static String getFileName(Purchase_Order__c po){
        DateTime dt = DateTime.now();
        String fileName = 'PO_' + (String.isNotBlank(po.Name) ? (po.Name) : 'Draft');
        return fileName;
    } 

    /*********************************************************************************************************************
    * Purpose/Methods:
    * Returns Purchase Order record
    *********************************************************************************************************************/
    public static Purchase_Order__c getPurchaseOrder(String purchaseOrderId){

        String query = 'SELECT Id, Name, RecordType.DeveloperName, ShipTo__c,ShipTo_Name__c,ShipTo_Addr1__c, ShipTo_Addr2__c, ShipTo_City__c, ShipTo_State__c, ShipTo_Zip__c,ShipTo_Phone__c,Vendor__c,ShipTo_Location__r.Fax_Phone_Number__c, Branch_Location__r.Name, Branch_Location__r.Phone__c, Branch_Location__r.Fax_Phone_Number__c, Vendor__r.Email__c, Vendor__r.Fax, Vendor__r.Billing_Street1__c, Vendor__r.Billing_Street2__c, Vendor__r.BillingCity, Vendor__r.BillingState, Vendor__r.BillingPostalCode, PO_Comments__c, PO_Total__c, vendor_Number__c,Vendor_Name_Text__c,Vendor_Address__c,Vendor_Phone__c,OrderedBy_Name__c,Ordered_From__c,Ordered_For__c, OrderedBy__r.Phone, OrderedBy__r.Email, Terms__c,Term_Days__c, Barcode__c,CreatedDate,Requested_Date__c,  (select id, Quantity__c,Quantity_Rcvd__c,Unit_Cost__c,Total_Cost_Calc__c,Item_Description_Text__c,Equipment_Num__c,Manufacturer__c,Item_Class__c from PO_Line_Items__r), (Select id,Bin_1__c from PO_Receipts__r)';
        query += ' FROM Purchase_Order__c WHERE Id = :purchaseOrderId';
        Purchase_Order__c po = Database.query(query);
        return po;
    }   

    /*********************************************************************************************************************
    * Purpose/Methods:
    * Removes extra data from the payload
    *********************************************************************************************************************/
    public static void stripExtraData(Map<String,Object> poMap){
        poMap.remove('attributes');
        poMap.remove('RecordType');
        poMap.remove('RecordTypeId');
        
        if(poMap.containsKey('ShipTo_Location__r') && poMap.get('ShipTo_Location__r') != null){
            ((Map<String, Object>)poMap.get('ShipTo_Location__r')).remove('attributes');
        }
        //if(poMap.containsKey('RecordType') && poMap.get('RecordType') != null){
        //    ((Map<String, Object>)poMap.get('RecordType')).remove('attributes');
        //}
        if(poMap.containsKey('Vendor__r') && poMap.get('Vendor__r') != null){
            ((Map<String, Object>)poMap.get('Vendor__r')).remove('attributes');
        }
        if(poMap.containsKey('OrderedBy__r') && poMap.get('OrderedBy__r') != null){
            ((Map<String, Object>)poMap.get('OrderedBy__r')).remove('attributes');
        }
        if(poMap.containsKey('Branch_Location__r') && poMap.get('Branch_Location__r') != null){
            ((Map<String, Object>)poMap.get('Branch_Location__r')).remove('attributes');
        }
        if(poMap.containsKey('PO_Line_Items__r') && poMap.get('PO_Line_Items__r') != null){
            Map<String, Object> poLineMap = (Map<String, Object>)poMap.get('PO_Line_Items__r');
            poLineMap.remove('attributes');
            poLineMap.remove('done');
            poLineMap.remove('totalSize');
            for(Object obj : (List<Object>)poLineMap.get('records')){
                Map<String, Object> pl = (Map<String, Object>)obj;
                pl.remove('attributes');
            }
        }
        if(poMap.containsKey('PO_Receipts__r') && poMap.get('PO_Receipts__r') != null){
            Map<String, Object> prMap = (Map<String, Object>)poMap.get('PO_Receipts__r');
            prMap.remove('attributes');
            prMap.remove('done');
            prMap.remove('totalSize');
            for(Object obj : (List<Object>)prMap.get('records')){
                Map<String, Object> pr = (Map<String, Object>)obj;
                pr.remove('attributes');
            }
        }
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