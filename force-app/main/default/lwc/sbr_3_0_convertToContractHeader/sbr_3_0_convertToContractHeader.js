import { LightningElement, api } from 'lwc';

export default class Sbr_3_0_convertToContractHeader extends LightningElement {
    locationOptions = [];
    assetSearchTypePlaceholderFunc = 'Search this list';
    @api isRental = false;
    @api inventoryLabel = '';
    inventoryNumber = 10;
}