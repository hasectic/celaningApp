# celaningApp
Business Scenario: Create a system for managing a professional cleaning services company that operates in a major metropolitan area

Overview: The company works with a team that works with individuals cleaning private homes and also with companies cleaning offices.

The job delivery unit is always cleaners per day. (e.g.: a private homeowner hires one cleaner for one day, a large office hires three cleaners for one day)

The jobs can be booked individually (ad-hoc) or with the following recurrences: weekly, bi-weekly or monthly

Payment method is always a Credit Card.

The standard rate is 180 USD/cleaner/day, recurring jobs have a 10% discount

The company employees works on commission, the gross revenue for each job is split 50/50 (50% is company revenue and 50% is the employee pay)

The company needs to keep track of: all booked and executed jobs the total revenue generated and the number of jobs executed per client the amount due and paid and the number of jobs executed by each cleaner

Additional Feature 1: A dashboard displaying the number of jobs executed and booked for the current week. Display the client address (where the job will be executed on Google Maps)

Additional Feature 2: Consider the cleaners are paid every 1st and 15th of each month and design a system that accrues all jobs executed by each cleaner and keep track of all payments made to the cleaner. All jobs executed between the 1st and the 14th of each month is paid on the 15th All jobs executed between the 15th and last day of the month are paid on the 1st


One component for Booking creation : BookingCreation
one component to show map on booking : showAddress
Controller to booking creation : BookingCreateController


Batch class for recurring booking creation 
BookingGenerationBatch


Batch class for payment generation
PaymentCreationBatch


Trigger to execute booking and cancelled booking
BookingTrigger
BookingTriggerHelper


object : 
Account as client
contact as employee
Leave
Booking
Job Delivery
Payment

