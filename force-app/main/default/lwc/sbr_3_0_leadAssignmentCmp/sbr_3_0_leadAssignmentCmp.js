import { LightningElement, api, track, wire } from 'lwc';
import { updateRecord,getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import getUserRecord from '@salesforce/apex/SBR_3_0_UserLocationDA.getUserRecord';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import ID_LEAD from '@salesforce/schema/Lead.Id';
import OWNER_LEAD from '@salesforce/schema/Lead.OwnerId';
import LAT_LEAD from '@salesforce/schema/Lead.Latitude';
import LON_LEAD from '@salesforce/schema/Lead.Longitude';
import fetchTerritoryReps from '@salesforce/apex/SBR_3_0_Invocable_RepsByTerritoryNoAR.getTerritoryRepsByCoordinates';


export default class Sbr_3_0_leadAssignmentCmp extends NavigationMixin(LightningElement) {
    @api recordId;
    @api relatedRecordId;
    @api objectApiName;
    @track selectedUserId;
    @track userId;
    @track repResponses = [];
    userAR = [];
    availableUsers = [];
    availableUsersOptions=[];
    leadLattitude;
    leadLongitude;
    userList;
    isSpinner=false;
    repIds=[];
    allOsr=[];
    repDetailsArray = [];
    errorAssignToRequired=false;
    apiParameterProspectType='Account';

    @wire(getRecord,{recordId:'$recordId',fields:[LAT_LEAD ,LON_LEAD]})
    leadDetails({error, data}) {
        this.isSpinner=true;
        this.isListView=false;
        
        // Api call with Lead lattitute and Longitute
        if(data){

            console.log("LEAD Details:"+ JSON.stringify(data));
            this.leadLattitude=data.fields.Latitude.value;
            this.leadLongitude=data.fields.Longitude.value;
            
            fetchTerritoryReps({ latitude: this.leadLattitude, longitude: this.leadLongitude })
            .then(result => {
                this.repResponses =result;
                this.repDetailsArray = result.map(item => {
                        return {
                            Id: item.Id,
                            AnalysisRegionName: item.Analysis_Region2__c ? item.Analysis_Region2__r.Name : '-',
                            RepType: item.Rep_Type__c || '-',
                            RepId: item.RepId__c || '-',
                            Sales_Rep_Name__c: item.Sales_Rep_Name__c || '-'
                        };
                    });
                console.log('Rep Details Array: ', this.repDetailsArray);

                this.isSpinner = false;
                this.isListView = true;
            })
            .catch(error => {
                console.error('Error fetching rep data: ', error);
                this.isSpinner = false;
            });


        }else if (error) {
            console.error('Error fetching lead data: ', error);
        }
    }

    getUserData() {
        if (this.userId) {
            getUserRecord({ userId: this.userId })
                .then(result => {
                    console.log('result ', result);
                    this.selectedUserId = result[0].User__c;
                    console.log('$$getting user data ', this.selectedUserId);
                })
                .catch(error => {
                    console.error(error);
                });
        }
    }

    handleSave() {
        this.isSpinner = true;
        console.log('selected user ', this.selectedUserId);
        if (this.selectedUserId != undefined) {
            this.errorAssignToRequired = false;
            const fields = {};
            fields[ID_LEAD.fieldApiName] = this.recordId;
            fields[OWNER_LEAD.fieldApiName] = this.selectedUserId;
            const recordInput = { fields };
            updateRecord(recordInput)
                .then(() => {
                    this.isSpinner = false;
                    this.navigateToRecordPage();
                })
                .catch(error => {
                    this.isSpinner = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            message: error.body.message,
                            variant: 'error'
                        })
                    );
                });
        } else {
            this.isSpinner = false;
            this.errorAssignToRequired = true;
        }
    }

     
    close(){
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
            recordId: this.recordId,
            actionName: 'view'
        }
        });
	}

    handleRepSelect(event){
            // this.selectedUserId=event.target.dataset.id;
            // const userId = event.target.dataset.id;
            // this.getUserRecord(userId);
            this.userId = event.target.dataset.id;
			console.log('user id ', this.userId);
            this.selectedUserId = null;
            this.getUserData();
            const allRadio = this.template.querySelectorAll('input');
            for (let eachRadio of allRadio){
                console.log(eachRadio.checked);
                console.log(eachRadio.name);
                if(eachRadio.name==event.target.dataset.id){
                    eachRadio.checked =true;
                }else{
                    eachRadio.checked =false;
                }
            }
    }

    navigateToRecordPage() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view'
            }
        },
            true // Replaces the current page in your browser history with the URL to resolve caching issue
        );
    }
}