public class SBR_3_0_CommandCenterCallout {
    public static String doCalloutGet (String AccountNumber,String CompanyCode){
        Global_API_Settings__mdt oGlobalAPISettings = Global_API_Settings__mdt.getInstance('Command_Center_Callount');
        String AccessToken = SBR_3_0_CommandCenterCallout.getAccessToken();
        System.debug('AccessToken'+AccessToken);
        SBR_3_0_ManageWebsiteUserWrapper responseWrap = SBR_3_0_ManageWebsiteUserWrapper.parse(AccessToken);
        system.debug('responseWrap'+responseWrap);
        system.debug('AccessToken'+responseWrap.access_token);
        HttpRequest req = new HttpRequest(); 
        req.setEndpoint(oGlobalAPISettings.Host__c+oGlobalAPISettings.Resource__c+AccountNumber+'/users');
        req.setHeader('Authorization','Bearer ' + responseWrap.access_token);
        req.setHeader('companyId',CompanyCode);
        Blob oBlob = Crypto.GenerateAESKey(128);
        String oConveredCode = EncodingUtil.ConvertTohex(oBlob);
        String oGUID = oConveredCode.SubString(0,8)+ '-' + oConveredCode.SubString(8,12) + '-' + oConveredCode.SubString(12,16) + '-' + oConveredCode.SubString(16,20) + '-' + oConveredCode.substring(20);
        System.debug('oGUID'+oGUID);
        req.setHeader('x-correlation-id',oGUID);
        req.setMethod(oGlobalAPISettings.Method__c); 
        req.setTimeout(120000);
        Http http = new Http();
        HTTPResponse res = http.send(req);
        system.debug('Status Code'+res.getStatusCode());
        system.debug('Status getBody'+res.getBody());
        if(res.getStatusCode() != 200){
            throw new AuraHandledException(res.getStatus()); 
        }
        else{
            system.debug(res.getBody());
            return res.getBody();
        }
    }
    public static String doCalloutCreate (String URI,String AccountNumber,String CompanyCode,String Email){
        Global_API_Settings__mdt oGlobalAPISettings = Global_API_Settings__mdt.getInstance('Command_Center_Callount');
        String AccessToken = SBR_3_0_CommandCenterCallout.getAccessToken();
        System.debug('AccessToken'+AccessToken);
        SBR_3_0_ManageWebsiteUserWrapper responseWrap = SBR_3_0_ManageWebsiteUserWrapper.parse(AccessToken);
        system.debug('responseWrap'+responseWrap);
        system.debug('AccessToken'+responseWrap.access_token);
        HttpRequest req = new HttpRequest();
        req.setEndpoint(oGlobalAPISettings.Host__c+oGlobalAPISettings.Resource__c+'invite');
        req.setHeader('Authorization','Bearer ' + responseWrap.access_token);
        req.setHeader('companyId',CompanyCode);
        req.setHeader('Content-Type','application/json');
        Blob oBlob = Crypto.GenerateAESKey(128); 
        String oConveredCode = EncodingUtil.ConvertTohex(oBlob);
        String oGUID = oConveredCode.SubString(0,8)+ '-' + oConveredCode.SubString(8,12) + '-' + oConveredCode.SubString(12,16) + '-' + oConveredCode.SubString(16,20) + '-' + oConveredCode.substring(20);
        System.debug('oGUID'+oGUID);
        req.setHeader('x-correlation-id',oGUID);
        req.setBody(URI);
        req.setMethod(oGlobalAPISettings.Method__c); 
        req.setTimeout(120000);
        Http http = new Http();
        HTTPResponse res = http.send(req);
        system.debug('Status Code'+res.getStatusCode());
        system.debug('Status getBody'+res.getBody());
        system.debug(res.getBody());
        return res.getBody();  
    }
    public static String doCalloutSearch (String Email){
        Global_API_Settings__mdt oGlobalAPISettings = Global_API_Settings__mdt.getInstance('Command_Center_Callount');
        String AccessToken = SBR_3_0_CommandCenterCallout.getAccessToken();
        System.debug('AccessToken'+AccessToken);
        SBR_3_0_ManageWebsiteUserWrapper responseWrap = SBR_3_0_ManageWebsiteUserWrapper.parse(AccessToken);
        system.debug('responseWrap'+responseWrap);
        system.debug('AccessToken'+responseWrap.access_token); 
        HttpRequest req = new HttpRequest();
        req.setEndpoint(oGlobalAPISettings.Host__c+oGlobalAPISettings.Resource__c+'accounts');
        req.setHeader('Authorization','Bearer ' + responseWrap.access_token);
        Blob oBlob = Crypto.GenerateAESKey(128);
        String oConveredCode = EncodingUtil.ConvertTohex(oBlob);
        String oGUID = oConveredCode.SubString(0,8)+ '-' + oConveredCode.SubString(8,12) + '-' + oConveredCode.SubString(12,16) + '-' + oConveredCode.SubString(16,20) + '-' + oConveredCode.substring(20);
        System.debug('oGUID'+oGUID);
        req.setHeader('x-correlation-id',oGUID);
        req.setHeader('email', Email);
        req.setMethod(oGlobalAPISettings.Method__c); 
        req.setTimeout(120000);
        Http http = new Http();
        HTTPResponse res = http.send(req);
        system.debug('Status Code'+res.getStatusCode());
        system.debug('Status getBody'+res.getBody());
        system.debug(res.getBody());
        return res.getBody();
    }
    public static String doCalloutSearchEmail (String SearchString){
        Global_API_Settings__mdt oGlobalAPISettings = Global_API_Settings__mdt.getInstance('Command_Center_Callount');
        String AccessToken = SBR_3_0_CommandCenterCallout.getAccessToken();
        System.debug('AccessToken'+AccessToken);
        SBR_3_0_ManageWebsiteUserWrapper responseWrap = SBR_3_0_ManageWebsiteUserWrapper.parse(AccessToken);
        system.debug('responseWrap'+responseWrap);
        HttpRequest req = new HttpRequest();
        req.setEndpoint(oGlobalAPISettings.Host__c+oGlobalAPISettings.Resource__c+'email?search='+SearchString);
        req.setHeader('Authorization','Bearer ' + responseWrap.access_token);
        Blob oBlob = Crypto.GenerateAESKey(128);
        String oConveredCode = EncodingUtil.ConvertTohex(oBlob);
        String oGUID = oConveredCode.SubString(0,8)+ '-' + oConveredCode.SubString(8,12) + '-' + oConveredCode.SubString(12,16) + '-' + oConveredCode.SubString(16,20) + '-' + oConveredCode.substring(20);
        System.debug('oGUID'+oGUID);
        req.setHeader('x-correlation-id',oGUID);
        req.setMethod(oGlobalAPISettings.Method__c); 
        req.setTimeout(120000);
        Http http = new Http();
        HTTPResponse res = http.send(req);
        system.debug('Status Code'+res.getStatusCode());
        system.debug('Status getBody'+res.getBody());
        if(res.getStatusCode() != 200){
            throw new AuraHandledException(res.getStatus()); 
        }
        else{
            system.debug(res.getBody());
            return res.getBody();
        }
    }
    public static String getAccessToken (){
        Global_API_Settings__mdt oGlobalAPISettings = Global_API_Settings__mdt.getInstance('Command_Center_Auth');
        list<Credential__c> lCredentials = [SELECT Name, Key_Id__c, Secret__c, Environment__c FROM Credential__c WHERE Name = 'Mule_Token_Endpoint'];
		if(!lCredentials.isEmpty()){
            HttpRequest req = new HttpRequest();
            Map <String, String> paramValueMap = new Map<String,String>();
            paramValueMap.put('grant_type','client_credentials');
            paramValueMap.put('client_id',lCredentials[0].Key_Id__c);
            paramValueMap.put('client_secret',lCredentials[0].Secret__c);
            paramValueMap.put('scope','Mulesoft');
            System.debug('paramValueMap'+paramValueMap);
            String paramValue = constructURI(paramValueMap); 
            req.setEndpoint(oGlobalAPISettings.Host__c+oGlobalAPISettings.Resource__c);
            req.setMethod(oGlobalAPISettings.Method__c);
            req.setHeader('Content-Type','application/x-www-form-urlencoded');
            req.setHeader('Cookie','__cf_bm=2GkkQE12WKtt_QjxBB82uk.Urlacp7Lb.YInHjXdGog-1687458656-0-AbipAymYZJ30RepPt7YMOSY8p4/FUzGxShJfVoZPdq7fa46qt+px7tnbAHFmWG2ZyhZoa72RbE/dDjYorkInJxg=');
            Blob oBlob = Crypto.GenerateAESKey(128);
            String oConveredCode = EncodingUtil.ConvertTohex(oBlob);
            String oGUID = oConveredCode.SubString(0,8)+ '-' + oConveredCode.SubString(8,12) + '-' + oConveredCode.SubString(12,16) + '-' + oConveredCode.SubString(16,20) + '-' + oConveredCode.substring(20);
            System.debug('oGUID'+oGUID);
            req.setHeader('x-correlation-id',oGUID);
            req.setBody(paramValue);
            req.setTimeout(120000);
            Http http = new Http();
            HTTPResponse res = http.send(req);
            system.debug('Status Code'+res.getStatusCode());
            system.debug('Status getBody'+res.getBody());
            if(res.getStatusCode() != 200 ){
                throw new AuraHandledException(res.getBody());    
            }
            else{
                system.debug(res.getBody());
                return res.getBody();
            }
        }
        else{
            throw new AuraHandledException('No Credentials Found'); 
        }
    }
    public static String constructURI (Map<String,String> paramValue){
        String URIStr;
        system.debug('paramValue'+paramValue);
        List<String> parameters = new List<String>();
        parameters.addAll(paramValue.keySet());
        system.debug('parameters'+parameters);
        for(Integer i = 0; i<parameters.size(); i++ ){
            if(i == 0){//First one
				URIStr = parameters[i] + '=' + paramValue.get(parameters[i]);                 
            }
            else{//Remaning items in List
                URIStr += '&' + parameters[i] + '=' + paramValue.get(parameters[i]);
            }
        }
        system.debug('URIStr'+URIStr);
        return URIStr;
    }
}