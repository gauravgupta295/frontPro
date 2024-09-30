import { LightningElement, api, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getRecord, updateRecord } from 'lightning/uiRecordApi';

import checkPermissionSetGroup from '@salesforce/apex/SBR_3_0_PermissionSetGroupAssignment.checkPermissionSetGroup';
import EQUIPMENT_NUMBER from "@salesforce/schema/Asset.SM_PS_Equipment_Number__c";
import CAT_CLASS from "@salesforce/schema/Asset.SM_PS_Cat_Class__c";
import ASSIGNED_LOCATION_ID from "@salesforce/schema/Asset.SM_PS_Assigned_Location__c";
import ASSIGNED_LOCATION_NAME from "@salesforce/schema/Asset.SM_PS_Assigned_Location__r.Branch_Location_Name__c";
import STATUS from "@salesforce/schema/Asset.Status";
import FIELD_EMPLOYEE_EQUIPMENT_COMMENT from "@salesforce/schema/Asset.SM_PS_Field_Employee_Equipment_Comment__c";
import EQUIPMENT_DESCRIPTION from "@salesforce/schema/Asset.SM_PS_Miscellaneous_Options__c";
import CURRENT_LOCATION_ID  from "@salesforce/schema/Asset.SM_PS_Current_Location__c";
import CURRENT_LOCATION_NAME  from "@salesforce/schema/Asset.SM_PS_Current_Location__r.Branch_Location_Name__c";
import HOURS  from "@salesforce/schema/Asset.SM_PS_Current_MiHr__c";
import FOR_SALE from "@salesforce/schema/Asset.SM_PS_For_Sale__c";
import ASSET_NUMBER from "@salesforce/schema/Asset.Name";  //Added as part of the story#FRONT - 17780 by Gopal Raj
import { CloseActionScreenEvent } from "lightning/actions";

import FORM_FACTOR from "@salesforce/client/formFactor"; //Added as part of the story#FRONT - 17780 by Gopal Raj

const SMALL_FORM_FACTOR = "Small"; //Added as part of the story#FRONT - 17780 by Gopal Raj
/*Start: Added as part of the story#FRONT - 17780 by Gopal Raj*/
import DESKTOP_TEMPLATE from "./sbr_3_0_updateAssetStatus_Desktop/sbr_3_0_updateAssetStatusDesktop.html";
import MOBILE_TEMPLATE from "./sbr_3_0_updateAssetStatus_Mobile/sbr_3_0_updateAssetStatusMobile.html";
/*End: Added as part of the story#FRONT - 17780 by Gopal Raj*/


export default class Sbr_3_0_updateAssetStatusModal extends LightningElement {
    @api recordId;
    @api objectApiName;
    equipNum;
    catClass;
    assignedLocId;
    assignedLocName;
    status;
    fieldComment;
    equipDescription;
    currentLocId;
    currentLocName;
    hours;
    forSale;
    assetNumber; //Added as part of the story#FRONT - 17780 by Gopal Raj

    hasBMPermission=false;
    hasERSPermission=false;
    canBMEdit=true;
    canERSEdit=true;
    BMstatusList = ['ON RENT', 'JUNKED', 'SAFETY/SERVICE LOCKOUT','SCHEDULED FOR PICKUP', 'IN TRANSIT', 'SOLD' ];
    ERSstatusList = ['ON RENT', 'JUNKED', 'SOLD', 'STOLEN', 'IN TRANSIT', 'SCHEDULED FOR PICKUP', 'SAFETY/SERVICE LOCKOUT' ];

    /*Start:Added as part of the story#FRONT - 17780 by Gopal Raj*/
    get isMobile() {
        return FORM_FACTOR === SMALL_FORM_FACTOR;
    }
    /*end:Added as part of the story#FRONT - 17780 by Gopal Raj*/


    checkCanBMEdit(){
        if (this.BMstatusList.includes(this.status)){
            this.canBMEdit = false;
        } 
    }


    checkCanERSEdit(){
        if (this.ERSstatusList.includes(this.status)){
            this.canERSEdit = false;
        } 
    }

    connectedCallback(){
        this.checkBMPermission();
        this.checkERSPermission();
        
    }

    checkBMPermission(){
        checkPermissionSetGroup({
             permissionSetGroupName: 'Branch_Manager'
        }).then(result => {
            this.hasBMPermission = result;
            
        }).catch((error) => {
            console.error('Error checking for Branch Manager permission set', error);

        });
    }

    checkERSPermission(){
        checkPermissionSetGroup({
             permissionSetGroupName: 'ERS'
        }).then(result => {
            this.hasERSPermission = result;
           
        }).catch((error) => {
            console.error('Error checking for ERS permission set', error);

        });
    }


    @wire(getRecord, { recordId: '$recordId', fields: [EQUIPMENT_NUMBER, CAT_CLASS, ASSIGNED_LOCATION_ID, STATUS, FIELD_EMPLOYEE_EQUIPMENT_COMMENT, EQUIPMENT_DESCRIPTION, CURRENT_LOCATION_ID, HOURS, FOR_SALE, ASSIGNED_LOCATION_NAME,  CURRENT_LOCATION_NAME,ASSET_NUMBER] })
    wiredRecord({ error, data }) {
        if (data) {
            this.equipNum = data.fields.SM_PS_Equipment_Number__c.value;
            this.catClass = data.fields.SM_PS_Cat_Class__c.value;
            this.assignedLocId = data.fields.SM_PS_Assigned_Location__c.value;
            this.assignedLocName = data.fields.SM_PS_Assigned_Location__r.displayValue;
            this.status = data.fields.Status.value;
            this.fieldComment = data.fields.SM_PS_Field_Employee_Equipment_Comment__c.value;
            this.equipDescription = data.fields.SM_PS_Miscellaneous_Options__c.value;
            this.currentLocId = data.fields.SM_PS_Current_Location__c.value;
            this.currentLocName = data.fields.SM_PS_Current_Location__r.displayValue;
            this.hours = data.fields.SM_PS_Current_MiHr__c.value;
            this.forSale = data.fields.SM_PS_For_Sale__c.value;
            this.assetNumber = data.fields.Name.value;
            this.checkCanBMEdit();
            this.checkCanERSEdit();

        } else if (error) {
            console.error('Error loading record', error);
        }

       
    }

  

    get BMoptions(){  
            return [
                { label: 'Available', value: 'AVAILABLE' },
                { label: 'Down - More Than 20 Days', value: 'DOWN - MORE THAN 20 DAYS' },
                { label: 'Held For Sale', value: 'HELD FOR SALE' },
                { label: 'On Truck', value: 'ON TRUCK' },
                { label: 'Down - Less Than 20 Days', value: 'DOWN - LESS THAN 20 DAYS' },
                { label: 'Satelite Branch', value: 'SATELITE BRANCH' },
                { label: 'Returned - Need Check Out', value: 'RETURNED - NEED CHECK OUT' },
                { label: 'Seasonal', value: 'SEASONAL' },
                { label: 'Held For Central Disposal', value: 'HELD FOR CENTRAL DISPOSAL' },
                { label: 'Missing Lost', value: 'MISSING LOST' },
                { label: 'Junked', value: 'JUNKED' },
                { label: 'Stolen', value: 'STOLEN' }
                
            ];
        
    }

    get ERSoptions(){  
        return [
                { label: 'Available', value: 'AVAILABLE' },
                { label: 'Down - More Than 20 Days', value: 'DOWN - MORE THAN 20 DAYS' },
                { label: 'Held For Sale', value: 'HELD FOR SALE' },
                { label: 'On Truck', value: 'ON TRUCK' },
                { label: 'Down - Less Than 20 Days', value: 'DOWN - LESS THAN 20 DAYS' },
                { label: 'Satelite Branch', value: 'SATELITE BRANCH' },
                { label: 'Returned - Need Check Out', value: 'RETURNED - NEED CHECK OUT' },
                { label: 'Seasonal', value: 'SEASONAL' },
                { label: 'Held For Central Disposal', value: 'HELD FOR CENTRAL DISPOSAL' }
            
        ];
    
}

get disabledOptions(){
  return [
     { label: 'On Rent', value: 'ON RENT' },
     { label: 'Junked', value: 'JUNKED' },
     { label: 'Safety/Service Lockout', value: 'SAFETY/SERVICE LOCKOUT' },
     { label: 'Scheduled For Pickup', value: 'SCHEDULED FOR PICKUP' },
     { label: 'In Transit', value: 'IN TRANSIT' },
     { label: 'Sold', value: 'SOLD' },
     { label: 'Stolen', value: 'STOLEN' }

     
  ];
}

    handleStatusChange(event){
      this.status = event.target.value;
    }
    
    handleCommentChange(event){
      this.fieldComment = event.target.value;
    }

    handleHoursChange(event){
      this.hours = event.target.value;
    }

    handleForSaleChange(event){
      this.forSale = !this.forSale;
    }
  
    closeModal() {
      this.dispatchEvent(new CloseActionScreenEvent());
      this.closeAuraAction(); //Added as part of the story#FRONT - 17780 by Gopal Raj
    }
  
    /*Start: Added as part of the story#FRONT - 17780 by Gopal Raj*/
    closeAuraAction() {
        this.dispatchEvent(new CustomEvent("closeauraaction"));
      } 

    render() {
        let renderTemplate;
        if (this.isMobile) {
            renderTemplate = MOBILE_TEMPLATE;
        }
        else{
            renderTemplate = DESKTOP_TEMPLATE;          
        }
        return renderTemplate;
    }
    /*End: Added as part of the story#FRONT - 17780 by Gopal Raj*/


  
}