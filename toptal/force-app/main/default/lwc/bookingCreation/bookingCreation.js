/* eslint-disable no-console */
import { LightningElement, track, wire, api } from 'lwc';
import retriveCustomerInfo from '@salesforce/apex/BookingCreateController.retriveBookingInfo';
import saveAppointment from '@salesforce/apex/BookingCreateController.saveAppointment';
import { updateRecord } from 'lightning/uiRecordApi';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import Server_Error from '@salesforce/label/c.Server_Error';

import recurringType from '@salesforce/schema/Booking__c.Recurring_Type__c';

import { getPicklistValues } from 'lightning/uiObjectInfoApi';

export default class BookingCreation extends NavigationMixin(LightningElement) {
     Bookingtemp = {Payment_Mode__c:'',Total_Paid_Amount__c:'',Booking_Date__c: '', Recurring__c: '', Discount__c: '', Recurring_Type__c: '',Cleaning_Amount__c:'' };
    @track isLoading = false;
    mapMarkers;
    bookingid;
    @api recordId;
    error;
    @track recurringTypeOption = [];
    CustomerName;
    currentCustomerId;
    ClientType;
    assetList;
    cleanAvailLabel;
    okselected = [];
    discountRate;
     recur = false;
   numberOfWorker;
     discountDetail;
    

    // GET recurringType PICKIST VALUES
    @wire(getPicklistValues, { recordTypeId: '012000000000000AAA', fieldApiName: recurringType })
    wiredrecurringTypeValue({ error, data }) {
        if (data) {
            this.recurringTypeOption = data.values;
        }else if (error) {
            /*eslint-disable  no-console*/
            console.log('== recurringTypeOption PickList Error ', error);
        }
    }
    
    
    //Constructor
    connectedCallback() {
        this.isLoading = true;
        retriveCustomerInfo({
            recordId: this.recordId
        }).then(result => {            
           // if (result === Server_Error) {
             //   this.error = result;
           // } else {
                //console.log(JSON.stringify(result)+'>>>');
                let obj = Object.assign({},result); //JSON.parse(JSON.stringify(result));
                //console.log(obj.client+'>>>');
                this.error = undefined;
                this.currentCustomerId = obj.client.Id;
                this.bookingid =  this.currentCustomerId;
                this.CustomerName = obj.client.Name;
                this.ClientType = obj.client.Type;
                this.numberOfWorker = obj.numberOfWorker ;
                this.discountRate = obj.discount ;
                this.Bookingtemp = obj.booking;
                this.Bookingtemp.Recurring__c=false;
                this.Bookingtemp.Total_Paid_Amount__c=this.Bookingtemp.Cleaning_Amount__c;
                this.recur=false;
                this.assetList=[];
                if(result.conList.length>0){
                    for(let i = 0; i< obj.conList.length; i++){
                        let lbl=obj.conList[i].Name;
                        if(obj.conList[i].EMP_ID__c)
                        lbl+=' - '+obj.conList[i].EMP_ID__c;
                        this.assetList.push({label : lbl, value : obj.conList[i].Id});
                    }
                }else{
                    this.showErrorDetails('Number of Cleaner needed for the job is not available, please try for another date.','');  
                }
                this.cleanAvailLabel = "Please select "+this.numberOfWorker+" Cleaner(s)";
                this.mapMarkers= [{
                    location: {
                        City: obj.client.ShippingStreet,
                        Country: obj.client.ShippingCountry,
                        PostalCode: obj.client.ShippingPostalCode,
                        State: obj.client.ShippingState,
                        Street: obj.client.ShippingStreet
                    },
                    value: this.CustomerName,
                    title: this.CustomerName,
                    description: 'Address for cleaning', //escape the apostrophe in the string using &#39;
                    icon: 'standard:account'
                }];
                this.isLoading = false;
               // console.log(this.Bookingtemp.Cleaning_Amount__c+'>>>');
           // }            
        }).catch(error => {
            this.isLoading = false;            
            this.showErrorDetails(error,'');
        })
       
    }
    handleChange(e) {
        if(e.detail.value.length<=this.numberOfWorker)
            this.okselected = e.detail.value;
        else
            this.showErrorDetails(this.numberOfWorker+' cleaner(s) already selected.','');
    }

    // Handle On Change Events
    handlefield(event) {
        let proTyname = event.target.name;
        if (proTyname === 'Recurring__c') {
            this.Bookingtemp[proTyname] = event.target.checked;
            if (this.Bookingtemp[proTyname]){
                this.recur=true;
                this.Bookingtemp.Discount__c = this.Bookingtemp.Cleaning_Amount__c * this.discountRate * .01; 
                this.discountDetail = " "+this.Bookingtemp.Discount__c+"  ("+this.discountRate+"%)";
            }
            else{
                this.recur=false;
                this.Bookingtemp.Discount__c=0;
            }
            this.Bookingtemp.Total_Paid_Amount__c = this.Bookingtemp.Cleaning_Amount__c - this.Bookingtemp.Discount__c;
        }
        else
            this.Bookingtemp[proTyname] = event.target.value; 
    }

   
   
    // save method to create Appointment
    saveMethod() {
        console.log('>>>ok');
        this.isLoading = true;
        if (this.validationCheckMethod()) {
            let str = String(this.okselected);
            if(!this.Bookingtemp.Recurring__c)
                this.Bookingtemp.Discount__c=0;
            console.log(this.okselected+'>>>nook'+str);
            saveAppointment({
                recordId: this.currentCustomerId,
                data: JSON.stringify(this.Bookingtemp),
                jdEmployeeIDs: str
            })
                .then(result => {
                    this.isLoading = false;
                    if (result.startsWith("a05")) {                        
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Success',
                                message: 'Booking Created.',
                                variant: 'success'
                            })
                        );
                        this.redirectToBookingDetail(result);
                    }
                    else {
                        this.showErrorDetails(result,'');
                    }
                })
                .catch(error => {
                    this.isLoading = false;                    
                    this.showErrorDetails(error,'');
                })
        }
       /* else {
            this.isLoading = false;           
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Something is wrong',
                    message: 'Check your inputs and try again.',
                    variant: 'error'
                })
            );
        }*/
    }
    validationCheckMethod(){
      //  console.log(this.Bookingtemp.Booking_Date__c);
        if(!this.Bookingtemp.Booking_Date__c){
            this.isLoading = false; 
            this.showErrorDetails('Entrer Booking Date.','Booking Date blank');          
            return false;
        }
        else if(this.Bookingtemp.Booking_Date__c<=new Date().toISOString().slice(0, 10)){
            this.isLoading = false; 
            this.showErrorDetails('Booking Date should be in the future','Booking Date');          
            return false;
        }
        if(this.Bookingtemp.Recurring__c && !this.Bookingtemp.Recurring_Type__c){
            this.isLoading = false;     
            this.showErrorDetails('Please choose recurring type.','Recurring Type Missing');
            return false;
        }
        if(this.okselected.length <this.numberOfWorker){
            this.isLoading = false; 
            this.showErrorDetails('Please choose cleaner.','Cleaner');          
            return false;
        }
       
           
        return true;
    }
  
    // redirect to workOrder detail page
    redirectToBookingDetail(bookingId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                "recordId": bookingId,
                "objectApiName": "Booking__c",
                "actionName": "view"
            },
        });
    }
    //method to show toast error message
    showErrorDetails(error,title) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: error,
                variant: 'error'
            })
        );
    }
    //Method to close the quick action
    closeModal() {
        console.log('>>'+this.recordId);
        const value = this.recordId;
        // Fire the custom event of Aura
        this.dispatchEvent(new CustomEvent('SubmitReq', {detail: {value}}));
    }

}