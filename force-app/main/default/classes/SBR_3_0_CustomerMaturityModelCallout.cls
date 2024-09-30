public with sharing class SBR_3_0_CustomerMaturityModelCallout {
    public static String CMMCalloutGet(String companyId,String customerId){
        Map<String,SBR_3_0_Customer_Maturity_Model_Labels__mdt> mLabels = SBR_3_0_Customer_Maturity_Model_Labels__mdt.getAll();
        System.debug('mLabels'+mLabels);  
        Global_API_Settings__mdt oGlobalAPISettings = Global_API_Settings__mdt.getInstance('Customer_Maturity_Model');
        String AccessToken = SBR_3_0_CustomerMaturityModelCallout.getAccessToken();
        SBR_3_0_CustomerMaturityModelWrapper responseWrap = SBR_3_0_CustomerMaturityModelWrapper.parse(AccessToken);
        system.debug('responseWrap'+responseWrap);
        system.debug('AccessToken'+responseWrap.access_token);
        HttpRequest req = new HttpRequest();
        req.setEndpoint(oGlobalAPISettings.Host__c+oGlobalAPISettings.Resource__c+customerId+'/recommendations');
        req.setHeader('Authorization','Bearer ' + responseWrap.access_token);
        req.setHeader('companyId',companyId);
        Blob oBlob = Crypto.GenerateAESKey(128);
        String oConveredCode = EncodingUtil.ConvertTohex(oBlob);
        String oGUID = oConveredCode.SubString(0,8)+ '-' + oConveredCode.SubString(8,12) + '-' + oConveredCode.SubString(12,16) + '-' + oConveredCode.SubString(16,20) + '-' + oConveredCode.substring(20);
        req.setHeader('x-correlation-id',oGUID);
        req.setMethod(oGlobalAPISettings.Method__c); 
        req.setTimeout(120000);
        Http http = new Http();
        HTTPResponse res = http.send(req);
        system.debug('Status Code'+res.getStatusCode());
        system.debug('Status getBody'+res.getBody());
        if(res.getStatusCode() != 200){ 
            throw new AuraHandledException(mLabels.get('Error_loading_data_Please_refresh_or_co').Label_Value__c);
        }
        else{
            system.debug(res.getBody());
            return res.getBody();
        }
    }
    
    public static String getAccessToken(){
        Map<String,SBR_3_0_Customer_Maturity_Model_Labels__mdt> mLabels = SBR_3_0_Customer_Maturity_Model_Labels__mdt.getAll();
        System.debug('mLabels'+mLabels); 
        list<Credential__c> lCredentials = [SELECT Name, Key_Id__c, Secret__c, Environment__c FROM Credential__c WHERE Name = 'Mule_Token_Endpoint'];
		Global_API_Settings__mdt oGlobalAPISettings = Global_API_Settings__mdt.getInstance('Customer_Maturity_Model_Auth');
		if(!lCredentials.isEmpty()){
            HttpRequest req = new HttpRequest();
            Map <String, String> paramValueMap = new Map<String,String>();
            paramValueMap.put('grant_type','client_credentials');
            paramValueMap.put('client_id',lCredentials[0].Key_Id__c);
            paramValueMap.put('client_secret',lCredentials[0].Secret__c);
            paramValueMap.put('scope','Mulesoft');
            String paramValue = constructURI(paramValueMap);
            req.setEndpoint(oGlobalAPISettings.Host__c+oGlobalAPISettings.Resource__c);
            req.setMethod(oGlobalAPISettings.Method__c);
            req.setHeader('Content-Type','application/x-www-form-urlencoded');
            req.setHeader('Cookie','__cf_bm=2GkkQE12WKtt_QjxBB82uk.Urlacp7Lb.YInHjXdGog-1687458656-0-AbipAymYZJ30RepPt7YMOSY8p4/FUzGxShJfVoZPdq7fa46qt+px7tnbAHFmWG2ZyhZoa72RbE/dDjYorkInJxg=');
            Blob oBlob = Crypto.GenerateAESKey(128);
            String oConveredCode = EncodingUtil.ConvertTohex(oBlob);
            String oGUID = oConveredCode.SubString(0,8)+ '-' + oConveredCode.SubString(8,12) + '-' + oConveredCode.SubString(12,16) + '-' + oConveredCode.SubString(16,20) + '-' + oConveredCode.substring(20);
            req.setHeader('x-correlation-id',oGUID);
            req.setBody(paramValue);
            req.setTimeout(120000);
            Http http = new Http();
            HTTPResponse res = http.send(req);
            system.debug('Status Code'+res.getStatusCode());
            system.debug('Status getBody'+res.getBody());
            if(res.getStatusCode() != 200){
                throw new AuraHandledException(mLabels.get('Error_loading_data_Please_refresh_or_co').Label_Value__c);   
            }
            else{
               system.debug(res.getBody());
               return res.getBody();
            }
        }
        else{
            throw new AuraHandledException(mLabels.get('Error_loading_data_Please_refresh_or_co').Label_Value__c); 
        }
    }
    
    public static String FeedbackCalloutGet(string Feedback){
        Global_API_Settings__mdt oGlobalAPISettings = Global_API_Settings__mdt.getInstance('Product_Recommendation_Feedback');
        String AccessToken = SBR_3_0_CustomerMaturityModelCallout.getAccessToken();
        System.debug('AccessToken'+AccessToken);
        SBR_3_0_CustomerMaturityModelWrapper responseWrap = SBR_3_0_CustomerMaturityModelWrapper.parse(AccessToken);
        system.debug('responseWrap'+responseWrap);
        system.debug('AccessToken'+responseWrap.access_token);
        HttpRequest req = new HttpRequest();
        req.setEndpoint(oGlobalAPISettings.Host__c+oGlobalAPISettings.Resource__c);
        req.setHeader('Authorization','Bearer ' + responseWrap.access_token);
        req.setHeader('Content-Type','application/json');
        req.setMethod(oGlobalAPISettings.Method__c); 
        req.setTimeout(120000);
        req.setBody(Feedback);
        Http http = new Http();
        HTTPResponse res = http.send(req);
        system.debug('Status Code'+res.getStatusCode());
        system.debug('Status getBody'+res.getBody());
        if(res.getStatusCode() != 201){
            throw new AuraHandledException(res.getBody());
        }
        else{
            system.debug(res.getBody());
            return res.getBody();
        }
    }
    public static String constructURI (Map<String,String> paramValue){
        String URIStr;
        system.debug('paramValue'+paramValue);
        List<String> parameters = new List<String>();
        parameters.addAll(paramValue.keySet());
        system.debug('parameters'+parameters);
        for(Integer i = 0; i<parameters.size(); i++ ){
            if(i == 0){
				URIStr = parameters[i] + '=' + paramValue.get(parameters[i]);                 
            }
            else{
                URIStr += '&' + parameters[i] + '=' + paramValue.get(parameters[i]);
            }
        }
        system.debug('URIStr'+URIStr);
        return URIStr;
    }
}