/*********************************************************************************************************************
* Apex Class: SBR_3_0_SfsOrderFromSeController
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class containing all methods used to generate cxml and punchout data.
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION       DATE           Developer                       DETAIL FEATURES
1.0          2023-06-19          Vikas Kumar/Hrishi             Initial Version
2.0          2023-06-23          Vikas Kumar                    (Updated to get details user details from Curent User)   
**********************************************************************************************************************************************/
public with sharing class SBR_3_0_SfsOrderFromSeController {
    
    //static String URL='https://punchinca.smartequip.net/punchinsetup/';
	static String link;
    
    // Use for browser cookie
    public static String createToken(Integer length){
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String token = '';
        while (token.length() < length) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            token += chars.substring(idx, idx+1);
        }
        return token;
    }
    
    // Use for browser cookie
    public static String getUUID(){
        Blob b = Crypto.GenerateAESKey(128);
        String h = EncodingUtil.ConvertTohex(b);
        String guid = h.SubString(0,8)+ '-' + h.SubString(8,12) + '-' + h.SubString(12,16) + '-' + h.SubString(16,20) + '-' + h.substring(20);
        system.debug(guid);
        return guid;
    }
    public static list<WorkOrder> getWorkOrderDetails( Id recordId){ 
        List<WorkOrder> wo;
        
        wo= [select id,Asset.Name,
             SF_PS_Current_Loc__c,
             SF_PS_RM_WO_Number__c,SF_PS_Work_Order_Des__c,
             SF_PS_Company_Code__c 
             from 
             WorkOrder 
             where Id=:recordId];
        
        return wo;
    }
    
    // Genrate timestanp as per CXML format
    public Static String getGenerateTimeStamp(){
        system.debug('Datetime : '+ DateTime.now());
        system.debug('timestamp : '+ DateTime.now().getTime());
        //in secs
        return String.valueof(DateTime.now().getTime());
    }
    //get user details
    Public static list<user> getUserDetails(Id userId)
    {
        List<User> usr= [select id,UserName,Email,SF_PS_SE_Role_Id__c,Wynne_User_Name__c,CountryCode,Phone from User where Id =:userId];
        return usr;
    }
    
    // Genrate CXML for callouts
    public static void generateCXML(Id recordId,Map<String,Object> data) {
        try{
            
            //get Service resource ID
            string token=SBR_3_0_SfsOrderFromSeController.createToken(10);
            SmartEquipApiSetting__mdt punchoutDetails= SmartEquipApiSetting__mdt.getInstance('punchOut');
            //string identity=punchoutDetails.Identity__c+'';
            Id serviceResourceId=SBR_3_0_ServiceResourceDA.getServiceResourceIdFromWorkOrderId(recordId);
            String code=SBR_3_0_ServiceResourceDA.getServiceResourceCodeFromWorkOrderId(recordId);
            link=punchoutDetails.DeepLink__c+'';
			system.debug('link is->' + link);
            string identity='';
            if(code == '01'){
                 identity=punchoutDetails.Identity__c+'';
            }else if (code == '02') {
                 identity=punchoutDetails.Canada_Identity__c +'';
            }
            System.debug('identity is '+identity );
            //string identity=punchoutDetails.Identity__c+'';
            
            
            system.debug('this is serviceResourceId '+serviceResourceId);
            //get ServiceResource Details
          // List<ServiceResource> serviceResourceDetails=SBR_3_0_ServiceResourceDA.getServiceResourceById(serviceResourceId);
           // ServiceResource srDetails= new ServiceResource();
            
            system.debug('record ID '+recordId);
            string areaCode;
            string phone;
            string countryCode;
            User currentUser=getUserDetails(UserInfo.getUserId())[0];
            string deviceType=data.get('deviceType')+'';
            string url=data.get('url')+'';
            string deepLink='';
            if(deviceType=='Desktop')
            {
                deepLink=url;
            }
            else{
                deepLink=link+recordId;
            }

            
            
            
            List<WorkOrder> wo=SBR_3_0_SfsOrderFromSeController.getWorkOrderDetails(recordId);
            WorkOrder workOrder= wo[0];
            DOM.Document doc = new DOM.Document();
            // Create the cXML root elementS
            DOM.xmlNode cxmlElement = doc.createRootElement('cXML',null,null);
            cxmlElement.setAttribute('payloadID', token);
            
            // Time stamp generation
            String timeStamp=SBR_3_0_SfsOrderFromSeController.getGenerateTimeStamp();
            cxmlElement.setAttribute('timestamp', timeStamp);
            cxmlElement.setAttribute('xml:lang', 'en_US');
            
            // Create the Header element
            DOM.xmlNode headerElement = cxmlElement.addChildElement('Header',null,null);
            
            // Create the From element
            DOM.xmlNode fromElement = headerElement.addChildElement('From',null,null);
            
            // Create the Credential element for From
            DOM.xmlNode fromCredentialElement =  fromElement.addChildElement('Credential',null,null);
            fromCredentialElement.setAttribute('domain', 'SE');
            
            // Create the Identity element for From Credential
            DOM.xmlNode fromIdentityElement =  fromCredentialElement.addChildElement('Identity',null,null);
            system.debug(workorder);
            fromIdentityElement.addTextNode(workOrder.SF_PS_Company_Code__c);
            
            
            // Create the To element
            DOM.xmlNode toElement =  headerElement.addChildElement('To',null,null);
            
            
            // Create the Credential element for To
            DOM.xmlNode toCredentialElement = toElement.addChildElement('Credential',null,null);
            toCredentialElement.setAttribute('domain', 'SE');
            
            
            // Create the Identity element for To Credential
            DOM.xmlNode toIdentityElement = toCredentialElement.addChildElement('Identity',null,null);
            toIdentityElement.addTextNode(identity);
            
            
            // Create the Sender element
            DOM.xmlNode senderElement = headerElement.addChildElement('Sender',null,null);
            
            
            // Create the Credential element for Sender
            DOM.xmlNode senderCredentialElement = senderElement.addChildElement('Credential',null,null);
            senderCredentialElement.setAttribute('domain', 'Salesforce');
            
            
            // Create the Identity element for Sender Credential
            DOM.xmlNode senderIdentityElement = senderCredentialElement.addChildElement('Identity',null,null);
            senderIdentityElement.addTextNode('FIELDSERVICEMOBILE');
            
            
            // Create the UserAgent element
            DOM.xmlNode userAgentElement = senderElement.addChildElement('UserAgent',null,null);
            userAgentElement.addTextNode(currentUser.username);
            
            
            // Create the Request element
            DOM.xmlNode requestElement = cxmlElement.addChildElement('Request',null,null);
            
            
            // Create the PunchOutSetupRequest element
            DOM.xmlNode punchOutSetupRequestElement = requestElement.addChildElement('PunchOutSetupRequest',null,null);
            punchOutSetupRequestElement.setAttribute('operation', 'create');
            
            
            // Create the BuyerCookie element
            DOM.xmlNode buyerCookieElement = punchOutSetupRequestElement.addChildElement('BuyerCookie',null,null);
            buyerCookieElement.addTextNode(SBR_3_0_SfsOrderFromSeController.getUUID());//unique value to be generated by salesforce
            
            // Create the Extrinsic elements
            createExtrinsicElement(punchOutSetupRequestElement, 'CostCenter', workorder.SF_PS_Current_Loc__c);
            createExtrinsicElement( punchOutSetupRequestElement, 'UniqueName', currentUser.Wynne_User_Name__c);
            
            createExtrinsicElement( punchOutSetupRequestElement, 'transactionType', 'FIELDSERVICE');
            //deepLink
            
            //string deepLink='com.salesforce.fieldservice://v1/WorkOrder/';
            createExtrinsicElement( punchOutSetupRequestElement, 'FleetReturnUrl', deepLink);
            
            // Create the equipment Extrinsic element
            DOM.xmlNode equipmentExtrinsicElement = createExtrinsicElement(punchOutSetupRequestElement, 'equipment', null);
            createExtrinsicElement( equipmentExtrinsicElement, 'number', workOrder.Asset.Name);
            
            // Create the provisions Extrinsic element
            DOM.xmlNode provisionsExtrinsicElement = createExtrinsicElement( punchOutSetupRequestElement, 'provisions', null);
            createExtrinsicElement( provisionsExtrinsicElement, 'PO-SUBMIT', 'Y');
            
            // Create the workOrder Extrinsic element
            DOM.xmlNode workOrderExtrinsicElement = createExtrinsicElement( punchOutSetupRequestElement, 'workOrder', null);
            System.debug('Work order no' + workOrder.SF_PS_RM_WO_Number__c);
            String WorkoderNumber;
            if(workOrder.SF_PS_RM_WO_Number__c != null){
            	WorkoderNumber = workOrder.SF_PS_RM_WO_Number__c.substringAfter('-');
            }else{
            	WorkoderNumber = workOrder.SF_PS_RM_WO_Number__c;
            }
            createExtrinsicElement( workOrderExtrinsicElement, 'number', WorkoderNumber);
            
            // Create the orderingLimit Extrinsic element
            DOM.xmlNode orderingLimitExtrinsicElement = createExtrinsicElement( punchOutSetupRequestElement, 'orderingLimit', null);
            
            // Create the minAmount Extrinsic element
            DOM.xmlNode minAmountExtrinsicElement = createExtrinsicElement( orderingLimitExtrinsicElement, 'minAmount', null);
            createMoneyElement( minAmountExtrinsicElement, 'USD', '0');
            
            // Create the maxAmount Extrinsic element
            DOM.xmlNode maxAmountExtrinsicElement = createExtrinsicElement( orderingLimitExtrinsicElement, 'maxAmount', null);
            createMoneyElement( maxAmountExtrinsicElement, 'USD', '500.0');
            
            // Create the BrowserFormPost element
            DOM.xmlNode browserFormPostElement = punchOutSetupRequestElement.addChildElement('BrowserFormPost',null,null);
            
            
            // Create the URL element for BrowserFormPost
            DOM.xmlNode urlElement = browserFormPostElement.addChildElement('URL',null,null);
            //https://fieldservice-appurl-to-take-user-back.net
            urlElement.addTextNode(deepLink);
            
            
            // Create the Contact element
            DOM.xmlNode contactElement = punchOutSetupRequestElement.addChildElement('Contact',null,null);
            if(currentUser.SF_PS_SE_Role_Id__c!=null)
            {
            contactElement.setAttribute('role', currentUser.SF_PS_SE_Role_Id__c);
            }
            
            
            // Create the Name element for Contact
            DOM.xmlNode nameElement = contactElement.addChildElement('Name',null,null);
            nameElement.setAttribute('xml:lang', 'en_US');
            if(currentUser.Wynne_User_Name__c!=null)
            {
                nameElement.addTextNode(currentUser.Wynne_User_Name__c);
            }
            
            
            // Create the Email element for Contact
            DOM.xmlNode emailElement = contactElement.addChildElement('Email',null,null);
            emailElement.addTextNode(currentUser.Email);
            
            
            // Create the Phone element for Contact
            DOM.xmlNode phoneElement = contactElement.addChildElement('Phone',null,null);
            phoneElement.setAttribute('name', 'Office');
            
            
            // Create the TelephoneNumber element for Phone
            DOM.xmlNode telephoneNumberElement = phoneElement.addChildElement('TelephoneNumber',null,null);
            
            phone ='999-333-6666';
            if(currentUser.Phone!=null)
            {
                phone=currentUser.Phone;
            }
            
            list<String> phoneCodes=phone.split('-');
            if(phoneCodes.size()>=3)
            {
                areaCode=phoneCodes[1];
                countryCode=phoneCodes[0];
            }
            else if(phoneCodes.size()>=2)
            {
                areaCode=phoneCodes[0]; 
            }
            else if(phoneCodes.size()>=1)
            {
                phone=phoneCodes[0];
                areaCode='';
            }
            if(currentUser.CountryCode=='US')
            {
                countryCode='1';
            }
            else{
                countryCode='2';
            }
            
            
            // Create the CountryCode element for TelephoneNumber
            DOM.xmlNode countryCodeElement = telephoneNumberElement.addChildElement('CountryCode',null,null);
            countryCodeElement.setAttribute('isoCountryCode', countryCode);
            
            
            // Create the AreaOrCityCode element for TelephoneNumber
            DOM.xmlNode areaOrCityCodeElement = telephoneNumberElement.addChildElement('AreaOrCityCode',null,null);
            areaOrCityCodeElement.addTextNode(areaCode);
            
            
            // Create the Number element for TelephoneNumber
            DOM.xmlNode numberElement = telephoneNumberElement.addChildElement('Number',null,null);
            
            numberElement.addTextNode(phone);
            
            
            string body= doc.toXmlString();
            data.put('request',body);
            data.put('generated','T');
           
            
        }
        catch(Exception e)
        {
            data.put('statusCode',500);
            data.put('generated','F');
            data.put('message','Internal error Occured '+e.getMessage()+' - '+e.getLineNumber());
            system.debug(e.getMessage()+' '+e.getLineNumber());
            
        }
    }
    
    // create Extrinsic Elements
    private static DOM.xmlNode createExtrinsicElement(DOM.xmlNode parentElement, String name, String value) {
        DOM.xmlNode extrinsicElement = parentElement.addChildElement('Extrinsic',null,null);
        extrinsicElement.setAttribute('name', name);
        //parentElement.addChildElement(extrinsicElement);
        
        if (value != null) {
            extrinsicElement.addTextNode(value);
        }
        
        return extrinsicElement;
    }
    
    // create create Money Element
    private static void createMoneyElement(DOM.xmlNode parentElement, String currencyy, String value) {
        DOM.xmlNode moneyElement = parentElement.addChildElement('Money',null,null);
        moneyElement.setAttribute('currency', currencyy);
        moneyElement.addTextNode(value);
        //   parentElement.addChildElement(moneyElement);
    }
    public static void readResponse(string xmlResponse,map<string,Object> data)
    {
        // Create an instance of the XMLParser
        DOM.Document xmlDoc = new DOM.Document();
        xmlDoc.load(xmlResponse);
        
        // Get the root element
        DOM.XMLNode rootElement = xmlDoc.getRootElement();
        //get Response Node
        DOM.XMLNode respNode = rootElement.getChildElement('Response', null);
        //get Status Node
        DOM.XMLNode statusNode = respNode.getChildElement('Status', null);
        string statusCode= statusNode.getAttribute('code', null);
        system.debug(StatusCode);
        if(statusCode=='200')
        {
            // Find the URL element within the XML
            DOM.XMLNode urlNode =respNode
                .getChildElement('PunchOutSetupResponse', null)
                .getChildElement('StartPage', null)
                .getChildElement('URL', null);
            
            // Extract the URL value
            String url = urlNode.getText();
            System.debug('URL: ' + url);
            data.put('url',url);
        }
        else {
            string res= statusNode.getText();
            data.put('message',res);
        }
        data.put('statusCode',statusCode);
        
        
    }
    
    // Generate XML for LWC
    @AuraEnabled
    public static Map<string,object>  generateXml(Id recordId,string deviceType,string url){
        system.debug('this is record Id '+recordId);
        List<WorkOrder> wo=SBR_3_0_SfsOrderFromSeController.getWorkOrderDetails(recordId);
        Boolean isRentReady=wo[0]?.SF_PS_Work_Order_Des__c=='CHECK IN RETURN'?true:false;
        Map<string,object> data= new map<string,Object>();
        data.put('deviceType',deviceType);
        data.put('url',url);
        // Adding flag for rent ready Inspections
        data.put('isRentReady',isRentReady);
        SBR_3_0_SfsOrderFromSeController.generateCXML(recordId,data);
        String xmlString=data.get('request')+'';
        //data.put('generated','F');
        string generated=data.get('generated')+'';
        if(generated=='T' && !isRentReady)
        { SmartEquipApiSetting__mdt punchoutDetails= SmartEquipApiSetting__mdt.getInstance('punchOut');
         
         string append='<!DOCTYPE cXML SYSTEM "http://xml.cxml.org/schemas/cXML/'+punchoutDetails.Version__c+'/cXML.dtd">';
         Integer index=xmlString.IndexOf('?>');
         string newString=xmlString.substring(index+2);
         String existingXmlFormat=xmlString.substring(0,index+2);
         string body=existingXmlFormat+append+newstring;
         system.debug(append+newstring);
         Http p= new Http();
         HttpRequest req= new HttpRequest();
         //req.getBody(append+newstring);
         req.setEndpoint(punchoutDetails.Url__c+'');
         req.setMethod('POST');
         req.setBody(body);
         req.setHeader('Content-Type', 'application/xml');
         //req.setHeader('Accept', 'application/json');
         HttpResponse response=p.send(req);
         SYStem.debug(JSON.serializePretty(response.getbody()));
         data.put('request',body);
         data.put('response',response.getBody());
         SBR_3_0_SfsOrderFromSeController.readResponse(response.getBody(),data);
        }
        
        
        
        return data; 
    }
    
}