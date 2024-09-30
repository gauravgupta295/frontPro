({
    init: function(component, event, helper) {
        let recordId=component.get('v.recordId');
        let objectAPIName= component.get('v.sObjectName');
        
        let props1 = {
            
            objectapiname: 'ProductConsumed', // Associated Object
            mode: 'Edit', // Put some value if you want to work this in edit mode along with record id
            recordid: component.get('v.recordId'), //recordid require for edit mode
            recordtypeid: '', // record type id
            header: 'Edit Product Consumed', //header
            headericon: 'standard:product_consumed',
            headericonsize: 'medium',
            btnlabel: 'SAVE',
            variant: 'standard',
            sucessmessage: 'Record Updated Successfully !!', //Success Message
            errormessage: '',
            outercss: '',
            innercss: '',
            largeff: 'slds-col slds-size_6-of-12 slds-var-p-horizontal_x-small',
            smallff: 'slds-col slds-size_12-of-12 slds-var-p-horizontal_x-small',
            showcancel: false,
            // Field sets are done for UI and layout and styling arrangement
            fieldSetOne: [
                { apiname: 'WorkOrderId', disabled: true, readonly: false, value: '', required: false },
                { apiname: 'SF_PS_ItemType__c', disabled: true, readonly: false, value: '', required: false },
            ],
            // For styling purpouse different field set is created in LWC
            fieldSetTwo: [
                { apiname: 'SF_PS_Warning_Price__c', disabled: false, readonly: false, value: '', required: false },  // Warninig price
            ],
            // For Layout arrangement
            fieldSetThree: [
                { apiname: 'SF_PS_Description__c', disabled: true, readonly: false, value: '', required: false },
            ],
            // For styling purpouse different field set is created in LWC
            fieldSetFour:[
                { apiname: 'SF_PS_Minimum_Price__c', disabled: true, readonly: false, value: '', required: false },
                { apiname: 'SF_PS_Stock_Class__c', disabled: false, readonly: false, value: '', required: false }, 
            ],
            // Remainig fields
            fieldSetFive:[	
                { apiname: 'SF_PS_Cost_Price__c', disabled: true, readonly: false, value: '', required: false},
                { apiname: 'SF_PS_Orig_Selling_Price__c', disabled: true, readonly: false, value: '', required: false },
                { apiname: 'SF_PS_List_Price__c', disabled: true, readonly: false, value: '', required: false},
                { apiname: 'SF_PS_Quantity__c', disabled: false, readonly: false, value: '', required: true, invalidValueError: false },
                { apiname: 'SF_PS_Unit_Of_Measure__c', disabled: true, readonly: false, value: '', required: false },
               
               
            ],
            fieldSetSix:[
                { apiname: 'SF_PS_Labor_Code__c', disabled: false, readonly: false, value: '', required: true }, // Added labor code 
            ]
        };

        let props2 = {
            
            objectapiname: 'SF_PS_Quoted_Part__c', // Associated Object
            mode: 'Edit', // Put some value if you want to work this in edit mode along with record id
            recordid: component.get('v.recordId'), //recordid require for edit mode
            recordtypeid: '', // record type id
            header: 'Edit Quoted Part', //header
            headericon: 'custom:custom14',
            headericonsize: 'medium',
            btnlabel: 'SAVE',
            variant: 'standard',
            sucessmessage: 'Record Updated Successfully !!', //Success Message
            errormessage: '',
            outercss: '',
            innercss: '',
            largeff: 'slds-col slds-size_6-of-12 slds-var-p-horizontal_x-small',
            smallff: 'slds-col slds-size_12-of-12 slds-var-p-horizontal_x-small',
            showcancel: false,

             // Field sets are done for UI and layout and styling arrangement
             fieldSetOne: [
                { apiname: 'SF_PS_WorkOrderId__c', disabled: true, readonly: false, value: '', required: false },
                { apiname: 'SF_PS_ItemType__c', disabled: true, readonly: false, value: '', required: false },
            ],

            // For styling purpouse different field set is created in LWC
            fieldSetTwo: [
                { apiname: 'SF_PS_Warning_Price__c', disabled: false, readonly: false, value: '', required: false },  // Warninig price
            ],

            // For Layout arrangement
            fieldSetThree: [
                { apiname: 'SM_PS_Description__c', disabled: true, readonly: false, value: '', required: false },
            ],

            // For styling purpouse different field set is created in LWC
            fieldSetFour:[
                { apiname: 'SF_PS_Minimum_Price__c', disabled: true, readonly: false, value: '', required: false },
                { apiname: 'SF_PS_Stock_Class__c', disabled: false, readonly: false, value: '', required: false }, 
            ],
             // Remainig fields
             fieldSetFive:[	
                { apiname: 'SF_PS_Cost_Price__c', disabled: true, readonly: false, value: '', required: false},
                { apiname: 'SF_PS_Orig_Selling_Price__c', disabled: true, readonly: false, value: '', required: false },
                { apiname: 'SF_PS_List_Price__c', disabled: true, readonly: false, value: '', required: false},
                { apiname: 'SF_PS_Quantity__c', disabled: false, readonly: false, value: '', required: true, invalidValueError: false },
                { apiname: 'SF_PS_Unit_Of_Measure__c', disabled: true, readonly: false, value: '', required: false },  
               
            ],
            fieldSetSix:[
                { apiname: 'SF_PS_Labor_Code__c', disabled: false, readonly: false, value: '', required: true }, // Added labor code 
            ]
        
        };
        let props = (objectAPIName == 'ProductConsumed') ? props1 : props2;
        component.set('v.props',props);
    }
 
})