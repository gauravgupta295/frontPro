import LightningDatatable from 'lightning/datatable';
import imageTableItemType from './imageTableItemTemplate.html';

export default class Sbr_3_0_customLineItems extends LightningDatatable {
    
    static customTypes = {
        image: {
            template: imageTableItemType,
            typeAttributes: ['imgUrl', 'altText']
        }
    }
}