import { LightningElement,api } from 'lwc';

export default class Sbr_3_0_sfsGenericDataTable extends LightningElement {
    //Public exposed property
    @api title;
    @api message;
    @api messageTitle;
    @api tableRecs;
    @api columns;
    @api addButtonLabel;
    @api viewButtonLabel;
    @api editButtonLabel;
    @api deleteButtonLabel;
    @api refreshButtonLabel;
    @api showTable;
    @api hideLastColumn=false;
    @api hideAllButtons=false;
    @api buttonHideMsg


    selectedRecords=[];
    showEditButton=false;
    showDeleteButton=false;
    showAddButton=true;
    showViewButton=false;

    // To handle selection of records
    handleSelect(event){
        //console.log("FROM ROW SELECTED:"+JSON.stringify(event.target.dataset.detail.Name)); 
        let recId =event.target.dataset.id;
        // Logic to add and remove selected records in table by checkbox 
        if(event.target.checked==true){
            this.selectedRecords.push({Id:recId,
                detail:event.target.dataset.detail
            });
            console.log("hey;"+JSON.stringify(this.selectedRecords));
            // Created the event with the data.
            const selectedEvent = new CustomEvent("handleselectclick", {
                detail: this.selectedRecords,bubbles: true
            });
        
            // Dispatches the event.
            this.dispatchEvent(selectedEvent);
        }
        else{
            const index = this.selectedRecords.findIndex(function(item,i){
                return item.Id === recId;
            });
            console.log("hey;"+index );
            this.selectedRecords.splice(index,1);
            console.log("hey;"+this.selectedRecords);
            // Created the event with the data.
            const deSelectedEvent = new CustomEvent("handleselectclick", {
                detail: this.selectedRecords,bubbles: true
            });
        
            // Dispatches the event.
            this.dispatchEvent(deSelectedEvent);
        }

        // Logic to show and hide button 
        if(this.selectedRecords.length>1){
            this.showDeleteButton =true;
            this.showEditButton =false;
            this.showAddButton=false;
            this.showViewButton=false;
        }else if(this.selectedRecords.length==1){
            this.showEditButton =true;
            this.showDeleteButton =true;
            this.showAddButton=false;
            this.showViewButton=true;
        }else {
            this.showDeleteButton =false;
            this.showEditButton =false;
            this.showAddButton=true;
            this.showViewButton=false;
        }
    }

    // To handle click of add button
    handleAddClick(event){
        console.log('child Add');
        // Created the event with the data.
        const selectedEvent = new CustomEvent("handleaddclick", {
            detail: this.selectedRecords
        });

        // Dispatches the event.
        this.dispatchEvent(selectedEvent);
    }

    // To handle click of view button
    handleViewClick(event){
        debugger;
        console.log('Checkpoint view button' + JSON.stringify(this.selectedRecords));
        // Created the event with the data.
        const selectedEvent = new CustomEvent("handleviewclick", {
            detail: this.selectedRecords
        });

        // Dispatches the event.
        this.dispatchEvent(selectedEvent);
    }

    // To handle click of edit button
    handleEditClick(event){
        // Created the event with the data.
        const selectedEvent = new CustomEvent("handleeditclick", {
            detail: this.selectedRecords
        });

        // Dispatches the event.
        this.dispatchEvent(selectedEvent);
    }

    //To handle click of Delete Click
    handleDeleteClick(event){
        console.log('child');

        // Created the event with the data.
        const selectedEvent = new CustomEvent("handledeleteclick", {
            detail: this.selectedRecords
        });

        // Dispatches the event.
        this.dispatchEvent(selectedEvent);
    }

    //  Use this fucntion to clear selections from table
    @api
    handleRemoveSelection(){
        this.selectedRecords=[];
        this.showDeleteButton=false;
        this.showEditButton=false;
        this.showAddButton=true;
        this.showViewButton=false;
        for (let checks of this.template.querySelectorAll("[data-field='checkbox']")){
            checks.checked=false;
        };
    }
}