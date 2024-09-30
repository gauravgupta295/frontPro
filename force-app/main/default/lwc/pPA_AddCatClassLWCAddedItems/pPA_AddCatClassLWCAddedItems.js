import { api } from 'lwc';
import LightningModal from 'lightning/modal';
import handleUpdateProducts from '@salesforce/apex/PPA_AddCatClassController.handleUpdateProducts';

export default class pPA_AddCatClassLWCAddedItems extends LightningModal {
    @api addedRecords;
    @api recordId;
    showSpinner = false;
    
    addToPriceList() {
        let pushRecords = [];

        this.showSpinner = true;

        if (this.addedRecords.length > 0) {
            for (var i = 0; i < this.addedRecords.length; i++) {        
                let pushRecord = {
                    recordId: this.addedRecords[i].Id,
                    Source: this.addedRecords[i].Source,
                    SuperCategory: this.addedRecords[i].SuperCategory,
                    Category: this.addedRecords[i].Category,
                    SubCategory: this.addedRecords[i].SubCategory,
                    CatClass: this.addedRecords[i].CatClass,
                    ProductName: this.addedRecords[i].ProductName,
                    ApplyRateType: this.addedRecords[i].ApplyRateType,
                    CatClassOwner: this.addedRecords[i].CatClassOwner,
                    MinRate: this.addedRecords[i].MinRate,
                    NewDay: this.addedRecords[i].NewDay,
                    NewWeek: this.addedRecords[i].NewWeek,
                    NewMonth: this.addedRecords[i].NewMonth,
                    MinDay: this.addedRecords[i].MinDay,
                    MinWeek: this.addedRecords[i].MinWeek,
                    MinMonth: this.addedRecords[i].MinMonth,
                    priceListId: this.recordId
                };
      
                pushRecords.push(pushRecord);
            }
      
            handleUpdateProducts({ updateProducts: JSON.stringify(pushRecords) })
                .then((result) => {
                    this.close('OK');
                })
                .catch((error) => {
                    this.showSpinner = false;
                    this.error = error;
                    console.log(error);
                });
        }
    }

    handleRemoveProduct(event){
       const key = event.target.dataset.key;
       this.addedRecords = this.addedRecords.filter(rec => rec.Id !== key);

       if(this.addedRecords.length == 0) {
          this.close(this.addedRecords);
       }
    }

    handleRemoveAll(){
        this.addedRecords = [];
        this.close(this.addedRecords);
    }

    handleClose() {
        this.close(this.addedRecords);
    }
}