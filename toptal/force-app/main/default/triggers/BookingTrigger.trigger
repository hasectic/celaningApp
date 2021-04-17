trigger BookingTrigger on Booking__c (before update) {
    
    if(trigger.isBefore && trigger.isUpdate){
        Set<String> setBookingIds = new Set<String>();
        List<Booking__c> listBooking = new List<Booking__c>();
        
        for(Booking__c booking : trigger.New){
            if(String.isNotBlank(booking.Status__c) && booking.Status__c != trigger.oldMap.get(booking.Id).Status__c
               && booking.Status__c == 'Cancelled')
                setBookingIds.add(booking.Id);
            
            if(String.isNotBlank(booking.Status__c) && booking.Status__c != trigger.oldMap.get(booking.Id).Status__c
               && booking.Status__c == 'Executed')
                listBooking.add(booking);
        }
        
        //To delete Job Delivery if Booking get cancelled
        if(setBookingIds.size() > 0)
            BookingTriggerHelper.deleteJobDelivery(setBookingIds);
        
        //To update payment per job value if Booking get executed
        if(listBooking.size() > 0)
            BookingTriggerHelper.updateJobDelivery(listBooking);
    }
    
    
}