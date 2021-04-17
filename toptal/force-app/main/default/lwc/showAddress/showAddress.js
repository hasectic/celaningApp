import { LightningElement ,api} from 'lwc';
import retriveMapInfo from '@salesforce/apex/BookingCreateController.retriveMapInfo';
import { updateRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
export default class ShowAddress extends LightningElement {
    @api recordId;
    mapMarkers;
    
    connectedCallback() {
        
        this.isLoading = true;
        retriveMapInfo({
            recordId: this.recordId
        }).then(result => {            

                let obj = Object.assign({},result); //JSON.parse(JSON.stringify(result));
                console.log('>>>');
                this.error = undefined;
                this.mapMarkers= [{
                    location: {
                        City: obj.Client__r.ShippingStreet,
                        Country: obj.Client__r.ShippingCountry,
                        PostalCode: obj.Client__r.ShippingPostalCode,
                        State: obj.Client__r.ShippingState,
                        Street: obj.Client__r.ShippingStreet
                    },
                    value: obj.Client__r.name,
                    title: obj.Client__r.name,
                    description: 'Address for cleaning', //escape the apostrophe in the string using &#39;
                    icon: 'standard:account'
                }];
                this.isLoading = false;
               // console.log(this.Bookingtemp.Cleaning_Amount__c+'>>>');
           // }            
        }).catch(error => {
            this.isLoading = false;            
           // this.showErrorDetails(error,'');
        })
    }
}