public class BookingTriggerHelper {
    
    public static void deleteJobDelivery(Set<String> setBookingIds){
        List<Job_Delivery__c> listJobDelivery = [SELECT Id FROM Job_Delivery__c WHERE Booking__c IN :setBookingIds];
        if(listJobDelivery.size() > 0)
            delete listJobDelivery;
    }
    
    public static void updateJobDelivery(List<Booking__c> listBooking){
        Map<String,Booking__c> mapBookingIdToEMPPayment = new Map<String,Booking__c>();
        List<Job_Delivery__c> listJobDelivery = new List<Job_Delivery__c>();
        
        for(Booking__c booking : listBooking){
            if(booking.Payment_For_Employee__c != NULL)
                mapBookingIdToEMPPayment.put(booking.Id,booking);
        }
        
        if(mapBookingIdToEMPPayment.keySet().size() > 0){
            for(Job_Delivery__c jobDelvry : [SELECT Id,Payment_Per_Job__c,Booking__c,Status__c FROM Job_Delivery__c WHERE Booking__c IN: mapBookingIdToEMPPayment.keySet()]){
                if(mapBookingIdToEMPPayment.containsKey(jobDelvry.Booking__c)){
                    jobDelvry.Payment_Per_Job__c = mapBookingIdToEMPPayment.get(jobDelvry.Booking__c).Payment_For_Employee__c;
                    jobDelvry.Status__c= 'Executed';
                    jobDelvry.Delivery_Date__c = mapBookingIdToEMPPayment.get(jobDelvry.Booking__c).Booking_Date__c ;
                    listJobDelivery.add(jobDelvry);
                }
            }
        }

        if(listJobDelivery.size() > 0)
            update listJobDelivery;
    }
}