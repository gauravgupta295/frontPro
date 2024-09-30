import saveSObjects from "@salesforce/apex/SBR_3_0_LineItemEditorCmpController.saveSObjects";
import { Logger } from "c/sbr_3_0_frontlineUtils";
import { track } from "lwc";
const logger = Logger.create(true);

/*FRONT-8693*/
async function updateLineItems(quoteItems, orderItems, objType) {
  const reslt = await saveSObjects({
    quoteLines: [quoteItems],
    orderLines: orderItems,
    objectType: objType
  });
}

const LineItemMixin = (Base) => {
  return class extends Base {
    addConsumableItem(item) {
      try {
        let id = Math.random().toString(16).slice(2);
        let subTotal = 0.0;
        //calculate subtotal based on Quantity and Rates
        if (item.lineItem.quantity && item.lineItem.sellPrice) {
          subTotal = item.lineItem.quantity * item.lineItem.sellPrice;
        }
        let _item = {
          Id: id,
          Product: item.lineItem.id,
          Name: item.lineItem.name,
          Quantity: item.lineItem.quantity,
          Sale_Price: item.lineItem.sellPrice,
          Item_Subtotal: subTotal,
          Item_Type: item.lineItem.itemType,
          _isChecked: false,
          productType: item.lineItem.productType,
          stockClass: item.lineItem.stockClass, //25958
          itemNumber: item.lineItem.itemNumber, //25958
          hasKit: false,
          noAvailability: ""
        };
        if (this.objectApiName) {
          this.lineItems.push(_item);
        }
        this.cartSalesLineItems = [...this.cartSalesLineItems, _item];
        this.updateLineItemsTable();
        this.sendIsCartEmpty();
        this.beginRefresh();
      } catch (error) {
        logger.log("❌ error here ❌ " + error.stack);
      }
    }

    /*FRONT-11379 */
    countMap = new Map();
    _selectedLineItems = [];
    @track
    _selectedLineItemsFiltered = [];
    toggleRemoveAllFooter = false;
    get isCartFilled() {
      return this.cartSalesLineItems.length > 0 || this.lineItems.length > 0
        ? true
        : false;
    }
    get isCountMapFilled() {
      let retVar = false;
      this.countMap.forEach((val) => {
        if (val > 0) retVar = true;
      });
      return retVar;
    }

    get salesItemsDynamicLabel() {
      return "Sales Items (" + this.cartSalesLineItems.length + ")";
    }
    get rentalLineItemsDynamicLabelForPI() {
      return "Rental Items (" + this.lineItems.length + ")";
    }

    handleRemoveSelectedRecordFromPI(event) {
      try {
        if (event?.detail?.payload) {
          this.cartSalesLineItems = this.cartSalesLineItems.filter(
            (itm) => itm.Id !== event?.detail?.payload?.Id
          );

          this._selectedLineItemsFiltered =
            this._selectedLineItemsFiltered.filter(
              (itm) => itm.Id !== event?.detail?.payload?.Id
            );
        } else {
          this._selectedLineItemsFiltered = [];
        }
      } catch (error) {
        logger.log("error >> " + error.stack);
      }
    }

    get selectedRecordsCount() {
      return this._selectedLineItemsFiltered?.length;
    }

    get selectedRecordsCountCheck() {
      return this._selectedLineItemsFiltered?.length > 0;
    }
    updateSelectedRecordsCount(event) {
      this._selectedLineItems.push(event?.detail?.selectedRecord);

      let isRecordPresentInFilteredArray = this._selectedLineItemsFiltered.some(
        (itm) => {
          return itm.Id === event?.detail?.selectedRecord?.Id;
        }
      );

      if (!isRecordPresentInFilteredArray && event?.detail?.isChecked) {
        this._selectedLineItemsFiltered.push(event?.detail?.selectedRecord);
      }

      if (isRecordPresentInFilteredArray && !event?.detail?.isChecked) {
        let tmpSelectedLineItems = this._selectedLineItemsFiltered.filter(
          (obj) => {
            return obj.Id !== event?.detail?.selectedRecord?.Id;
          }
        );
        // logger.log("tmpSelectedLineItems >> " + tmpSelectedLineItems);
        this._selectedLineItemsFiltered = [...tmpSelectedLineItems];
      }
    }

    handleClearCartOnMobile(event) {
      this.clearAllItems();
    }

    handleEditDetailsOnMobile(event) {
      this.dispatchEvent(new CustomEvent("displaycartinfo"));
    }

    clearAllItems() {
      this.dispatchEvent(new CustomEvent("clearallitems"));
    }

    selectionPanelActionsForPI() {
      let allGCs = this.template.querySelectorAll(
        "c-sbr_3_0_line-items-grid-section-cmp"
      );

      allGCs.forEach((gc) => {
        gc.selectionPanelActionsForPI();
      });

      this._selectedLineItemsFiltered = [
        ...this.lineItems,
        ...this.cartSalesLineItems
      ];
    }

    toggleRemoveModalForPI() {
      // logger.log("!!! toggleRemoveModalForPI");
      // this.template.querySelector(".removeModalOnLI").toggleModal();
    }

    updateSalesLineItemGridData(event) {
      this.cartSalesLineItems = structuredClone(event.detail);
    }
    /* FRONT-24214 : Filtering substitute lineItems from Sales/Misc row actions */
    formatSalesColumns(salesColumns) {
      let tmpSalesColumns = JSON.parse(JSON.stringify(salesColumns));
      tmpSalesColumns.forEach((col) => {
        if (
          col.type &&
          col.type === "action" &&
          col.typeAttributes.rowActions
        ) {
          let formattedRow = col.typeAttributes.rowActions.filter(
            (action) => action.name !== "substitute_item"
          );
          col.typeAttributes.rowActions = formattedRow;
        }
      });
      return tmpSalesColumns;
    }
  };
};

export { LineItemMixin, updateLineItems };