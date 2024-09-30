({
    init: function(component, event, helper) {
        let recordId=component.get('v.recordId');
        let objectAPIName= component.get('v.sObjectName');
        let pageRef = component.get("v.pageReference");
        let difValues=pageRef.state.defaultFieldValues;
        let workOrderId,mode,header;
        if(difValues){
            let defaults= difValues.split(',');
            workOrderId=defaults[0].split('=')[1];
        }
        if(!workOrderId)
        {
            
            
            console.log(JSON.stringify(pageRef));
            var state = pageRef.state; // state holds any query params
            console.log('state = '+JSON.stringify(state));
            var base64Context = state.inContextOfRef;
            console.log('base64Context = '+base64Context);
            if ( base64Context && base64Context.startsWith("1\.")) {
                base64Context = base64Context.substring(2);
                console.log('base64Context = '+base64Context);
            }
            if(base64Context){
                var addressableContext = JSON.parse(window.atob(base64Context));
                console.log('addressableContext = '+JSON.stringify(addressableContext));
                workOrderId=addressableContext.attributes.recordId;
                component.set("v.recordId", addressableContext.attributes.recordId);
            }
           
        }
        component.set("v.woId",workOrderId);
        let props1 = {
            
            objectapiname: 'ProductConsumed', // Associated Object
            mode: 'create', // Put some value if you want to work this in edit mode along with record id
            recordid: '', //recordid require for edit mode
            recordtypeid: '', // record type id
            header: 'Add Product Consumed', //header
            headericon: 'standard:product_consumed',
            headericonsize: 'medium',
            btnlabel: 'SAVE',
            variant: 'standard',
            sucessmessage: 'Record Created Successfully !!', //Success Message
            errormessage: '',
            outercss: '',
            innercss: '',   
            largeff: 'slds-col slds-size_6-of-12 slds-var-p-horizontal_x-small',
            smallff: 'slds-col slds-size_12-of-12 slds-var-p-horizontal_x-small',
            showcancel: false,
            
            
            fieldSet: [
                { apiname: 'WorkOrderId', disabled: false, readonly: false,  required: true ,value:workOrderId},
                
                { apiname: 'SF_PS_ItemType__c', disabled: false, readonly: false, value: 'P', required: true },
                //{ apiname: 'SF_PS_Minimum_Price__c', disabled: true, readonly: false, value: '', required: false },
                { apiname: 'SF_PS_Warning_Price__c', disabled: false, readonly: false, value: '', required: true },  // Warninig price
                { apiname: 'SF_PS_Description__c', disabled: true, readonly: false, value: '', required: false },
                { apiname: 'SF_PS_Minimum_Price__c', disabled: true, readonly: false, value: '', required: false },
                { apiname: 'SF_PS_Stock_Class__c', disabled: false, readonly: false, value: '', required: true },
                { apiname: 'SF_PS_Cost_Price__c', disabled: true, readonly: false, value: '', required: false },
                { apiname: 'SF_PS_Orig_Selling_Price__c', disabled: true, readonly: false, value: '', required: false },
                { apiname: 'SF_PS_List_Price__c', disabled: true, readonly: false, value: '', required: false },
                { apiname: 'SF_PS_Quantity__c', disabled: false, readonly: false, value: '', required: true , invalidValueError: false },
                { apiname: 'SF_PS_Product_SKU__c', disabled: true, readonly: false, value: '', required: false },
                { apiname: 'SF_PS_Unit_Of_Measure__c', disabled: true, readonly: false, value: '', required: false },
                { apiname: 'SF_PS_Labor_Code__c', disabled: false, readonly: false, value: '', required: true },
           
            ]

           

            

                
                };
                let props2 = {
                
                objectapiname: 'SF_PS_Quoted_Part__c', // Associated Object
                mode: 'New',
                woId:workOrderId,  // Put some value if you want to work this in edit mode along with record id
                recordid: '', //recordid require for edit mode
                recordtypeid: '', // record type id
                header: 'Add Quoted Part', //header
                headericon: 'custom:custom14',
                headericonsize: 'medium',
                btnlabel: 'SAVE',
                variant: 'standard',
                sucessmessage: 'Record Created Successfully !!', //Success Message
                errormessage: '',
                outercss: '',
                innercss: '',
                largeff: 'slds-col slds-size_6-of-12 slds-var-p-horizontal_x-small',
                smallff: 'slds-col slds-size_12-of-12 slds-var-p-horizontal_x-small',
                showcancel: false,
                
                fieldSet: [
                { apiname: 'SF_PS_WorkOrderId__c', disabled: false, readonly: false,  required: true,value:workOrderId },
                { apiname: 'SF_PS_Parts_Type__c', disabled: false, readonly: false,  required: true,value:'Inventory' },

                { apiname: 'SF_PS_ItemType__c', disabled: false, readonly: false, value: '', required: true,value:'P'  },
                { apiname: 'SF_PS_Warning_Price__c', disabled: false, readonly: false, value: '', required: true },  // Warninig price
                { apiname: 'SM_PS_Description__c', disabled: true, readonly: false, value: '', required: false },
                { apiname: 'SF_PS_Minimum_Price__c', disabled: true, readonly: false, value: '', required: false },
                { apiname: 'SF_PS_Stock_Class__c', disabled: false, readonly: false, value: '', required: true },
                { apiname: 'SF_PS_Cost_Price__c', disabled: true, readonly: false, value: '', required: false },
                { apiname: 'SF_PS_Orig_Selling_Price__c', disabled: true, readonly: false, value: '', required: false },
                { apiname: 'SF_PS_List_Price__c', disabled: true, readonly: false, value: '', required: false },
                { apiname: 'SF_PS_Quantity__c', disabled: false, readonly: false, value: '', required: true, invalidValueError: false  },
                { apiname: 'SF_PS_Unit_Of_Measure__c', disabled: true, readonly: false, value: '', required: false },
                { apiname: 'SF_PS_Labor_Code__c', disabled: false, readonly: false, value: '', required: true },

            ]
            
        };
        let props = (objectAPIName == 'ProductConsumed') ? props1 : props2;
        component.set('v.props',props);
    }
    
})