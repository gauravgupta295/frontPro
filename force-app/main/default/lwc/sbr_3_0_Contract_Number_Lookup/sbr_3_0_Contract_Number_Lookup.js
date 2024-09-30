/* eslint-disable @lwc/lwc/no-api-reassignments */
import { LightningElement, api, track } from 'lwc';
import {FlowAttributeChangeEvent} from 'lightning/flowSupport';
import executeQuery from "@salesforce/apex/SBR_3_0_CustomQueryController.executeQuery";

/**
 * Todo: pass all fields we need to fetch from lookup SM_PS_Branch_Location_Number__c, SM_PS_Branch_Location__c
 */
export default class Sbr_3_0_Contract_Number_Lookup extends LightningElement {
    @api initialLookupValue;
    objectAPIName;
    componentLabel;
    @api selectedContract;
    @api contractJobLocation;
    @api contractJobNumber;
    @api customer;
    @api driver_state;
    @api contractId;
    @api applyRPP;
    @api customerPONumber;
    @api isRequired;
    fieldsToQuery;
    lstId = [];
    filterClause;
    _whereClause;

    set whereCondition(conditions) {
        this._whereClause = 'WHERE ' + conditions;
    }
    get whereCondition() {
        return this._whereClause;
    }

    connectedCallback()
    {
        this.objectAPIName = 'SM_PS_Equipment_Contract_History__c';
        this.componentLabel = 'Contract Number';
        this.fieldsToQuery = 'SM_PS_Branch_Location_Number__c,SM_PS_Branch_Location__c,SM_PS_Contract_Order__r.Jobsite__r.Location.Address__c,'+
        'SM_PS_Contract_Order__r.Jobsite__r.AssociatedLocationNumber,SM_PS_Contract_Order__r.Account.RM_Account_Number__c,SM_PS_Contract_Order__r.Account.Name,'+
        'SM_PS_Contract_Order__r.Driver_License_Number__c,SM_PS_Contract_Order__r.Driver_License_State__c,SM_PS_Contract_Order__r.RPP__c,SM_PS_Contract_Order__r.Customer_PO_Number__c';
        //this.whereCondition = 'WHERE Id IN: ';
        // this.filterClause = 'SM_PS_Equipment_Number__c = \''+this.contractId+'\'';
        this.filterClause = 'SM_PS_Equipment_Number__c = \'' + this.contractId + '\' AND SM_PS_Contract_Order__r.Account_Record_Type_Txt__c = \'credit\'';
    }

    handleLookupChange(event)
    {
        if (event.detail.selectedRecord !== undefined && Object.keys(event.detail.selectedRecord).length > 0 ) {
                this.selectedContract = event.detail.selectedRecord;

                // Set Where Clause
                this.whereCondition = 'Id = \'' + this.selectedContract.Id + '\'';

                //Get the latest data
                this.getSelectedRecordFields(this.whereCondition);

                // this.contractJobLocation = event.detail.selectedRecord.SM_PS_Branch_Location__c;
                // this.contractJobNumber = event.detail.selectedRecord.SM_PS_Branch_Location_Number__c;
                // this.dispatchFlowAttributeChangeEvent('selectedContract');
                // this.dispatchFlowAttributeChangeEvent('contractJobNumber');
                // this.dispatchFlowAttributeChangeEvent('contractJobLocation');
            } else {
                this.selectedContract = undefined;
                this.contractJobLocation = undefined;
                this.contractJobNumber = undefined;
                this.customer = undefined;
                this.driver_state = undefined;
                this.applyRPP = undefined;
                this.customerPONumber='';
                this.dispatchFlowAttributeChangeEvent('selectedContract');
                this.dispatchFlowAttributeChangeEvent('contractJobNumber');
                this.dispatchFlowAttributeChangeEvent('contractJobLocation');
                this.dispatchFlowAttributeChangeEvent('customer');
                this.dispatchFlowAttributeChangeEvent('driver_state');
                this.dispatchFlowAttributeChangeEvent('applyRPP');
                this.dispatchFlowAttributeChangeEvent('customerPONumber');
            }
    }

    dispatchFlowAttributeChangeEvent(attributeName)
    {
        const attributeChangeEvent = new FlowAttributeChangeEvent(
            attributeName,
            this[attributeName]
        );
        this.dispatchEvent(attributeChangeEvent);
    }

    getSelectedRecordFields(whereConditions)
    {
        executeQuery({fieldsCSV: this.fieldsToQuery, objAPIName: this.objectAPIName, whereClause: whereConditions}).then((resp) =>{
            console.log(JSON.stringify(resp));
            if(resp && Array.isArray(resp) && resp.length > 0)
            {
                let latestRecordData = resp[0];
                this.contractJobLocation = latestRecordData?.SM_PS_Contract_Order__r?.Jobsite__r?.Location?.Address__c;
                this.contractJobNumber = latestRecordData?.SM_PS_Contract_Order__r?.Jobsite__r?.AssociatedLocationNumber;

                this.customer = (latestRecordData?.SM_PS_Contract_Order__r?.Account?.RM_Account_Number__c ?
                                latestRecordData?.SM_PS_Contract_Order__r?.Account?.RM_Account_Number__c : '') +' '+
                                (latestRecordData?.SM_PS_Contract_Order__r?.Account?.Name ?
                                latestRecordData?.SM_PS_Contract_Order__r?.Account?.Name : '');

                this.driver_state = ((latestRecordData?.SM_PS_Contract_Order__r?.Driver_License_Number__c) ?
                                    latestRecordData?.SM_PS_Contract_Order__r?.Driver_License_Number__c : '') + ' '+
                                    ((latestRecordData?.SM_PS_Contract_Order__r?.Driver_License_State__c) ?
                                    latestRecordData?.SM_PS_Contract_Order__r?.Driver_License_State__c : '');
                this.applyRPP = (latestRecordData?.SM_PS_Contract_Order__r?.RPP__c == 'Y');
                this.customerPONumber = latestRecordData?.SM_PS_Contract_Order__r?.Customer_PO_Number__c;
                if(this.customerPONumber == undefined) {
                    this.customerPONumber = '';
                }
                this.dispatchFlowAttributeChangeEvent('selectedContract');
                this.dispatchFlowAttributeChangeEvent('contractJobNumber');
                this.dispatchFlowAttributeChangeEvent('contractJobLocation');
                this.dispatchFlowAttributeChangeEvent('customer');
                this.dispatchFlowAttributeChangeEvent('driver_state');
                this.dispatchFlowAttributeChangeEvent('applyRPP');
                this.dispatchFlowAttributeChangeEvent('customerPONumber');
            }
        }).catch((err)=>{
            console.log(JSON.stringify(err));
        })
    }
}

/**
 * '[{"Id":"a618J0000008Qx9QAE","SM_PS_Branch_Location_Number__c":"0693","SM_PS_Branch_Location__c":"MAUI PC693","SM_PS_Contract_Order__c":"8018J000000O4RBQA0","SM_PS_Contract_Order__r":{"Jobsite__c":"0Kt8J0000000AueSAE","Id":"8018J000000O4RBQA0","Jobsite__r":{"LocationId":"1318J000000534yQAA","AssociatedLocationNumber":"AL-15261393","Id":"0Kt8J0000000AueSAE","Location":{"Address__c":"12 Main Street  Toronto, ON M7N7B3","Id":"1318J000000534yQAA"}}}}]'
 */