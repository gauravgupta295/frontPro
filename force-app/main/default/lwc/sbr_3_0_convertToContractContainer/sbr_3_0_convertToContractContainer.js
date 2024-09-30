import { LightningElement } from 'lwc';
import {loadStyle} from 'lightning/platformResourceLoader';
import customTableCSS from '@salesforce/resourceUrl/sbr_3_0_customDataTable_css';


const salesActions = [
  { label: "Product Details", name: "product_details" }
];

export default class Sbr_3_0_convertToContractContainer extends LightningElement {

    isMobile = false;
    tabsPanelHeight;
    _iconName = "standard:lead_list";
    accname = 'Rental Items';
    trueVar = true;
    isRentalAccordianIsActive = true;
    isSalesAccordianIsActive = true;
    accordianClassSales = "slds-accordion__section slds-is-open";
    accordianClassRental = "slds-accordion__section slds-is-open";
    subText = '17 of 50 line item(s) currently selected for conversion';
    preSelectedRows=['000','111','222','333','444','555','666','777','888','999'];  //FRONT-20938
    isCssLoaded = false;
    inventoryNumber=10;
    rentalColumns = [
        { label: 'Cat Class Description', fieldName: 'catClassDesc' , hideDefaultActions: true},
        { label: 'Cat Class', fieldName: 'catClass', hideDefaultActions: true },
        { label: 'Quantity', fieldName: 'quantity', type: 'number', cellAttributes: { alignment: 'left' }, hideDefaultActions: true},
        { label: 'Asset #', fieldName: 'assetNo', hideDefaultActions: true, cellAttributes: { class :{fieldName:'assetGreen'}}},   //FRONT-20938
        { label: 'Status', fieldName: 'status', hideDefaultActions: true},
        { label: 'Available Assets', fieldName: 'availableAssets', hideDefaultActions: true },
        {
          type: 'action',
          typeAttributes: {
              rowActions: this.getRowActions,
              menuAlignment: 'right'
          }, hideDefaultActions: true
        } 
      ];
      
    salesColumns = [
        { label: 'Item Name', fieldName: 'itemName', hideDefaultActions: true },
        { label: 'Part/Item #', fieldName: 'itemNumber', hideDefaultActions: true},
        { label: 'Stock/Vendor', fieldName: 'vendor', hideDefaultActions: true },
        { label: 'Quantity', fieldName: 'quantity', type: 'number', cellAttributes: { alignment: 'left' }, hideDefaultActions: true },
        { label: 'Available', fieldName: 'available', type: 'number', cellAttributes: { alignment: 'left' }, hideDefaultActions: true},
        {
          type: 'action',
          typeAttributes: {
              rowActions: salesActions,
              menuAlignment: 'right'
          },
          hideDefaultActions: true
        } 
      ];
    
      rentalData = [
        { catClassDesc: '000', Id: '000', quantity: 1, catClass: '0070025', assetNo: 'Assign Asset', status: 'Available', availableAssets: 0}, //FRONT-20938 starts
        { catClassDesc: '111', Id: '111', quantity: 1, catClass: '0070025', assetNo: '0025', status: 'Available', availableAssets: 0},
        { catClassDesc: '222', Id: '222', quantity: 1, catClass: '0070025', assetNo: '0025', status: 'Available', availableAssets: 0},
        { catClassDesc: '333', Id: '333', quantity: 1, catClass: '0070025', assetNo: '0025', status: 'Available', availableAssets: 0},
        { catClassDesc: '444', Id: '444', quantity: 1, catClass: '0070025', assetNo: '0025', status: 'Available', availableAssets: 0},
        { catClassDesc: '555', Id: '555', quantity: 1, catClass: '0070025', assetNo: '0025', status: 'Available', availableAssets: 0},
        { catClassDesc: '666', Id: '666', quantity: 1, catClass: '0070025', assetNo: '0025', status: 'Available', availableAssets: 0},
        { catClassDesc: '777', Id: '777', quantity: 1, catClass: '0070025', assetNo: '0025', status: 'Available', availableAssets: 0},
        { catClassDesc: '888', Id: '888', quantity: 1, catClass: '0070025', assetNo: '0025', status: 'Available', availableAssets: 0},
        { catClassDesc: '999', Id: '999', quantity: 1, catClass: '0070025', assetNo: '0025', status: 'Available', availableAssets: 0}   //FRONT-20938 ends
      ];

      salesData = [
        { itemName: '000', Id: '000', quantity: 25, itemNumber: 'XXX-XXXX', vendor: '0025', available: 0}, //FRONT-20938 starts
        { itemName: '111', Id: '111', quantity: 25, itemNumber: 'XXX-XXXX', vendor: '0025', available: 1},
        { itemName: '222', Id: '222', quantity: 25, itemNumber: 'XXX-XXXX', vendor: '0025', available: 2},
        { itemName: '333', Id: '333', quantity: 25, itemNumber: 'XXX-XXXX', vendor: '0025', available: 3},
        { itemName: '444', Id: '444', quantity: 25, itemNumber: 'XXX-XXXX', vendor: '0025', available: 4},
        { itemName: '555', Id: '555', quantity: 25, itemNumber: 'XXX-XXXX', vendor: '0025', available: 5},
        { itemName: '666', Id: '666', quantity: 25, itemNumber: 'XXX-XXXX', vendor: '0025', available: 6},
        { itemName: '777', Id: '777', quantity: 25, itemNumber: 'XXX-XXXX', vendor: '0025', available: 7},
        { itemName: '888', Id: '888', quantity: 25, itemNumber: 'XXX-XXXX', vendor: '0025', available: 8},
        { itemName: '999', Id: '999', quantity: 25, itemNumber: 'XXX-XXXX', vendor: '0025', available: 9}    //FRONT-20938 ends
      ];

      getRowActions( row, doneCallback ) {                //FRONT-20938 starts

        const actions = [];
        
        if ( row['assetNo'] === 'Assign Asset' ) {
            actions.push( {
                'label': 'Assign Asset',
                'name': 'Assign Asset'
            } );
        }
        else{
           actions.push( { label: "Re-Assign Asset", name: "reassign_asset" },
                         { label: "Remove Asset", name: "remove_asset" }, 
                         { label: "View Asset Details", name: "view_asset_details" })
        } 
        setTimeout( () => {
            doneCallback( actions );
        }, 200 );

    }   //FRONT-20938 ends

    renderedCallback(){                       //FRONT-20938 starts
        if(this.isCssLoaded) return
        this.isCssLoaded = true
        loadStyle(this,customTableCSS).then(()=>{
            console.log("Loaded Successfully")
        }).catch(error=>{ 
            console.error("Error in loading the colors")
        })
    }      //FRONT-20938 ends

    connectedCallback(){
        console.log('inside container');
        this.isMobile = window.matchMedia('(max-width: 480px)').matches;
        this.rentalData.forEach((record) => {                        //FRONT-20938
         record['assetGreen']='successLink'
        });
        console.log('Rental Data is ',this.rentalData);
    }

    accordianActive(event) {
      let currentAccordian = event.currentTarget.dataset.accordianName;
      console.log('event-> ', JSON.parse(JSON.stringify(event.currentTarget)));
      if(currentAccordian === "sales") {
        this.isSalesAccordianIsActive = !this.isSalesAccordianIsActive;
        if(this.isSalesAccordianIsActive) {
          this.accordianClassSales = "slds-accordion__section slds-is-open";
        } else {
          this.accordianClassSales = "slds-accordion__section";
        }
      } else if(currentAccordian === "rental") {
        this.isRentalAccordianIsActive = !this.isRentalAccordianIsActive;
      if(this.isRentalAccordianIsActive) {
        this.accordianClassRental = "slds-accordion__section slds-is-open";
      } else {
        this.accordianClassRental = "slds-accordion__section";
      }
      }
    }

}