public class SBR_3_0_ManageWebsiteUserIntegration {
	public static SBR_3_0_ManageWebsiteUserWrapper UserSearch (String CompanyCode,String AccountNumber){
        System.debug('CompanyCode'+CompanyCode);
        System.debug('AccountNumber'+AccountNumber);
        String response = SBR_3_0_CommandCenterCallout.doCalloutGet(AccountNumber,CompanyCode);
        System.debug('response'+response);
        SBR_3_0_ManageWebsiteUserWrapper responseWrap = SBR_3_0_ManageWebsiteUserWrapper.parse(response);
        system.debug(responseWrap);
        return responseWrap;
    }
    public static SBR_3_0_ManageWebsiteUserWrapper UserInvite (String FirstName,String LastName,String Email,String CompanyCode,String AccountNumber,String Name,String UserType){
        System.debug('FirstName'+FirstName);
        System.debug('LastName'+LastName);
        System.debug('Email'+Email);
        System.debug('CompanyCode'+CompanyCode);
        System.debug('AccountNumber'+AccountNumber);
        System.debug('Name'+Name);
        System.debug('UserType'+UserType);
        User oUser = 	[
            				SELECT
							Id,
            				FirstName,
            				LastName,
            				Email,
            				EmployeeNumber
            				FROM
							User
							WHERE
							Id =: UserInfo.getUserId()
        				];
        SBR_3_0_ManageWebsiteUserRequestWrapper oRequest = new SBR_3_0_ManageWebsiteUserRequestWrapper();
        if(UserType == 'Cash'){
        	oRequest.overideNonCredit = true;    
        }
        else{
            oRequest.overideNonCredit = false;
        }
        oRequest.accountNumber = Integer.valueOf(AccountNumber);
        oRequest.accountName = Name;
        SBR_3_0_ManageWebsiteUserRequestWrapper.Customer oCustomer = new SBR_3_0_ManageWebsiteUserRequestWrapper.Customer();
        oCustomer.firstName = FirstName;
        oCustomer.lastName = LastName;
        oCustomer.email = Email;
        oCustomer.isAdmin = TRUE;
        oRequest.customer = oCustomer;
        SBR_3_0_ManageWebsiteUserRequestWrapper.requester orequester = new SBR_3_0_ManageWebsiteUserRequestWrapper.requester();
        orequester.firstName = oUser.FirstName;
        orequester.lastName = oUser.LastName;
        orequester.email = oUser.Email;
        if(!String.isEmpty(oUser.EmployeeNumber) && oUser.EmployeeNumber != NULL){
        	orequester.employeeId = Integer.valueOf(oUser.EmployeeNumber);
        }
        else{
            orequester.employeeId = 92287;
        }
        oRequest.requester = orequester;
        String JSONString = JSON.serialize(oRequest);
    	system.debug('JSONString : ' + JSONString );
        String response = SBR_3_0_CommandCenterCallout.doCalloutCreate(JSONString,AccountNumber,CompanyCode,Email);
        System.debug('response'+response);
        SBR_3_0_ManageWebsiteUserWrapper responseWrap = SBR_3_0_ManageWebsiteUserWrapper.parse(response);
        system.debug(responseWrap);
        return responseWrap;
    }
    public static SBR_3_0_MWUAccountSearchWrapper AccountsSearch (String Email){
        System.debug('Email'+Email);
        String response = SBR_3_0_CommandCenterCallout.doCalloutSearch(Email);
        System.debug('response'+response);
        SBR_3_0_MWUAccountSearchWrapper responseWrap = SBR_3_0_MWUAccountSearchWrapper.parse(response);
        system.debug(responseWrap);
        return responseWrap;
    }
    public static list<SBR_3_0_MWUAccountEmailSearchWrapper.Users> AccountsEmailSearch (String SearchString){
        String response = SBR_3_0_CommandCenterCallout.doCalloutSearchEmail(SearchString);
        System.debug('response'+response);
        SBR_3_0_MWUAccountEmailSearchWrapper responseWrap = SBR_3_0_MWUAccountEmailSearchWrapper.parse(response);
        system.debug(responseWrap);
        list<SBR_3_0_MWUAccountEmailSearchWrapper.Users> lUsers = responseWrap.Data.users;
        return lUsers;
    }
}