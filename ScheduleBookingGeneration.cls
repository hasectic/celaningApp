global class ScheduleBookingGeneration implements Schedulable {
   global void execute(SchedulableContext sc) {
      BookingGenerationBatch b = new BookingGenerationBatch(); 
      database.executebatch(b,1);
   }
}